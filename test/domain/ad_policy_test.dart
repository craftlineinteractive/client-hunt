import 'dart:math';

import 'package:clienthunt/domain/ads/ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controllable clock: tests move time forward instead of waiting.
class _Clock {
  _Clock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

/// A `Random` that always returns the same double, so the chance roll is exact.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  final DateTime start = DateTime(2026, 11, 26, 9);

  AdPolicy buildPolicy({
    double randomValue = 0,
    DateTime? startedAt,
    AdPolicyConfig config = const AdPolicyConfig(),
    _Clock? clock,
  }) {
    final _Clock resolved = clock ?? _Clock(startedAt ?? start);
    return AdPolicy(
      config: config,
      clock: resolved.call,
      random: _FixedRandom(randomValue),
      startedAt: startedAt ?? start,
    );
  }

  test('defaults are the approved values', () {
    const AdPolicyConfig config = AdPolicyConfig();
    expect(config.interstitialChance, 0.35);
    expect(
      config.minIntervalBetweenInterstitials,
      const Duration(seconds: 120),
    );
    expect(config.minUserActionsBetweenInterstitials, 2);
    expect(config.noInterstitialInFirstSeconds, 60);
    expect(config.noInterstitialWithinSecondsAfterRewarded, 60);
    expect(AdTrigger.values, <AdTrigger>[
      AdTrigger.resultsClosed,
      AdTrigger.exportFinished,
      AdTrigger.leadSaved,
      AdTrigger.leadDetailClosed,
    ]);
  });

  test('never for Pro, never while busy', () {
    final AdPolicy policy = buildPolicy();
    final _Clock clock = _Clock(start);
    policy.recordUserAction();
    policy.recordUserAction();
    clock.advance(const Duration(seconds: 120));

    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: true,
        isBusy: false,
      ),
      isFalse,
    );
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: true,
      ),
      isFalse,
    );
  });

  test('no interstitial in the first minute', () {
    final _Clock clock = _Clock(start);
    final AdPolicy policy = buildPolicy(clock: clock);
    policy.recordUserAction();
    policy.recordUserAction();
    clock.advance(const Duration(seconds: 59));

    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );

    clock.advance(const Duration(seconds: 1));
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isTrue,
    );
  });

  test('needs two completed actions', () {
    final _Clock clock = _Clock(start);
    final AdPolicy policy = buildPolicy(clock: clock);
    clock.advance(const Duration(minutes: 5));

    expect(
      policy.shouldShowInterstitial(
        AdTrigger.leadSaved,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );

    policy.recordUserAction();
    expect(policy.actionsSinceLastInterstitial, 1);
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.leadSaved,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );

    policy.recordUserAction();
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.leadSaved,
        isPro: false,
        isBusy: false,
      ),
      isTrue,
    );
  });

  test('the chance roll is respected', () {
    final DateTime fiveMinutesIn = start.add(const Duration(minutes: 5));

    AdPolicy policy(double randomValue) {
      final _Clock clock = _Clock(fiveMinutesIn);
      final AdPolicy created = buildPolicy(
        randomValue: randomValue,
        clock: clock,
        startedAt: start,
      );
      created.recordUserAction();
      created.recordUserAction();
      return created;
    }

    // 0.349 is under 0.35: show. 0.35 and above: skip.
    expect(
      policy(0.349).shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isTrue,
    );
    expect(
      policy(0.35).shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );
    expect(
      policy(0.9).shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );
  });

  test('respects the interval between interstitials', () {
    final _Clock clock = _Clock(start);
    final AdPolicy policy = buildPolicy(clock: clock);
    clock.advance(const Duration(minutes: 5));
    policy.recordUserAction();
    policy.recordUserAction();
    policy.recordInterstitialShown();
    expect(policy.secondsSinceLastInterstitial, 0);

    clock.advance(const Duration(seconds: 119));
    policy.recordUserAction();
    policy.recordUserAction();
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.exportFinished,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );

    clock.advance(const Duration(seconds: 1));
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.exportFinished,
        isPro: false,
        isBusy: false,
      ),
      isTrue,
    );
  });

  test('showing an interstitial resets the action counter', () {
    final _Clock clock = _Clock(start);
    final AdPolicy policy = buildPolicy(clock: clock);
    clock.advance(const Duration(minutes: 5));
    policy
      ..recordUserAction()
      ..recordUserAction()
      ..recordInterstitialShown();
    expect(policy.actionsSinceLastInterstitial, 0);

    policy.recordUserAction();
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );
  });

  test('no interstitial within a minute of a rewarded ad', () {
    final _Clock clock = _Clock(start);
    final AdPolicy policy = buildPolicy(clock: clock);
    clock.advance(const Duration(minutes: 5));
    policy
      ..recordUserAction()
      ..recordUserAction()
      ..recordRewardedShown();

    clock.advance(const Duration(seconds: 59));
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isFalse,
    );

    clock.advance(const Duration(seconds: 1));
    expect(
      policy.shouldShowInterstitial(
        AdTrigger.resultsClosed,
        isPro: false,
        isBusy: false,
      ),
      isTrue,
    );
  });

  test('a new policy has no interstitial history', () {
    final AdPolicy policy = buildPolicy();
    expect(policy.secondsSinceLastInterstitial, isNull);
    expect(policy.secondsSinceStart, 0);
  });
}
