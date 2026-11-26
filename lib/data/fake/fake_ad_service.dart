import 'package:flutter/material.dart';

import '../../dev/test_ad_page.dart';
import '../../domain/repositories/ad_service.dart';

/// What the fake rewarded ad does at the next show.
enum FakeRewardedOutcome {
  /// The user watches to the end; the reward is earned.
  earned(displayName: 'Rewarded: earned'),

  /// The user closes before the reward.
  dismissedEarly(displayName: 'Rewarded: closed early'),

  /// No fill: nothing is shown and the search proceeds.
  unavailable(displayName: 'Rewarded: unavailable'),

  /// The SDK errors: nothing is shown and the search proceeds.
  failed(displayName: 'Rewarded: failed');

  const FakeRewardedOutcome({required this.displayName});

  /// Label for the debug panel.
  final String displayName;
}

/// What the fake interstitial does when the policy allows one.
enum FakeInterstitialOutcome {
  /// The test ad is shown and reported as shown.
  shown(displayName: 'Interstitial: shown'),

  /// Nothing is shown, as if there were no fill.
  notShown(displayName: 'Interstitial: not shown');

  const FakeInterstitialOutcome({required this.displayName});

  /// Label for the debug panel.
  final String displayName;
}

/// Configuration of the fake ad service, exposed to the debug panel.
@immutable
class FakeAdConfig {
  const FakeAdConfig({
    this.rewarded = FakeRewardedOutcome.earned,
    this.interstitial = FakeInterstitialOutcome.shown,
    this.loadDelay = const Duration(milliseconds: 350),
    this.showDelay = const Duration(milliseconds: 250),
    this.useTestAdPage = true,
  });

  /// Rewarded outcome.
  final FakeRewardedOutcome rewarded;

  /// Interstitial outcome.
  final FakeInterstitialOutcome interstitial;

  /// Simulated preload latency.
  final Duration loadDelay;

  /// Simulated show latency (before the test ad page opens).
  final Duration showDelay;

  /// Whether to present [TestAdPage]. Widget tests turn this off and resolve the
  /// configured outcome directly.
  final bool useTestAdPage;

  /// Copy with selected fields replaced.
  FakeAdConfig copyWith({
    FakeRewardedOutcome? rewarded,
    FakeInterstitialOutcome? interstitial,
    Duration? loadDelay,
    Duration? showDelay,
    bool? useTestAdPage,
  }) {
    return FakeAdConfig(
      rewarded: rewarded ?? this.rewarded,
      interstitial: interstitial ?? this.interstitial,
      loadDelay: loadDelay ?? this.loadDelay,
      showDelay: showDelay ?? this.showDelay,
      useTestAdPage: useTestAdPage ?? this.useTestAdPage,
    );
  }

  @override
  String toString() => 'FakeAdConfig(${rewarded.name}, ${interstitial.name})';
}

/// In-memory [AdService] for development and tests.
///
/// Loads after [FakeAdConfig.loadDelay], reports readiness honestly, and presents
/// the labelled [TestAdPage] on the root navigator when [FakeAdConfig.useTestAdPage]
/// is true. Nothing here resembles a real ad and no network is touched.
class FakeAdService implements AdService {
  FakeAdService({this.config = const FakeAdConfig(), this.navigatorKey});

  /// Outcomes, delays and whether the test ad page is used.
  final FakeAdConfig config;

  /// Root navigator used to present the test ad page. Without it the configured
  /// outcome is returned directly (widget tests).
  final GlobalKey<NavigatorState>? navigatorKey;

  bool _rewardedReady = false;
  bool _interstitialReady = false;
  Future<void>? _rewardedLoad;
  Future<void>? _interstitialLoad;

  @override
  bool get isRewardedReady => _rewardedReady;

  @override
  bool get isInterstitialReady => _interstitialReady;

  @override
  Future<void> preloadRewarded() {
    if (_rewardedReady) {
      return Future<void>.value();
    }
    return _rewardedLoad ??= _delay(config.loadDelay).then((_) {
      _rewardedReady = true;
      _rewardedLoad = null;
    });
  }

  @override
  Future<void> preloadInterstitial() {
    if (_interstitialReady) {
      return Future<void>.value();
    }
    return _interstitialLoad ??= _delay(config.loadDelay).then((_) {
      _interstitialReady = true;
      _interstitialLoad = null;
    });
  }

  @override
  Future<RewardedResult> showRewarded() async {
    _rewardedReady = false;
    await _delay(config.showDelay);

    switch (config.rewarded) {
      case FakeRewardedOutcome.unavailable:
        return const RewardUnavailable('no fill');
      case FakeRewardedOutcome.failed:
        return const RewardFailed('simulated playback error');
      case FakeRewardedOutcome.earned:
      case FakeRewardedOutcome.dismissedEarly:
        final bool? earned = await _presentTestAd(
          isRewarded: true,
          allowEarlyClose:
              config.rewarded == FakeRewardedOutcome.dismissedEarly,
        );
        if (earned == null) {
          // No navigator (or the page is disabled): resolve the configured
          // outcome directly.
          return config.rewarded == FakeRewardedOutcome.earned
              ? const RewardEarned()
              : const RewardDismissedEarly();
        }
        return earned ? const RewardEarned() : const RewardDismissedEarly();
    }
  }

  @override
  Future<bool> showInterstitial() async {
    _interstitialReady = false;
    await _delay(config.showDelay);

    if (config.interstitial == FakeInterstitialOutcome.notShown) {
      return false;
    }
    final bool? shown = await _presentTestAd(
      isRewarded: false,
      allowEarlyClose: true,
    );
    // With no navigator, a "shown" configuration reports true.
    return shown ?? true;
  }

  /// Pushes [TestAdPage] on the root navigator; `null` when it cannot be shown.
  Future<bool?> _presentTestAd({
    required bool isRewarded,
    required bool allowEarlyClose,
  }) async {
    if (!config.useTestAdPage) {
      return null;
    }
    final BuildContext? context = navigatorKey?.currentContext;
    if (context == null) {
      return null;
    }
    return Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => TestAdPage(
          isRewarded: isRewarded,
          allowEarlyClose: allowEarlyClose,
        ),
      ),
    );
  }

  Future<void> _delay(Duration duration) {
    if (duration <= Duration.zero) {
      return Future<void>.value();
    }
    return Future<void>.delayed(duration);
  }
}
