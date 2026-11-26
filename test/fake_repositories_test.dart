import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 26, 9);
  late DummyDataSet data;
  late FakeLeadRepository leads;

  setUp(() {
    data = DummyData.build(now: now);
    leads = FakeLeadRepository(
      data: data,
      latency: Duration.zero,
      clock: () => now,
    );
  });

  tearDown(() async {
    await leads.dispose();
  });

  group('LeadRepository reads', () {
    test('starts with the 128 saved leads', () async {
      expect(await leads.savedCount(), 128);
      expect(await leads.watchSavedLeads().first, hasLength(128));
    });

    test('filters by status with the mockup counts', () async {
      Future<int> count(LeadStatus status) async =>
          (await leads.watchSavedLeads(status: status).first).length;

      expect(await count(LeadStatus.newLead), 42);
      expect(await count(LeadStatus.contacted), 38);
      expect(await count(LeadStatus.replied), 19);
      expect(await count(LeadStatus.closed), 29);
    });

    test('filters by list', () async {
      expect(
        (await leads.watchSavedLeads(listId: 'list-hot').first),
        hasLength(14),
      );
      expect(
        (await leads.watchSavedLeads(listId: 'list-cafes').first),
        hasLength(22),
      );
    });

    test('searches text across name, category and contacts', () async {
      final List<Lead> result = await leads
          .watchSavedLeads(text: 'navrangpura')
          .first;
      expect(result, isNotEmpty);
      for (final Lead lead in result) {
        expect(
          <String>[
            lead.name,
            lead.category,
            lead.area,
            lead.city,
            ...lead.emails.map((EmailContact email) => email.value),
            ...lead.phones.map((PhoneContact phone) => phone.value),
          ].join(' ').toLowerCase(),
          contains('navrangpura'),
        );
      }
    });

    test('sorts by name and by recency', () async {
      final List<Lead> byName = await leads
          .watchSavedLeads(sort: SavedLeadSort.name)
          .first;
      final List<String> names = byName
          .map((Lead lead) => lead.name.toLowerCase())
          .toList();
      final List<String> sorted = <String>[...names]..sort();
      expect(names, sorted);

      final List<Lead> recent = await leads.watchSavedLeads().first;
      expect(recent.first.savedAt!.isAfter(recent.last.savedAt!), isTrue);
    });

    test('getLead resolves saved and unsaved leads', () async {
      expect((await leads.getLead(DummyData.heroLeadId))?.isSaved, isTrue);
      final Lead unsaved = data.dentistResults[5];
      expect((await leads.getLead(unsaved.id))?.name, unsaved.name);
      expect(await leads.getLead('missing'), isNull);
    });
  });

  group('LeadRepository writes', () {
    test('saveLead marks the lead saved', () async {
      final Lead unsaved = data.dentistResults[5];
      final Lead saved = await leads.saveLead(unsaved);

      expect(saved.isSaved, isTrue);
      expect(saved.savedAt, now);
      expect(await leads.savedCount(), 129);
    });

    test('saveMany stores every lead', () async {
      final List<Lead> stored = await leads.saveMany(
        data.dentistResults.skip(10).take(3),
      );
      expect(stored, hasLength(3));
      expect(await leads.savedCount(), 131);
      expect(
        (await leads.watchSavedLeads().first).where(
          (Lead lead) => lead.isSaved,
        ),
        hasLength(131),
      );
    });

    test('updateLead applies partial CRM fields', () async {
      final Lead? updated = await leads.updateLead(
        DummyData.heroLeadId,
        LeadUpdate(
          status: LeadStatus.contacted,
          note: 'Called on Monday',
          tags: const <String>['Hot lead', 'Called'],
          reminderAt: now.add(const Duration(days: 1)),
        ),
      );

      expect(updated, isNotNull);
      expect(updated!.status, LeadStatus.contacted);
      expect(updated.note, 'Called on Monday');
      expect(updated.tags, <String>['Hot lead', 'Called']);
      expect(updated.reminderAt, now.add(const Duration(days: 1)));

      // Unset fields keep their value.
      expect(updated.name, data.heroLead.name);
    });

    test('updateLead can clear a reminder', () async {
      expect(data.savedLeads.first.reminderAt, isNotNull);
      final Lead? updated = await leads.updateLead(
        DummyData.heroLeadId,
        const LeadUpdate(clearReminder: true),
      );
      expect(updated!.reminderAt, isNull);
    });

    test('updateLead returns null for an unsaved id', () async {
      expect(
        await leads.updateLead(
          'missing',
          const LeadUpdate(status: LeadStatus.replied),
        ),
        isNull,
      );
    });

    test('deleteLeads removes leads and recounts lists', () async {
      await leads.deleteLeads(<String>[DummyData.heroLeadId]);
      expect(await leads.savedCount(), 127);

      final Map<String, int> counts = <String, int>{
        for (final LeadList list in await leads.watchLists().first)
          list.id: list.count,
      };
      expect(counts['list-hot'], 13);
      expect(counts['list-dentists'], 35);
    });

    test('createList is idempotent by name', () async {
      final LeadList created = await leads.createList('Ahmedabad clinics');
      expect(created.count, 0);

      final LeadList again = await leads.createList('ahmedabad clinics');
      expect(again.id, created.id);
      expect(await leads.watchLists().first, hasLength(5));
    });

    test('addToList updates membership and the list count', () async {
      final LeadList list = await leads.createList('Callbacks');
      await leads.addToList(<String>[DummyData.heroLeadId], list.id);

      final List<LeadList> lists = await leads.watchLists().first;
      expect(
        lists.firstWhere((LeadList entry) => entry.id == list.id).count,
        1,
      );
      expect(
        (await leads.getLead(DummyData.heroLeadId))!.listIds,
        contains(list.id),
      );
    });

    test('existsBySignature finds the same business', () async {
      expect(await leads.existsBySignature(data.heroLead), isTrue);
      expect(await leads.existsBySignature(data.dentistResults[3]), isFalse);
    });
  });

  group('QuotaRepository', () {
    test('starts at 3 of 5 and stops at zero', () async {
      final FakeQuotaRepository quota = FakeQuotaRepository(
        latency: Duration.zero,
      );
      addTearDown(quota.dispose);

      expect(await quota.watchRemainingToday().first, 3);
      expect(await quota.consumeOne(), 2);
      expect(await quota.consumeOne(), 1);
      expect(await quota.consumeOne(), 0);
      expect(await quota.consumeOne(), 0);
      expect(quota.remainingToday, 0);
    });
  });

  group('SearchHistoryRepository', () {
    test('has two entries, adds newest first and dedupes by query', () async {
      final FakeSearchHistoryRepository history = FakeSearchHistoryRepository(
        data: data,
        latency: Duration.zero,
      );
      addTearDown(history.dispose);

      expect(await history.watchRecent().first, hasLength(2));

      await history.add(
        SearchHistoryEntry(
          id: 'history-gyms',
          query: const SearchQuery(
            niches: <String>['Gyms'],
            locations: <String>['Pune'],
          ),
          resultCount: 12,
          searchedAt: now,
        ),
      );
      final List<SearchHistoryEntry> recent = await history.watchRecent().first;
      expect(recent, hasLength(3));
      expect(recent.first.query.displayTitle, 'Gyms in Pune');

      await history.add(
        SearchHistoryEntry(
          id: 'history-gyms-2',
          query: const SearchQuery(
            niches: <String>['Gyms'],
            locations: <String>['Pune'],
          ),
          resultCount: 15,
          searchedAt: now,
        ),
      );
      final List<SearchHistoryEntry> deduped = await history
          .watchRecent()
          .first;
      expect(deduped, hasLength(3));
      expect(deduped.first.resultCount, 15);

      await history.clear();
      expect(await history.watchRecent().first, isEmpty);
    });

    test('honours the limit', () async {
      final FakeSearchHistoryRepository history = FakeSearchHistoryRepository(
        data: data,
        latency: Duration.zero,
      );
      addTearDown(history.dispose);
      expect(await history.watchRecent(limit: 1).first, hasLength(1));
    });
  });

  group('SettingsRepository', () {
    test('streams the default and every update', () async {
      final FakeSettingsRepository settings = FakeSettingsRepository(
        latency: Duration.zero,
      );
      addTearDown(settings.dispose);

      expect(await settings.watch().first, const AppSettings());
      await settings.update(
        settings.value.copyWith(
          maxResults: 200,
          themeMode: ThemeMode.dark,
          skipSaved: false,
        ),
      );
      final AppSettings updated = await settings.watch().first;
      expect(updated.maxResults, 200);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.skipSaved, isFalse);
    });
  });

  group('SubscriptionRepository', () {
    test('is Free by default and Pro when told so', () async {
      expect(
        await const FakeSubscriptionRepository().watchEntitlements().first,
        freeEntitlements,
      );
      expect(
        await const FakeSubscriptionRepository(
          isPro: true,
        ).watchEntitlements().first,
        proEntitlements,
      );
      expect(
        await const FakeSubscriptionRepository().availablePlans(),
        ProPlan.all,
      );
    });
  });

  group('ExportService', () {
    test('reports the file, size and counts', () async {
      const FakeExportService export = FakeExportService(
        latency: Duration.zero,
      );
      final ExportResult result = await export.export(
        data.dentistResults,
        const ExportOptions(),
      );

      expect(result.filePath, '/exports/leads.csv');
      expect(result.format, ExportFormat.csv);
      expect(result.leadCount, 42);
      expect(result.byteSize, greaterThan(0));
    });

    test('counts the contacts it would copy', () async {
      const FakeExportService export = FakeExportService(
        latency: Duration.zero,
      );
      final int emails = data.dentistResults.fold<int>(
        0,
        (int total, Lead lead) => total + lead.emails.length,
      );
      final int phones = data.dentistResults.fold<int>(
        0,
        (int total, Lead lead) => total + lead.phones.length,
      );

      expect(await export.copyEmails(data.dentistResults), emails);
      expect(await export.copyPhones(data.dentistResults), phones);
    });
  });
}
