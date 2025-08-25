import 'dart:convert';
import 'subscription_plan.dart';
import 'subscription_status.dart';

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;
  final bool autoRenewal;
  final String? paymentMethod; // e.g., 'gcash', 'paypal', 'credit_card'
  final String? transactionId;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.autoRenewal = true,
    this.paymentMethod,
    this.transactionId,
    required this.amountPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Check if subscription is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == SubscriptionStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  // Check if subscription has expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate) ||
        status == SubscriptionStatus.expired;
  }

  // Get days remaining in subscription
  int get daysRemaining {
    if (isExpired) return 0;
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  // Get hours remaining in subscription
  int get hoursRemaining {
    if (isExpired) return 0;
    final now = DateTime.now();
    return endDate.difference(now).inHours;
  }

  // Check if subscription expires soon (within 3 days)
  bool get expiresSoon {
    return daysRemaining <= 3 && daysRemaining > 0;
  }

  // Get formatted remaining time
  String get remainingTimeFormatted {
    if (isExpired) return 'Expired';

    final days = daysRemaining;
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} remaining';
    }

    final hours = hoursRemaining;
    return '$hours hour${hours == 1 ? '' : 's'} remaining';
  }

  // Get subscription period description
  String get periodDescription {
    final formatter =
        DateTime.now().day == startDate.day ? 'MMM d' : 'MMM d, yyyy';
    return '${_formatDate(startDate, formatter)} - ${_formatDate(endDate, formatter)}';
  }

  // Copy with updated fields
  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    bool? autoRenewal,
    String? paymentMethod,
    String? transactionId,
    double? amountPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.toString(),
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'nextPaymentDate': nextPaymentDate?.toIso8601String(),
      'autoRenewal': autoRenewal,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'amountPaid': amountPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['userId'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      lastPaymentDate:
          json['lastPaymentDate'] != null
              ? DateTime.parse(json['lastPaymentDate'])
              : null,
      nextPaymentDate:
          json['nextPaymentDate'] != null
              ? DateTime.parse(json['nextPaymentDate'])
              : null,
      autoRenewal: json['autoRenewal'] ?? true,
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'],
      amountPaid: json['amountPaid'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert list of subscriptions to JSON string
  static String encodeSubscriptions(List<Subscription> subscriptions) =>
      jsonEncode(
        subscriptions
            .map<Map<String, dynamic>>((subscription) => subscription.toJson())
            .toList(),
      );

  // Convert JSON string to list of subscriptions
  static List<Subscription> decodeSubscriptions(String subscriptions) =>
      (jsonDecode(subscriptions) as List<dynamic>)
          .map<Subscription>((item) => Subscription.fromJson(item))
          .toList();

  // Helper method to format dates
  String _formatDate(DateTime date, String pattern) {
    // Simple date formatting - in a real app you might use intl package
    switch (pattern) {
      case 'MMM d':
        return '${_getMonthName(date.month)} ${date.day}';
      case 'MMM d, yyyy':
        return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      default:
        return date.toString();
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
