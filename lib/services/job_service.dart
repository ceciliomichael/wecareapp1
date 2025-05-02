import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/application_service.dart';

class JobService {
  static const String _jobsKey = 'jobs';
  static final Uuid _uuid = Uuid();

  // Save list of jobs to SharedPreferences
  static Future<void> saveJobs(List<Job> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = Job.encodeJobs(jobs);
    await prefs.setString(_jobsKey, encodedData);
  }

  // Get all jobs from SharedPreferences
  static Future<List<Job>> getJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jobsString = prefs.getString(_jobsKey);

    if (jobsString == null) {
      return [];
    }

    return Job.decodeJobs(jobsString);
  }

  // Create a new job
  static Future<Job> createJob({
    required String employerId,
    required String title,
    required String description,
    required double salary,
    required String location,
    required List<String> requiredSkills,
  }) async {
    final job = Job(
      id: _uuid.v4(),
      employerId: employerId,
      title: title,
      description: description,
      salary: salary,
      location: location,
      datePosted: DateTime.now(),
      isActive: true,
      requiredSkills: requiredSkills,
    );

    // Save to storage
    final jobs = await getJobs();
    jobs.add(job);
    await saveJobs(jobs);

    return job;
  }

  // Update an existing job
  static Future<Job> updateJob(Job updatedJob) async {
    final jobs = await getJobs();
    final index = jobs.indexWhere((job) => job.id == updatedJob.id);

    if (index >= 0) {
      jobs[index] = updatedJob;
      await saveJobs(jobs);
      return updatedJob;
    } else {
      throw Exception('Job not found');
    }
  }

  // Delete a job
  static Future<void> deleteJob(String jobId) async {
    final jobs = await getJobs();
    final filtered = jobs.where((job) => job.id != jobId).toList();

    if (filtered.length < jobs.length) {
      await saveJobs(filtered);
    } else {
      throw Exception('Job not found');
    }
  }

  // Get jobs by employer
  static Future<List<Job>> getJobsByEmployer(String employerId) async {
    final jobs = await getJobs();
    return jobs.where((job) => job.employerId == employerId).toList();
  }

  // Get active jobs (for helpers to browse)
  static Future<List<Job>> getActiveJobs() async {
    final jobs = await getJobs();
    return jobs.where((job) => job.isActive).toList();
  }

  // Toggle job active status
  static Future<Job> toggleJobStatus(String jobId) async {
    final jobs = await getJobs();
    final index = jobs.indexWhere((job) => job.id == jobId);

    if (index >= 0) {
      final job = jobs[index];
      final updatedJob = job.copyWith(isActive: !job.isActive);
      jobs[index] = updatedJob;
      await saveJobs(jobs);
      return updatedJob;
    } else {
      throw Exception('Job not found');
    }
  }

  // Get a job by ID
  static Future<Job?> getJobById(String jobId) async {
    final jobs = await getJobs();
    try {
      return jobs.firstWhere((job) => job.id == jobId);
    } catch (e) {
      return null;
    }
  }

  // Search jobs by title or skills
  static Future<List<Job>> searchJobs(String query) async {
    final jobs = await getActiveJobs();
    final lowercaseQuery = query.toLowerCase();

    return jobs.where((job) {
      return job.title.toLowerCase().contains(lowercaseQuery) ||
          job.description.toLowerCase().contains(lowercaseQuery) ||
          job.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  // Apply for a job
  static Future<void> applyForJob(
    String jobId,
    String helperId,
    String coverLetter,
  ) async {
    try {
      // Check if job exists and is active
      final job = await getJobById(jobId);
      if (job == null) {
        throw Exception('Job not found');
      }

      if (!job.isActive) {
        throw Exception('This job is no longer accepting applications');
      }

      // Create application using ApplicationService
      await ApplicationService.createApplication(
        jobId: jobId,
        helperId: helperId,
        coverLetter: coverLetter,
      );
    } catch (e) {
      // Rethrow the exception with more context
      throw Exception('Failed to submit application: ${e.toString()}');
    }
  }
}
