import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import 'provider_job_details_screen.dart';

class ProviderMyJobsScreen extends StatefulWidget {
  const ProviderMyJobsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderMyJobsScreen> createState() => _ProviderMyJobsScreenState();
}

class _ProviderMyJobsScreenState extends State<ProviderMyJobsScreen> {
  List<dynamic> _requestedJobs = [];
  List<dynamic> _activeJobs = [];
  bool _isLoading = false;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      
      // Load both requested and active jobs
      final requestedResult = await apiService.getRequestedJobs();
      final activeResult = await apiService.getProviderSelectedJobs();
      
      if (mounted) {
        setState(() {
          _requestedJobs = requestedResult['data'] ?? [];
          _activeJobs = activeResult['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'interested':
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
      case 'pending':
        return Colors.blue;
      case 'interested':
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

  List<dynamic> get _filteredJobs {
    if (_selectedStatus == null) {
      // Combine both lists when no filter is selected
      return [..._requestedJobs, ..._activeJobs];
    }
    
    // Filter requested jobs
    final filteredRequested = _requestedJobs.where((job) => 
      job['status']?.toString().toLowerCase() == _selectedStatus?.toLowerCase()
    ).toList();
    
    // Filter active jobs
    final filteredActive = _activeJobs.where((job) => 
      job['job']['status']?.toString().toLowerCase() == _selectedStatus?.toLowerCase()
    ).toList();
    
    return [...filteredRequested, ...filteredActive];
  }

  String _getDisplayStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'interested':
        return 'PENDING';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text(
          'My Jobs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: Column(
          children: [
            // Status Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (selected) {
                      setState(() => _selectedStatus = null);
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF3A7D44),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedStatus == null ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _selectedStatus == 'pending',
                    onSelected: (selected) {
                      setState(() => _selectedStatus = 'pending');
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF3A7D44),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'pending' ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('In Progress'),
                    selected: _selectedStatus == 'in_progress',
                    onSelected: (selected) {
                      setState(() => _selectedStatus = 'in_progress');
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF3A7D44),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'in_progress' ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: _selectedStatus == 'completed',
                    onSelected: (selected) {
                      setState(() => _selectedStatus = 'completed');
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF3A7D44),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'completed' ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Cancelled'),
                    selected: _selectedStatus == 'cancelled',
                    onSelected: (selected) {
                      setState(() => _selectedStatus = 'cancelled');
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    selectedColor: const Color(0xFF3A7D44),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'cancelled' ? Colors.white : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),

            // Jobs List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7D44)),
                      ),
                    )
                  : _filteredJobs.isEmpty
                      ? Center(
                          child: Text(
                            'No jobs found',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            final jobData = job['job'] ?? job;
                            final status = jobData['status']?.toString().toLowerCase();
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: const Color(0xFF2D2D2D),
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProviderJobDetailsScreen(job: jobData),
                                    ),
                                  );
                                  
                                  // If job status was updated, refresh the list
                                  if (result == true) {
                                    _loadJobs();
                                  }
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3A7D44).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getStatusIcon(status),
                                              color: _getStatusColor(status),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  jobData['job_type']?['name'] ?? 'Unknown Job Type',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  jobData['description'] ?? 'No description',
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getDisplayStatus(status),
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${jobData['estimated_cost'] ?? '0.00'} Birr',
                                            style: const TextStyle(
                                              color: Color(0xFF3A7D44),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 