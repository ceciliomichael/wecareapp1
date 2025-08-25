import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../models/salary_type.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/contact_helper_service.dart';
import '../../services/storage_service.dart';
import '../auth/auth_screen.dart';
import '../chat/conversations_list_screen.dart';
import 'job_posting_screen.dart';
import 'my_jobs_screen.dart';
import 'applications_screen.dart';
import 'employer_profile_screen.dart';
import 'helper_services_screen.dart';
import 'subscription_screen.dart';

class EmployerDashboard extends StatefulWidget {
  final User employer;

  const EmployerDashboard({super.key, required this.employer});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  List<Job> _recentJobs = [];
  List<Job> _helperPostedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await JobService.getJobsByPoster(widget.employer.id);
      final helperJobs = await JobService.getHelperPostedJobs();

      setState(() {
        _recentJobs = jobs;
        _helperPostedJobs = helperJobs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      MyJobsScreen(employer: widget.employer),
      ApplicationsScreen(employer: widget.employer),
      EmployerProfileScreen(employer: widget.employer),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If on home tab, show exit confirmation
        if (_currentIndex == 0) {
          final shouldPop =
              await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Exit App?'),
                      content: const Text(
                        'Are you sure you want to exit the app?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
              ) ??
              false;

          if (shouldPop && mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // If on other tabs, navigate to home tab
          setState(() {
            _currentIndex = 0;
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WeCare Employer'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: pages,
        ),
        floatingActionButton:
            _currentIndex == 0 || _currentIndex == 1
                ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => JobPostingScreen(
                              employer: widget.employer,
                              onJobPosted: _loadData,
                            ),
                      ),
                    );
                  },
                  tooltip: 'Post a New Job',
                  child: const Icon(Icons.add),
                )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.work), label: 'My Jobs'),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Applications',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome, ${widget.employer.name}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your job postings and applications',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => JobPostingScreen(
                                      employer: widget.employer,
                                      onJobPosted: _loadData,
                                    ),
                              ),
                            );
                          },
                          icon: Icons.add_circle,
                          label: 'Post Job',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _buildActionButton(
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          },
                          icon: Icons.work,
                          label: 'My Jobs',
                          color: Colors.amber,
                        ),
                        _buildActionButton(
                          onTap: () {
                            setState(() {
                              _currentIndex = 2;
                              _pageController.animateToPage(
                                2,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          },
                          icon: Icons.people,
                          label: 'Applications',
                          color: Colors.amber[700]!,
                        ),
                        _buildActionButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ConversationsListScreen(
                                      currentUser: widget.employer,
                                    ),
                              ),
                            );
                          },
                          icon: Icons.chat,
                          label: 'Messages',
                          color: Colors.green[600]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SubscriptionScreen(
                                      employer: widget.employer,
                                    ),
                              ),
                            );
                          },
                          icon: Icons.star,
                          label: 'Premium',
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 80),
                        const SizedBox(width: 80),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent jobs section
            const Text(
              'Recent Job Postings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recentJobs.isEmpty
                ? _buildEmptyState()
                : Column(
                  children:
                      _recentJobs
                          .take(3)
                          .map((job) => _buildJobCard(job))
                          .toList(),
                ),
            if (_recentJobs.length > 3) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  child: const Text('View All Jobs'),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Helper Services section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Services Offered by Helpers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_helperPostedJobs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to the helper services screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => HelperServicesScreen(
                                employer: widget.employer,
                              ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _helperPostedJobs.isEmpty
                ? _buildEmptyHelperServices()
                : Column(
                  children:
                      _helperPostedJobs
                          .take(3)
                          .map((job) => _buildHelperServiceCard(job))
                          .toList(),
                ),

            // Tips section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tips for Employers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Provide detailed job descriptions to attract qualified helpers',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Specify required skills and experience clearly',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Respond to applications promptly',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Verify helper credentials during interviews',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        job.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color:
                          job.isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to job details
          setState(() {
            _currentIndex = 1;
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No job postings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first job post to find helpers',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => JobPostingScreen(
                        employer: widget.employer,
                        onJobPosted: _loadData,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Post a Job'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHelperServices() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handyman_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No helper services available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Helpers haven\'t posted any services yet',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHelperServiceCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.handyman, color: Colors.blue, size: 24),
        ),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  '${job.salary.toStringAsFixed(2)} ${job.salaryType.label}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat, color: Colors.teal),
              onPressed: () async {
                await _contactHelperForService(job);
              },
              tooltip: 'Contact Helper',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // Navigate to the helper services screen with this job pre-selected
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HelperServicesScreen(employer: widget.employer),
            ),
          );
        },
      ),
    );
  }

  Future<void> _contactHelperForService(Job job) async {
    try {
      final users = await StorageService.getUsers();
      final helper = users.firstWhere(
        (user) => user.id == job.posterId,
        orElse: () => throw Exception('Helper not found'),
      );

      if (mounted) {
        await ContactHelperService.contactHelperForJob(
          context: context,
          employer: widget.employer,
          helper: helper,
          job: job,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error contacting helper: $e')));
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await AuthService.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }
}
