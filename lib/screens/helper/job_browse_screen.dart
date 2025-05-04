import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../models/salary_type.dart';
import '../../services/job_service.dart';
import '../../components/job_section_header.dart';
import '../../components/saved_job_card.dart';

class JobBrowseScreen extends StatefulWidget {
  final User helper;

  const JobBrowseScreen({Key? key, required this.helper}) : super(key: key);

  @override
  State<JobBrowseScreen> createState() => _JobBrowseScreenState();
}

class _JobBrowseScreenState extends State<JobBrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Job> _bestMatchJobs = [];
  List<Job> _recentJobs = [];
  List<Job> _savedJobs = [];
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load best matches
      final bestMatches = await JobService.findBestMatchesForHelper(
        widget.helper,
      );

      // Load recent jobs
      final recentJobs = await JobService.getRecentJobs();

      // Load saved jobs
      final savedJobs = await JobService.getSavedJobsForUser(widget.helper.id);

      setState(() {
        _bestMatchJobs = bestMatches;
        _recentJobs = recentJobs;
        _savedJobs = savedJobs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveJob(Job job) async {
    try {
      await JobService.saveJobForUser(job.id, widget.helper.id);
      _loadJobs(); // Refresh job lists
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving job: $e')));
      }
    }
  }

  Future<void> _unsaveJob(Job job) async {
    try {
      await JobService.unsaveJobForUser(job.id, widget.helper.id);
      _loadJobs(); // Refresh job lists
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing saved job: $e')));
      }
    }
  }

  void _viewJobDetails(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _buildJobDetailScreen(job)),
    ).then((_) {
      // Refresh jobs when returning from details
      _loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Best Matches'),
                Tab(text: 'Recent'),
                Tab(text: 'Saved'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Best Matches tab
                _buildBestMatchesTab(),

                // Recent Jobs tab
                _buildRecentJobsTab(),

                // Saved Jobs tab
                _buildSavedJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestMatchesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredJobs =
        _searchQuery.isEmpty
            ? _bestMatchJobs
            : _bestMatchJobs
                .where(
                  (job) =>
                      job.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.requiredSkills.any(
                        (skill) => skill.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      ),
                )
                .toList();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No matching jobs found for your skills.\nUpdate your profile with relevant skills.'
                  : 'No jobs match your search criteria.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          return _buildJobListItem(job);
        },
      ),
    );
  }

  Widget _buildRecentJobsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredJobs =
        _searchQuery.isEmpty
            ? _recentJobs
            : _recentJobs
                .where(
                  (job) =>
                      job.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.requiredSkills.any(
                        (skill) => skill.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      ),
                )
                .toList();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.watch_later_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No recent jobs available at the moment.'
                  : 'No recent jobs match your search criteria.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          return _buildJobListItem(job);
        },
      ),
    );
  }

  Widget _buildSavedJobsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredJobs =
        _searchQuery.isEmpty
            ? _savedJobs
            : _savedJobs
                .where(
                  (job) =>
                      job.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      job.requiredSkills.any(
                        (skill) => skill.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      ),
                )
                .toList();

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No saved jobs yet.\nSave jobs to find them easily later.'
                  : 'No saved jobs match your search criteria.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          return SavedJobCard(
            job: job,
            onTap: () => _viewJobDetails(job),
            onUnsave: () => _unsaveJob(job),
          );
        },
      ),
    );
  }

  Widget _buildJobListItem(Job job) {
    final isSaved = job.isSavedByUser(widget.helper.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewJobDetails(job),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      if (isSaved) {
                        _unsaveJob(job);
                      } else {
                        _saveJob(job);
                      }
                    },
                    tooltip: isSaved ? 'Remove from saved' : 'Save job',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.location,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    '₱${job.salary.toStringAsFixed(2)} ${job.salaryType.label}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skills preview
                  Expanded(
                    child:
                        job.requiredSkills.isNotEmpty
                            ? Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children:
                                  job.requiredSkills.take(2).map((skill) {
                                    return Chip(
                                      label: Text(
                                        skill,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                            )
                            : const Text(
                              'No specific skills required',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetailScreen(Job job) {
    // We'll use the existing JobDetailScreen from helper_dashboard.dart
    // This is a reference to avoid duplicating code
    return JobDetailScreen(job: job, helper: widget.helper);
  }
}

class JobDetailScreen extends StatelessWidget {
  final Job job;
  final User helper;

  const JobDetailScreen({Key? key, required this.job, required this.helper})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, job.location),
            _buildInfoRow(
              Icons.attach_money,
              '₱${job.salary.toStringAsFixed(2)} per day',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Posted on ${_formatDate(job.datePosted)}',
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Required Skills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  job.requiredSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ApplyJobScreen(job: job, helper: helper),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply for this Job',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ApplyJobScreen extends StatefulWidget {
  final Job job;
  final User helper;

  const ApplyJobScreen({Key? key, required this.job, required this.helper})
    : super(key: key);

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final TextEditingController _coverLetterController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    final coverLetter = _coverLetterController.text.trim();

    if (coverLetter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a cover letter')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Using the application service to submit application
      await JobService.applyForJob(
        widget.job.id,
        widget.helper.id,
        coverLetter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applying for: ${widget.job.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Why do you think you\'re a good fit for this job?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coverLetterController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText:
                    'Write a cover letter that showcases your skills and experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Submit Application',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
