import 'package:flutter/material.dart';

import 'lead_source.dart';
import 'model_equality.dart';

/// The user's persisted preferences, shown on the Settings screen.
///
/// One immutable value covers every default the search form picks up, so changing
/// "Max results" in Settings changes the next search without any other coupling.
/// The *limits* are not here — those come from `Entitlements`; [maxResults] is
/// only the preferred value, clamped against the gate by the caller.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultCountry = 'India',
    this.defaultSources = const <LeadSource>{LeadSource.maps},
    this.maxResults = 50,
    this.dedupe = true,
    this.skipSaved = true,
    this.adPersonalization = true,
  }) : assert(maxResults > 0, 'Max results must be positive');

  /// Light, dark or follow the device.
  final ThemeMode themeMode;

  /// Country used when the user does not name one ("India").
  final String defaultCountry;

  /// Sources pre-selected on the Search form.
  final Set<LeadSource> defaultSources;

  /// Preferred result cap (25, 50, 100 or 200).
  final int maxResults;

  /// Remove duplicate businesses by default.
  final bool dedupe;

  /// Skip leads the user already saved, by default.
  final bool skipSaved;

  /// Whether ads may be personalized. Only meaningful on Free.
  final bool adPersonalization;

  /// Copy with selected fields replaced.
  AppSettings copyWith({
    ThemeMode? themeMode,
    String? defaultCountry,
    Set<LeadSource>? defaultSources,
    int? maxResults,
    bool? dedupe,
    bool? skipSaved,
    bool? adPersonalization,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultCountry: defaultCountry ?? this.defaultCountry,
      defaultSources: defaultSources ?? this.defaultSources,
      maxResults: maxResults ?? this.maxResults,
      dedupe: dedupe ?? this.dedupe,
      skipSaved: skipSaved ?? this.skipSaved,
      adPersonalization: adPersonalization ?? this.adPersonalization,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSettings &&
            other.themeMode == themeMode &&
            other.defaultCountry == defaultCountry &&
            setsEqual<LeadSource>(other.defaultSources, defaultSources) &&
            other.maxResults == maxResults &&
            other.dedupe == dedupe &&
            other.skipSaved == skipSaved &&
            other.adPersonalization == adPersonalization;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    defaultCountry,
    setsHash<LeadSource>(defaultSources),
    maxResults,
    dedupe,
    skipSaved,
    adPersonalization,
  );

  @override
  String toString() =>
      'AppSettings(${themeMode.name}, $maxResults results, '
      '${defaultSources.length} sources)';
}
