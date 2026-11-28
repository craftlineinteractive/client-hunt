import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/models/models.dart';

/// The demo data every fake repository and engine reads from.
///
/// Two hard rules:
///
/// 1. **Fictional.** Business names are assembled from invented word lists, every
///    email and website uses the reserved `.example` TLD, and every phone number
///    uses the `+91 00000 xxxxx` pattern. `00000` is not an assigned Indian
///    prefix, so no real business can own one of these numbers. No real brand
///    name (including the mockups' "Shalby") may appear here.
/// 2. **Deterministic.** Everything is generated from a fixed seed, so counts,
///    names and states are identical on every launch and in every test.
///
/// The numbers are not arbitrary: the Results mockup shows 42 leads / 31 emails /
/// 40 phones and the Saved mockup shows 128 leads split 42/38/19/29 across four
/// statuses and four lists of 14/9/36/22. Those are asserted in the tests.
abstract final class DummyData {
  /// The one lead every screen can open (lead detail hero).
  static const String heroLeadId = 'lead-hero-0001';

  /// Total leads in the "Dentists in Ahmedabad" scenario.
  static const int dentistResultTotal = 42;

  /// Leads in that scenario with at least one email.
  static const int dentistWithEmail = 31;

  /// Leads in that scenario with at least one phone.
  static const int dentistWithPhone = 40;

  /// Leads in the debug-only "large" scenario, for long-list checks.
  static const int largeResultTotal = 200;

  /// Total saved leads.
  static const int savedLeadTotal = 128;

  /// Free searches already used today, so 3 of 5 remain.
  static const int searchesUsedToday = 2;

  /// Daily free allowance, mirroring `freeEntitlements.freeSearchesPerDay`.
  static const int dailySearchLimit = 5;

  /// Builds a complete, independent data set.
  ///
  /// [now] fixes the timestamps so tests can assert on relative dates. The seed
  /// only feeds incidental variation (ratings, review counts, open state); every
  /// asserted count is assigned explicitly below.
  static DummyDataSet build({DateTime? now, int seed = 20261126}) {
    final DateTime reference = now ?? DateTime.now();
    final Random random = Random(seed);

    final List<Lead> dentistResults = _dentistResults(reference, random);
    final _SavedBuild saved = _savedLeads(reference, dentistResults);

    return DummyDataSet(
      dentistResults: dentistResults,
      largeResults: _largeResults(reference, random),
      savedLeads: saved.leads,
      lists: saved.lists,
      recentSearches: _recentSearches(reference),
      searchesRemainingToday: dailySearchLimit - searchesUsedToday,
    );
  }

  // ---------------------------------------------------------------------------
  // Word lists. Invented combinations only: no real business names.
  // ---------------------------------------------------------------------------

  static const List<String> _prefixes = <String>[
    'Northline',
    'Cedar',
    'Bright',
    'Copper',
    'Anchor',
    'Quiet Street',
    'Maple',
    'Lantern',
    'Harbor',
    'Sunrise',
    'Willow',
    'Granite',
    'Meadow',
    'Ironwood',
    'Marigold',
    'Pepper',
    'Silverleaf',
    'Stonebridge',
    'Westfield',
    'Alder',
  ];

  static const List<String> _dentalTypes = <String>[
    'Dental Studio',
    'Family Dental',
    'Dental Clinic',
    'Orthodontics',
    'Smile Care',
    'Dental Practice',
  ];

  static const List<String> _cafeTypes = <String>[
    'Coffee House',
    'Roastery',
    'Cafe',
    'Bakehouse',
    'Espresso Bar',
  ];

  static const List<String> _otherTypes = <String>[
    'Salon',
    'Barber Studio',
    'Fitness Club',
    'Legal Associates',
  ];

  static const List<String> _ahmedabadAreas = <String>[
    'Navrangpura',
    'Satellite',
    'Vastrapur',
    'Bodakdev',
    'Gurukul',
    'Maninagar',
    'Bopal',
    'Prahlad Nagar',
    'Thaltej',
    'Chandkheda',
  ];

  static const List<String> _mumbaiAreas = <String>[
    'Bandra West',
    'Andheri East',
    'Powai',
    'Lower Parel',
    'Colaba',
    'Juhu',
    'Dadar',
    'Borivali',
    'Malad West',
    'Worli',
  ];

  /// `+91 00000 00001` — not a routable Indian number.
  static String fakePhone(int index) =>
      '+91 00000 ${index.toString().padLeft(5, '0')}';

  /// `contact@northline-dental-studio.example` — reserved TLD.
  static String fakeEmail(String slug, {String mailbox = 'contact'}) =>
      '$mailbox@$slug.example';

  /// `northline-dental-studio.example`.
  static String fakeWebsite(String slug) => '$slug.example';

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static String _businessName(int index) {
    final String prefix = _prefixes[index % _prefixes.length];
    final int round = index ~/ _prefixes.length;
    final List<String> types = index < dentistResultTotal
        ? _dentalTypes
        : _cafeTypes;
    final String type = types[round % types.length];
    return '$prefix $type';
  }

  // ---------------------------------------------------------------------------
  // Search results: Dentists in Ahmedabad.
  // ---------------------------------------------------------------------------

  static List<Lead> _dentistResults(DateTime now, Random random) {
    final List<Lead> leads = <Lead>[];

    for (int index = 0; index < dentistResultTotal; index++) {
      final String name = _businessName(index);
      final String slug = _slug(name);
      final String area = _ahmedabadAreas[index % _ahmedabadAreas.length];

      // Exactly 31 with email, exactly 40 with phone, hero first.
      final bool hasEmail = index < dentistWithEmail;
      final bool hasPhone = index < dentistWithPhone;
      // Every third lead has no website.
      final bool hasWebsite = index % 3 != 0;
      // Six leads carry a second number.
      final bool hasSecondPhone = index % 7 == 0 && hasPhone;
      // A few carry a second, non-primary address.
      final bool hasSecondEmail = index % 9 == 3 && hasEmail;

      final List<PhoneContact> phones = <PhoneContact>[
        if (hasPhone)
          PhoneContact(
            value: fakePhone(1001 + index),
            kind: PhoneKind.mobile,
            status: ValidationStatus.likelyValid,
            confidence: 0.82,
            isPrimary: !hasSecondPhone,
          ),
        if (hasSecondPhone)
          PhoneContact(
            value: fakePhone(2001 + index),
            kind: PhoneKind.landline,
            status: ValidationStatus.valid,
            confidence: 0.9,
            isPrimary: true,
          ),
      ];

      final List<EmailContact> emails = <EmailContact>[
        if (hasEmail)
          EmailContact(
            value: fakeEmail(slug),
            isRoleBased: true,
            domainHasMx: true,
            matchesWebsiteDomain: hasWebsite,
            status: ValidationStatus.likelyValid,
            confidence: 0.78,
            foundOnUrl: hasWebsite ? fakeWebsite(slug) : null,
            isPrimary: true,
          ),
        if (hasSecondEmail)
          EmailContact(
            value: fakeEmail(slug, mailbox: 'hello'),
            domainHasMx: true,
            status: ValidationStatus.risky,
            confidence: 0.55,
          ),
      ];

      final int ratingStep = (index * 7) % 18;
      final bool isOpen = index.isEven;

      leads.add(
        Lead(
          id: index == 0
              ? heroLeadId
              : 'result-${index.toString().padLeft(4, '0')}',
          name: name,
          category: 'Dental clinic',
          address:
              '${12 + index} $area Road, Ahmedabad, Gujarat 3800${15 + index % 5}',
          area: area,
          city: 'Ahmedabad',
          state: 'Gujarat',
          latitude: 23.0225 + index * 0.004,
          longitude: 72.5714 + random.nextDouble() * 0.05,
          phones: phones,
          emails: emails,
          website: hasWebsite ? fakeWebsite(slug) : null,
          // The hero carries the mockup's 4.8 (184); the rest spread 3.2-4.9.
          rating: index == 0
              ? 4.8
              : double.parse((3.2 + ratingStep / 10).toStringAsFixed(1)),
          reviewCount: index == 0 ? 184 : 5 + (index * 97) % 396,
          isOpenNow: isOpen,
          openingHours: isOpen ? 'Mon-Sat, 9AM-8PM' : 'Mon-Sat, 10AM-7PM',
          sources: const <LeadSource>{LeadSource.maps},
          confidenceScore: hasPhone && hasEmail ? 88 : (hasPhone ? 71 : 54),
          discoveredAt: now.subtract(Duration(minutes: 4 + index)),
          isSaved: index == 0,
          savedAt: index == 0 ? now.subtract(const Duration(days: 2)) : null,
          tags: index == 0 ? const <String>['Hot lead'] : const <String>[],
          note: index == 0
              ? 'Spoke to clinic manager, requested PDF proposal'
              : '',
        ),
      );
    }

    return leads;
  }

  // ---------------------------------------------------------------------------
  // Large result set (debug scenario).
  // ---------------------------------------------------------------------------

  /// 200 deterministic leads that exercise a long list: some without email,
  /// phone, website or rating, so the missing-value paths are covered too.
  static List<Lead> _largeResults(DateTime now, Random random) {
    final List<Lead> leads = <Lead>[];

    for (int index = 0; index < largeResultTotal; index++) {
      final String prefix = _prefixes[index % _prefixes.length];
      final int kind = index % 3;
      final String type = switch (kind) {
        0 => _dentalTypes[index % _dentalTypes.length],
        1 => _cafeTypes[index % _cafeTypes.length],
        _ => _otherTypes[index % _otherTypes.length],
      };
      final String name = '$prefix $type';
      final String slug = _slug(name);
      final bool hasPhone = index % 5 != 0;
      final bool hasEmail = index % 3 != 0;
      final bool hasWebsite = index % 4 != 0;
      final bool hasRating = index % 9 != 4;
      final String area = _ahmedabadAreas[index % _ahmedabadAreas.length];

      leads.add(
        Lead(
          id: 'large-${index.toString().padLeft(4, '0')}',
          name: name,
          category: switch (kind) {
            0 => 'Dental clinic',
            1 => 'Cafe',
            _ => 'Salon',
          },
          address: '${4 + index} $area Road, Ahmedabad',
          area: area,
          city: 'Ahmedabad',
          state: 'Gujarat',
          latitude: 23.0225 + index * 0.001,
          longitude: 72.5714 + random.nextDouble() * 0.05,
          phones: <PhoneContact>[
            if (hasPhone)
              PhoneContact(
                value: fakePhone(5001 + index),
                kind: index % 4 == 0 ? PhoneKind.landline : PhoneKind.mobile,
                status: ValidationStatus.likelyValid,
                confidence: 0.8,
                isPrimary: true,
              ),
          ],
          emails: <EmailContact>[
            if (hasEmail)
              EmailContact(
                value: fakeEmail(slug),
                status: ValidationStatus.likelyValid,
                confidence: 0.76,
                isPrimary: true,
              ),
          ],
          website: hasWebsite ? fakeWebsite(slug) : null,
          rating: hasRating
              ? double.parse((3.0 + (index % 21) / 10).toStringAsFixed(1))
              : null,
          reviewCount: hasRating ? 4 + (index * 37) % 500 : null,
          isOpenNow: hasRating ? index.isEven : null,
          openingHours: 'Mon-Sat, 9AM-8PM',
          sources: const <LeadSource>{LeadSource.maps},
          confidenceScore: 50 + index % 45,
          discoveredAt: now.subtract(Duration(minutes: index)),
        ),
      );
    }

    return leads;
  }

  // ---------------------------------------------------------------------------
  // Saved leads and lists.
  // ---------------------------------------------------------------------------

  static _SavedBuild _savedLeads(DateTime now, List<Lead> results) {
    final List<Lead> leads = <Lead>[];

    for (int index = 0; index < savedLeadTotal; index++) {
      // The hero is the same business as the first search result, so opening it
      // from Saved or from Results shows identical contact details.
      if (index == 0) {
        leads.add(
          results.first.copyWith(
            isSaved: true,
            savedAt: now.subtract(const Duration(days: 2)),
            status: LeadStatus.newLead,
            tags: const <String>['Hot lead'],
            note: 'Spoke to clinic manager, requested PDF proposal',
            reminderAt: DateTime(now.year, now.month, now.day + 1, 10),
          ),
        );
        continue;
      }

      // 42 new, 38 contacted, 19 replied, 29 closed.
      final LeadStatus status = index < 42
          ? LeadStatus.newLead
          : index < 80
          ? LeadStatus.contacted
          : index < 99
          ? LeadStatus.replied
          : LeadStatus.closed;

      // The first 64 are dentists, the next 32 cafes (22 of them are on the
      // Cafes list), the rest salons, gyms and law firms.
      final String category;
      final String type;
      if (index < 64) {
        category = 'Dental clinic';
        type = _dentalTypes[index % _dentalTypes.length];
      } else if (index < 96) {
        category = 'Cafe';
        type = _cafeTypes[index % _cafeTypes.length];
      } else {
        type = _otherTypes[index % _otherTypes.length];
        category = switch (type) {
          'Salon' || 'Barber Studio' => 'Salon',
          'Fitness Club' => 'Gym',
          _ => 'Law firm',
        };
      }

      final String prefix = _prefixes[(index * 3) % _prefixes.length];
      // The hero keeps the exact name it has in the search results.
      final String name = index == 0
          ? '${_prefixes[0]} ${_dentalTypes[0]}'
          : '$prefix $type';
      final String slug = _slug(name);
      final bool inMumbai = index >= 48;
      final String city = inMumbai ? 'Mumbai' : 'Ahmedabad';
      final String area = inMumbai
          ? _mumbaiAreas[index % _mumbaiAreas.length]
          : _ahmedabadAreas[index % _ahmedabadAreas.length];

      final bool hasEmail = index % 3 != 0;
      final bool hasPhone = index % 5 != 0;
      final bool hasWebsite = index % 4 != 0;

      leads.add(
        Lead(
          id: index == 0
              ? heroLeadId
              : 'saved-${index.toString().padLeft(4, '0')}',
          name: name,
          category: category,
          address: '${8 + index} $area Road, $city',
          area: area,
          city: city,
          state: inMumbai ? 'Maharashtra' : 'Gujarat',
          phones: <PhoneContact>[
            if (hasPhone)
              PhoneContact(
                value: fakePhone(3001 + index),
                kind: PhoneKind.mobile,
                status: ValidationStatus.likelyValid,
                confidence: 0.8,
                isPrimary: true,
              ),
          ],
          emails: <EmailContact>[
            if (hasEmail)
              EmailContact(
                value: fakeEmail(slug),
                isRoleBased: true,
                domainHasMx: true,
                status: ValidationStatus.likelyValid,
                confidence: 0.74,
                isPrimary: true,
              ),
          ],
          website: hasWebsite ? fakeWebsite(slug) : null,
          rating: index == 0
              ? 4.8
              : double.parse(
                  (3.2 + ((index * 5) % 18) / 10).toStringAsFixed(1),
                ),
          reviewCount: index == 0 ? 184 : 5 + (index * 53) % 396,
          isOpenNow: index % 3 != 0,
          openingHours: 'Mon-Sat, 9AM-8PM',
          sources: const <LeadSource>{LeadSource.maps},
          confidenceScore: 60 + index % 35,
          discoveredAt: now.subtract(Duration(days: 2 + index % 30)),
          isSaved: true,
          savedAt: now.subtract(Duration(days: index % 21, hours: index % 24)),
          status: status,
          tags: switch (index) {
            0 => const <String>['Hot lead'],
            1 => const <String>['Follow up'],
            64 => const <String>['Hot lead', 'Cafes'],
            3 => const <String>['Follow up', 'Dentists'],
            _ => const <String>[],
          },
          note: switch (index) {
            0 => 'Spoke to clinic manager, requested PDF proposal',
            1 => 'Sent outreach email, waiting for response',
            6 => 'Owner interested in wholesale supply',
            40 => 'Needs a tasting appointment',
            77 => 'Asked for a call back next month',
            _ => '',
          },
          reminderAt: switch (index) {
            1 || 8 || 22 => DateTime(now.year, now.month, now.day + 1, 10),
            5 || 31 => now.subtract(const Duration(days: 2)),
            _ => null,
          },
        ),
      );
    }

    // List membership. Sizes are fixed by the Saved mockup: 14 / 9 / 36 / 22.
    final List<String> hot = <String>[
      for (int index = 0; index < 126; index += 9) leads[index].id,
    ];
    final List<String> followUp = <String>[
      for (final int index in <int>[3, 17, 31, 45, 59, 73, 87, 101, 115])
        leads[index].id,
    ];
    final List<String> dentists = <String>[
      for (int index = 0; index < 36; index++) leads[index].id,
    ];
    final List<String> cafes = <String>[
      for (int index = 64; index < 86; index++) leads[index].id,
    ];

    final Map<String, List<String>> membership = <String, List<String>>{};
    void assign(String listId, List<String> ids) {
      for (final String id in ids) {
        (membership[id] ??= <String>[]).add(listId);
      }
    }

    assign('list-hot', hot);
    assign('list-follow-up', followUp);
    assign('list-dentists', dentists);
    assign('list-cafes', cafes);

    final List<Lead> withLists = <Lead>[
      for (final Lead lead in leads)
        if (membership[lead.id] == null)
          lead
        else
          lead.copyWith(listIds: membership[lead.id]!),
    ];

    return _SavedBuild(
      leads: withLists,
      lists: <LeadList>[
        LeadList(id: 'list-hot', name: 'Hot leads', count: hot.length),
        LeadList(
          id: 'list-follow-up',
          name: 'Follow up',
          count: followUp.length,
        ),
        LeadList(id: 'list-dentists', name: 'Dentists', count: dentists.length),
        LeadList(id: 'list-cafes', name: 'Cafes', count: cafes.length),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recent searches.
  // ---------------------------------------------------------------------------

  static List<SearchHistoryEntry> _recentSearches(DateTime now) {
    return <SearchHistoryEntry>[
      SearchHistoryEntry(
        id: 'history-dentists-ahmedabad',
        query: const SearchQuery(
          niches: <String>['Dentists'],
          locations: <String>['Ahmedabad'],
        ),
        resultCount: dentistResultTotal,
        searchedAt: now.subtract(const Duration(days: 2)),
      ),
      SearchHistoryEntry(
        id: 'history-cafes-mumbai',
        query: const SearchQuery(
          niches: <String>['Cafes'],
          locations: <String>['Mumbai'],
        ),
        resultCount: 88,
        searchedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}

/// The generated saved-lead store plus its lists.
@immutable
class _SavedBuild {
  const _SavedBuild({required this.leads, required this.lists});

  final List<Lead> leads;
  final List<LeadList> lists;
}

/// One immutable snapshot of the demo data.
@immutable
class DummyDataSet {
  const DummyDataSet({
    required this.dentistResults,
    this.largeResults = const <Lead>[],
    required this.savedLeads,
    required this.lists,
    required this.recentSearches,
    required this.searchesRemainingToday,
  });

  /// The 42 "Dentists in Ahmedabad" leads, hero first.
  final List<Lead> dentistResults;

  /// The 200-lead debug scenario, for long lists.
  final List<Lead> largeResults;

  /// The 128 saved leads, hero first.
  final List<Lead> savedLeads;

  /// Hot leads 14, Follow up 9, Dentists 36, Cafes 22.
  final List<LeadList> lists;

  /// Two recent searches, newest first.
  final List<SearchHistoryEntry> recentSearches;

  /// 3 of 5 free searches left.
  final int searchesRemainingToday;

  /// The fixed lead every screen can open.
  Lead get heroLead => dentistResults.first;

  /// Look a lead up across both stores.
  Lead? leadById(String id) {
    for (final Lead lead in <Lead>[
      ...savedLeads,
      ...dentistResults,
      ...largeResults,
    ]) {
      if (lead.id == id) {
        return lead;
      }
    }
    return null;
  }
}
