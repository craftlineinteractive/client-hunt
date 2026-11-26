/// What a rewarded ad returned.
///
/// A sealed result, so the ad gate must handle every ending: an earned reward,
/// the user closing early, no fill, and a playback error. Only [RewardEarned]
/// lets the search run; the other three are resolved by the caller's policy.
sealed class RewardedResult {
  const RewardedResult();
}

/// The user watched the ad to the end and earned the reward.
final class RewardEarned extends RewardedResult {
  const RewardEarned();

  @override
  String toString() => 'RewardEarned()';
}

/// The user closed the ad before the reward was earned.
final class RewardDismissedEarly extends RewardedResult {
  const RewardDismissedEarly();

  @override
  String toString() => 'RewardDismissedEarly()';
}

/// No ad could be shown: not loaded, no fill, frequency capped, no network.
///
/// Not a user error. The search must never be blocked by it.
final class RewardUnavailable extends RewardedResult {
  const RewardUnavailable(this.reason);

  /// Short, log-safe reason (\"no fill\", \"not loaded\").
  final String reason;

  @override
  String toString() => 'RewardUnavailable($reason)';
}

/// The ad SDK reported a playback failure.
final class RewardFailed extends RewardedResult {
  const RewardFailed(this.message);

  /// Short, log-safe message. Never shown to the user verbatim.
  final String message;

  @override
  String toString() => 'RewardFailed($message)';
}

/// The ads seam.
///
/// The app has no banner or native placements. Two formats only:
///
/// * **Rewarded**, always opt-in: Home shows a confirmation dialog, then
///   [showRewarded]. A reward is what lets a Free search run.
/// * **Interstitial**, at natural breaks chosen by `AdPolicy`.
///
/// The fake in `data/fake/` presents a labelled test-ad page; prompt E implements
/// this interface over AdMob (test ad unit ids first). Nothing else in the app may
/// talk to an ads SDK.
abstract interface class AdService {
  /// Loads the next rewarded ad. Safe to call repeatedly; a load in flight is not
  /// started twice.
  Future<void> preloadRewarded();

  /// Whether a rewarded ad is loaded and can be shown right now.
  bool get isRewardedReady;

  /// Loads the next interstitial.
  Future<void> preloadInterstitial();

  /// Whether an interstitial is loaded and can be shown right now.
  bool get isInterstitialReady;

  /// Shows the rewarded ad and waits for its outcome.
  ///
  /// Returns [RewardUnavailable] rather than throwing when nothing is loaded.
  Future<RewardedResult> showRewarded();

  /// Shows an interstitial. True when it was actually presented.
  Future<bool> showInterstitial();
}
