import 'dart:async';

import '../../domain/models/models.dart';
import '../../domain/repositories/lead_repository.dart';
import 'dummy_data.dart';

/// In-memory [LeadRepository] seeded with the 128 saved demo leads.
///
/// Everything works: saving, bulk save, partial CRM updates, deletion, lists and
/// their live counts, text/status/list filtering and sorting. Screens therefore
/// behave like they will on SQLite in prompt C — the only difference is that this
/// store forgets everything on restart.
///
/// Mutations take [latency] (150 ms by default) so optimistic UI is exercised;
/// watches emit immediately and again after every write.
class FakeLeadRepository implements LeadRepository {
  FakeLeadRepository({
    DummyDataSet? data,
    this.latency = const Duration(milliseconds: 150),
    DateTime Function()? clock,
  }) : _data = data ?? DummyData.build(),
       _clock = clock ?? DateTime.now {
    for (final Lead lead in _data.savedLeads) {
      _saved[lead.id] = lead;
      _known[lead.id] = lead;
    }
    for (final Lead lead in _data.dentistResults) {
      _known.putIfAbsent(lead.id, () => lead);
    }
    for (final LeadList list in _data.lists) {
      _lists[list.id] = list;
    }
  }

  final DummyDataSet _data;

  /// Simulated write latency.
  final Duration latency;

  final DateTime Function() _clock;

  /// Saved leads, in insertion order.
  final Map<String, Lead> _saved = <String, Lead>{};

  /// Every lead the fake can resolve by id: saved first, then search results.
  final Map<String, Lead> _known = <String, Lead>{};

  final Map<String, LeadList> _lists = <String, LeadList>{};

  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Lead>> watchSavedLeads({
    String? listId,
    LeadStatus? status,
    String? text,
    SavedLeadSort sort = SavedLeadSort.recent,
  }) async* {
    yield _query(listId: listId, status: status, text: text, sort: sort);
    await for (final Object? _ in _changes.stream) {
      yield _query(listId: listId, status: status, text: text, sort: sort);
    }
  }

  @override
  Future<Lead?> getLead(String id) async {
    await _pause();
    return _saved[id] ?? _known[id];
  }

  @override
  Future<Lead> saveLead(Lead lead) async {
    await _pause();
    final Lead stored = _store(lead);
    return stored;
  }

  @override
  Future<List<Lead>> saveMany(Iterable<Lead> leads) async {
    await _pause();
    return <Lead>[for (final Lead lead in leads) _store(lead)];
  }

  @override
  Future<Lead?> updateLead(String id, LeadUpdate update) async {
    await _pause();
    final Lead? current = _saved[id];
    if (current == null) {
      return null;
    }
    Lead next = current.copyWith(
      status: update.status,
      tags: update.tags,
      note: update.note,
      reminderAt: update.reminderAt,
    );
    if (update.clearReminder) {
      next = next.withoutReminder();
    }
    _saved[id] = next;
    _known[id] = next;
    _notify();
    return next;
  }

  @override
  Future<void> deleteLeads(Iterable<String> ids) async {
    await _pause();
    for (final String id in ids.toSet()) {
      _saved.remove(id);
      _known.remove(id);
    }
    _recountLists();
    _notify();
  }

  @override
  Stream<List<LeadList>> watchLists() async* {
    yield _listSnapshot();
    await for (final Object? _ in _changes.stream) {
      yield _listSnapshot();
    }
  }

  @override
  Future<LeadList> createList(String name) async {
    await _pause();
    final String trimmed = name.trim();
    for (final LeadList existing in _lists.values) {
      if (existing.name.toLowerCase() == trimmed.toLowerCase()) {
        return existing;
      }
    }
    final String id =
        'list-${trimmed.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-')}';
    final LeadList list = LeadList(id: id, name: trimmed);
    _lists[id] = list;
    _notify();
    return list;
  }

  @override
  Future<void> addToList(Iterable<String> leadIds, String listId) async {
    await _pause();
    if (!_lists.containsKey(listId)) {
      return;
    }
    for (final String id in leadIds.toSet()) {
      final Lead? lead = _saved[id];
      if (lead == null || lead.listIds.contains(listId)) {
        continue;
      }
      final Lead updated = lead.copyWith(
        listIds: <String>[...lead.listIds, listId],
      );
      _saved[id] = updated;
      _known[id] = updated;
    }
    _recountLists();
    _notify();
  }

  @override
  Future<int> savedCount() async => _saved.length;

  @override
  Future<bool> existsBySignature(Lead lead) async {
    final String signature = _signature(lead);
    return _saved.values.any((Lead saved) => _signature(saved) == signature);
  }

  /// Releases the change stream. The app never needs this; tests do.
  Future<void> dispose() => _changes.close();

  // ---------------------------------------------------------------------------

  Lead _store(Lead lead) {
    final Lead stored = lead.copyWith(
      isSaved: true,
      savedAt: lead.savedAt ?? _clock(),
    );
    _saved[stored.id] = stored;
    _known[stored.id] = stored;
    _recountLists();
    _notify();
    return stored;
  }

  List<Lead> _query({
    String? listId,
    LeadStatus? status,
    String? text,
    SavedLeadSort sort = SavedLeadSort.recent,
  }) {
    Iterable<Lead> leads = _saved.values;

    if (listId != null) {
      leads = leads.where((Lead lead) => lead.listIds.contains(listId));
    }
    if (status != null) {
      leads = leads.where((Lead lead) => lead.status == status);
    }
    final String query = (text ?? '').trim().toLowerCase();
    if (query.isNotEmpty) {
      leads = leads.where((Lead lead) => _matches(lead, query));
    }

    final List<Lead> result = leads.toList();
    switch (sort) {
      case SavedLeadSort.recent:
        result.sort((Lead a, Lead b) => _compareSavedAtDesc(a, b));
      case SavedLeadSort.name:
        result.sort(
          (Lead a, Lead b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case SavedLeadSort.status:
        result.sort((Lead a, Lead b) {
          final int byStatus = a.status.index.compareTo(b.status.index);
          return byStatus != 0 ? byStatus : _compareSavedAtDesc(a, b);
        });
    }
    return List<Lead>.unmodifiable(result);
  }

  int _compareSavedAtDesc(Lead a, Lead b) {
    final DateTime? left = a.savedAt;
    final DateTime? right = b.savedAt;
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return right.compareTo(left);
  }

  bool _matches(Lead lead, String query) {
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(query);

    return contains(lead.name) ||
        contains(lead.category) ||
        contains(lead.area) ||
        contains(lead.city) ||
        lead.emails.any((EmailContact email) => contains(email.value)) ||
        lead.phones.any((PhoneContact phone) => contains(phone.value));
  }

  List<LeadList> _listSnapshot() {
    return List<LeadList>.unmodifiable(<LeadList>[
      for (final LeadList list in _lists.values) list,
    ]);
  }

  void _recountLists() {
    for (final String id in _lists.keys.toList()) {
      final LeadList list = _lists[id]!;
      final int count = _saved.values
          .where((Lead lead) => lead.listIds.contains(id))
          .length;
      if (count != list.count) {
        _lists[id] = list.copyWith(count: count);
      }
    }
  }

  String _signature(Lead lead) {
    final String phone =
        lead.primaryPhone?.value.replaceAll(RegExp(r'\D'), '') ?? '';
    final String domain = (lead.website ?? '').toLowerCase().trim();
    return '${lead.name.toLowerCase().trim()}|$phone|$domain';
  }

  Future<void> _pause() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
