import 'dart:convert';
import 'user_type.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String
  password; // Note: In a real app, this would be hashed and not stored directly
  final UserType userType;
  final String? photoUrl; // base64 string
  final bool isActive; // Whether user is currently active
  final DateTime lastActive; // Last time user was active

  // Trial usage tracking
  final int trialUsageCount; // Number of times user has used the app
  final DateTime? firstUsageDate; // When user first used the app
  final bool isTrialExpired; // Whether trial period has expired

  // Helper-specific fields
  final List<String>? skills;
  final String? experience;

  // Employer-specific fields
  final String? address;
  final String? companyName;
  final String? barangayClearance; // base64 string for document verification

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.userType,
    this.photoUrl,
    this.isActive = true,
    DateTime? lastActive,
    this.trialUsageCount = 0,
    this.firstUsageDate,
    this.isTrialExpired = false,
    this.skills,
    this.experience,
    this.address,
    this.companyName,
    this.barangayClearance,
  }) : lastActive = lastActive ?? DateTime.now();

  // Get trial limit based on user type
  int get trialLimit {
    switch (userType) {
      case UserType.employer:
        return 3;
      case UserType.helper:
        return 5;
    }
  }

  // Get remaining trial uses
  int get remainingTrialUses {
    final remaining = trialLimit - trialUsageCount;
    return remaining < 0 ? 0 : remaining;
  }

  // Check if user has trial uses remaining
  bool get hasTrialUsesRemaining {
    return remainingTrialUses > 0 && !isTrialExpired;
  }

  // Check if user needs subscription (trial expired or used up)
  bool get needsSubscription {
    return isTrialExpired || trialUsageCount >= trialLimit;
  }

  // Get trial status description
  String get trialStatusDescription {
    if (isTrialExpired) {
      return 'Trial expired';
    } else if (trialUsageCount >= trialLimit) {
      return 'Trial uses exhausted';
    } else {
      return '$remainingTrialUses trial use${remainingTrialUses == 1 ? '' : 's'} remaining';
    }
  }

  // Create a copy of this user with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    UserType? userType,
    String? photoUrl,
    bool? isActive,
    DateTime? lastActive,
    int? trialUsageCount,
    DateTime? firstUsageDate,
    bool? isTrialExpired,
    List<String>? skills,
    String? experience,
    String? address,
    String? companyName,
    String? barangayClearance,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      userType: userType ?? this.userType,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      lastActive: lastActive ?? this.lastActive,
      trialUsageCount: trialUsageCount ?? this.trialUsageCount,
      firstUsageDate: firstUsageDate ?? this.firstUsageDate,
      isTrialExpired: isTrialExpired ?? this.isTrialExpired,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      barangayClearance: barangayClearance ?? this.barangayClearance,
    );
  }

  // Convert user to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password, // In a real app, we wouldn't include this in JSON
      'userType': userType.toString(),
      'photoUrl': photoUrl,
      'isActive': isActive,
      'lastActive': lastActive.toIso8601String(),
      'trialUsageCount': trialUsageCount,
      'firstUsageDate': firstUsageDate?.toIso8601String(),
      'isTrialExpired': isTrialExpired,
      'skills': skills,
      'experience': experience,
      'address': address,
      'companyName': companyName,
      'barangayClearance': barangayClearance,
    };
  }

  // Create a user from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      userType:
          json['userType'] == 'UserType.employer'
              ? UserType.employer
              : UserType.helper,
      photoUrl: json['photoUrl'],
      isActive: json['isActive'] ?? true,
      lastActive:
          json['lastActive'] != null
              ? DateTime.parse(json['lastActive'])
              : DateTime.now(),
      trialUsageCount: json['trialUsageCount'] ?? 0,
      firstUsageDate:
          json['firstUsageDate'] != null
              ? DateTime.parse(json['firstUsageDate'])
              : null,
      isTrialExpired: json['isTrialExpired'] ?? false,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      experience: json['experience'],
      address: json['address'],
      companyName: json['companyName'],
      barangayClearance: json['barangayClearance'],
    );
  }

  // Convert list of users to JSON string
  static String encodeUsers(List<User> users) => jsonEncode(
    users.map<Map<String, dynamic>>((user) => user.toJson()).toList(),
  );

  // Convert JSON string to list of users
  static List<User> decodeUsers(String users) =>
      (jsonDecode(users) as List<dynamic>)
          .map<User>((item) => User.fromJson(item))
          .toList();
}
