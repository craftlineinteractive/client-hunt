import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'entitlements.dart';

/// Why an action is locked.
///
/// The paywall uses this to decide *which* copy to lead with (a source gate reads
/// differently from a saved-lead cap), and analytics use it to know what the user
/// tried to do. It deliberately carries no UI text: copy lives in
/// `core/constants/app_strings.dart`.
enum LockReason {
  /// The source is Pro-only (Instagram, LinkedIn, Facebook, X).
  sourceRequiresPro,

  /// Deep search needs Pro.
  deepSearchRequiresPro,

  /// The "No website" filter needs Pro.
  noWebsiteFilterRequiresPro,

  /// A result cap above the plan's maximum (100 and 200 on Free).
  maxResultsRequiresPro,

  /// The saved-lead cap is reached.
  savedLeadLimitReached,

  /// Today's free search allowance is used up.
  dailySearchLimitReached,
}

/// One choice in the Filters screen's "Max results" row.
@immutable
class MaxResultsOption {
  const MaxResultsOption({required this.value, required this.isLocked});

  /// 25, 50, 100 or 200.
  final int value;

  /// True when the current plan cannot select it; the row shows a lock badge.
  final bool isLocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaxResultsOption &&
          other.value == value &&
          other.isLocked == isLocked;

  @override
  int get hashCode => Object.hash(value, isLocked);

  @override
  String toString() => 'MaxResultsOption($value, locked: $isLocked)';
}

/// Answers "may this user do X?" from one [Entitlements] value.
///
/// The UI never compares limits itself: a locked chip asks
/// `gate.canUseSource(LeadSource.instagram)`, and a paywall opened from that chip
/// asks why. Keeping the rules here means the Home chips, the Filters rows, the
/// save path and the engine all agree.
@immutable
class FeatureGate {
  const FeatureGate(this.entitlements);

  /// The plan being gated.
  final Entitlements entitlements;

  /// Every selectable result cap, in display order.
  static const List<int> maxResultsValues = <int>[25, 50, 100, 200];

  /// True when [source] may be searched on this plan.
  bool canUseSource(LeadSource source) =>
      entitlements.allowedSources.contains(source);

  /// True when Deep search may run.
  bool get canUseDeepSearch => entitlements.deepSearchAllowed;

  /// True when the "No website" filter may be switched on.
  bool get canUseNoWebsiteFilter => entitlements.noWebsiteFilterAllowed;

  /// True when ad slots render.
  bool get showsAds => entitlements.adsEnabled;

  /// True when [format] may be exported.
  bool canExport(ExportFormat format) =>
      entitlements.exportFormats.contains(format);

  /// The "Max results" row: 25 and 50 are free, 100 and 200 carry a Pro lock on
  /// Free; on Pro everything up to 200 is selectable.
  List<MaxResultsOption> get maxResultsOptions => <MaxResultsOption>[
    for (final int value in maxResultsValues)
      MaxResultsOption(
        value: value,
        isLocked: value > entitlements.maxResultsPerSearch,
      ),
  ];

  /// True when a search may ask for [value] results.
  bool isMaxResultsAllowed(int value) =>
      value <= entitlements.maxResultsPerSearch;

  /// True when another lead may be saved at [savedCount] existing saves.
  bool canSaveMore(int savedCount) {
    final int? cap = entitlements.maxSavedLeads;
    return cap == null || savedCount < cap;
  }

  /// How many more leads may be saved; `null` when unlimited.
  int? remainingSavedSlots(int savedCount) {
    final int? cap = entitlements.maxSavedLeads;
    if (cap == null) {
      return null;
    }
    return (cap - savedCount).clamp(0, cap);
  }

  /// True when the user may run a search with [remainingToday] searches left.
  bool canSearchToday(int remainingToday) {
    if (entitlements.freeSearchesPerDay == null) {
      return true;
    }
    return remainingToday > 0;
  }

  /// Why [source] is locked, or `null` when it is allowed.
  LockReason? reasonForSource(LeadSource source) =>
      canUseSource(source) ? null : LockReason.sourceRequiresPro;

  /// Why [depth] is locked, or `null` when it is allowed.
  LockReason? reasonForDepth(SearchDepth depth) =>
      depth.isPro && !canUseDeepSearch
      ? LockReason.deepSearchRequiresPro
      : null;

  /// Why [value] is locked, or `null` when it is allowed.
  LockReason? reasonForMaxResults(int value) =>
      isMaxResultsAllowed(value) ? null : LockReason.maxResultsRequiresPro;

  /// Why the "No website" filter is locked, or `null` when it is allowed.
  LockReason? get reasonForNoWebsiteFilter =>
      canUseNoWebsiteFilter ? null : LockReason.noWebsiteFilterRequiresPro;

  /// Why saving is blocked at [savedCount] existing saves, or `null`.
  LockReason? reasonForSaving(int savedCount) =>
      canSaveMore(savedCount) ? null : LockReason.savedLeadLimitReached;

  /// Why searching is blocked with [remainingToday] searches left, or `null`.
  LockReason? reasonForSearching(int remainingToday) =>
      canSearchToday(remainingToday)
      ? null
      : LockReason.dailySearchLimitReached;

  /// The first reason anything in [request] is locked, or `null` when all of it
  /// is allowed. Checked in the order the user meets the controls.
  LockReason? reasonForLock({
    LeadSource? source,
    SearchDepth? depth,
    int? maxResults,
    bool wantsNoWebsiteFilter = false,
    int? savedCount,
    int? searchesRemainingToday,
  }) {
    if (source != null) {
      final LockReason? reason = reasonForSource(source);
      if (reason != null) {
        return reason;
      }
    }
    if (depth != null) {
      final LockReason? reason = reasonForDepth(depth);
      if (reason != null) {
        return reason;
      }
    }
    if (wantsNoWebsiteFilter) {
      final LockReason? reason = reasonForNoWebsiteFilter;
      if (reason != null) {
        return reason;
      }
    }
    if (maxResults != null) {
      final LockReason? reason = reasonForMaxResults(maxResults);
      if (reason != null) {
        return reason;
      }
    }
    if (savedCount != null) {
      final LockReason? reason = reasonForSaving(savedCount);
      if (reason != null) {
        return reason;
      }
    }
    if (searchesRemainingToday != null) {
      final LockReason? reason = reasonForSearching(searchesRemainingToday);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  @override
  String toString() => 'FeatureGate(${entitlements.isPro ? 'Pro' : 'Free'})';
}
