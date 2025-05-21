import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';
import '../../jobs/screens/post_job_screen.dart';
import '../../../core/services/api_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../jobs/screens/job_details_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<dynamic> _activeJobs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
        _loadActiveJobs();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _loadActiveJobs() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final jobs = await apiService.getActiveJobs();
      
      print('All jobs: $jobs'); // Debug log
      
      final activeJobs = jobs.where((job) {
        final status = job['status']?.toString().toLowerCase();
        print('Job ${job['id']} status: $status'); // Debug log
        // Show all jobs except completed and cancelled
        return status != 'completed' && status != 'cancelled';
      }).toList();

      print('Filtered active jobs: $activeJobs'); // Debug log

      if (mounted) {
        setState(() {
          _activeJobs = activeJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading active jobs: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
    
    try {
      final authService = context.read<AuthService>();
      await authService.logout();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
                  children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.name ?? ''),
            accountEmail: Text(_currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
              child: _currentUser?.profileImage != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _currentUser!.profileImage!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Text(
                      _currentUser?.name[0].toUpperCase() ?? '',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        ),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              if (_currentUser?.userType == 'customer') {
                Navigator.pushNamed(context, '/customer-profile');
              } else {
                Navigator.pushNamed(context, '/provider-profile');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              // Navigate to messages
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings
              Navigator.pop(context);
            },
                                      ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              // Navigate to help
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
                                ),
                              ],
                            ),
    );
  }

  Widget _buildCustomerHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                        ),
                      ),
                    ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            'Post a Job',
                            Icons.add_circle_outline,
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PostJobScreen(),
                                ),
                              );
                              if (result == true) {
                                // Add a small delay to allow backend to process
                                await Future.delayed(const Duration(seconds: 1));
                                _loadActiveJobs(); // Refresh jobs after posting
                              }
                            },
                          ),
                          _buildActionCard(
                            'My Jobs',
                            Icons.work_outline,
                            () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyJobsScreen(),
                          ),
                        );
                            },
                          ),
                          _buildActionCard(
                            'Notifications',
                            Icons.notifications_outlined,
                            () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                            },
                          ),
                          _buildActionCard(
                            'Profile',
                            Icons.person_outline,
                            () {
                              Navigator.pushNamed(context, '/customer-profile');
                            },
                          ),
                        ],
                      ),
              ],
            ),
          ),

          // Active Jobs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text(
                      'Active Jobs',
                        style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadActiveJobs,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyJobsScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                      ),
                      const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_activeJobs.isEmpty)
                  const Center(
                    child: Text('No active jobs found'),
                  )
                else
                  ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeJobs.length,
                    itemBuilder: (context, index) {
                      final job = _activeJobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.work),
                          ),
                          title: Text(job['job_type']?['name'] ?? 'Unknown Job Type'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Text(job['description'] ?? 'No description'),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${job['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                                style: TextStyle(
                                  color: _getStatusColor(job['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            try {
                              final apiService = context.read<ApiService>();
                              // Show loading indicator
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Loading job details...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              
                              // Fetch fresh job details
                              final freshJob = await apiService.getJobDetails(job['id']);
                              
                              if (mounted) {
                                // Navigate to job details and wait for result
                                final result = await Navigator.push(
                            context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailsScreen(job: freshJob),
                                  ),
                                );
                                
                                // If job status was updated, refresh the active jobs list
                                if (result == true) {
                                  _loadActiveJobs();
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading job details: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                            },
                          ),
                        ],
                      ),
          ),
                    ],
      ),
    );
  }

  Widget _buildProviderHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Jobs',
                    '5',
                    Icons.work_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '12',
                    Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    '4.8',
                    Icons.star,
                  ),
                ),
                  ],
                ),
          ),

          // Available Jobs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Jobs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.work),
                        ),
                        title: Text('Job Request ${index + 1}'),
                        subtitle: Text('Location: City Center'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Express interest in job
                          },
                          child: const Text('Express Interest'),
                        ),
                        onTap: () {
                          // Navigate to job details
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // My Active Jobs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Active Jobs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.work),
                        ),
                        title: Text('Active Job ${index + 1}'),
                        subtitle: Text('Status: In Progress'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Mark job as done
                          },
                          child: const Text('Mark Done'),
                        ),
                        onTap: () {
                          // Navigate to job details
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
              ),
            ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _currentUser == null
          ? const Center(child: Text('No user data available. Please log in again.'))
          : _currentUser!.userType == 'customer'
              ? _buildCustomerHome()
              : _buildProviderHome(),
    );
  }
} 