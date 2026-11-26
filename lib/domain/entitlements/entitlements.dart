import 'package:flutter/foundation.dart';

import '../models/model_equality.dart';
import '../models/models.dart';

/// What a user's subscription allows.
///
/// **One source of truth for Free vs Pro.** No screen, widget or engine may
/// hard-code a limit; they read an [Entitlements] from
/// `entitlementsProvider` and ask a `FeatureGate`. That way a pricing change is a
/// single edit here, and prompts C (storage) and E (billing) can swap the source
/// without touching UI code.
///
/// Null means *unlimited* — [maxSavedLeads] and [freeSearchesPerDay] use it so a
/// Pro plan can say "no cap" rather than inventing a big number.
@immutable
class Entitlements {
  const Entitlements({
    required this.isPro,
    required this.maxResultsPerSearch,
    required this.maxSavedLeads,
    required this.freeSearchesPerDay,
    required this.allowedSources,
    required this.deepSearchAllowed,
    required this.noWebsiteFilterAllowed,
    required this.adsEnabled,
    required this.exportFormats,
  }) : assert(maxResultsPerSearch > 0, 'A result cap must be positive');

  /// Whether the user has an active Pro subscription.
  final bool isPro;

  /// Highest `maxResults` value a search may use.
  final int maxResultsPerSearch;

  /// Saved-lead cap; `null` means unlimited.
  final int? maxSavedLeads;

  /// Searches allowed per calendar day; `null` means no daily limit.
  final int? freeSearchesPerDay;

  /// Sources the user may search. `{maps}` on Free, all five on Pro.
  ///
  /// [LeadSource.web] is a provenance tag, not a selectable source, so it never
  /// appears here.
  final Set<LeadSource> allowedSources;

  /// Whether Deep search (crawling business websites for emails) is allowed.
  final bool deepSearchAllowed;

  /// Whether the "No website" filter is allowed.
  final bool noWebsiteFilterAllowed;

  /// Whether ad slots render. True on Free, false on Pro.
  final bool adsEnabled;

  /// Formats the export screen may produce.
  final Set<ExportFormat> exportFormats;

  /// Sources a user can choose on the Search screen, in display order.
  static const List<LeadSource> selectableSources = <LeadSource>[
    LeadSource.maps,
    LeadSource.instagram,
    LeadSource.linkedin,
    LeadSource.facebook,
    LeadSource.x,
  ];

  /// Copy with selected fields replaced.
  Entitlements copyWith({
    bool? isPro,
    int? maxResultsPerSearch,
    int? maxSavedLeads,
    int? freeSearchesPerDay,
    Set<LeadSource>? allowedSources,
    bool? deepSearchAllowed,
    bool? noWebsiteFilterAllowed,
    bool? adsEnabled,
    Set<ExportFormat>? exportFormats,
  }) {
    return Entitlements(
      isPro: isPro ?? this.isPro,
      maxResultsPerSearch: maxResultsPerSearch ?? this.maxResultsPerSearch,
      maxSavedLeads: maxSavedLeads ?? this.maxSavedLeads,
      freeSearchesPerDay: freeSearchesPerDay ?? this.freeSearchesPerDay,
      allowedSources: allowedSources ?? this.allowedSources,
      deepSearchAllowed: deepSearchAllowed ?? this.deepSearchAllowed,
      noWebsiteFilterAllowed:
          noWebsiteFilterAllowed ?? this.noWebsiteFilterAllowed,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      exportFormats: exportFormats ?? this.exportFormats,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Entitlements &&
            other.isPro == isPro &&
            other.maxResultsPerSearch == maxResultsPerSearch &&
            other.maxSavedLeads == maxSavedLeads &&
            other.freeSearchesPerDay == freeSearchesPerDay &&
            setsEqual<LeadSource>(other.allowedSources, allowedSources) &&
            other.deepSearchAllowed == deepSearchAllowed &&
            other.noWebsiteFilterAllowed == noWebsiteFilterAllowed &&
            other.adsEnabled == adsEnabled &&
            setsEqual<ExportFormat>(other.exportFormats, exportFormats);
  }

  @override
  int get hashCode => Object.hash(
    isPro,
    maxResultsPerSearch,
    maxSavedLeads,
    freeSearchesPerDay,
    setsHash<LeadSource>(allowedSources),
    deepSearchAllowed,
    noWebsiteFilterAllowed,
    adsEnabled,
    setsHash<ExportFormat>(exportFormats),
  );

  @override
  String toString() =>
      'Entitlements(${isPro ? 'Pro' : 'Free'}, '
      '$maxResultsPerSearch results, saved: ${maxSavedLeads ?? 'unlimited'})';
}

/// Everything a user gets without paying.
///
/// 50 results per search, 50 saved leads, 5 searches a day, Maps only, no deep
/// search, no "no website" filter, ads on, all four export formats.
const Entitlements freeEntitlements = Entitlements(
  isPro: false,
  maxResultsPerSearch: 50,
  maxSavedLeads: 50,
  freeSearchesPerDay: 5,
  allowedSources: <LeadSource>{LeadSource.maps},
  deepSearchAllowed: false,
  noWebsiteFilterAllowed: false,
  adsEnabled: true,
  exportFormats: <ExportFormat>{
    ExportFormat.csv,
    ExportFormat.xlsx,
    ExportFormat.pdf,
    ExportFormat.vcf,
  },
);

/// Everything a Pro subscriber gets.
///
/// 200 results per search, unlimited saved leads, no daily search limit, all five
/// sources, deep search, the "no website" filter, no ads, all four formats.
const Entitlements proEntitlements = Entitlements(
  isPro: true,
  maxResultsPerSearch: 200,
  maxSavedLeads: null,
  freeSearchesPerDay: null,
  allowedSources: <LeadSource>{
    LeadSource.maps,
    LeadSource.instagram,
    LeadSource.linkedin,
    LeadSource.facebook,
    LeadSource.x,
  },
  deepSearchAllowed: true,
  noWebsiteFilterAllowed: true,
  adsEnabled: false,
  exportFormats: <ExportFormat>{
    ExportFormat.csv,
    ExportFormat.xlsx,
    ExportFormat.pdf,
    ExportFormat.vcf,
  },
);
