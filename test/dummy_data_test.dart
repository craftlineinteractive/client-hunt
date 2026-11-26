import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The demo data is the contract the B screens are built against, so its counts
/// and its fiction rules are asserted rather than eyeballed.
void main() {
  final DateTime now = DateTime(2026, 11, 26, 9);
  final DummyDataSet data = DummyData.build(now: now);

  group('Dentists in Ahmedabad scenario', () {
    test('has exactly 42 leads', () {
      expect(DummyData.dentistResultTotal, 42);
      expect(data.dentistResults, hasLength(42));
    });

    test('has exactly 31 leads with an email and 40 with a phone', () {
      expect(DummyData.dentistWithEmail, 31);
      expect(DummyData.dentistWithPhone, 40);
      expect(
        data.dentistResults.where((Lead lead) => lead.hasEmail).length,
        31,
      );
      expect(
        data.dentistResults.where((Lead lead) => lead.hasPhone).length,
        40,
      );
    });

    test('varies the fields the results screen renders', () {
      final List<Lead> leads = data.dentistResults;

      expect(leads.where((Lead lead) => !lead.hasWebsite), isNotEmpty);
      expect(leads.where((Lead lead) => lead.hasWebsite), isNotEmpty);
      expect(leads.where((Lead lead) => lead.isOpenNow == true), isNotEmpty);
      expect(leads.where((Lead lead) => lead.isOpenNow == false), isNotEmpty);
      expect(leads.where((Lead lead) => lead.phones.length > 1), isNotEmpty);
      expect(
        leads.where(
          (Lead lead) =>
              lead.emails.length > 1 &&
              lead.emails.any((EmailContact email) => !email.isPrimary),
        ),
        isNotEmpty,
      );

      for (final Lead lead in leads) {
        expect(lead.rating, inInclusiveRange(3.2, 4.9));
        expect(lead.reviewCount, inInclusiveRange(5, 400));
        expect(lead.sources, contains(LeadSource.maps));
        expect(lead.category, 'Dental clinic');
        expect(lead.city, 'Ahmedabad');
      }
    });

    test('uses the approved neighbourhood names', () {
      expect(
        data.dentistResults.map((Lead lead) => lead.area),
        contains('Navrangpura'),
      );
    });
  });

  group('Saved scenario', () {
    test('has exactly 128 saved leads', () {
      expect(DummyData.savedLeadTotal, 128);
      expect(data.savedLeads, hasLength(128));
      expect(data.savedLeads.every((Lead lead) => lead.isSaved), isTrue);
      expect(
        data.savedLeads.every((Lead lead) => lead.savedAt != null),
        isTrue,
      );
    });

    test('splits statuses 42 new / 38 contacted / 19 replied / 29 closed', () {
      int count(LeadStatus status) =>
          data.savedLeads.where((Lead lead) => lead.status == status).length;

      expect(count(LeadStatus.newLead), 42);
      expect(count(LeadStatus.contacted), 38);
      expect(count(LeadStatus.replied), 19);
      expect(count(LeadStatus.closed), 29);
      expect(LeadStatus.values.map(count).reduce((int a, int b) => a + b), 128);
    });

    test('has lists of 14, 9, 36 and 22', () {
      expect(data.lists, hasLength(4));
      final Map<String, int> counts = <String, int>{
        for (final LeadList list in data.lists) list.name: list.count,
      };
      expect(counts, <String, int>{
        'Hot leads': 14,
        'Follow up': 9,
        'Dentists': 36,
        'Cafes': 22,
      });
    });

    test('list counts match actual membership and leads can be in several', () {
      for (final LeadList list in data.lists) {
        final int actual = data.savedLeads
            .where((Lead lead) => lead.listIds.contains(list.id))
            .length;
        expect(actual, list.count, reason: list.name);
      }

      expect(
        data.savedLeads.where((Lead lead) => lead.listIds.length > 1),
        isNotEmpty,
      );
    });

    test('has notes, tags, reminders and a couple of overdue reminders', () {
      expect(
        data.savedLeads.where((Lead lead) => lead.note.isNotEmpty),
        isNotEmpty,
      );
      expect(
        data.savedLeads.where((Lead lead) => lead.tags.isNotEmpty),
        isNotEmpty,
      );

      final List<Lead> reminded = data.savedLeads
          .where((Lead lead) => lead.reminderAt != null)
          .toList();
      expect(reminded.length, greaterThanOrEqualTo(3));
      expect(
        reminded.where((Lead lead) => lead.reminderAt!.isAfter(now)),
        isNotEmpty,
        reason: 'some reminders are due tomorrow',
      );
      expect(
        reminded.where((Lead lead) => lead.reminderAt!.isBefore(now)),
        isNotEmpty,
        reason: 'some reminders are overdue',
      );
    });
  });

  group('Recent searches and quota', () {
    test('has the two mockup searches, newest first', () {
      expect(data.recentSearches, hasLength(2));
      expect(
        data.recentSearches.first.query.displayTitle,
        'Dentists in Ahmedabad',
      );
      expect(data.recentSearches.first.resultCount, 42);
      expect(data.recentSearches.last.query.displayTitle, 'Cafes in Mumbai');
      expect(data.recentSearches.last.resultCount, 88);
      expect(
        data.recentSearches.first.searchedAt.isAfter(
          data.recentSearches.last.searchedAt,
        ),
        isTrue,
      );
    });

    test('starts with 3 of 5 free searches left', () {
      expect(data.searchesRemainingToday, 3);
      expect(DummyData.dailySearchLimit, 5);
    });
  });

  group('fictional data', () {
    final List<Lead> all = <Lead>[...data.dentistResults, ...data.savedLeads];

    test('no real brand name from the mockups leaks in', () {
      for (final Lead lead in all) {
        expect(lead.name.toLowerCase(), isNot(contains('shalby')));
        expect(lead.name.toLowerCase(), isNot(contains('perfect smile')));
      }
    });

    test('every email and website uses the reserved .example TLD', () {
      for (final Lead lead in all) {
        for (final EmailContact email in lead.emails) {
          expect(email.value, endsWith('.example'), reason: email.value);
        }
        if (lead.hasWebsite) {
          expect(lead.website, endsWith('.example'), reason: lead.website);
        }
      }
    });

    test('every phone uses the unassigned 000 prefix', () {
      final RegExp fakeNumber = RegExp(r'^\+91 00000 \d{5}$');
      for (final Lead lead in all) {
        for (final PhoneContact phone in lead.phones) {
          expect(phone.value, matches(fakeNumber), reason: phone.value);
        }
      }
    });

    test('business names are unique', () {
      final List<String> names = data.dentistResults
          .map((Lead lead) => lead.name)
          .toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });

  test('generation is deterministic', () {
    final DummyDataSet again = DummyData.build(now: now);
    expect(again.dentistResults, data.dentistResults);
    expect(again.savedLeads, data.savedLeads);
    expect(again.lists, data.lists);
  });

  test('the hero lead is shared by the results and saved stores', () {
    expect(DummyData.heroLeadId, 'lead-hero-0001');
    expect(data.heroLead.id, DummyData.heroLeadId);
    expect(data.savedLeads.first.id, DummyData.heroLeadId);
    expect(data.leadById(DummyData.heroLeadId)?.name, data.heroLead.name);
    // The hero is the one the saved mockup details: Hot lead, dentists list,
    // tomorrow's reminder, a note and a second phone.
    final Lead hero = data.leadById(DummyData.heroLeadId)!;
    expect(hero.rating, 4.8);
    expect(hero.reviewCount, 184);
    expect(hero.phones.length, 2);
    expect(hero.note, isNotEmpty);
    expect(hero.tags, contains('Hot lead'));
    expect(hero.listIds, contains('list-dentists'));
  });
}
