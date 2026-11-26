import 'package:flutter/foundation.dart';

import 'model_equality.dart';

/// Business open-state filter.
///
/// There are exactly two values. "Recently active" was dropped from the product:
/// it needs social last-activity data the engine does not have, so offering it
/// would be a promise the app cannot keep. Open-now applies to Maps leads only.
enum OpenStatus {
  /// Any state.
  any(displayName: 'Any'),

  /// Open right now. Maps only.
  openNow(displayName: 'Open now');

  const OpenStatus({required this.displayName});

  /// Label used by the status segmented control.
  final String displayName;
}

/// How much work the engine does per result.
enum SearchDepth {
  /// Listing details only.
  fast(displayName: 'Fast'),

  /// Also crawls business websites for emails and phones. Pro only.
  deep(displayName: 'Deep');

  const SearchDepth({required this.displayName});

  /// Label used by the depth radio tiles.
  final String displayName;

  /// Whether this depth requires a Pro subscription.
  bool get isPro => this == SearchDepth.deep;
}

/// Result ordering.
enum SortOption {
  /// Best match for the query.
  relevance(displayName: 'Relevance'),

  /// Highest rating first. Maps only.
  rating(displayName: 'Rating'),

  /// Most reviews first. Maps only.
  reviews(displayName: 'Reviews'),

  /// Newest discovery first.
  newest(displayName: 'Newest'),

  /// Alphabetical by name.
  name(displayName: 'Name');

  const SortOption({required this.displayName});

  /// Label used by the sort selector.
  final String displayName;

  /// Whether this sort needs Maps-only fields.
  bool get needsMapsData =>
      this == SortOption.rating || this == SortOption.reviews;
}

/// Everything the Filters screen can change before a search runs.
///
/// Defaults match the approved mockup. Some filters depend on data only Maps can
/// provide (rating, reviews, open now) or on Pro (no website, deep search, 200
/// results); the engine must exclude leads that cannot satisfy them rather than
/// pretend they pass (README section 7).
@immutable
class SearchFilters {
  const SearchFilters({
    this.hasEmail = true,
    this.hasPhone = true,
    this.hasWebsite = false,
    this.hasWhatsApp = false,
    this.hasSocial = false,
    this.noWebsite = false,
    this.minRating,
    this.minReviews,
    this.openStatus = OpenStatus.any,
    this.mustInclude = const <String>[],
    this.exclude = const <String>[],
    this.depth = SearchDepth.fast,
    this.maxResults = 50,
    this.sortBy = SortOption.relevance,
    this.dedupe = true,
    this.skipSaved = true,
    this.removeInvalidPhones = true,
    this.groupByCity = false,
  });

  /// Require at least one email.
  final bool hasEmail;

  /// Require at least one phone.
  final bool hasPhone;

  /// Require a website.
  final bool hasWebsite;

  /// Require a WhatsApp-capable number.
  final bool hasWhatsApp;

  /// Require at least one social profile link.
  final bool hasSocial;

  /// Require **no** website. Pro only; Maps results only.
  final bool noWebsite;

  /// Minimum Maps rating (3.0–4.5), or null for any.
  final double? minRating;

  /// Minimum Maps review count (10/50/100), or null for any.
  final int? minReviews;

  /// Open-state filter.
  final OpenStatus openStatus;

  /// Keywords a lead must contain (name, category or description).
  final List<String> mustInclude;

  /// Keywords that disqualify a lead.
  final List<String> exclude;

  /// Listing-only or website-crawling search.
  final SearchDepth depth;

  /// Result cap: 25, 50, 100 or 200 (200 is Pro).
  final int maxResults;

  /// Result ordering.
  final SortOption sortBy;

  /// Remove duplicate businesses.
  final bool dedupe;

  /// Skip leads the user already saved.
  final bool skipSaved;

  /// Drop leads whose only phones fail validation.
  final bool removeInvalidPhones;

  /// Group results under city headers.
  final bool groupByCity;

  /// True when any filter deviates from the defaults; drives the "5 filters
  /// active" caption on the Filters screen.
  bool get hasActiveChanges =>
      hasEmail != true ||
      hasPhone != true ||
      hasWebsite ||
      hasWhatsApp ||
      hasSocial ||
      noWebsite ||
      minRating != null ||
      minReviews != null ||
      openStatus != OpenStatus.any ||
      mustInclude.isNotEmpty ||
      exclude.isNotEmpty ||
      depth != SearchDepth.fast ||
      maxResults != 50 ||
      sortBy != SortOption.relevance ||
      !dedupe ||
      !skipSaved ||
      !removeInvalidPhones ||
      groupByCity;

  /// Copy with selected fields replaced; null keeps the current value.
  SearchFilters copyWith({
    bool? hasEmail,
    bool? hasPhone,
    bool? hasWebsite,
    bool? hasWhatsApp,
    bool? hasSocial,
    bool? noWebsite,
    double? minRating,
    int? minReviews,
    OpenStatus? openStatus,
    List<String>? mustInclude,
    List<String>? exclude,
    SearchDepth? depth,
    int? maxResults,
    SortOption? sortBy,
    bool? dedupe,
    bool? skipSaved,
    bool? removeInvalidPhones,
    bool? groupByCity,
  }) {
    return SearchFilters(
      hasEmail: hasEmail ?? this.hasEmail,
      hasPhone: hasPhone ?? this.hasPhone,
      hasWebsite: hasWebsite ?? this.hasWebsite,
      hasWhatsApp: hasWhatsApp ?? this.hasWhatsApp,
      hasSocial: hasSocial ?? this.hasSocial,
      noWebsite: noWebsite ?? this.noWebsite,
      minRating: minRating ?? this.minRating,
      minReviews: minReviews ?? this.minReviews,
      openStatus: openStatus ?? this.openStatus,
      mustInclude: mustInclude ?? this.mustInclude,
      exclude: exclude ?? this.exclude,
      depth: depth ?? this.depth,
      maxResults: maxResults ?? this.maxResults,
      sortBy: sortBy ?? this.sortBy,
      dedupe: dedupe ?? this.dedupe,
      skipSaved: skipSaved ?? this.skipSaved,
      removeInvalidPhones: removeInvalidPhones ?? this.removeInvalidPhones,
      groupByCity: groupByCity ?? this.groupByCity,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchFilters &&
            other.hasEmail == hasEmail &&
            other.hasPhone == hasPhone &&
            other.hasWebsite == hasWebsite &&
            other.hasWhatsApp == hasWhatsApp &&
            other.hasSocial == hasSocial &&
            other.noWebsite == noWebsite &&
            other.minRating == minRating &&
            other.minReviews == minReviews &&
            other.openStatus == openStatus &&
            listsEqual<String>(other.mustInclude, mustInclude) &&
            listsEqual<String>(other.exclude, exclude) &&
            other.depth == depth &&
            other.maxResults == maxResults &&
            other.sortBy == sortBy &&
            other.dedupe == dedupe &&
            other.skipSaved == skipSaved &&
            other.removeInvalidPhones == removeInvalidPhones &&
            other.groupByCity == groupByCity;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    hasEmail,
    hasPhone,
    hasWebsite,
    hasWhatsApp,
    hasSocial,
    noWebsite,
    minRating,
    minReviews,
    openStatus,
    listsHash<String>(mustInclude),
    listsHash<String>(exclude),
    depth,
    maxResults,
    sortBy,
    dedupe,
    skipSaved,
    removeInvalidPhones,
    groupByCity,
  ]);

  @override
  String toString() => 'SearchFilters(max: $maxResults, depth: ${depth.name})';
}
