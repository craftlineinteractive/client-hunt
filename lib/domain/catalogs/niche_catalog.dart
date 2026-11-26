import 'package:flutter/foundation.dart';

/// One common B2B niche the search form knows about.
///
/// The catalog exists so typing \"dent\" can suggest \"Dentists\" and so a search
/// stores a canonical niche (\"Dentists\") instead of whatever the user typed
/// (\"dental clinic\"). It is static, offline data — no network, no package.
@immutable
class Niche {
  const Niche({
    required this.name,
    this.aliases = const <String>[],
    this.isPopular = false,
  }) : assert(name.length > 0, 'A niche needs a name');

  /// Canonical display name, plural and title case (\"Dentists\").
  final String name;

  /// Lower-case alternatives that map to [name] (\"dentist\", \"dental clinic\").
  final List<String> aliases;

  /// Whether this niche appears in Home's popular chips and ranks first in
  /// suggestions.
  final bool isPopular;

  @override
  String toString() => 'Niche($name${isPopular ? ', popular' : ''})';
}

/// The ~60 niches ClientHunt ships with.
///
/// Matching rules (shared with [CityCatalog]):
///
/// 1. Exact name (case-insensitive) — `dentists`
/// 2. Name prefix — `dent` → `Dentists`
/// 3. Exact alias — `dental clinic` → `Dentists`
/// 4. Alias prefix — `dental c` → `Dentists`
/// 5. Word prefix inside the name — `estate` → `Real Estate Agents`
///
/// Ties are broken by popularity (popular first), then alphabetically, so the
/// same query always produces the same list. [normalize] maps an alias to its
/// canonical name; any other input comes back trimmed with runs of spaces
/// collapsed, never empty.
abstract final class NicheCatalog {
  /// Every niche, in display order for the full list. Popular ones are marked.
  static const List<Niche> all = <Niche>[
    Niche(
      name: 'Dentists',
      aliases: <String>['dentist', 'dental clinic', 'dental clinics'],
      isPopular: true,
    ),
    Niche(
      name: 'Cafes',
      aliases: <String>['cafe', 'coffee shop', 'coffee shops', 'cafe shop'],
      isPopular: true,
    ),
    Niche(
      name: 'Salons',
      aliases: <String>[
        'salon',
        'hair salon',
        'beauty parlour',
        'beauty parlor',
      ],
      isPopular: true,
    ),
    Niche(
      name: 'Gyms',
      aliases: <String>[
        'gym',
        'fitness centre',
        'fitness center',
        'health club',
      ],
      isPopular: true,
    ),
    Niche(
      name: 'Real Estate Agents',
      aliases: <String>['real estate', 'realtors', 'property agents'],
      isPopular: true,
    ),
    Niche(
      name: 'Lawyers',
      aliases: <String>['lawyer', 'advocates', 'attorneys', 'law firm'],
      isPopular: true,
    ),
    Niche(
      name: 'Restaurants',
      aliases: <String>['restaurant', 'diners', 'eateries'],
      isPopular: true,
    ),
    Niche(
      name: 'Clinics',
      aliases: <String>['clinic', 'medical clinic', 'health clinic'],
      isPopular: true,
    ),
    Niche(name: 'Schools', aliases: <String>['school', 'cbse schools']),
    Niche(name: 'Hotels', aliases: <String>['hotel', 'lodging']),
    Niche(
      name: 'Interior Designers',
      aliases: <String>['interior designer', 'interior design'],
    ),
    Niche(
      name: 'Photographers',
      aliases: <String>['photographer', 'photography studio'],
    ),
    Niche(
      name: 'CA and Accountants',
      aliases: <String>[
        'chartered accountant',
        'chartered accountants',
        'accountant',
        'accountants',
        'ca',
        'ca firm',
        'cas',
      ],
    ),
    Niche(
      name: 'Coaching Centers',
      aliases: <String>['coaching center', 'coaching centre', 'coaching'],
    ),
    Niche(name: 'Bakeries', aliases: <String>['bakery', 'cake shop']),
    Niche(name: 'Spas', aliases: <String>['spa', 'day spa', 'massage spa']),
    Niche(
      name: 'Yoga Studios',
      aliases: <String>['yoga studio', 'yoga classes', 'yoga'],
    ),
    Niche(
      name: 'Physiotherapists',
      aliases: <String>['physiotherapist', 'physiotherapy clinic'],
    ),
    Niche(
      name: 'Dermatologists',
      aliases: <String>['dermatologist', 'skin clinic'],
    ),
    Niche(
      name: 'Pediatricians',
      aliases: <String>['pediatrician', 'child specialist'],
    ),
    Niche(name: 'Veterinarians', aliases: <String>['vet', 'veterinary clinic']),
    Niche(
      name: 'Pharmacies',
      aliases: <String>['pharmacy', 'chemist', 'medical store'],
    ),
    Niche(name: 'Opticians', aliases: <String>['optician', 'eyewear store']),
    Niche(
      name: 'Guest Houses',
      aliases: <String>['guest house', 'guesthouse', 'homestay'],
    ),
    Niche(
      name: 'Travel Agencies',
      aliases: <String>['travel agency', 'tour operator'],
    ),
    Niche(
      name: 'Property Developers',
      aliases: <String>['builder', 'builders', 'real estate developer'],
    ),
    Niche(
      name: 'Architects',
      aliases: <String>['architect', 'architecture firm'],
    ),
    Niche(
      name: 'Videographers',
      aliases: <String>['videographer', 'video production'],
    ),
    Niche(
      name: 'Event Planners',
      aliases: <String>['event planner', 'event management'],
    ),
    Niche(name: 'Caterers', aliases: <String>['caterer', 'catering service']),
    Niche(
      name: 'Wedding Planners',
      aliases: <String>['wedding planner', 'wedding planning'],
    ),
    Niche(
      name: 'Preschools',
      aliases: <String>['preschool', 'playschool', 'kindergarten'],
    ),
    Niche(
      name: 'Tuition Classes',
      aliases: <String>['tuition', 'tuition centre', 'tutor'],
    ),
    Niche(
      name: 'Driving Schools',
      aliases: <String>['driving school', 'driving instructor'],
    ),
    Niche(
      name: 'Financial Advisors',
      aliases: <String>['financial advisor', 'wealth manager'],
    ),
    Niche(
      name: 'Insurance Agents',
      aliases: <String>['insurance agent', 'insurance broker'],
    ),
    Niche(
      name: 'Business Consultants',
      aliases: <String>['consultant', 'consultants', 'business consulting'],
    ),
    Niche(
      name: 'Marketing Agencies',
      aliases: <String>['marketing agency', 'digital marketing'],
    ),
    Niche(
      name: 'Web Designers',
      aliases: <String>['web designer', 'website design'],
    ),
    Niche(
      name: 'Software Companies',
      aliases: <String>['software company', 'software development'],
    ),
    Niche(
      name: 'IT Services',
      aliases: <String>['it service', 'managed it', 'it support'],
    ),
    Niche(
      name: 'Printing Services',
      aliases: <String>['printing press', 'printers'],
    ),
    Niche(
      name: 'Courier Services',
      aliases: <String>['courier', 'courier service'],
    ),
    Niche(
      name: 'Logistics Companies',
      aliases: <String>['logistics', 'transport company'],
    ),
    Niche(
      name: 'Car Dealers',
      aliases: <String>['car dealer', 'automobile showroom'],
    ),
    Niche(
      name: 'Auto Repair Shops',
      aliases: <String>['car repair', 'garage', 'mechanic'],
    ),
    Niche(name: 'Car Wash', aliases: <String>['car washing', 'car detailing']),
    Niche(
      name: 'Laundry Services',
      aliases: <String>['laundry', 'dry cleaner', 'dry cleaning'],
    ),
    Niche(name: 'Tailors', aliases: <String>['tailor', 'stitching shop']),
    Niche(name: 'Boutiques', aliases: <String>['boutique', 'clothing store']),
    Niche(
      name: 'Jewellers',
      aliases: <String>['jeweller', 'jewellery store', 'jewelry store'],
    ),
    Niche(
      name: 'Furniture Stores',
      aliases: <String>['furniture shop', 'furniture'],
    ),
    Niche(
      name: 'Hardware Stores',
      aliases: <String>['hardware shop', 'hardware'],
    ),
    Niche(
      name: 'Electronics Stores',
      aliases: <String>['electronics shop', 'electronic store'],
    ),
    Niche(name: 'Pet Shops', aliases: <String>['pet shop', 'pet store']),
    Niche(
      name: 'Pet Groomers',
      aliases: <String>['pet grooming', 'dog grooming'],
    ),
    Niche(
      name: 'Fitness Trainers',
      aliases: <String>['personal trainer', 'fitness coach'],
    ),
    Niche(
      name: 'Dance Studios',
      aliases: <String>['dance studio', 'dance classes'],
    ),
    Niche(
      name: 'Music Schools',
      aliases: <String>['music school', 'music classes'],
    ),
    Niche(name: 'Bookstores', aliases: <String>['bookstore', 'book shop']),
  ];

  /// The niches shown as chips on Home, in the mockup's order.
  static List<Niche> get popular => <Niche>[
    for (final Niche niche in all)
      if (niche.isPopular) niche,
  ];

  /// Up to [limit] niches matching [input], best first.
  ///
  /// Returns an empty list for blank input or a non-positive [limit]. Matching is
  /// case-insensitive and ignores extra spaces, so \"  dental   c \" finds
  /// \"Dentists\".
  static List<Niche> suggest(String input, {int limit = 4}) {
    final String query = _collapse(input).toLowerCase();
    if (query.isEmpty || limit <= 0) {
      return const <Niche>[];
    }

    final List<Niche> matches = <Niche>[
      for (final Niche niche in all)
        if (_score(niche.name, niche.aliases, query) != null) niche,
    ];
    matches.sort((Niche a, Niche b) => _compare(a, b, query));
    return List<Niche>.unmodifiable(matches.take(limit));
  }

  /// The canonical name for a niche or one of its aliases; otherwise [input]
  /// trimmed, with internal runs of spaces collapsed to one.
  static String normalize(String input) {
    final String trimmed = _collapse(input);
    final String? canonical = canonicalOrNull(trimmed);
    return canonical ?? trimmed;
  }

  /// The canonical name for [input], or `null` when it is not in the catalog.
  static String? canonicalOrNull(String input) {
    final String query = _collapse(input).toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    for (final Niche niche in all) {
      if (niche.name.toLowerCase() == query) {
        return niche.name;
      }
      for (final String alias in niche.aliases) {
        if (alias.toLowerCase() == query) {
          return niche.name;
        }
      }
    }
    return null;
  }

  static int _compare(Niche a, Niche b, String query) {
    final int aScore = _score(a.name, a.aliases, query) ?? 99;
    final int bScore = _score(b.name, b.aliases, query) ?? 99;
    if (aScore != bScore) {
      return aScore.compareTo(bScore);
    }
    if (a.isPopular != b.isPopular) {
      return a.isPopular ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  }

  /// Lower is better; `null` means no match.
  static int? _score(String name, List<String> aliases, String query) {
    final String lowerName = name.toLowerCase();
    if (lowerName == query) {
      return 0;
    }
    if (lowerName.startsWith(query)) {
      return 1;
    }
    for (final String alias in aliases) {
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

/// Trims and collapses internal whitespace.
String _collapse(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');
