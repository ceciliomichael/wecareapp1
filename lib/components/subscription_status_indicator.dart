import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_status.dart';

class SubscriptionStatusIndicator extends StatelessWidget {
  final Subscription? subscription;
  final bool showDetails;
  final VoidCallback? onTap;

  const SubscriptionStatusIndicator({
    super.key,
    required this.subscription,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return _buildFreeStatus(context);
    }

    final status = subscription!.status;
    final isExpired = subscription!.isExpired;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(status, isExpired).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(status, isExpired).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, isExpired),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(status, isExpired),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status, isExpired),
                    fontSize: 14,
                  ),
                ),
                if (subscription!.plan.type.label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subscription!.plan.type.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 4),
              Text(
                _getDetailsText(status, isExpired),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreeStatus(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Free Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 4),
              Text(
                'Upgrade to premium for unlimited features',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status, bool isExpired) {
    if (isExpired || status == SubscriptionStatus.expired) {
      return Colors.red;
    }

    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.pending:
        return Colors.orange;
      case SubscriptionStatus.suspended:
        return Colors.amber;
      case SubscriptionStatus.cancelled:
        return Colors.grey;
      case SubscriptionStatus.expired:
        return Colors.red;
    }
  }

  String _getStatusText(SubscriptionStatus status, bool isExpired) {
    if (isExpired) return 'Expired';
    return status.label;
  }

  String _getDetailsText(SubscriptionStatus status, bool isExpired) {
    if (subscription == null) return '';

    if (isExpired) {
      return 'Subscription expired. Please renew to continue using premium features.';
    }

    switch (status) {
      case SubscriptionStatus.active:
        final remaining = subscription!.remainingTimeFormatted;
        return 'Premium features active. $remaining';
      case SubscriptionStatus.pending:
        return 'Payment confirmation pending';
      case SubscriptionStatus.suspended:
        return 'Subscription temporarily suspended';
      case SubscriptionStatus.cancelled:
        return 'Subscription cancelled';
      case SubscriptionStatus.expired:
        return 'Subscription expired';
    }
  }
}
