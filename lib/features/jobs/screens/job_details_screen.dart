import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import 'dart:async';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = false;
  List<dynamic> _providerRequests = [];
  bool _isLoadingRequests = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load provider requests if job is open
    if (widget.job['status']?.toString().toLowerCase() == 'open') {
      _loadProviderRequests();
      // Start periodic refresh every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (widget.job['status']?.toString().toLowerCase() == 'open') {
          _loadProviderRequests();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProviderRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final apiService = context.read<ApiService>();
      final jobId = widget.job['id'];
      
      // Ensure jobId is an integer
      if (jobId == null) {
        throw Exception('Job ID is null');
      }
      
      final int jobIdInt = jobId is int ? jobId : int.parse(jobId.toString());
      final requests = await apiService.getJobProviderRequests(jobIdInt);
      
      print('Loaded provider requests: $requests'); // Debug log
      
      if (mounted) {
        setState(() => _providerRequests = requests);
      }
    } catch (e) {
      print('Error loading provider requests: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading provider requests: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Icons.hourglass_empty;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateJobStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      if (status == 'completed') {
        // Check if job is in progress before allowing completion
        if (widget.job['status']?.toString().toLowerCase() != 'in_progress') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot complete job: Work must be in progress first'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
        try {
          await apiService.completeJob(widget.job['id']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job marked as completed successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate status was updated
          }
        } catch (e) {
          if (e.toString().contains('Provider has not marked this job as done yet')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot complete job: Provider must mark the job as done first'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            rethrow;
          }
        }
      } else if (status == 'cancelled') {
        await apiService.cancelJob(widget.job['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate status was updated
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleProviderAction(int providerId, bool isAccept) async {
    try {
      final apiService = context.read<ApiService>();
      final jobId = widget.job['id'];
      
      if (isAccept) {
        await apiService.acceptProvider(jobId, providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Provider accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Fetch fresh job details after accepting provider
          final freshJob = await apiService.getJobDetails(jobId);
          if (mounted) {
            setState(() {
              widget.job.clear();
              widget.job.addAll(freshJob);
            });
            // Pop back to previous screen with true to indicate status change
            Navigator.pop(context, true);
          }
        }
      } else {
        await apiService.declineProvider(jobId, providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Provider declined'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      // Refresh the provider requests list
      _loadProviderRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProviderRequestCard(Map<String, dynamic> request) {
    final providerProfile = request['provider_profile'];
    final user = providerProfile['user'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            providerProfile['rating'] ?? '0',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // View Profile button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderProfileScreen(
                          providerProfile: providerProfile,
                          user: user,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('View Profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Only show accept/decline buttons if job is open
            if (widget.job['status']?.toString().toLowerCase() == 'open')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleProviderAction(providerProfile['id'], false),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleProviderAction(providerProfile['id'], true),
                    child: const Text('Accept'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderRequests() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_providerRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No interested providers yet',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _providerRequests.length,
      itemBuilder: (context, index) {
        try {
          final request = _providerRequests[index];
          if (request == null) {
            print('Null request at index $index');
            return const SizedBox.shrink();
          }

          final providerProfile = request['provider_profile'];
          if (providerProfile == null) {
            print('Null provider profile at index $index');
            return const SizedBox.shrink();
          }

          final user = providerProfile['user'];
          if (user == null) {
            print('Null user data at index $index');
            return const SizedBox.shrink();
          }
          
          final name = user['name']?.toString() ?? 'Unknown Provider';
          final rating = providerProfile['rating']?.toString() ?? '0';
          final providerId = providerProfile['id'];
          
          return _buildProviderRequestCard(request);
        } catch (e) {
          print('Error building provider item at index $index: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildActionButtons() {
    final status = widget.job['status']?.toString().toLowerCase();
    
    // Don't show buttons if job is already completed or cancelled
    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (status == 'open')
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Note: You can only mark a job as complete after work has started',
                style: TextStyle(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (status == 'assigned')
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Provider has been assigned. Waiting for work to start.',
                style: TextStyle(
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _updateJobStatus('cancelled'),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              if (status == 'assigned')
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateJobStatus('in_progress'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (status == 'in_progress')
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateJobStatus('completed'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProviderRequests,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(widget.job['status']),
                                  color: _getStatusColor(widget.job['status']),
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${widget.job['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(widget.job['status']),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Job Type: ${widget.job['job_type']?['name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Description: ${widget.job['description'] ?? 'No description'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Estimated Cost: ${widget.job['estimated_cost']?.toString() ?? 'N/A'} Birr',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted: ${_formatDate(widget.job['created_at'])}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Show provider requests section if job is open
                    if (widget.job['status']?.toString().toLowerCase() == 'open') ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Provider Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildProviderRequests(),
                    ],
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }
}

class ProviderProfileScreen extends StatelessWidget {
  final Map<String, dynamic> providerProfile;
  final Map<String, dynamic> user;

  const ProviderProfileScreen({
    Key? key,
    required this.providerProfile,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? 'Unknown Provider';
    final phone = user['phone_number']?.toString() ?? 'N/A';
    final skills = providerProfile['skills']?.toString() ?? 'No skills listed';
    final experience = providerProfile['experience_years']?.toString() ?? '0';
    final rating = providerProfile['rating']?.toString() ?? '0';
    final bio = providerProfile['bio']?.toString() ?? 'No bio available';
    final location = providerProfile['location']?.toString() ?? 'Location not specified';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoSection('Contact Information', [
              _buildInfoRow(Icons.phone, 'Phone', phone),
              _buildInfoRow(Icons.location_on, 'Location', location),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection('Professional Details', [
              _buildInfoRow(Icons.star, 'Rating', rating),
              _buildInfoRow(Icons.work, 'Experience', '$experience years'),
              _buildInfoRow(Icons.build, 'Skills', skills),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection('About', [
              _buildInfoRow(Icons.description, 'Bio', bio),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 