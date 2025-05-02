import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/user_type.dart';
import '../../models/job.dart';
import '../../models/application.dart';
import '../../services/job_service.dart';
import '../../services/application_service.dart';
import '../../components/application_card.dart';

class ApplicationsScreen extends StatefulWidget {
  final User employer;

  const ApplicationsScreen({Key? key, required this.employer})
    : super(key: key);

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<Job> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, Job> _jobsMap = {};
  Map<String, User> _helpersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all jobs by the employer
      _jobs = await JobService.getJobsByEmployer(widget.employer.id);
      _jobsMap = {for (var job in _jobs) job.id: job};

      // Get all job IDs
      final jobIds = _jobs.map((job) => job.id).toList();

      // Get applications for those jobs
      _applications = await ApplicationService.getApplicationsForEmployerJobs(
        jobIds,
      );

      // Load helper user data (mock for now)
      // In a real app, you'd fetch this data from the server
      // For demonstration, we'll create a mock helper for each application
      _helpersMap = {};
      for (var appData in _applications) {
        final app = appData['application'] as Application;
        if (!_helpersMap.containsKey(app.helperId)) {
          // Mock helper data - this should come from your user service in production
          _helpersMap[app.helperId] = User(
            id: app.helperId,
            name: 'Helper ${app.helperId.substring(0, 4)}',
            email: 'helper${app.helperId.substring(0, 4)}@example.com',
            phone: '+639123456789',
            password: 'password123',
            userType: UserType.helper,
            skills: ['Cleaning', 'Cooking', 'Childcare'],
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String newStatus,
  ) async {
    try {
      await ApplicationService.updateApplicationStatus(
        applicationId,
        newStatus,
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Application ${newStatus == 'accepted' ? 'accepted' : 'rejected'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating application: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
              ? _buildEmptyState()
              : _buildApplicationsList(),
    );
  }

  Widget _buildApplicationsList() {
    // Group applications by job
    Map<String, List<Map<String, dynamic>>> groupedApplications = {};

    for (var appData in _applications) {
      final app = appData['application'] as Application;
      final jobId = app.jobId;

      if (!groupedApplications.containsKey(jobId)) {
        groupedApplications[jobId] = [];
      }

      groupedApplications[jobId]!.add(appData);
    }

    // Create an expandable list for each job
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedApplications.length,
      itemBuilder: (context, index) {
        final jobId = groupedApplications.keys.elementAt(index);
        final job = _jobsMap[jobId]!;
        final jobApplications = groupedApplications[jobId]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${jobApplications.length} applications'),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            children:
                jobApplications.map((appData) {
                  final app = appData['application'] as Application;
                  final helper = _helpersMap[app.helperId]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ApplicationCard(
                      application: app,
                      job: job,
                      helper: helper,
                      onStatusChange:
                          app.status == 'pending'
                              ? (newStatus) =>
                                  _updateApplicationStatus(app.id, newStatus)
                              : null,
                      onViewDetails: () {
                        // Show application details dialog
                        _showApplicationDetailsDialog(app, job, helper);
                      },
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showApplicationDetailsDialog(Application app, Job job, User helper) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${helper.name}\'s Application'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Job: ${job.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${app.status.toUpperCase()}'),
                  const SizedBox(height: 8),
                  Text(
                    'Applied on: ${app.dateApplied.toString().substring(0, 10)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cover Letter:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(app.coverLetter ?? 'No cover letter provided'),
                  const SizedBox(height: 16),
                  const Text(
                    'Helper Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Email: ${helper.email}'),
                  Text('Phone: ${helper.phone}'),
                  if (helper.skills != null && helper.skills!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Skills:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children:
                          helper.skills!.map((skill) {
                            return Chip(
                              label: Text(skill),
                              backgroundColor:
                                  job.requiredSkills.contains(skill)
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (app.status == 'pending') ...[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateApplicationStatus(app.id, 'rejected');
                  },
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateApplicationStatus(app.id, 'accepted');
                  },
                  child: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No applications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Helpers will appear here when they apply to your jobs',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_jobs.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to job posting tab
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/employer/post-job');
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Post a Job to Attract Helpers'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
