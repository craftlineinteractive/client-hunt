import 'package:flutter/foundation.dart';

import 'model_equality.dart';

/// How often a Pro plan is billed.
enum BillingPeriod {
  /// Charged every week.
  weekly(displayName: 'week'),

  /// Charged every month.
  monthly(displayName: 'month'),

  /// Charged once a year.
  yearly(displayName: 'year');

  const BillingPeriod({required this.displayName});

  /// Unit shown after the price ("/ year").
  final String displayName;
}

/// One purchasable Pro plan.
///
/// Prices are the approved mockup values (INR): ₹2,999 / year, ₹299 / month,
/// ₹99 / week. They live here as constants so the plan rows, the sticky bar and
/// the comparison copy cannot drift apart. Every other price-shaped string in the
/// paywall — "Save 16%", "About ₹250 / month", "₹2,999 billed yearly" — is
/// *derived* from these numbers below, so a price change cannot leave stale copy
/// behind. Billing itself is prompt E; nothing here charges anything.
@immutable
class ProPlan {
  const ProPlan({
    required this.id,
    required this.name,
    required this.priceInRupees,
    required this.period,
    this.badges = const <String>[],
  }) : assert(priceInRupees > 0, 'A plan price must be positive');

  /// Stable identifier used by the billing layer.
  final String id;

  /// Display name ("Yearly").
  final String name;

  /// Price in whole rupees.
  final int priceInRupees;

  /// Billing cadence.
  final BillingPeriod period;

  /// Marketing badges shown beside the plan name ("Best value", "Save 16%").
  final List<String> badges;

  /// e.g. "₹2,999 / year".
  String get priceLabel => '$formattedPrice / ${period.displayName}';

  /// The price with Indian digit grouping and the rupee glyph.
  String get formattedPrice {
    final String digits = priceInRupees.toString();
    if (digits.length <= 3) {
      return '₹$digits';
    }
    final String lastThree = digits.substring(digits.length - 3);
    final String rest = digits.substring(0, digits.length - 3);
    final StringBuffer grouped = StringBuffer();
    for (int index = 0; index < rest.length; index++) {
      final int remaining = rest.length - index;
      grouped.write(rest[index]);
      if (remaining > 1 && remaining % 2 == 0) {
        grouped.write(',');
      }
    }
    return '₹$grouped,$lastThree';
  }

  /// The default plan: yearly, with both badges.
  static const ProPlan yearly = ProPlan(
    id: 'pro_yearly',
    name: 'Yearly',
    priceInRupees: 2999,
    period: BillingPeriod.yearly,
    // "Save 16%" is not stored here; it is derived by [savingsLabel].
    badges: <String>['Best value'],
  );

  /// Monthly plan.
  static const ProPlan monthly = ProPlan(
    id: 'pro_monthly',
    name: 'Monthly',
    priceInRupees: 299,
    period: BillingPeriod.monthly,
  );

  /// Weekly plan.
  static const ProPlan weekly = ProPlan(
    id: 'pro_weekly',
    name: 'Weekly',
    priceInRupees: 99,
    period: BillingPeriod.weekly,
  );

  /// All plans in display order.
  static const List<ProPlan> all = <ProPlan>[yearly, monthly, weekly];

  /// Whole rupees per month when a yearly price is spread across a year.
  ///
  /// ₹2,999 / 12 ≈ ₹249.92, shown as ₹250. Null for plans that are not yearly.
  int? get monthlyEquivalentInRupees =>
      period == BillingPeriod.yearly ? (priceInRupees / 12).round() : null;

  /// Percent saved against paying the monthly plan for twelve months, rounded
  /// down: ₹299 × 12 = ₹3,588, so ₹2,999 is 16.4% less → 16.
  ///
  /// Null for plans that are not yearly.
  int? get savingsPercent {
    if (period != BillingPeriod.yearly) {
      return null;
    }
    final int twelveMonths = ProPlan.monthly.priceInRupees * 12;
    return ((1 - priceInRupees / twelveMonths) * 100).floor();
  }

  /// "Save 16%" for the yearly plan; null otherwise.
  String? get savingsLabel {
    final int? percent = savingsPercent;
    return percent == null ? null : 'Save $percent%';
  }

  /// The second line under the plan name.
  String get caption => switch (period) {
    BillingPeriod.yearly => 'About ₹$monthlyEquivalentInRupees / month',
    BillingPeriod.monthly => 'Billed every month',
    BillingPeriod.weekly => 'Billed every week',
  };

  /// The sticky-bar caption: "₹2,999 billed yearly".
  String get billingSummary => switch (period) {
    BillingPeriod.yearly => '$formattedPrice billed yearly',
    BillingPeriod.monthly => '$formattedPrice billed monthly',
    BillingPeriod.weekly => '$formattedPrice billed weekly',
  };

  /// Marketing badges in display order: the static [badges] plus the derived
  /// savings badge.
  List<String> get displayBadges => <String>[...badges, ?savingsLabel];

  /// Copy with selected fields replaced.
  ProPlan copyWith({
    String? id,
    String? name,
    int? priceInRupees,
    BillingPeriod? period,
    List<String>? badges,
  }) {
    return ProPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      priceInRupees: priceInRupees ?? this.priceInRupees,
      period: period ?? this.period,
      badges: badges ?? this.badges,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProPlan &&
            other.id == id &&
            other.name == name &&
            other.priceInRupees == priceInRupees &&
            other.period == period &&
            listsEqual<String>(other.badges, badges);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, priceInRupees, period, listsHash<String>(badges));

  @override
  String toString() => 'ProPlan($name, $priceLabel)';
}
