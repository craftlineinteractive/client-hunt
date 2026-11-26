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
/// the comparison copy cannot drift apart. Billing itself is prompt E; nothing in
/// A1 charges anything.
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
    badges: <String>['Best value', 'Save 16%'],
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
