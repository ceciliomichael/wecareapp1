# WeCare Implementation Plan

## Overview

This document outlines the implementation plan for the WeCare app, focusing on connecting Helpers and Employers. The implementation will follow a phased approach, prioritizing core features and using local storage for initial data management before moving to a backend solution.

## Phase 1: Enhanced Authentication & Local Storage Setup (Current)

### Goals
- Enhance registration for Helpers to include NBI clearance upload
- Set up local storage structure for user data, jobs, applications, and messages
- Implement basic user profile management

### Files to Create/Modify

#### Models
- `lib/models/user.dart` - User model with shared and role-specific properties
- `lib/models/job.dart` - Job posting model
- `lib/models/application.dart` - Job application model
- `lib/models/message.dart` - Chat message model
- `lib/models/conversation.dart` - Conversation model

#### Services
- `lib/services/storage_service.dart` - Local storage service using shared_preferences
- `lib/services/auth_service.dart` - Authentication service (mock)
- `lib/services/image_service.dart` - Image handling service (for base64 conversion)

#### Screens/Auth Enhancement
- `lib/screens/auth/register_screen.dart` - Modify to add NBI clearance upload for Helpers
- `lib/screens/auth/profile_setup_screen.dart` - Additional profile setup after registration

## Phase 2: Employer Screens & Functionality

### Goals
- Create employer dashboard
- Implement job posting and management
- Set up employer profile screens

### Files to Create

#### Screens/Employer
- `lib/screens/employer/employer_dashboard.dart` - Main employer dashboard
- `lib/screens/employer/job_posting_screen.dart` - Create/edit job postings
- `lib/screens/employer/my_jobs_screen.dart` - View and manage job postings
- `lib/screens/employer/applications_screen.dart` - View applications for jobs
- `lib/screens/employer/employer_profile_screen.dart` - View/edit employer profile

#### Components/Employer
- `lib/components/job_card.dart` - Reusable job posting card
- `lib/components/application_card.dart` - Reusable application card

## Phase 3: Helper Screens & Functionality

### Goals
- Create helper dashboard
- Implement job browsing and application
- Set up helper profile screens

### Files to Create

#### Screens/Helper
- `lib/screens/helper/helper_dashboard.dart` - Main helper dashboard
- `lib/screens/helper/job_browse_screen.dart` - Browse available jobs
- `lib/screens/helper/my_applications_screen.dart` - View submitted applications
- `lib/screens/helper/helper_profile_screen.dart` - View/edit helper profile

#### Components/Helper
- `lib/components/job_listing_card.dart` - Reusable job listing card
- `lib/components/application_status_card.dart` - Reusable application status card

## Phase 4: Messaging & Notifications

### Goals
- Implement in-app messaging between helpers and employers
- Set up local notifications for important events

### Files to Create

#### Screens/Messaging
- `lib/screens/chat/conversations_list_screen.dart` - List of active conversations
- `lib/screens/chat/chat_screen.dart` - Individual conversation screen

#### Services
- `lib/services/message_service.dart` - Message handling service
- `lib/services/notification_service.dart` - Local notification service

#### Components/Chat
- `lib/components/chat/message_bubble.dart` - Message display component
- `lib/components/chat/conversation_tile.dart` - Conversation list item

## Phase 5: Polish & Optimization

### Goals
- Implement search and filtering functionality
- Add ratings and reviews
- Optimize performance and UX

### Files to Create/Modify
- `lib/services/search_service.dart` - Search functionality
- `lib/models/review.dart` - Review model
- Various UI enhancements across existing screens

## Local Storage Structure

```
shared_preferences keys:
- users: List of User objects
- jobs: List of Job objects
- applications: List of Application objects
- conversations: List of Conversation objects
- messages: Map of conversation IDs to Lists of Message objects
- current_user: Current logged-in user ID
```

## Detailed Data Models

### User
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType userType; // enum: employer or helper
  final String? photoUrl; // base64 string
  
  // Helper-specific fields
  final String? nbiClearance; // base64 string
  final List<String>? skills;
  final String? experience;
  
  // Employer-specific fields
  final String? address;
}
```

### Job
```dart
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
}
```

### Application
```dart
class Application {
  final String id;
  final String jobId;
  final String helperId;
  final DateTime dateApplied;
  final String status; // pending, accepted, rejected
  final String? coverLetter;
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
}
```

### Conversation
```dart
class Conversation {
  final String id;
  final String employerId;
  final String helperId;
  final DateTime lastMessageTime;
  final String jobId; // related job
}
```

## Navigation Structure

```
App
├── SplashScreen
├── AuthScreen
│   ├── LoginScreen
│   ├── RegisterScreen
│   └── ProfileSetupScreen
├── EmployerScreens
│   ├── EmployerDashboard
│   ├── JobPostingScreen
│   ├── MyJobsScreen
│   ├── ApplicationsScreen
│   └── EmployerProfileScreen
├── HelperScreens
│   ├── HelperDashboard
│   ├── JobBrowseScreen
│   ├── MyApplicationsScreen
│   └── HelperProfileScreen
└── SharedScreens
    ├── ConversationsListScreen
    └── ChatScreen
```

## Implementation Timeline

- **Phase 1:** 1-2 weeks
- **Phase 2:** 1-2 weeks
- **Phase 3:** 1-2 weeks
- **Phase 4:** 1-2 weeks
- **Phase 5:** 1 week

Total estimated timeline: 5-9 weeks 