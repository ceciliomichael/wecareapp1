import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/subscription.dart';
import '../../models/subscription_plan.dart';
import '../../models/subscription_status.dart';
import '../../services/subscription_service.dart';
import '../../services/trial_usage_service.dart';
import '../../components/subscription_status_indicator.dart';
import '../../components/subscription_plan_card.dart';

class SubscriptionScreen extends StatefulWidget {
  final User employer;

  const SubscriptionScreen({super.key, required this.employer});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Subscription? _currentSubscription;
  List<SubscriptionPlan> _availablePlans = [];
  List<Subscription> _subscriptionHistory = [];
  TrialStatus? _trialStatus;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize default plans if needed
      await SubscriptionService.initializeDefaultPlans();

      // Load current subscription, available plans, and trial status
      final results = await Future.wait([
        SubscriptionService.getUserSubscription(widget.employer.id),
        SubscriptionService.getActivePlans(),
        SubscriptionService.getUserSubscriptionHistory(widget.employer.id),
        TrialUsageService.getTrialStatus(widget.employer.id),
      ]);

      setState(() {
        _currentSubscription = results[0] as Subscription?;
        _availablePlans = results[1] as List<SubscriptionPlan>;
        _subscriptionHistory = results[2] as List<Subscription>;
        _trialStatus = results[3] as TrialStatus;
        _isLoading = false;
      });

      // Check for expired subscriptions
      await SubscriptionService.checkExpiredSubscriptions();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscription data: $e')),
        );
      }
    }
  }

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    await _showPaymentDialog(plan);
  }

  Future<void> _showPaymentDialog(SubscriptionPlan plan) async {
    _selectedPaymentMethod = null;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Subscribe to ${plan.name}'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan: ${plan.name} - ${plan.formattedPrice}/${plan.type.periodLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select payment method:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        'GCash',
                        'PayPal',
                        'Credit Card',
                        'Bank Transfer',
                      ].map(
                        (method) => RadioListTile<String>(
                          title: Text(method),
                          value: method.toLowerCase().replaceAll(' ', '_'),
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedPaymentMethod = value;
                            });
                          },
                          dense: true,
                        ),
                      ),
                      if (plan.discountPercentage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.savings,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You save ${plan.discountPercentage}% (₱${plan.savings!.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    _selectedPaymentMethod != null
                        ? () => Navigator.pop(context, true)
                        : null,
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (result == true && _selectedPaymentMethod != null) {
      await _processPurchase(plan, _selectedPaymentMethod!);
    }
  }

  Future<void> _processPurchase(
    SubscriptionPlan plan,
    String paymentMethod,
  ) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Create subscription
      final subscription = await SubscriptionService.createSubscription(
        userId: widget.employer.id,
        plan: plan,
        paymentMethod: paymentMethod,
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
          _isProcessingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${plan.name}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data to update history
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renewSubscription() async {
    if (_currentSubscription == null) return;

    await _showPaymentDialog(_currentSubscription!.plan);
  }

  Future<void> _cancelSubscription() async {
    if (_currentSubscription == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Subscription'),
            content: const Text(
              'Are you sure you want to cancel your subscription? '
              'You will lose access to premium features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Subscription'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel Subscription'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await SubscriptionService.cancelSubscription(_currentSubscription!.id);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel subscription: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Current', icon: Icon(Icons.account_circle)),
            Tab(text: 'Plans', icon: Icon(Icons.payment)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrentTab(),
                  _buildPlansTab(),
                  _buildHistoryTab(),
                ],
              ),
    );
  }

  Widget _buildCurrentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current status card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Subscription Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SubscriptionStatusIndicator(
                    subscription: _currentSubscription,
                    showDetails: true,
                  ),
                  if (_currentSubscription != null) ...[
                    const SizedBox(height: 16),
                    _buildSubscriptionDetails(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          if (_currentSubscription?.isExpired == true ||
              _currentSubscription == null) ...[
            _buildUpgradePrompt(),
          ] else ...[
            _buildManagementActions(),
          ],

          const SizedBox(height: 16),

          // Features comparison
          _buildFeaturesComparison(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    if (_currentSubscription == null) return const SizedBox.shrink();

    final subscription = _currentSubscription!;
    return Column(
      children: [
        _buildDetailRow('Plan', subscription.plan.name),
        _buildDetailRow('Price', subscription.plan.formattedPrice),
        _buildDetailRow('Period', subscription.periodDescription),
        _buildDetailRow(
          'Auto-renewal',
          subscription.autoRenewal ? 'Enabled' : 'Disabled',
        ),
        if (subscription.paymentMethod != null)
          _buildDetailRow('Payment Method', subscription.paymentMethod!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Upgrade to Premium',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock unlimited job postings, priority listing, and advanced analytics',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Subscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _renewSubscription,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renew'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelSubscription,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    return Column(
      children: [
        // Trial Status Card
        if (_trialStatus != null && !_trialStatus!.hasActiveSubscription) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _trialStatus!.needsSubscription 
                            ? Icons.warning_amber 
                            : Icons.info_outline,
                        color: _trialStatus!.needsSubscription 
                            ? Colors.orange 
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trial Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _trialStatus!.statusDescription,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _trialStatus!.needsSubscription 
                          ? Colors.orange 
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trial usage: ${_trialStatus!.trialUsageCount}/${_trialStatus!.trialLimit}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (_trialStatus!.needsSubscription) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subscription required to continue using the app',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Features Comparison Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trial vs Premium Features',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildFeatureComparison(
                  'App Usage',
                  '${widget.employer.trialLimit} times only',
                  'Unlimited',
                ),
                _buildFeatureComparison('Job Postings', 'Limited', 'Unlimited'),
                _buildFeatureComparison('Priority Listing', '✗', '✓'),
                _buildFeatureComparison('Analytics', 'Basic', 'Advanced'),
                _buildFeatureComparison('Support', 'Email only', 'Email & Chat'),
                _buildFeatureComparison('Helper Verification', '✗', '✓'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureComparison(String feature, String free, String premium) {
    final hasActiveSub = _currentSubscription?.isActive == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    hasActiveSub
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                fontWeight: hasActiveSub ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    hasActiveSub
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                fontWeight: hasActiveSub ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the perfect subscription plan to continue using WeCare',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          if (_isProcessingPayment) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
          ..._availablePlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SubscriptionPlanCard(
                plan: plan,
                isCurrentPlan:
                    _currentSubscription?.plan.id == plan.id &&
                    _currentSubscription?.isActive == true,
                onSelect: () => _selectPlan(plan),
                isLoading: _isProcessingPayment,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_subscriptionHistory.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No subscription history',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your subscription history will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ..._subscriptionHistory.map(
              (subscription) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          subscription.status == SubscriptionStatus.active
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      subscription.status == SubscriptionStatus.active
                          ? Icons.check_circle
                          : Icons.history,
                      color:
                          subscription.status == SubscriptionStatus.active
                              ? Colors.green
                              : Colors.grey,
                    ),
                  ),
                  title: Text(
                    subscription.plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.periodDescription),
                      const SizedBox(height: 4),
                      Text(
                        subscription.status.label,
                        style: TextStyle(
                          color:
                              subscription.status == SubscriptionStatus.active
                                  ? Colors.green
                                  : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    subscription.plan.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
