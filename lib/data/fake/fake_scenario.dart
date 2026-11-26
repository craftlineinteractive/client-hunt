import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_ad_service.dart';
import 'fake_location_service.dart';

/// Which behaviour the fake engine shows on the next search.
///
/// This is how the B prompts check every state without a network: loading,
/// partial results, empty and both error kinds. Debug builds switch it from the
/// design gallery's "Fake data" panel.
enum FakeScenario {
  /// ~700 ms search that returns the 42 Dentists leads.
  normal(displayName: 'Normal'),

  /// The same run at roughly triple the latency, to see loading states.
  slow(displayName: 'Slow'),

  /// Completes with zero leads, so the empty state renders.
  empty(displayName: 'Empty'),

  /// Fails immediately with no network.
  errorNoNetwork(displayName: 'Error: no network'),

  /// Fails after the first stage with a rate-limit error.
  errorRateLimited(displayName: 'Error: rate limited'),

  /// Maps succeeds, a social source is blocked: partial degradation.
  partialSourceBlocked(displayName: 'Partial: source blocked');

  const FakeScenario({required this.displayName});

  /// Label for the debug panel.
  final String displayName;
}

/// The scenario the next search uses. Debug-only in practice; harmless in release
/// because it defaults to [FakeScenario.normal].
class FakeScenarioController extends Notifier<FakeScenario> {
  @override
  FakeScenario build() => FakeScenario.normal;

  /// Selects a scenario for the next searches.
  void set(FakeScenario scenario) => state = scenario;
}

/// Current fake search scenario.
final NotifierProvider<FakeScenarioController, FakeScenario>
fakeScenarioProvider = NotifierProvider<FakeScenarioController, FakeScenario>(
  FakeScenarioController.new,
);

/// Whether the fake data layer pretends the user has Pro.
///
/// Simulates a purchase so every locked/unlocked state can be checked without
/// billing. It feeds `FakeSubscriptionRepository`, which is the only thing that
/// decides entitlements — no screen reads this flag directly.
class FakeProController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Turns the pretend subscription on or off.
  void set(bool isPro) => state = isPro;
}

/// Debug Pro switch for the fake subscription.
final NotifierProvider<FakeProController, bool> fakeProEnabledProvider =
    NotifierProvider<FakeProController, bool>(FakeProController.new);

/// Ad outcomes used by the fake ad service.
///
/// Changing any of these rebuilds the fake service, which is exactly what the
/// next ad should pick up.
class FakeAdConfigController extends Notifier<FakeAdConfig> {
  @override
  FakeAdConfig build() => const FakeAdConfig();

  /// Replaces the whole configuration.
  void set(FakeAdConfig config) => state = config;

  /// Picks the rewarded outcome.
  void setRewarded(FakeRewardedOutcome outcome) =>
      state = state.copyWith(rewarded: outcome);

  /// Picks the interstitial outcome.
  void setInterstitial(FakeInterstitialOutcome outcome) =>
      state = state.copyWith(interstitial: outcome);
}

/// Current fake ad configuration.
final NotifierProvider<FakeAdConfigController, FakeAdConfig>
fakeAdConfigProvider = NotifierProvider<FakeAdConfigController, FakeAdConfig>(
  FakeAdConfigController.new,
);

/// Debug switch that makes the next [AdTrigger] show an interstitial even when
/// the 35% roll and the action counter would refuse.
///
/// The rest of the policy still applies: Pro and `isBusy` always win.
class ForcedInterstitialController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Turns the override on or off.
  void set(bool value) => state = value;
}

/// Debug "force the next interstitial" switch.
final NotifierProvider<ForcedInterstitialController, bool>
forcedInterstitialProvider =
    NotifierProvider<ForcedInterstitialController, bool>(
      ForcedInterstitialController.new,
    );

/// Location outcome used by the fake location service.
class FakeLocationController extends Notifier<FakeLocationOutcome> {
  @override
  FakeLocationOutcome build() => FakeLocationOutcome.found;

  /// Chooses found, denied or unavailable.
  void set(FakeLocationOutcome outcome) => state = outcome;
}

/// Current fake location outcome.
final NotifierProvider<FakeLocationController, FakeLocationOutcome>
fakeLocationOutcomeProvider =
    NotifierProvider<FakeLocationController, FakeLocationOutcome>(
      FakeLocationController.new,
    );
