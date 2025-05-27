import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';
import '../../jobs/screens/post_job_screen.dart';
import '../../../core/services/api_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../jobs/screens/job_details_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';
import '../../jobs/screens/provider_job_details_screen.dart';
import '../../jobs/screens/provider_my_jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<dynamic> _activeJobs = [];
  List<dynamic> _requestedJobs = [];
  List<dynamic> _providerActiveJobs = [];
  bool _isLoading = false;
  bool _isLoadingRequested = false;
  bool _isLoadingProviderActive = false;
  bool _hasMoreProviderActiveJobs = false;
  int _currentProviderActivePage = 1;
  final ScrollController _providerActiveScrollController = ScrollController();
  double _lastScrollPosition = 0;
  int _totalProviderActiveJobs = 0;
  String _providerRating = "0";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _providerActiveScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
        if (user?.userType == 'customer') {
          _loadActiveJobs();
        } else {
          // Check if provider has a profile
          try {
            final apiService = context.read<ApiService>();
            final profile = await apiService.getProviderProfile();
            // If we get here, profile exists
            setState(() {
              _providerRating = profile['rating'] ?? "0";
            });
            _loadRequestedJobs();
            _loadProviderActiveJobs();
          } catch (e) {
            // If profile doesn't exist, redirect to profile setup
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/provider-profile-setup');
            }
          }
        }
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

  Future<void> _loadRequestedJobs() async {
    if (_currentUser == null || _currentUser!.userType != 'provider') return;

    setState(() {
      _isLoadingRequested = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.getRequestedJobs();
      print('Requested Jobs Response: $result'); // Debug log

      List<dynamic> jobs = [];
      if (result is Map<String, dynamic> && result.containsKey('data')) {
        jobs = List<dynamic>.from(result['data']);
      }

      if (mounted) {
        setState(() {
          _requestedJobs = jobs;
          _isLoadingRequested = false;
        });
      }
    } catch (e) {
      print('Error loading requested jobs: $e');
      if (mounted) {
        setState(() {
          _isLoadingRequested = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requested jobs: $e')),
        );
      }
    }
  }

  Future<void> _loadProviderActiveJobs({int page = 1}) async {
    if (_currentUser == null || _currentUser!.userType != 'provider') return;

    // Save the current scroll position before loading more
    if (page > 1) {
      _lastScrollPosition = _providerActiveScrollController.position.pixels;
    }

    setState(() {
      _isLoadingProviderActive = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.getProviderSelectedJobs(page: page);
      print('Provider Active Jobs Response: $result'); // Debug log
      
      if (result is Map<String, dynamic> && result.containsKey('data')) {
        final jobs = List<dynamic>.from(result['data']);
        // Filter to only show in_progress jobs on the frontend
        final inProgressJobs = jobs.where((job) => job['job']['status'] == 'in_progress').toList();
        final hasMorePages = result['next_page_url'] != null;
        
        // Get total in-progress jobs from the API response
        final totalInProgress = result['total_in_progress'] as int? ?? 0;
        
        if (mounted) {
          setState(() {
            if (page == 1) {
              _providerActiveJobs = inProgressJobs;
              _totalProviderActiveJobs = totalInProgress;
            } else {
              _providerActiveJobs.addAll(inProgressJobs);
              // Scroll back to the last position after a short delay
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_providerActiveScrollController.hasClients) {
                  _providerActiveScrollController.jumpTo(_lastScrollPosition);
                }
              });
            }
            _hasMoreProviderActiveJobs = hasMorePages;
            _currentProviderActivePage = page;
            _isLoadingProviderActive = false;
          });
        }
      } else {
        throw Exception('Invalid response format for provider active jobs');
      }
    } catch (e) {
      print('Error loading provider active jobs: $e');
      if (mounted) {
        setState(() {
          _isLoadingProviderActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading provider active jobs: $e')),
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
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _currentUser?.name ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              _currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3A7D44),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF3A7D44).withOpacity(0.2),
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
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1557683316-973673baf926?ixlib=rb-4.0.3'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_rounded,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            onTap: () async {
              Navigator.pop(context);
              if (_currentUser?.userType == 'customer') {
                Navigator.pushNamed(context, '/customer-profile');
              } else {
                try {
                  final apiService = context.read<ApiService>();
                  await apiService.getProviderProfile();
                  Navigator.pushNamed(context, '/provider-profile');
                } catch (e) {
                  Navigator.pushNamed(context, '/provider-profile-setup');
                }
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.message_rounded,
            title: 'Messages',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.help_rounded,
            title: 'Help & Support',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[300]),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.grey[800],
    );
  }

  Widget _buildCustomerHome() {
    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for services...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                            await Future.delayed(const Duration(seconds: 1));
                            _loadActiveJobs();
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
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
                            child: const Text(
                              'View All',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_activeJobs.isEmpty)
                    Center(
                      child: Text(
                        'No active jobs found',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeJobs.length,
                      itemBuilder: (context, index) {
                        final job = _activeJobs[index];
                        return _buildJobCard(job);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color(0xFF2D2D2D),
      child: InkWell(
        onTap: () async {
          try {
            final apiService = context.read<ApiService>();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loading job details...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            final freshJob = await apiService.getJobDetails(job['id']);
            
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsScreen(job: freshJob),
                ),
              );
              
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A7D44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work,
                      color: Color(0xFF3A7D44),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      job['job_type']?['name'] ?? 'Unknown Job Type',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                      color: _getStatusColor(job['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(job['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${job['estimated_cost'] ?? '0.00'} Birr',
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
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color(0xFF2D2D2D),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7D44).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFF3A7D44),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderHome() {
    return Container(
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
      child: SingleChildScrollView(
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
                      'Requested',
                      _requestedJobs.length.toString(),
                      Icons.add_circle_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProviderMyJobsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Rating',
                      _providerRating,
                      Icons.star,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Notifications',
                      '',
                      Icons.notifications_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Requested Jobs
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Requested Jobs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadRequestedJobs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingRequested)
                    const Center(child: CircularProgressIndicator())
                  else if (_requestedJobs.isEmpty)
                    Center(
                      child: Text(
                        'No requested jobs found',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _requestedJobs.length,
                      itemBuilder: (context, index) {
                        final requestedJob = _requestedJobs[index];
                        final job = requestedJob['job'];
                        return _buildProviderJobCard(job, requestedJob['status']);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Active Jobs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadProviderActiveJobs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingProviderActive)
                    const Center(child: CircularProgressIndicator())
                  else if (_providerActiveJobs.isEmpty)
                    Center(
                      child: Text(
                        'No active jobs found',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  else
                    ListView.builder(
                      controller: _providerActiveScrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _providerActiveJobs.length + (_hasMoreProviderActiveJobs ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _providerActiveJobs.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _isLoadingProviderActive
                                    ? null
                                    : () => _loadProviderActiveJobs(page: _currentProviderActivePage + 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoadingProviderActive
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Load More'),
                              ),
                            ),
                          );
                        }

                        final jobData = _providerActiveJobs[index];
                        final job = jobData['job'];
                        return _buildProviderJobCard(job, job['status']);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderJobCard(Map<String, dynamic> job, String? status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color(0xFF2D2D2D),
      child: InkWell(
        onTap: () async {
          try {
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderJobDetailsScreen(job: job),
                ),
              );
              
              if (result == true) {
                _loadProviderActiveJobs();
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A7D44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work,
                      color: Color(0xFF3A7D44),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['job_type']?['name'] ?? 'Unknown Job Type',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['description'] ?? 'No description',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
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
                      status?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${job['estimated_cost'] ?? '0.00'} Birr',
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
  }

  Widget _buildStatCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color(0xFF2D2D2D),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7D44).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF3A7D44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text(
          'Local Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _currentUser == null
          ? const Center(
              child: Text(
                'No user data available. Please log in again.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _currentUser!.userType == 'customer'
              ? _buildCustomerHome()
              : _buildProviderHome(),
    );
  }
} 