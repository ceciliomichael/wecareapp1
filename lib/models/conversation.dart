import 'dart:convert';

class Conversation {
  final String id;
  final String employerId;
  final String helperId;
  final DateTime lastMessageTime;
  final String jobId;
  final String? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.employerId,
    required this.helperId,
    required this.lastMessageTime,
    required this.jobId,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      employerId: json['employerId'],
      helperId: json['helperId'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      jobId: json['jobId'],
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employerId': employerId,
      'helperId': helperId,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'jobId': jobId,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }

  Conversation copyWith({
    String? id,
    String? employerId,
    String? helperId,
    DateTime? lastMessageTime,
    String? jobId,
    String? lastMessage,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      helperId: helperId ?? this.helperId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      jobId: jobId ?? this.jobId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static List<Conversation> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Conversation.fromJson(json)).toList();
  }

  static String toJsonList(List<Conversation> conversations) {
    final List<Map<String, dynamic>> jsonList =
        conversations.map((conversation) => conversation.toJson()).toList();
    return json.encode(jsonList);
  }
}
