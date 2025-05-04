import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import '../../components/job_card.dart';
import 'job_posting_screen.dart';

class MyJobsScreen extends StatefulWidget {
  final User employer;

  const MyJobsScreen({Key? key, required this.employer}) : super(key: key);

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<Job> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await JobService.getJobsByPoster(widget.employer.id);
      setState(() {
        _jobs = jobs;
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

  void _editJob(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => JobPostingScreen(
              employer: widget.employer,
              job: job,
              onJobPosted: _loadJobs,
            ),
      ),
    );
  }

  Future<void> _toggleJobStatus(Job job) async {
    try {
      await JobService.toggleJobStatus(job.id);
      _loadJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job status: $e')),
        );
      }
    }
  }

  Future<void> _deleteJob(Job job) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Job'),
            content: Text('Are you sure you want to delete "${job.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await JobService.deleteJob(job.id);
        _loadJobs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting job: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _jobs.isEmpty
              ? _buildEmptyState()
              : _buildJobsList(),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return JobCard(
          job: job,
          showActions: true,
          onTap: () => _editJob(job),
          onEdit: () => _editJob(job),
          onDelete: () => _deleteJob(job),
          onToggleStatus: () => _toggleJobStatus(job),
        );
      },
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
            Icon(Icons.work_outline, size: 80, color: Colors.grey.shade400),
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
              textAlign: TextAlign.center,
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
                          onJobPosted: _loadJobs,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Post a Job'),
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
