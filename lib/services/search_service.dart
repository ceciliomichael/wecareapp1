import 'package:wecareapp1/models/job.dart';
import 'package:wecareapp1/models/user.dart';
import 'package:wecareapp1/models/user_type.dart';
import 'package:wecareapp1/models/application.dart';
import 'package:wecareapp1/services/job_service.dart';
import 'package:wecareapp1/services/application_service.dart';
import 'package:wecareapp1/services/storage_service.dart';

class SearchService {
  // Singleton pattern
  static final SearchService _instance = SearchService._internal();

  factory SearchService() {
    return _instance;
  }

  SearchService._internal();

  // Search jobs by various criteria
  Future<List<Job>> searchJobs({
    String? query,
    List<String>? skills,
    double? minSalary,
    double? maxSalary,
    String? location,
    bool? isActive,
    String? employerId,
  }) async {
    List<Job> allJobs = await JobService.getJobs();

    return allJobs.where((job) {
      // Filter by search query (title or description contains query)
      if (query != null && query.isNotEmpty) {
        bool matchesQuery =
            job.title.toLowerCase().contains(query.toLowerCase()) ||
            job.description.toLowerCase().contains(query.toLowerCase());
        if (!matchesQuery) return false;
      }

      // Filter by required skills
      if (skills != null && skills.isNotEmpty) {
        bool hasRequiredSkill = skills.any(
          (skill) => job.requiredSkills.any(
            (jobSkill) => jobSkill.toLowerCase().contains(skill.toLowerCase()),
          ),
        );
        if (!hasRequiredSkill) return false;
      }

      // Filter by salary range
      if (minSalary != null && job.salary < minSalary) return false;
      if (maxSalary != null && job.salary > maxSalary) return false;

      // Filter by location
      if (location != null && location.isNotEmpty) {
        if (!job.location.toLowerCase().contains(location.toLowerCase())) {
          return false;
        }
      }

      // Filter by active status
      if (isActive != null && job.isActive != isActive) return false;

      // Filter by employer
      if (employerId != null && job.posterId != employerId) return false;

      return true;
    }).toList();
  }

  // Search users (helpers) by skills and other criteria
  Future<List<User>> searchHelpers({
    String? query,
    List<String>? skills,
    String? experience,
  }) async {
    List<User> allUsers = await StorageService.getUsers();
    List<User> helpers =
        allUsers.where((user) => user.userType == UserType.helper).toList();

    return helpers.where((helper) {
      // Filter by search query (name or email contains query)
      if (query != null && query.isNotEmpty) {
        bool matchesQuery =
            helper.name.toLowerCase().contains(query.toLowerCase()) ||
            helper.email.toLowerCase().contains(query.toLowerCase());
        if (!matchesQuery) return false;
      }

      // Filter by skills
      if (skills != null && skills.isNotEmpty && helper.skills != null) {
        bool hasSkill = skills.any(
          (skill) => helper.skills!.any(
            (helperSkill) =>
                helperSkill.toLowerCase().contains(skill.toLowerCase()),
          ),
        );
        if (!hasSkill) return false;
      }

      // Filter by experience
      if (experience != null &&
          experience.isNotEmpty &&
          helper.experience != null) {
        if (!helper.experience!.toLowerCase().contains(
          experience.toLowerCase(),
        )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Filter applications by status and date
  Future<List<Application>> filterApplications({
    String? jobId,
    String? helperId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    List<Application> allApplications =
        await ApplicationService.getApplications();

    return allApplications.where((application) {
      // Filter by job ID
      if (jobId != null && application.jobId != jobId) return false;

      // Filter by helper ID
      if (helperId != null && application.helperId != helperId) return false;

      // Filter by status
      if (status != null && application.status != status) return false;

      // Filter by date range
      if (fromDate != null && application.dateApplied.isBefore(fromDate)) {
        return false;
      }
      if (toDate != null && application.dateApplied.isAfter(toDate)) {
        return false;
      }

      return true;
    }).toList();
  }
}
