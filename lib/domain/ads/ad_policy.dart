import 'dart:math';

import 'package:flutter/foundation.dart';

/// A point in the app where an interstitial may be shown.
///
/// Only places the user has *finished* something qualify, so an ad never
/// interrupts work. `appResumed` is deliberately absent: returning to the app is
/// the worst possible moment for a full-screen ad.
///
/// B1 implements the policy and wires no trigger of its own yet; later prompts
/// call [AdTrigger.resultsClosed] (B2), [AdTrigger.exportFinished] (B6),
/// [AdTrigger.leadDetailClosed] (B3) and [AdTrigger.leadSaved] (B3/B4).
enum AdTrigger {
  /// The user left the results screen.
  resultsClosed,

  /// An export finished successfully.
  exportFinished,

  /// A lead was saved.
  leadSaved,

  /// The user left a lead detail screen.
  leadDetailClosed,
}

/// The tunable numbers behind interstitial frequency.
///
/// One object, so every rule is visible in one place and tests can assert each
/// one independently. Defaults are the approved values.
@immutable
class AdPolicyConfig {
  const AdPolicyConfig({
    this.interstitialChance = 0.35,
    this.minIntervalBetweenInterstitials = const Duration(seconds: 120),
    this.minUserActionsBetweenInterstitials = 2,
    this.noInterstitialInFirstSeconds = 60,
    this.noInterstitialWithinSecondsAfterRewarded = 60,
  }) : assert(
         interstitialChance >= 0 && interstitialChance <= 1,
         'Chance is a probability',
       );

  /// Probability of showing an interstitial when every other rule passes.
  final double interstitialChance;

  /// Minimum gap between two interstitials.
  final Duration minIntervalBetweenInterstitials;

  /// Completed user actions required between two interstitials.
  final int minUserActionsBetweenInterstitials;

  /// No interstitial in the first minute of the session.
  final int noInterstitialInFirstSeconds;

  /// No interstitial this soon after a rewarded ad was shown.
  final int noInterstitialWithinSecondsAfterRewarded;
}

/// Decides whether an interstitial may appear.
///
/// Pure rules over an injectable clock and [Random], so the whole thing is unit
/// tested without a device or an ads SDK:
///
/// * never for Pro;
/// * never while busy (typing, loading, or a dialog is open);
/// * never in the first [AdPolicyConfig.noInterstitialInFirstSeconds];
/// * never within
///   [AdPolicyConfig.noInterstitialWithinSecondsAfterRewarded] of a rewarded ad;
/// * never within [AdPolicyConfig.minIntervalBetweenInterstitials] of the last
///   interstitial;
/// * only after [AdPolicyConfig.minUserActionsBetweenInterstitials] completed
///   actions;
/// * and then only with [AdPolicyConfig.interstitialChance] probability.
///
/// Screens call [recordUserAction] when the user completes something and
/// [recordInterstitialShown] after a show; [maybeShowInterstitial] on the
/// coordinator does both correctly.
class AdPolicy {
  AdPolicy({
    this.config = const AdPolicyConfig(),
    DateTime Function()? clock,
    Random? random,
    DateTime? startedAt,
  }) : _now = clock ?? DateTime.now,
       _random = random ?? Random(),
       _startedAt = startedAt ?? (clock ?? DateTime.now)();

  /// Frequency numbers.
  final AdPolicyConfig config;

  final DateTime Function() _now;
  final Random _random;
  final DateTime _startedAt;

  DateTime? _lastInterstitialAt;
  DateTime? _lastRewardedAt;
  int _actionsSinceLastInterstitial = 0;

  /// When this policy was created; the first-minute rule measures from here.
  DateTime get startedAt => _startedAt;

  /// Completed actions since the last interstitial.
  int get actionsSinceLastInterstitial => _actionsSinceLastInterstitial;

  /// Seconds since the last interstitial, or `null` if there has not been one.
  int? get secondsSinceLastInterstitial {
    final DateTime? last = _lastInterstitialAt;
    if (last == null) {
      return null;
    }
    return _now().difference(last).inSeconds;
  }

  /// Whole seconds since the session started.
  int get secondsSinceStart => _now().difference(_startedAt).inSeconds;

  /// Whether an interstitial may be shown at [trigger] right now.
  ///
  /// Does not record anything and does not show anything; [trigger] is accepted
  /// so per-trigger rules can be added without changing call sites.
  bool shouldShowInterstitial(
    AdTrigger trigger, {
    required bool isPro,
    required bool isBusy,
  }) {
    if (isPro || isBusy) {
      return false;
    }
    final DateTime now = _now();
    if (now.difference(_startedAt).inSeconds <
        config.noInterstitialInFirstSeconds) {
      return false;
    }
    final DateTime? rewardedAt = _lastRewardedAt;
    if (rewardedAt != null &&
        now.difference(rewardedAt).inSeconds <
            config.noInterstitialWithinSecondsAfterRewarded) {
      return false;
    }
    final DateTime? interstitialAt = _lastInterstitialAt;
    if (interstitialAt != null &&
        now.difference(interstitialAt) <
            config.minIntervalBetweenInterstitials) {
      return false;
    }
    if (_actionsSinceLastInterstitial <
        config.minUserActionsBetweenInterstitials) {
      return false;
    }
    return _random.nextDouble() < config.interstitialChance;
  }

  /// Counts one completed user action (a search submitted, a lead saved, …).
  void recordUserAction() => _actionsSinceLastInterstitial++;

  /// Notes that a rewarded ad was shown, which suppresses interstitials for a
  /// minute.
  void recordRewardedShown() => _lastRewardedAt = _now();

  /// Notes that an interstitial was shown: the action counter resets and the
  /// interval clock starts.
  void recordInterstitialShown() {
    _lastInterstitialAt = _now();
    _actionsSinceLastInterstitial = 0;
  }

  @override
  String toString() =>
      'AdPolicy(actions: $_actionsSinceLastInterstitial, '
      'last interstitial: ${secondsSinceLastInterstitial ?? 'never'})';
}
