import 'dart:math';

import 'package:clienthunt/domain/ads/ad_coordinator.dart';
import 'package:clienthunt/domain/ads/ad_policy.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/repositories/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every call so tests can prove what the coordinator did *not* touch.
class _RecordingAdService implements AdService {
  _RecordingAdService({
    this.rewardedReady = true,
    this.rewarded = const RewardEarned(),
    this.interstitialShown = true,
    this.throwOnShow = false,
    this.readyAfterPreload = true,
  });

  bool rewardedReady;
  RewardedResult rewarded;
  bool interstitialReady = true;
  bool interstitialShown;
  bool throwOnShow;
  bool readyAfterPreload;

  int rewardedPreloads = 0;
  int rewardedShows = 0;
  int interstitialPreloads = 0;
  int interstitialShows = 0;

  @override
  bool get isRewardedReady => rewardedReady;

  @override
  bool get isInterstitialReady => interstitialReady;

  @override
  Future<void> preloadRewarded() async {
    rewardedPreloads++;
    rewardedReady = readyAfterPreload;
  }

  @override
  Future<void> preloadInterstitial() async {
    interstitialPreloads++;
    interstitialReady = readyAfterPreload;
  }

  @override
  Future<RewardedResult> showRewarded() async {
    rewardedShows++;
    rewardedReady = false;
    if (throwOnShow) {
      throw StateError('sdk exploded');
    }
    return rewarded;
  }

  @override
  Future<bool> showInterstitial() async {
    interstitialShows++;
    interstitialReady = false;
    if (throwOnShow) {
      throw StateError('sdk exploded');
    }
    return interstitialShown;
  }
}

class _RecordingLogger implements AdLogger {
  final List<String> lines = <String>[];

  @override
  void info(String message) => lines.add('info: $message');

  @override
  void warn(String message, [Object? error]) =>
      lines.add('warn: $message${error == null ? '' : ' ($error)'}');
}

/// A `Random` that always allows the chance roll.
class _YesRandom implements Random {
  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;
}

void main() {
  final DateTime start = DateTime(2026, 11, 26, 9);
  late DateTime now;

  AdCoordinator build({
    required _RecordingAdService service,
    required Entitlements entitlements,
    _RecordingLogger? logger,
    bool Function()? forced,
    AdPolicyConfig config = const AdPolicyConfig(interstitialChance: 1),
  }) {
    return AdCoordinator(
      adService: service,
      policy: AdPolicy(
        config: config,
        clock: () => now,
        random: _YesRandom(),
        startedAt: start,
      ),
      entitlements: entitlements,
      logger: logger ?? _RecordingLogger(),
      isInterstitialForced: forced,
    );
  }

  setUp(() => now = start);

  group('runRewardedGate', () {
    test('Pro proceeds without touching the ad service', () async {
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: proEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.proceed);
      expect(service.rewardedPreloads, 0);
      expect(service.rewardedShows, 0);
    });

    test('an earned reward proceeds', () async {
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.proceed);
      expect(service.rewardedShows, 1);
      // The reward starts the no-interstitial window.
      expect(
        coordinator.policy.shouldShowInterstitial(
          AdTrigger.resultsClosed,
          isPro: false,
          isBusy: false,
        ),
        isFalse,
      );
    });

    test('closing early cancels the search', () async {
      final _RecordingAdService service = _RecordingAdService(
        rewarded: const RewardDismissedEarly(),
      );
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.cancelledByUser);
    });

    test('no fill skips the ad instead of blocking', () async {
      final _RecordingAdService service = _RecordingAdService(
        rewarded: const RewardUnavailable('no fill'),
      );
      final _RecordingLogger logger = _RecordingLogger();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
        logger: logger,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.skippedNoAd);
      expect(
        logger.lines.any((String line) => line.contains('no fill')),
        isTrue,
        reason: 'the reason must be logged',
      );
    });

    test('a playback failure skips the ad', () async {
      final _RecordingAdService service = _RecordingAdService(
        rewarded: const RewardFailed('boom'),
      );
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.skippedNoAd);
    });

    test('a thrown SDK error becomes a skip, never an exception', () async {
      final _RecordingAdService service = _RecordingAdService(
        throwOnShow: true,
      );
      final _RecordingLogger logger = _RecordingLogger();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
        logger: logger,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.skippedNoAd);
      expect(
        logger.lines.any((String line) => line.startsWith('warn:')),
        isTrue,
      );
    });

    test('an ad that never becomes ready is skipped', () async {
      final _RecordingAdService service = _RecordingAdService(
        rewardedReady: false,
        readyAfterPreload: false,
      );
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.skippedNoAd);
      expect(service.rewardedPreloads, 1);
      expect(service.rewardedShows, 0);
    });

    test('a missing preload is loaded first', () async {
      final _RecordingAdService service = _RecordingAdService(
        rewardedReady: false,
      );
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );

      expect(await coordinator.runRewardedGate(), AdGateResult.proceed);
      // One preload before showing, plus the background reload for the next tap.
      expect(service.rewardedPreloads, 2);
      expect(service.rewardedShows, 1);
    });
  });

  group('maybeShowInterstitial', () {
    Future<void> ageSession(AdCoordinator coordinator) async {
      now = start.add(const Duration(minutes: 5));
      coordinator.policy
        ..recordUserAction()
        ..recordUserAction();
    }

    test('never for Pro', () async {
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: proEntitlements,
      );
      await ageSession(coordinator);

      expect(
        await coordinator.maybeShowInterstitial(AdTrigger.resultsClosed),
        isFalse,
      );
      expect(service.interstitialShows, 0);
    });

    test('never while busy', () async {
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );
      await ageSession(coordinator);

      expect(
        await coordinator.maybeShowInterstitial(
          AdTrigger.leadSaved,
          isBusy: true,
        ),
        isFalse,
      );
      expect(service.interstitialShows, 0);
    });

    test('shows when the policy allows it and records the show', () async {
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );
      await ageSession(coordinator);

      expect(
        await coordinator.maybeShowInterstitial(AdTrigger.resultsClosed),
        isTrue,
      );
      expect(service.interstitialShows, 1);
      expect(coordinator.policy.actionsSinceLastInterstitial, 0);
      expect(coordinator.policy.secondsSinceLastInterstitial, 0);
    });

    test('a forced flag bypasses the roll but not Pro or busy', () async {
      bool forced = true;
      final _RecordingAdService service = _RecordingAdService();
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
        forced: () => forced,
      );
      // Fresh session: the first-minute rule would normally refuse.
      expect(
        await coordinator.maybeShowInterstitial(AdTrigger.exportFinished),
        isTrue,
      );

      forced = false;
      expect(
        await coordinator.maybeShowInterstitial(AdTrigger.exportFinished),
        isFalse,
      );
    });

    test('no fill is a quiet false', () async {
      final _RecordingAdService service = _RecordingAdService(
        interstitialShown: false,
      );
      final AdCoordinator coordinator = build(
        service: service,
        entitlements: freeEntitlements,
      );
      await ageSession(coordinator);

      expect(
        await coordinator.maybeShowInterstitial(AdTrigger.resultsClosed),
        isFalse,
      );
    });
  });
}
