import 'dart:convert';
import 'salary_type.dart';

class Job {
  final String id;
  final String posterId; // Can be either employerId or helperId
  final bool postedByHelper; // Flag to indicate if posted by helper
  final String title;
  final String description;
  final double salary;
  final SalaryType salaryType; // Enum: hourly, daily, weekly, biweekly, monthly
  final String location;
  final DateTime datePosted;
  final bool isActive;
  final List<String> requiredSkills;
  final List<String> savedByUserIds; // Users who saved this job

  Job({
    required this.id,
    required this.posterId,
    this.postedByHelper = false,
    required this.title,
    required this.description,
    required this.salary,
    this.salaryType = SalaryType.monthly,
    required this.location,
    required this.datePosted,
    required this.isActive,
    required this.requiredSkills,
    List<String>? savedByUserIds,
  }) : savedByUserIds = savedByUserIds ?? [];

  // Create a copy with updated fields
  Job copyWith({
    String? id,
    String? posterId,
    bool? postedByHelper,
    String? title,
    String? description,
    double? salary,
    SalaryType? salaryType,
    String? location,
    DateTime? datePosted,
    bool? isActive,
    List<String>? requiredSkills,
    List<String>? savedByUserIds,
  }) {
    return Job(
      id: id ?? this.id,
      posterId: posterId ?? this.posterId,
      postedByHelper: postedByHelper ?? this.postedByHelper,
      title: title ?? this.title,
      description: description ?? this.description,
      salary: salary ?? this.salary,
      salaryType: salaryType ?? this.salaryType,
      location: location ?? this.location,
      datePosted: datePosted ?? this.datePosted,
      isActive: isActive ?? this.isActive,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      savedByUserIds: savedByUserIds ?? this.savedByUserIds,
    );
  }

  // Convert job to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'posterId': posterId,
      'postedByHelper': postedByHelper,
      'title': title,
      'description': description,
      'salary': salary,
      'salaryType': salaryType.toString(),
      'location': location,
      'datePosted': datePosted.toIso8601String(),
      'isActive': isActive,
      'requiredSkills': requiredSkills,
      'savedByUserIds': savedByUserIds,
    };
  }

  // Create job from JSON map
  factory Job.fromJson(Map<String, dynamic> json) {
    SalaryType parseSalaryType(String typeStr) {
      if (typeStr.contains('hourly')) return SalaryType.hourly;
      if (typeStr.contains('daily')) return SalaryType.daily;
      if (typeStr.contains('weekly')) return SalaryType.weekly;
      if (typeStr.contains('biweekly')) return SalaryType.biweekly;
      return SalaryType.monthly; // Default
    }

    return Job(
      id: json['id'],
      posterId:
          json['posterId'] ?? json['employerId'], // Backward compatibility
      postedByHelper: json['postedByHelper'] ?? false,
      title: json['title'],
      description: json['description'],
      salary: json['salary'].toDouble(),
      salaryType:
          json['salaryType'] != null
              ? parseSalaryType(json['salaryType'])
              : SalaryType.monthly,
      location: json['location'],
      datePosted: DateTime.parse(json['datePosted']),
      isActive: json['isActive'],
      requiredSkills: List<String>.from(json['requiredSkills']),
      savedByUserIds:
          json['savedByUserIds'] != null
              ? List<String>.from(json['savedByUserIds'])
              : [],
    );
  }

  // Encode list of jobs to JSON string
  static String encodeJobs(List<Job> jobs) => jsonEncode(
    jobs.map<Map<String, dynamic>>((job) => job.toJson()).toList(),
  );

  // Decode JSON string to list of jobs
  static List<Job> decodeJobs(String jobs) =>
      (jsonDecode(jobs) as List<dynamic>)
          .map<Job>((item) => Job.fromJson(item))
          .toList();

  // Check if job is saved by a specific user
  bool isSavedByUser(String userId) {
    return savedByUserIds.contains(userId);
  }
}
