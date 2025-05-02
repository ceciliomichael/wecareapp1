import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/application.dart';

class ApplicationService {
  static const String _applicationsKey = 'applications';
  static final Uuid _uuid = Uuid();

  // Save list of applications to SharedPreferences
  static Future<void> saveApplications(List<Application> applications) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = Application.encodeApplications(applications);
    await prefs.setString(_applicationsKey, encodedData);
  }

  // Get all applications from SharedPreferences
  static Future<List<Application>> getApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? applicationsString = prefs.getString(_applicationsKey);

    if (applicationsString == null) {
      return [];
    }

    return Application.decodeApplications(applicationsString);
  }

  // Create a new application
  static Future<Application> createApplication({
    required String jobId,
    required String helperId,
    String? coverLetter,
  }) async {
    // Check if helper has already applied for this job
    final applications = await getApplications();
    final existingApplication =
        applications
            .where((app) => app.jobId == jobId && app.helperId == helperId)
            .toList();

    if (existingApplication.isNotEmpty) {
      throw Exception('You have already applied for this job');
    }

    final application = Application(
      id: _uuid.v4(),
      jobId: jobId,
      helperId: helperId,
      dateApplied: DateTime.now(),
      status: 'pending',
      coverLetter: coverLetter,
    );

    // Save to storage
    applications.add(application);
    await saveApplications(applications);

    return application;
  }

  // Update application status
  static Future<Application> updateApplicationStatus(
    String applicationId,
    String newStatus,
  ) async {
    final applications = await getApplications();
    final index = applications.indexWhere((app) => app.id == applicationId);

    if (index >= 0) {
      final updatedApplication = applications[index].copyWith(
        status: newStatus,
      );
      applications[index] = updatedApplication;
      await saveApplications(applications);
      return updatedApplication;
    } else {
      throw Exception('Application not found');
    }
  }

  // Get applications by job ID
  static Future<List<Application>> getApplicationsByJob(String jobId) async {
    final applications = await getApplications();
    return applications.where((app) => app.jobId == jobId).toList();
  }

  // Get applications by helper ID
  static Future<List<Application>> getApplicationsByHelper(
    String helperId,
  ) async {
    final applications = await getApplications();
    return applications.where((app) => app.helperId == helperId).toList();
  }

  // Get applications by employer's jobs
  static Future<List<Map<String, dynamic>>> getApplicationsForEmployerJobs(
    List<String> jobIds,
  ) async {
    final applications = await getApplications();
    final filteredApplications =
        applications.where((app) => jobIds.contains(app.jobId)).toList();

    // Return applications with job IDs for easier reference
    return filteredApplications
        .map((app) => {'application': app, 'jobId': app.jobId})
        .toList();
  }

  // Delete an application
  static Future<void> deleteApplication(String applicationId) async {
    final applications = await getApplications();
    final filtered =
        applications.where((app) => app.id != applicationId).toList();

    if (filtered.length < applications.length) {
      await saveApplications(filtered);
    } else {
      throw Exception('Application not found');
    }
  }
}
