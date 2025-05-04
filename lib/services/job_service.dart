import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../models/salary_type.dart';
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

  // Create a new job by an employer
  static Future<Job> createJob({
    required String posterId,
    required String title,
    required String description,
    required double salary,
    required SalaryType salaryType,
    required String location,
    required List<String> requiredSkills,
    bool postedByHelper = false,
  }) async {
    final job = Job(
      id: _uuid.v4(),
      posterId: posterId,
      postedByHelper: postedByHelper,
      title: title,
      description: description,
      salary: salary,
      salaryType: salaryType,
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

  // Get jobs by poster (employer or helper)
  static Future<List<Job>> getJobsByPoster(String posterId) async {
    final jobs = await getJobs();
    return jobs.where((job) => job.posterId == posterId).toList();
  }

  // Get active jobs (for helpers to browse)
  static Future<List<Job>> getActiveJobs() async {
    final jobs = await getJobs();
    return jobs.where((job) => job.isActive && !job.postedByHelper).toList();
  }

  // Get jobs posted by helpers
  static Future<List<Job>> getHelperPostedJobs([String? helperId]) async {
    final jobs = await getJobs();
    return jobs
        .where(
          (job) =>
              job.postedByHelper &&
              job.isActive &&
              (helperId == null || job.posterId == helperId),
        )
        .toList();
  }

  // Get jobs posted by employers
  static Future<List<Job>> getEmployerPostedJobs() async {
    final jobs = await getJobs();
    return jobs.where((job) => !job.postedByHelper && job.isActive).toList();
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

  // Save a job (add to user's saved jobs)
  static Future<Job> saveJobForUser(String jobId, String userId) async {
    final jobs = await getJobs();
    final index = jobs.indexWhere((job) => job.id == jobId);

    if (index >= 0) {
      final job = jobs[index];

      // Check if already saved
      if (job.savedByUserIds.contains(userId)) {
        return job; // Already saved, no change needed
      }

      // Create a new list with the userId added
      final updatedSavedByIds = List<String>.from(job.savedByUserIds)
        ..add(userId);
      final updatedJob = job.copyWith(savedByUserIds: updatedSavedByIds);

      jobs[index] = updatedJob;
      await saveJobs(jobs);
      return updatedJob;
    } else {
      throw Exception('Job not found');
    }
  }

  // Unsave a job (remove from user's saved jobs)
  static Future<Job> unsaveJobForUser(String jobId, String userId) async {
    final jobs = await getJobs();
    final index = jobs.indexWhere((job) => job.id == jobId);

    if (index >= 0) {
      final job = jobs[index];

      // Check if not saved
      if (!job.savedByUserIds.contains(userId)) {
        return job; // Not saved, no change needed
      }

      // Create a new list with the userId removed
      final updatedSavedByIds = List<String>.from(job.savedByUserIds)
        ..remove(userId);
      final updatedJob = job.copyWith(savedByUserIds: updatedSavedByIds);

      jobs[index] = updatedJob;
      await saveJobs(jobs);
      return updatedJob;
    } else {
      throw Exception('Job not found');
    }
  }

  // Get saved jobs for a user
  static Future<List<Job>> getSavedJobsForUser(String userId) async {
    final jobs = await getJobs();
    return jobs.where((job) => job.savedByUserIds.contains(userId)).toList();
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

  // Find best matches for a helper based on their skills
  static Future<List<Job>> findBestMatchesForHelper(User helper) async {
    if (helper.skills == null || helper.skills!.isEmpty) {
      return []; // No skills to match
    }

    final jobs = await getEmployerPostedJobs();

    // Score each job based on skill match
    final scoredJobs =
        jobs.map((job) {
          int matchScore = 0;

          // Count matching skills
          for (final skill in helper.skills!) {
            if (job.requiredSkills.any(
              (jobSkill) => jobSkill.toLowerCase() == skill.toLowerCase(),
            )) {
              matchScore++;
            }
          }

          return {'job': job, 'score': matchScore};
        }).toList();

    // Sort by score (highest first) and extract the job objects
    scoredJobs.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return scoredJobs
        .where(
          (item) => (item['score'] as int) > 0,
        ) // Only return jobs with at least one matching skill
        .map((item) => item['job'] as Job)
        .toList();
  }

  // Get recent jobs
  static Future<List<Job>> getRecentJobs({int limit = 10}) async {
    final jobs = await getActiveJobs();

    // Sort by date posted (newest first)
    jobs.sort((a, b) => b.datePosted.compareTo(a.datePosted));

    // Return only the specified number of jobs
    return jobs.take(limit).toList();
  }

  // Apply for a job
  static Future<void> applyForJob(
    String jobId,
    String helperId,
    String coverLetter,
  ) async {
    final job = await getJobById(jobId);

    if (job == null) {
      throw Exception('Job not found');
    }

    try {
      await ApplicationService.createApplication(
        jobId: jobId,
        helperId: helperId,
        coverLetter: coverLetter,
      );
    } catch (e) {
      throw Exception('Failed to apply for job: ${e.toString()}');
    }
  }
}
