import 'package:flutter/foundation.dart';

/// One Indian city the search form knows about.
///
/// [state] is used by the Filters screen and by grouping; [aliases] carry the
/// names people actually type (\"Bombay\", \"Bangalore\", \"Baroda\").
@immutable
class City {
  const City({
    required this.name,
    required this.state,
    this.aliases = const <String>[],
  }) : assert(name.length > 0, 'A city needs a name');

  /// Canonical display name (\"Bengaluru\").
  final String name;

  /// State or union territory (\"Karnataka\").
  final String state;

  /// Alternative names, lower case (\"bangalore\").
  final List<String> aliases;

  @override
  String toString() => 'City($name, $state)';
}

/// The ~44 Indian cities ClientHunt ships with.
///
/// Ranking is identical to [NicheCatalog.suggest]: exact name, name prefix, exact
/// alias, alias prefix, word prefix — no popularity tier because a city list has
/// no \"popular\" concept. Aliases let \"Bombay\" and \"Bangalore\" resolve to the
/// official names, which is what ends up stored in a search.
abstract final class CityCatalog {
  /// Every city, alphabetically by canonical name.
  static const List<City> all = <City>[
    City(name: 'Agra', state: 'Uttar Pradesh'),
    City(name: 'Ahmedabad', state: 'Gujarat', aliases: <String>['amdavad']),
    City(name: 'Amritsar', state: 'Punjab'),
    City(name: 'Aurangabad', state: 'Maharashtra'),
    City(
      name: 'Bengaluru',
      state: 'Karnataka',
      aliases: <String>['bangalore', 'bengalooru'],
    ),
    City(name: 'Bhopal', state: 'Madhya Pradesh'),
    City(
      name: 'Bhubaneswar',
      state: 'Odisha',
      aliases: <String>['bhubaneshwar'],
    ),
    City(name: 'Chandigarh', state: 'Chandigarh'),
    City(name: 'Chennai', state: 'Tamil Nadu', aliases: <String>['madras']),
    City(name: 'Coimbatore', state: 'Tamil Nadu', aliases: <String>['kovai']),
    City(name: 'Dehradun', state: 'Uttarakhand'),
    City(name: 'Delhi', state: 'Delhi', aliases: <String>['new delhi', 'ncr']),
    City(name: 'Faridabad', state: 'Haryana'),
    City(name: 'Gandhinagar', state: 'Gujarat'),
    City(name: 'Ghaziabad', state: 'Uttar Pradesh'),
    City(name: 'Guwahati', state: 'Assam'),
    City(name: 'Gurugram', state: 'Haryana', aliases: <String>['gurgaon']),
    City(name: 'Hyderabad', state: 'Telangana'),
    City(name: 'Indore', state: 'Madhya Pradesh'),
    City(name: 'Jaipur', state: 'Rajasthan'),
    City(name: 'Jodhpur', state: 'Rajasthan'),
    City(name: 'Kanpur', state: 'Uttar Pradesh'),
    City(
      name: 'Kochi',
      state: 'Kerala',
      aliases: <String>['cochin', 'ernakulam'],
    ),
    City(name: 'Kolkata', state: 'West Bengal', aliases: <String>['calcutta']),
    City(name: 'Lucknow', state: 'Uttar Pradesh'),
    City(name: 'Ludhiana', state: 'Punjab'),
    City(name: 'Madurai', state: 'Tamil Nadu'),
    City(name: 'Mumbai', state: 'Maharashtra', aliases: <String>['bombay']),
    City(name: 'Mysuru', state: 'Karnataka', aliases: <String>['mysore']),
    City(name: 'Nagpur', state: 'Maharashtra'),
    City(name: 'Nashik', state: 'Maharashtra', aliases: <String>['nasik']),
    City(
      name: 'Noida',
      state: 'Uttar Pradesh',
      aliases: <String>['greater noida'],
    ),
    City(name: 'Panaji', state: 'Goa', aliases: <String>['goa', 'panjim']),
    City(name: 'Patna', state: 'Bihar'),
    City(name: 'Pune', state: 'Maharashtra', aliases: <String>['poona']),
    City(name: 'Raipur', state: 'Chhattisgarh'),
    City(name: 'Rajkot', state: 'Gujarat'),
    City(name: 'Ranchi', state: 'Jharkhand'),
    City(name: 'Surat', state: 'Gujarat'),
    City(name: 'Thane', state: 'Maharashtra'),
    City(
      name: 'Thiruvananthapuram',
      state: 'Kerala',
      aliases: <String>['trivandrum'],
    ),
    City(name: 'Udaipur', state: 'Rajasthan'),
    City(name: 'Vadodara', state: 'Gujarat', aliases: <String>['baroda']),
    City(
      name: 'Varanasi',
      state: 'Uttar Pradesh',
      aliases: <String>['banaras', 'kashi'],
    ),
    City(name: 'Vijayawada', state: 'Andhra Pradesh'),
    City(
      name: 'Visakhapatnam',
      state: 'Andhra Pradesh',
      aliases: <String>['vizag'],
    ),
  ];

  /// Up to [limit] cities matching [input], best first.
  static List<City> suggest(String input, {int limit = 4}) {
    final String query = input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (query.isEmpty || limit <= 0) {
      return const <City>[];
    }

    final List<City> matches = <City>[
      for (final City city in all)
        if (_score(city, query) != null) city,
    ];
    matches.sort((City a, City b) => _compare(a, b, query));
    return List<City>.unmodifiable(matches.take(limit));
  }

  /// The canonical city name for a city or alias; otherwise [input] trimmed with
  /// whitespace collapsed.
  static String normalize(String input) {
    final String trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    return canonicalOrNull(trimmed) ?? trimmed;
  }

  /// The canonical name for [input], or `null` when it is not a known city.
  static String? canonicalOrNull(String input) {
    final String query = input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    for (final City city in all) {
      if (city.name.toLowerCase() == query) {
        return city.name;
      }
      for (final String alias in city.aliases) {
        if (alias.toLowerCase() == query) {
          return city.name;
        }
      }
    }
    return null;
  }

  static int _compare(City a, City b, String query) {
    final int aScore = _score(a, query) ?? 99;
    final int bScore = _score(b, query) ?? 99;
    if (aScore != bScore) {
      return aScore.compareTo(bScore);
    }
    return a.name.compareTo(b.name);
  }

  static int? _score(City city, String query) {
    final String lowerName = city.name.toLowerCase();
    if (lowerName == query) {
      return 0;
    }
    if (lowerName.startsWith(query)) {
      return 1;
    }
    for (final String alias in city.aliases) {
      final String lowerAlias = alias.toLowerCase();
      if (lowerAlias == query) {
        return 2;
      }
      if (lowerAlias.startsWith(query)) {
        return 3;
      }
    }
    for (final String word in lowerName.split(' ')) {
      if (word.startsWith(query)) {
        return 4;
      }
    }
    return null;
  }
}
