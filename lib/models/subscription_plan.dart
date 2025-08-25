import 'dart:convert';

enum SubscriptionPlanType { starter, standard, premium }

extension SubscriptionPlanTypeExtension on SubscriptionPlanType {
  String get label {
    switch (this) {
      case SubscriptionPlanType.starter:
        return 'Starter';
      case SubscriptionPlanType.standard:
        return 'Standard';
      case SubscriptionPlanType.premium:
        return 'Premium';
    }
  }

  int get durationInDays {
    switch (this) {
      case SubscriptionPlanType.starter:
        return 28; // 4 weeks
      case SubscriptionPlanType.standard:
        return 90; // 3 months (approximately)
      case SubscriptionPlanType.premium:
        return 150; // 5 months (approximately)
    }
  }

  String get periodLabel {
    switch (this) {
      case SubscriptionPlanType.starter:
        return '4 weeks';
      case SubscriptionPlanType.standard:
        return '3 months';
      case SubscriptionPlanType.premium:
        return '5 months';
    }
  }

  String get shortPeriodLabel {
    switch (this) {
      case SubscriptionPlanType.starter:
        return '1 month';
      case SubscriptionPlanType.standard:
        return '3 months';
      case SubscriptionPlanType.premium:
        return '5 months';
    }
  }
}

class SubscriptionPlan {
  final String id;
  final SubscriptionPlanType type;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<String> features;
  final bool isPopular;
  final double? originalPrice; // For showing discounts
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'PHP',
    required this.features,
    this.isPopular = false,
    this.originalPrice,
    this.isActive = true,
  });

  // Calculate discount percentage if original price exists
  int? get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) {
      return null;
    }
    return ((originalPrice! - price) / originalPrice! * 100).round();
  }

  // Get savings amount
  double? get savings {
    if (originalPrice == null || originalPrice! <= price) {
      return null;
    }
    return originalPrice! - price;
  }

  // Format price with currency
  String get formattedPrice {
    return '₱${price.toStringAsFixed(0)}';
  }

  // Format original price with currency
  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return '₱${originalPrice!.toStringAsFixed(0)}';
  }

  // Get price per month for comparison
  double get pricePerMonth {
    switch (type) {
      case SubscriptionPlanType.starter:
        return price; // 4 weeks ≈ 1 month
      case SubscriptionPlanType.standard:
        return price / 3; // 3 months
      case SubscriptionPlanType.premium:
        return price / 5; // 5 months
    }
  }

  // Format price per month
  String get formattedPricePerMonth {
    return '₱${pricePerMonth.toStringAsFixed(0)}/month';
  }

  // Copy with updated fields
  SubscriptionPlan copyWith({
    String? id,
    SubscriptionPlanType? type,
    String? name,
    String? description,
    double? price,
    String? currency,
    List<String>? features,
    bool? isPopular,
    double? originalPrice,
    bool? isActive,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      originalPrice: originalPrice ?? this.originalPrice,
      isActive: isActive ?? this.isActive,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'features': features,
      'isPopular': isPopular,
      'originalPrice': originalPrice,
      'isActive': isActive,
    };
  }

  // Create from JSON
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      type: SubscriptionPlanType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'] ?? 'PHP',
      features: List<String>.from(json['features']),
      isPopular: json['isPopular'] ?? false,
      originalPrice: json['originalPrice']?.toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert list of plans to JSON string
  static String encodePlans(List<SubscriptionPlan> plans) => jsonEncode(
    plans.map<Map<String, dynamic>>((plan) => plan.toJson()).toList(),
  );

  // Convert JSON string to list of plans
  static List<SubscriptionPlan> decodePlans(String plans) =>
      (jsonDecode(plans) as List<dynamic>)
          .map<SubscriptionPlan>((item) => SubscriptionPlan.fromJson(item))
          .toList();
}
