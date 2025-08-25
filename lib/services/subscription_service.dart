import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_status.dart';
import 'storage_service.dart';

class SubscriptionService {
  static final Uuid _uuid = Uuid();

  // Storage keys
  static const String _subscriptionsKey = 'user_subscriptions';
  static const String _plansKey = 'subscription_plans';

  // Initialize default subscription plans
  static Future<void> initializeDefaultPlans() async {
    final existingPlans = await getAvailablePlans();
    if (existingPlans.isNotEmpty) return; // Plans already exist

    final defaultPlans = [
      SubscriptionPlan(
        id: _uuid.v4(),
        type: SubscriptionPlanType.starter,
        name: 'Starter Plan',
        description: 'Perfect for getting started',
        price: 199.00,
        features: [
          'Unlimited job postings',
          'Basic analytics',
          'Email support',
          'Standard listing',
        ],
      ),
      SubscriptionPlan(
        id: _uuid.v4(),
        type: SubscriptionPlanType.standard,
        name: 'Standard Plan',
        description: 'Most popular choice for regular users',
        price: 299.00,
        isPopular: true,
        features: [
          'Unlimited job postings',
          'Priority listing',
          'Advanced analytics',
          'Email & chat support',
          'Helper verification tools',
          'Custom job templates',
        ],
      ),
      SubscriptionPlan(
        id: _uuid.v4(),
        type: SubscriptionPlanType.premium,
        name: 'Premium Plan',
        description: 'Best value for long-term users',
        price: 499.00,
        features: [
          'All standard features',
          'Highest priority listing',
          'Premium analytics & reporting',
          'Priority customer support',
          'API access',
          'Custom branding',
          'Dedicated account manager',
        ],
      ),
    ];

    await _savePlans(defaultPlans);
  }

  // Get all available subscription plans
  static Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      final plansJson = await StorageService.getString(_plansKey);
      if (plansJson == null || plansJson.isEmpty) {
        return [];
      }
      return SubscriptionPlan.decodePlans(plansJson);
    } catch (e) {
      return [];
    }
  }

  // Get active subscription plans only
  static Future<List<SubscriptionPlan>> getActivePlans() async {
    final allPlans = await getAvailablePlans();
    return allPlans.where((plan) => plan.isActive).toList();
  }

  // Get subscription by user ID
  static Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final subscriptionsJson = await StorageService.getString(
        _subscriptionsKey,
      );
      if (subscriptionsJson == null || subscriptionsJson.isEmpty) {
        return null;
      }

      final subscriptions = Subscription.decodeSubscriptions(subscriptionsJson);
      final userSubscription =
          subscriptions
              .where((sub) => sub.userId == userId)
              .where((sub) => sub.status != SubscriptionStatus.cancelled)
              .toList();

      if (userSubscription.isEmpty) return null;

      // Return the most recent active subscription
      userSubscription.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return userSubscription.first;
    } catch (e) {
      return null;
    }
  }

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription(String userId) async {
    final subscription = await getUserSubscription(userId);
    return subscription?.isActive ?? false;
  }

  // Create a new subscription
  static Future<Subscription> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: plan.type.durationInDays));

    final subscription = Subscription(
      id: _uuid.v4(),
      userId: userId,
      plan: plan,
      startDate: now,
      endDate: endDate,
      status: SubscriptionStatus.active,
      lastPaymentDate: now,
      nextPaymentDate:
          plan.type == SubscriptionPlanType.starter
              ? endDate
              : _calculateNextPaymentDate(endDate, plan.type),
      autoRenewal: true,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      amountPaid: plan.price,
    );

    await _saveSubscription(subscription);
    return subscription;
  }

  // Renew subscription
  static Future<Subscription> renewSubscription({
    required String subscriptionId,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final subscription = await _getSubscriptionById(subscriptionId);
    if (subscription == null) {
      throw Exception('Subscription not found');
    }

    final now = DateTime.now();
    final newEndDate = now.add(
      Duration(days: subscription.plan.type.durationInDays),
    );

    final renewedSubscription = subscription.copyWith(
      startDate: now,
      endDate: newEndDate,
      status: SubscriptionStatus.active,
      lastPaymentDate: now,
      nextPaymentDate: _calculateNextPaymentDate(newEndDate, subscription.plan.type),
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      amountPaid: subscription.plan.price,
    );

    await _saveSubscription(renewedSubscription);
    return renewedSubscription;
  }

  // Cancel subscription
  static Future<Subscription> cancelSubscription(String subscriptionId) async {
    final subscription = await _getSubscriptionById(subscriptionId);
    if (subscription == null) {
      throw Exception('Subscription not found');
    }

    final cancelledSubscription = subscription.copyWith(
      status: SubscriptionStatus.cancelled,
      autoRenewal: false,
    );

    await _saveSubscription(cancelledSubscription);
    return cancelledSubscription;
  }

  // Update subscription status
  static Future<Subscription> updateSubscriptionStatus(
    String subscriptionId,
    SubscriptionStatus status,
  ) async {
    final subscription = await _getSubscriptionById(subscriptionId);
    if (subscription == null) {
      throw Exception('Subscription not found');
    }

    final updatedSubscription = subscription.copyWith(status: status);
    await _saveSubscription(updatedSubscription);
    return updatedSubscription;
  }

  // Check and update expired subscriptions
  static Future<void> checkExpiredSubscriptions() async {
    try {
      final subscriptionsJson = await StorageService.getString(
        _subscriptionsKey,
      );
      if (subscriptionsJson == null || subscriptionsJson.isEmpty) return;

      final subscriptions = Subscription.decodeSubscriptions(subscriptionsJson);
      final now = DateTime.now();
      bool hasUpdates = false;

      for (int i = 0; i < subscriptions.length; i++) {
        final subscription = subscriptions[i];

        // Check if subscription has expired
        if (subscription.status == SubscriptionStatus.active &&
            now.isAfter(subscription.endDate)) {
          subscriptions[i] = subscription.copyWith(
            status: SubscriptionStatus.expired,
          );
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await _saveSubscriptions(subscriptions);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Get subscription history for user
  static Future<List<Subscription>> getUserSubscriptionHistory(
    String userId,
  ) async {
    try {
      final subscriptionsJson = await StorageService.getString(
        _subscriptionsKey,
      );
      if (subscriptionsJson == null || subscriptionsJson.isEmpty) {
        return [];
      }

      final subscriptions = Subscription.decodeSubscriptions(subscriptionsJson);
      final userSubscriptions =
          subscriptions.where((sub) => sub.userId == userId).toList();

      // Sort by creation date, newest first
      userSubscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return userSubscriptions;
    } catch (e) {
      return [];
    }
  }

  // Helper methods
  static Future<void> _saveSubscription(Subscription subscription) async {
    try {
      final subscriptionsJson = await StorageService.getString(
        _subscriptionsKey,
      );
      List<Subscription> subscriptions = [];

      if (subscriptionsJson != null && subscriptionsJson.isNotEmpty) {
        subscriptions = Subscription.decodeSubscriptions(subscriptionsJson);
      }

      // Remove existing subscription with same ID
      subscriptions.removeWhere((sub) => sub.id == subscription.id);

      // Add updated subscription
      subscriptions.add(subscription);

      await _saveSubscriptions(subscriptions);
    } catch (e) {
      throw Exception('Failed to save subscription');
    }
  }

  static Future<void> _saveSubscriptions(
    List<Subscription> subscriptions,
  ) async {
    final subscriptionsJson = Subscription.encodeSubscriptions(subscriptions);
    await StorageService.setString(_subscriptionsKey, subscriptionsJson);
  }

  static Future<void> _savePlans(List<SubscriptionPlan> plans) async {
    final plansJson = SubscriptionPlan.encodePlans(plans);
    await StorageService.setString(_plansKey, plansJson);
  }

  static Future<Subscription?> _getSubscriptionById(
    String subscriptionId,
  ) async {
    try {
      final subscriptionsJson = await StorageService.getString(
        _subscriptionsKey,
      );
      if (subscriptionsJson == null || subscriptionsJson.isEmpty) {
        return null;
      }

      final subscriptions = Subscription.decodeSubscriptions(subscriptionsJson);
      return subscriptions.where((sub) => sub.id == subscriptionId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  static DateTime _calculateNextPaymentDate(
    DateTime endDate,
    SubscriptionPlanType type,
  ) {
    switch (type) {
      case SubscriptionPlanType.starter:
        return endDate;
      case SubscriptionPlanType.standard:
        return DateTime(endDate.year, endDate.month + 3, endDate.day);
      case SubscriptionPlanType.premium:
        return DateTime(endDate.year, endDate.month + 5, endDate.day);
    }
  }
}
