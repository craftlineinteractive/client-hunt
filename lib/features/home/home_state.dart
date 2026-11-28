import 'package:flutter/foundation.dart';

import '../../domain/models/models.dart';

/// What is wrong with a niche or city field, or `null` when it is valid.
///
/// A tiny enum instead of a message: the state layer never owns copy, the page
/// maps each value to a string from `HomeStrings`.
enum PlaceIssue {
  /// Fewer than two characters after trimming.
  tooShort,

  /// More than sixty characters after trimming.
  tooLong,

  /// A character outside letters, numbers, space and `. , & ' - /`.
  invalidCharacters,
}

/// Validates one niche or city value using the rules Home relies on.
///
/// Trimming happens first, so a field of spaces is [PlaceIssue.tooShort] rather
/// than valid. The character set is deliberately conservative: it is what the
/// catalogs and the engine can normalize, and it keeps a stray emoji or control
/// character out of a stored search.
PlaceIssue? validatePlace(String value) {
  final String trimmed = value.trim();
  if (trimmed.length < 2) {
    return PlaceIssue.tooShort;
  }
  if (trimmed.length > 60) {
    return PlaceIssue.tooLong;
  }
  if (!RegExp(r"^[A-Za-z0-9 .,&'/-]+$").hasMatch(trimmed)) {
    return PlaceIssue.invalidCharacters;
  }
  return null;
}

/// Whether the Home quota still allows a search.
enum HomeQuotaStatus {
  /// A Free user has searches left today.
  available,

  /// A Free user has used today's allowance.
  exhausted,

  /// Pro: no daily limit.
  unlimited,
}

/// Everything the Search tab's form holds.
///
/// Immutable and owned by [HomeController]. The quick toggles are *not* separate
/// fields: they are `hasEmail` / `hasPhone` / `hasWebsite` inside [filters], the
/// same object the Filters screen returns, so there is one source of truth and
/// one count of active filters.
@immutable
class HomeState {
  const HomeState({
    required this.niche,
    required this.location,
    required this.sources,
    required this.filters,
    required this.defaultCountry,
    required this.maxResultsCap,
    this.preferredMaxResults = 50,
    this.isSubmitting = false,
    this.isLocating = false,
  });

  /// Raw niche text as typed (\"Dentists\", \"dental clinic\").
  final String niche;

  /// Raw city text as typed (\"Ahmedabad\", \"Bombay\").
  final String location;

  /// Selected sources. Never empty; Maps is free, the other four are Pro.
  final Set<LeadSource> sources;

  /// The advanced filters, including the three quick toggles.
  final SearchFilters filters;

  /// Country context taken from settings (\"India\").
  final String defaultCountry;

  /// The plan's result ceiling (50 Free, 200 Pro).
  final int maxResultsCap;

  /// The preferred result count from settings, before the plan cap applies.
  final int preferredMaxResults;

  /// True while the rewarded dialog or ad is running: disables the CTA and
  /// blocks a second submit.
  final bool isSubmitting;

  /// True while the device location is being resolved.
  final bool isLocating;

  /// Validation problem in the niche field, or `null`.
  PlaceIssue? get nicheIssue => validatePlace(niche);

  /// Validation problem in the city field, or `null`.
  PlaceIssue? get locationIssue => validatePlace(location);

  /// Whether the form can run: both fields valid and at least one source.
  bool get canSearch =>
      nicheIssue == null && locationIssue == null && sources.isNotEmpty;

  /// Number of filters that differ from the defaults, including quick toggles.
  int get activeFilterCount => filters.activeFilterCount;

  /// The result cap actually sent: the filter value clamped to the plan.
  ///
  /// The Filters screen may choose 25 or 100; a Free user can never ask for more
  /// than 50 even if a stored value says otherwise.
  int get effectiveMaxResults =>
      filters.maxResults.clamp(25, maxResultsCap).toInt();

  /// A copy with selected fields replaced.
  HomeState copyWith({
    String? niche,
    String? location,
    Set<LeadSource>? sources,
    SearchFilters? filters,
    String? defaultCountry,
    int? maxResultsCap,
    int? preferredMaxResults,
    bool? isSubmitting,
    bool? isLocating,
  }) {
    return HomeState(
      niche: niche ?? this.niche,
      location: location ?? this.location,
      sources: sources ?? this.sources,
      filters: filters ?? this.filters,
      defaultCountry: defaultCountry ?? this.defaultCountry,
      maxResultsCap: maxResultsCap ?? this.maxResultsCap,
      preferredMaxResults: preferredMaxResults ?? this.preferredMaxResults,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLocating: isLocating ?? this.isLocating,
    );
  }

  @override
  String toString() =>
      'HomeState("$niche in $location", ${sources.length} sources, '
      '$activeFilterCount filters)';
}

/// Which quick toggle was switched.
enum HomeQuickFilter {
  /// Require at least one email.
  email,

  /// Require at least one phone.
  phone,

  /// Require a website.
  website,
}
