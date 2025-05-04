# WeCare App Implementation Plan - Revised

## Overview

This implementation plan has been revised based on the client's updated requirements. It focuses on enhancing the WeCare app with new features including Best Matches functionality, NBI clearance requirements, salary option enhancements, and modifications to the messaging system.

## Phase 1: Authentication & Registration Enhancements ✅

### Goals
- Add NBI clearance upload requirement for employers during registration
- Update user model to store verification documents
- Enhance profile screens for both user types

### Implementation Details

#### Models to Modify
- `lib/models/user.dart` - Update to include NBI clearance for employers, active status flag

#### Screens to Modify
- `lib/screens/auth/register_screen.dart` - Add NBI clearance upload for employers
- `lib/screens/employer/employer_profile_screen.dart` - Display NBI clearance information
- `lib/screens/auth/login_screen.dart` - Add active/inactive status indicator

## Phase 2: Job Posting Enhancements ✅

### Goals
- Modify job model to include flexible salary options (hourly, daily, weekly, biweekly, monthly)
- Allow helpers to post job requests/services
- Update job browsing to include Best Matches, Recent Jobs, and Saved Jobs sections

### Implementation Details

#### Models to Modify
- `lib/models/job.dart` - Add salary type enum, saved status, posted_by_helper flag

#### New Components
- `lib/components/job_section_header.dart` - Section headers for job categories
- `lib/components/saved_job_card.dart` - Card for saved job listings

#### Screens to Modify
- `lib/screens/employer/job_posting_screen.dart` - Add salary type selection
- `lib/screens/helper/job_browse_screen.dart` - Implement tabbed sections for Best Matches, Recent, Saved
- `lib/screens/helper/helper_dashboard.dart` - Add post job/service button and functionality

#### New Screens
- `lib/screens/helper/post_service_screen.dart` - Allow helpers to post services they offer

#### Services to Modify
- `lib/services/job_service.dart` - Add methods for job matching, saving jobs, and helper job posting

## Phase 3: Profile & Visibility Enhancements ✅

### Goals
- Enhance helper profiles to be visible alongside their service posts
- Implement active/inactive status indicators
- Create more comprehensive profile views

### Implementation Details

#### Components to Create
- `lib/components/activity_status_indicator.dart` - Visual indicator for active/inactive status
- `lib/components/helper_service_card.dart` - Card showing helper alongside their service

#### Screens to Modify
- `lib/screens/helper/helper_profile_screen.dart` - Enhanced profile view with services offered
- `lib/screens/employer/employer_profile_screen.dart` - Add active status toggle
- `lib/screens/helper/helper_dashboard.dart` - Add services management section

#### Services to Modify
- `lib/services/auth_service.dart` - Add methods to toggle and track active status

## Phase 4: Messaging Adjustments ✅

### Goals
- Implement limited messaging functionality that allows sending/receiving messages 
- Maintain message icon but limit functionality as specified
- Add read/unread status and active indicators

### Implementation Details

#### Models to Modify
- `lib/models/message.dart` - Add read status and delivery confirmation

#### Components to Modify
- `lib/components/chat/message_bubble.dart` - Add read receipt indicators
- `lib/components/chat/conversation_tile.dart` - Add active status indicators

#### Screens to Modify
- `lib/screens/chat/chat_screen.dart` - Update to show active status and read receipts
- `lib/screens/chat/conversations_list_screen.dart` - Show active status in conversation list

#### Services to Modify
- `lib/services/message_service.dart` - Update to support read receipts and status tracking

## Phase 5: Ratings & Reviews Enhancements ✅

### Goals
- Enhance the existing ratings and reviews system
- Make reviews more prominent in profiles
- Improve review submission UI

### Implementation Details

#### Components to Create/Modify
- `lib/components/review/detailed_rating_breakdown.dart` - Show rating breakdown by category
- `lib/components/review/review_card.dart` - Enhanced design for review cards

#### Screens to Modify
- `lib/screens/helper/helper_profile_screen.dart` - More prominent reviews section
- `lib/screens/employer/employer_profile_screen.dart` - More prominent reviews section

#### Services to Modify
- `lib/services/review_service.dart` - Enhance review data structure and queries

## Data Model Modifications

### Job
```dart
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
}

enum SalaryType {
  hourly,
  daily, 
  weekly,
  biweekly, // 15 days
  monthly
}
```

### User
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType userType; // enum: employer or helper
  final String? photoUrl; // base64 string
  final bool isActive; // Whether user is currently active
  final DateTime lastActive; // Last time user was active
  
  // Helper-specific fields
  final List<String>? skills;
  final String? experience;
  
  // Employer-specific fields
  final String? address;
  final String? nbiClearance; // base64 string for document
}
```

### Message
```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readTimestamp;
}
```

## Implementation Timeline

- **Phase 1:** 1 week ✅
- **Phase 2:** 2 weeks ✅
- **Phase 3:** 1 week ✅
- **Phase 4:** 1 week ✅
- **Phase 5:** 1 week ✅

Total estimated timeline: 6 weeks ✅ 