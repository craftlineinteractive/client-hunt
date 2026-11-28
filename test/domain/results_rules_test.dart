import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/lead_search_engine.dart';
import 'package:clienthunt/domain/results/contact_rules.dart';
import 'package:clienthunt/domain/results/results_filter.dart';
import 'package:clienthunt/features/results/lead_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure rules behind the Results screen: chips, text search, sorting, contact
/// availability, the export hand-off and lead lookup by id.
void main() {
  final DateTime now = DateTime(2026, 11, 26, 9);
  final DummyDataSet data = DummyData.build(now: now);
  const SearchRequest sessionRequest = SearchRequest(
    id: 'search-session',
    query: SearchQuery(
      niches: <String>['Dentists'],
      locations: <String>['Ahmedabad'],
    ),
  );

  Lead lead({
    String id = 'lead-1',
    String name = 'Northline Dental Studio',
    String category = 'Dental clinic',
    String area = 'Satellite',
    List<PhoneContact> phones = const <PhoneContact>[],
    List<EmailContact> emails = const <EmailContact>[],
    String? website,
    double? rating,
    int? reviewCount,
    bool isSaved = false,
    DateTime? discoveredAt,
  }) {
    return Lead(
      id: id,
      name: name,
      category: category,
      area: area,
      city: 'Ahmedabad',
      phones: phones,
      emails: emails,
      website: website,
      rating: rating,
      reviewCount: reviewCount,
      isSaved: isSaved,
      discoveredAt: discoveredAt ?? now,
    );
  }

  const PhoneContact mobile = PhoneContact(
    value: '+91 90000 11001',
    kind: PhoneKind.mobile,
    isPrimary: true,
  );
  const PhoneContact landline = PhoneContact(
    value: '+91 79 4000 1100',
    kind: PhoneKind.landline,
  );
  const EmailContact email = EmailContact(value: 'hello@northline.in');

  group('ResultsFilter chips', () {
    final List<Lead> leads = <Lead>[
      lead(
        id: 'a',
        phones: <PhoneContact>[mobile],
        emails: <EmailContact>[email],
        website: 'https://northline.in',
        rating: 4.6,
      ),
      lead(id: 'b', phones: <PhoneContact>[landline]),
      lead(id: 'c', website: 'northland.dental', rating: 3.9),
      lead(id: 'd', isSaved: true),
    ];

    List<String> idsFor(
      ResultsChip chip, {
      Set<String> saved = const <String>{},
    }) {
      return ResultsFilter(
        chip: chip,
      ).apply(leads, savedIds: saved).map((Lead lead) => lead.id).toList();
    }

    test('all keeps every lead', () {
      expect(idsFor(ResultsChip.all), <String>['a', 'b', 'c', 'd']);
    });

    test('email, phone and website need the field itself', () {
      expect(idsFor(ResultsChip.email), <String>['a']);
      expect(idsFor(ResultsChip.phone), <String>['a', 'b']);
      expect(idsFor(ResultsChip.website), <String>['a', 'c']);
    });

    test('whatsApp needs a mobile number, not just a phone', () {
      // b has only a landline: it can be called but not messaged.
      expect(idsFor(ResultsChip.whatsApp), <String>['a']);
    });

    test('rating 4+ excludes unrated leads rather than treating them as 0', () {
      expect(idsFor(ResultsChip.rating4Plus), <String>['a']);
    });

    test('saved reads the live saved ids, not only the lead snapshot', () {
      expect(idsFor(ResultsChip.saved), <String>['d']);
      expect(idsFor(ResultsChip.saved, saved: <String>{'b'}), <String>[
        'b',
        'd',
      ]);
    });
  });

  group('ResultsFilter text', () {
    final Lead subject = lead(
      phones: <PhoneContact>[mobile],
      emails: <EmailContact>[email],
      website: 'https://northline.in/contact',
    );

    bool matches(String query) =>
        ResultsFilter(text: query).matches(subject, savedIds: <String>{});

    test('matches name, category and area, case-insensitively', () {
      expect(matches('northline'), isTrue);
      expect(matches('NORTHLINE'), isTrue);
      expect(matches('dental'), isTrue);
      expect(matches('satellite'), isTrue);
      expect(matches('baker'), isFalse);
    });

    test('matches the email and the website domain, not the URL path', () {
      expect(matches('hello@northline'), isTrue);
      expect(matches('northline.in'), isTrue);
      expect(matches('https://'), isFalse);
      expect(matches('contact'), isFalse);
    });

    test('matches phone digits without punctuation', () {
      expect(matches('11001'), isTrue);
      expect(matches('+91 90000 11001'), isTrue);
      // Digits of a number this lead does not have.
      expect(matches('40001100'), isFalse);
    });

    test('a chip and a query combine with AND', () {
      const ResultsFilter filter = ResultsFilter(
        chip: ResultsChip.website,
        text: 'northline',
      );
      expect(filter.matches(subject, savedIds: <String>{}), isTrue);
      expect(
        const ResultsFilter(
          chip: ResultsChip.saved,
          text: 'northline',
        ).matches(subject, savedIds: <String>{}),
        isFalse,
      );
    });

    test('whitespace alone is not a filter', () {
      expect(const ResultsFilter(text: '   ').isActive, isFalse);
      expect(const ResultsFilter(text: '   ').hasText, isFalse);
      expect(const ResultsFilter(text: 'x').isActive, isTrue);
      expect(const ResultsFilter(text: 'x').hasText, isTrue);
      expect(
        const ResultsFilter(chip: ResultsChip.email, text: 'x').isActive,
        isTrue,
      );
    });
  });

  group('ResultsSort', () {
    final List<Lead> leads = <Lead>[
      lead(id: 'a', name: 'Beta Dental', rating: 4.1, reviewCount: 90),
      lead(id: 'b', name: 'alpha Smiles'),
      lead(id: 'c', name: 'Cedar Dental', rating: 4.9, reviewCount: 12),
      lead(id: 'd', name: 'Delta Dental', rating: 4.1, reviewCount: 140),
    ];

    List<String> ids(List<Lead> sorted) =>
        sorted.map((Lead lead) => lead.id).toList();

    test('relevance is the engine order, untouched', () {
      expect(ids(ResultsSort.apply(leads, SortOption.relevance)), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test('rating is descending and puts missing ratings last', () {
      expect(ids(ResultsSort.apply(leads, SortOption.rating)), <String>[
        'c',
        'a',
        'd',
        'b',
      ]);
    });

    test('reviews is descending and puts missing counts last', () {
      expect(ids(ResultsSort.apply(leads, SortOption.reviews)), <String>[
        'd',
        'a',
        'c',
        'b',
      ]);
    });

    test('name is A to Z, case-insensitively', () {
      expect(ids(ResultsSort.apply(leads, SortOption.name)), <String>[
        'b',
        'a',
        'c',
        'd',
      ]);
    });

    test('equal values keep their arrival order', () {
      final List<Lead> tied = <Lead>[
        lead(id: 'first', name: 'Same', rating: 4.2, reviewCount: 3),
        lead(id: 'second', name: 'Same', rating: 4.2, reviewCount: 3),
      ];
      expect(ids(ResultsSort.apply(tied, SortOption.rating)), <String>[
        'first',
        'second',
      ]);
    });

    test('the input list is not mutated', () {
      final List<Lead> original = <Lead>[...leads];
      ResultsSort.apply(leads, SortOption.name);
      expect(leads, original);
    });

    test('the menu offers the four sortable options', () {
      expect(ResultsSort.menuOptions, <SortOption>[
        SortOption.relevance,
        SortOption.rating,
        SortOption.reviews,
        SortOption.name,
      ]);
    });
  });

  group('ContactRules', () {
    final Lead both = lead(
      phones: <PhoneContact>[landline, mobile],
      emails: <EmailContact>[email],
    );

    test('a landline can be called but not messaged', () {
      final Lead onlyLandline = lead(phones: <PhoneContact>[landline]);
      expect(ContactRules.canCall(onlyLandline), isTrue);
      expect(ContactRules.canWhatsApp(onlyLandline), isFalse);
      expect(ContactRules.whatsAppPhone(onlyLandline), isNull);
    });

    test('a mobile enables WhatsApp', () {
      expect(ContactRules.canWhatsApp(both), isTrue);
      expect(ContactRules.whatsAppPhone(both)?.value, mobile.value);
    });

    test('the primary contact wins, otherwise the first', () {
      final Lead noPrimary = lead(
        phones: <PhoneContact>[
          const PhoneContact(value: '+91 1', kind: PhoneKind.mobile),
          const PhoneContact(value: '+91 2', kind: PhoneKind.mobile),
        ],
        emails: <EmailContact>[
          const EmailContact(value: 'first@x.in'),
          const EmailContact(value: 'second@x.in'),
        ],
      );
      expect(ContactRules.primaryPhone(noPrimary)?.value, '+91 1');
      expect(ContactRules.primaryEmail(noPrimary)?.value, 'first@x.in');
      // `mobile` carries isPrimary in this fixture, so it wins over the first.
      expect(ContactRules.primaryPhone(both)?.value, mobile.value);
    });

    test('an empty lead can do nothing, and copying needs phone or email', () {
      final Lead bare = lead();
      expect(ContactRules.canCall(bare), isFalse);
      expect(ContactRules.canWhatsApp(bare), isFalse);
      expect(ContactRules.canEmail(bare), isFalse);
      expect(ContactRules.canCopy(bare), isFalse);
      expect(ContactRules.canCopy(lead(emails: <EmailContact>[email])), isTrue);
    });
  });

  group('ExportArgs', () {
    const ExportArgs args = ExportArgs(
      title: 'Dentists in Ahmedabad',
      leadIds: <String>['a', 'b'],
      scope: ExportScope.selectedOnly,
      resultCount: 42,
      withEmail: 31,
      withPhone: 40,
    );

    test('describes the hand-off', () {
      expect(args.leadCount, 2);
      expect(args.isSelection, isTrue);
      expect(args.toString(), contains('selectedOnly'));
    });

    test('has value equality, including the id list', () {
      expect(
        args,
        const ExportArgs(
          title: 'Dentists in Ahmedabad',
          leadIds: <String>['a', 'b'],
          scope: ExportScope.selectedOnly,
          resultCount: 42,
          withEmail: 31,
          withPhone: 40,
        ),
      );
      expect(args, isNot(args.copyWith(leadIds: <String>['a'])));
      expect(args.copyWith(leadIds: <String>['a']).leadCount, 1);
    });

    test('defaults to exporting every visible lead', () {
      const ExportArgs all = ExportArgs(
        title: 'Dentists',
        leadIds: <String>['a'],
      );
      expect(all.scope, ExportScope.allLeads);
      expect(all.isSelection, isFalse);
    });
  });

  group('leadByIdProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          leadRepositoryProvider.overrideWithValue(
            FakeLeadRepository(data: data, latency: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('resolves from the session before the saved store', () async {
      final Lead sessionLead = data.dentistResults.first;
      container
          .read(leadSessionProvider.notifier)
          .set(
            LeadSession(
              request: sessionRequest,
              leads: <Lead>[sessionLead],
              status: LeadSessionStatus.completed,
            ),
          );

      final Lead? resolved = await container.read(
        leadByIdProvider(sessionLead.id).future,
      );
      expect(resolved?.id, sessionLead.id);
      expect(resolved?.name, sessionLead.name);
    });

    test('falls back to the repository for a saved lead', () async {
      final Lead saved = data.savedLeads.first;
      final Lead? resolved = await container.read(
        leadByIdProvider(saved.id).future,
      );
      expect(resolved?.id, saved.id);
    });

    test('returns null for an unknown id', () async {
      expect(await container.read(leadByIdProvider('missing').future), isNull);
    });

    test('the session wins when it holds the same id as the store', () async {
      final Lead saved = data.savedLeads.first;
      final Lead renamed = saved.copyWith(name: 'Renamed in session');
      container
          .read(leadSessionProvider.notifier)
          .set(LeadSession(request: sessionRequest, leads: <Lead>[renamed]));

      final Lead? resolved = await container.read(
        leadByIdProvider(saved.id).future,
      );
      expect(resolved?.name, 'Renamed in session');
    });
  });
}
