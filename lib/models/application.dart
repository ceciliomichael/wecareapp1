import 'dart:convert';

class Application {
  final String id;
  final String jobId;
  final String helperId;
  final DateTime dateApplied;
  final String status; // pending, accepted, rejected
  final String? coverLetter;

  Application({
    required this.id,
    required this.jobId,
    required this.helperId,
    required this.dateApplied,
    required this.status,
    this.coverLetter,
  });

  // Create a copy with updated fields
  Application copyWith({
    String? id,
    String? jobId,
    String? helperId,
    DateTime? dateApplied,
    String? status,
    String? coverLetter,
  }) {
    return Application(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      helperId: helperId ?? this.helperId,
      dateApplied: dateApplied ?? this.dateApplied,
      status: status ?? this.status,
      coverLetter: coverLetter ?? this.coverLetter,
    );
  }

  // Convert application to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'helperId': helperId,
      'dateApplied': dateApplied.toIso8601String(),
      'status': status,
      'coverLetter': coverLetter,
    };
  }

  // Create application from JSON map
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      jobId: json['jobId'],
      helperId: json['helperId'],
      dateApplied: DateTime.parse(json['dateApplied']),
      status: json['status'],
      coverLetter: json['coverLetter'],
    );
  }

  // Encode list of applications to JSON string
  static String encodeApplications(List<Application> applications) =>
      jsonEncode(
        applications
            .map<Map<String, dynamic>>((application) => application.toJson())
            .toList(),
      );

  // Decode JSON string to list of applications
  static List<Application> decodeApplications(String applications) =>
      (jsonDecode(applications) as List<dynamic>)
          .map<Application>((item) => Application.fromJson(item))
          .toList();
}
