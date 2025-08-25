enum SubscriptionStatus { active, expired, suspended, cancelled, pending }

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.pending:
        return 'Pending';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Your subscription is active and all features are available';
      case SubscriptionStatus.expired:
        return 'Your subscription has expired. Please renew to continue using premium features';
      case SubscriptionStatus.suspended:
        return 'Your subscription is temporarily suspended';
      case SubscriptionStatus.cancelled:
        return 'Your subscription has been cancelled';
      case SubscriptionStatus.pending:
        return 'Your subscription payment is pending confirmation';
    }
  }

  bool get isPremium {
    return this == SubscriptionStatus.active;
  }
}
