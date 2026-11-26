import 'package:flutter/foundation.dart';

import '../entitlements/entitlements.dart';
import '../repositories/ad_service.dart';
import 'ad_policy.dart';

/// How the rewarded gate ended.
enum AdGateResult {
  /// Run the search now (reward earned, Pro user, or no ad was available).
  proceed,

  /// The user closed the rewarded ad early. Do not run the search.
  cancelledByUser,

  /// No ad was loaded, there was no fill, or playback failed. The user is not
  /// blocked: continue exactly as if they had watched it.
  skippedNoAd,
}

/// A minimal logging seam.
///
/// Ads failures must be observable but never crash a search. Prompt E can point
/// this at its analytics/crash logger; tests can record the messages.
abstract interface class AdLogger {
  /// Something expected happened (a preload, a skip).
  void info(String message);

  /// Something failed. [error] is for logs only, never user-facing copy.
  void warn(String message, [Object? error]);
}

/// Writes ad events to the debug console. The default in debug builds.
class DebugPrintAdLogger implements AdLogger {
  const DebugPrintAdLogger();

  @override
  void info(String message) => debugPrint('[ads] $message');

  @override
  void warn(String message, [Object? error]) =>
      debugPrint('[ads] $message${error == null ? '' : ': $error'}');
}

/// Discards ad events. Useful in tests that do not assert on logs.
class SilentAdLogger implements AdLogger {
  const SilentAdLogger();

  @override
  void info(String message) {}

  @override
  void warn(String message, [Object? error]) {}
}

/// **The one place that decides whether an ad runs.**
///
/// Screens ask the coordinator; they never call [AdService] or [AdPolicy]
/// themselves. It:
///
/// * returns [AdGateResult.proceed] immediately for Pro, without touching the ad
///   service at all;
/// * preloads a missing rewarded ad before showing it;
/// * treats every failure as non-blocking — [AdGateResult.skippedNoAd] for no
///   fill, load errors and playback errors, [AdGateResult.cancelledByUser] only
///   when the user really closed the ad early;
/// * never throws: an SDK exception becomes a logged skip.
///
/// [maybeShowInterstitial] applies [AdPolicy] and records the show; callers pass
/// `isBusy: true` whenever the user is typing, a search is loading, or a dialog
/// is open.
class AdCoordinator {
  AdCoordinator({
    required this.adService,
    required this.policy,
    required this.entitlements,
    this.logger = const DebugPrintAdLogger(),
    this.isInterstitialForced,
  });

  /// The ads implementation (fake today, AdMob in prompt E).
  final AdService adService;

  /// The session's frequency rules.
  final AdPolicy policy;

  /// The plan being gated. Pro returns proceed immediately.
  final Entitlements entitlements;

  /// Where ad outcomes are reported.
  final AdLogger logger;

  /// Debug-only override ("force the next interstitial"). Null in release.
  final bool Function()? isInterstitialForced;

  /// Runs the rewarded step of a Free search.
  ///
  /// The caller shows the opt-in dialog first; this method only plays the ad. It
  /// returns [AdGateResult.proceed] for Pro users without loading anything.
  Future<AdGateResult> runRewardedGate() async {
    if (entitlements.isPro || !entitlements.adsEnabled) {
      return AdGateResult.proceed;
    }

    try {
      if (!adService.isRewardedReady) {
        await adService.preloadRewarded();
      }
      if (!adService.isRewardedReady) {
        logger.warn('Rewarded ad skipped: not ready after preload');
        return AdGateResult.skippedNoAd;
      }

      final RewardedResult result = await adService.showRewarded();
      switch (result) {
        case RewardEarned():
          policy.recordRewardedShown();
          logger.info('Reward earned');
          // Keep the next tap instant.
          unawaitedPreload();
          return AdGateResult.proceed;
        case RewardDismissedEarly():
          logger.info('Rewarded ad closed before the reward');
          return AdGateResult.cancelledByUser;
        case RewardUnavailable(:final String reason):
          logger.warn('Rewarded ad unavailable: $reason');
          return AdGateResult.skippedNoAd;
        case RewardFailed(:final String message):
          logger.warn('Rewarded ad failed: $message');
          return AdGateResult.skippedNoAd;
      }
    } catch (error) {
      logger.warn('Rewarded gate errored, continuing without an ad', error);
      return AdGateResult.skippedNoAd;
    }
  }

  /// Shows an interstitial if [AdPolicy] allows it at [trigger].
  ///
  /// A load failure is not an error the user sees: it just means no ad. Returns
  /// true only when an interstitial was actually presented.
  Future<bool> maybeShowInterstitial(
    AdTrigger trigger, {
    bool isBusy = false,
  }) async {
    if (entitlements.isPro || !entitlements.adsEnabled) {
      return false;
    }
    final bool forced = isInterstitialForced?.call() ?? false;
    if (!forced &&
        !policy.shouldShowInterstitial(
          trigger,
          isPro: entitlements.isPro,
          isBusy: isBusy,
        )) {
      return false;
    }

    try {
      if (!adService.isInterstitialReady) {
        await adService.preloadInterstitial();
      }
      if (!adService.isInterstitialReady) {
        logger.info('Interstitial skipped at ${trigger.name}: not ready');
        return false;
      }
      final bool shown = await adService.showInterstitial();
      if (shown) {
        policy.recordInterstitialShown();
        logger.info('Interstitial shown at ${trigger.name}');
      }
      return shown;
    } catch (error) {
      logger.warn('Interstitial at ${trigger.name} errored', error);
      return false;
    }
  }

  /// Loads the rewarded ad in the background, e.g. when Home appears, so the
  /// next Find Leads tap is instant.
  void preloadRewarded() => unawaitedPreload();

  /// Fires a preload without making the caller wait for it.
  void unawaitedPreload() {
    adService.preloadRewarded().catchError((Object error) {
      logger.warn('Rewarded preload failed', error);
    });
  }
}
