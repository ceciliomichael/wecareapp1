import 'dart:convert';

class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final double salary;
  final String location;
  final DateTime datePosted;
  final bool isActive;
  final List<String> requiredSkills;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.salary,
    required this.location,
    required this.datePosted,
    required this.isActive,
    required this.requiredSkills,
  });

  // Create a copy with updated fields
  Job copyWith({
    String? id,
    String? employerId,
    String? title,
    String? description,
    double? salary,
    String? location,
    DateTime? datePosted,
    bool? isActive,
    List<String>? requiredSkills,
  }) {
    return Job(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      title: title ?? this.title,
      description: description ?? this.description,
      salary: salary ?? this.salary,
      location: location ?? this.location,
      datePosted: datePosted ?? this.datePosted,
      isActive: isActive ?? this.isActive,
      requiredSkills: requiredSkills ?? this.requiredSkills,
    );
  }

  // Convert job to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employerId': employerId,
      'title': title,
      'description': description,
      'salary': salary,
      'location': location,
      'datePosted': datePosted.toIso8601String(),
      'isActive': isActive,
      'requiredSkills': requiredSkills,
    };
  }

  // Create job from JSON map
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      employerId: json['employerId'],
      title: json['title'],
      description: json['description'],
      salary: json['salary'].toDouble(),
      location: json['location'],
      datePosted: DateTime.parse(json['datePosted']),
      isActive: json['isActive'],
      requiredSkills: List<String>.from(json['requiredSkills']),
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
}
