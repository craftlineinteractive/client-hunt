import 'package:flutter/foundation.dart';

import 'lead_source.dart';
import 'model_equality.dart';

/// What the user asked for: one or more niches in one or more places.
///
/// This is the input to the lead engine and the payload stored in search history.
/// It is deliberately separate from [SearchFilters]: the query is *what to look
/// for*, filters are *how to narrow it*.
@immutable
class SearchQuery {
  const SearchQuery({
    this.niches = const <String>[],
    this.locations = const <String>[],
    this.sources = const <LeadSource>{LeadSource.maps},
    this.radiusKm = 25,
    this.country = 'India',
  });

  /// Free-text niches ("Dentists") or the popular-chip value.
  final List<String> niches;

  /// Cities or areas ("Ahmedabad").
  final List<String> locations;

  /// Sources to search. Maps is free; social sources require Pro.
  final Set<LeadSource> sources;

  /// Search radius in kilometres around the location.
  final double radiusKm;

  /// Country context for the search.
  final String country;

  /// True when the query is complete enough to run.
  bool get isRunnable => niches.isNotEmpty && locations.isNotEmpty;

  /// A readable title for history rows and the results app bar.
  String get displayTitle {
    final String niche = niches.isEmpty ? 'Leads' : niches.join(', ');
    final String place = locations.isEmpty ? country : locations.join(', ');
    return '$niche in $place';
  }

  /// Copy with selected fields replaced.
  SearchQuery copyWith({
    List<String>? niches,
    List<String>? locations,
    Set<LeadSource>? sources,
    double? radiusKm,
    String? country,
  }) {
    return SearchQuery(
      niches: niches ?? this.niches,
      locations: locations ?? this.locations,
      sources: sources ?? this.sources,
      radiusKm: radiusKm ?? this.radiusKm,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchQuery &&
            listsEqual<String>(other.niches, niches) &&
            listsEqual<String>(other.locations, locations) &&
            setsEqual<LeadSource>(other.sources, sources) &&
            other.radiusKm == radiusKm &&
            other.country == country;
  }

  @override
  int get hashCode => Object.hash(
    listsHash<String>(niches),
    listsHash<String>(locations),
    setsHash<LeadSource>(sources),
    radiusKm,
    country,
  );

  @override
  String toString() => 'SearchQuery($displayTitle, ${sources.length} sources)';
}
