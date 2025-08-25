import '../models/user.dart';
import '../models/user_type.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

class TrialUsageService {
  // Helper method to get user by ID
  static Future<User?> _getUserById(String userId) async {
    final users = await StorageService.getUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Increment trial usage count for a user
  static Future<User> incrementTrialUsage(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    // Don't increment if user has active subscription
    final hasActiveSubscription = await SubscriptionService.hasActiveSubscription(userId);
    if (hasActiveSubscription) {
      return user;
    }

    // Don't increment if trial is already expired or exhausted
    if (user.needsSubscription) {
      return user;
    }

    final now = DateTime.now();
    final updatedUser = user.copyWith(
      trialUsageCount: user.trialUsageCount + 1,
      firstUsageDate: user.firstUsageDate ?? now,
    );

    await StorageService.updateUser(updatedUser);
    return updatedUser;
  }

  // Check if user can perform an action (has subscription or trial uses remaining)
  static Future<bool> canPerformAction(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      return false;
    }

    // Check if user has active subscription
    final hasActiveSubscription = await SubscriptionService.hasActiveSubscription(userId);
    if (hasActiveSubscription) {
      return true;
    }

    // Check if user has trial uses remaining
    return user.hasTrialUsesRemaining;
  }

  // Get trial status for a user
  static Future<TrialStatus> getTrialStatus(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final hasActiveSubscription = await SubscriptionService.hasActiveSubscription(userId);
    if (hasActiveSubscription) {
      return TrialStatus(
        hasActiveSubscription: true,
        trialUsageCount: user.trialUsageCount,
        trialLimit: user.trialLimit,
        remainingTrialUses: 0,
        needsSubscription: false,
        statusDescription: 'Active subscription',
      );
    }

    return TrialStatus(
      hasActiveSubscription: false,
      trialUsageCount: user.trialUsageCount,
      trialLimit: user.trialLimit,
      remainingTrialUses: user.remainingTrialUses,
      needsSubscription: user.needsSubscription,
      statusDescription: user.trialStatusDescription,
    );
  }

  // Force expire trial for a user (admin function)
  static Future<User> expireTrial(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final updatedUser = user.copyWith(isTrialExpired: true);
    await StorageService.updateUser(updatedUser);
    return updatedUser;
  }

  // Reset trial for a user (admin function)
  static Future<User> resetTrial(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final updatedUser = user.copyWith(
      trialUsageCount: 0,
      firstUsageDate: null,
      isTrialExpired: false,
    );

    await StorageService.updateUser(updatedUser);
    return updatedUser;
  }

  // Get trial limits for different user types
  static int getTrialLimit(UserType userType) {
    switch (userType) {
      case UserType.employer:
        return 3;
      case UserType.helper:
        return 5;
    }
  }
}

class TrialStatus {
  final bool hasActiveSubscription;
  final int trialUsageCount;
  final int trialLimit;
  final int remainingTrialUses;
  final bool needsSubscription;
  final String statusDescription;

  TrialStatus({
    required this.hasActiveSubscription,
    required this.trialUsageCount,
    required this.trialLimit,
    required this.remainingTrialUses,
    required this.needsSubscription,
    required this.statusDescription,
  });

  bool get canPerformAction => hasActiveSubscription || remainingTrialUses > 0;
}
