import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// How the Saved list is ordered.
enum SavedLeadSort {
  /// Most recently saved first (default).
  recent(displayName: 'Recent'),

  /// Alphabetical by business name.
  name(displayName: 'Name'),

  /// Grouped by CRM status, newest first inside each group.
  status(displayName: 'Status');

  const SavedLeadSort({required this.displayName});

  /// Label for the sort menu.
  final String displayName;
}

/// A partial CRM update.
///
/// Sent to [LeadRepository.updateLead]; every field is optional so the UI can
/// change one thing at a time. [clearReminder] exists because `reminderAt: null`
/// cannot distinguish "leave it" from "remove it" — the same trap the `Lead`
/// model documents.
@immutable
class LeadUpdate {
  const LeadUpdate({
    this.status,
    this.tags,
    this.note,
    this.reminderAt,
    this.clearReminder = false,
  }) : assert(
         !(clearReminder && reminderAt != null),
         'Set a reminder or clear it, not both',
       );

  /// New CRM stage.
  final LeadStatus? status;

  /// Replacement tag list.
  final List<String>? tags;

  /// Replacement note.
  final String? note;

  /// New follow-up reminder.
  final DateTime? reminderAt;

  /// Remove the existing reminder.
  final bool clearReminder;

  /// True when the update changes nothing.
  bool get isEmpty =>
      status == null &&
      tags == null &&
      note == null &&
      reminderAt == null &&
      !clearReminder;
}

/// Saved leads and user lists — the on-device CRM.
///
/// Implemented by `FakeLeadRepository` in development and by the SQLite-backed
/// repository in prompt C. Reads are streams so the Saved screen, the Saved
/// count on Home and the quota checks all update from one write.
abstract interface class LeadRepository {
  /// Saved leads, filtered and sorted.
  ///
  /// [listId] restricts to one user list; [status] to one CRM stage; [text]
  /// matches name, category, area, city, email or phone (case-insensitive).
  Stream<List<Lead>> watchSavedLeads({
    String? listId,
    LeadStatus? status,
    String? text,
    SavedLeadSort sort = SavedLeadSort.recent,
  });

  /// One lead by id, saved or not (search results are not in this store). Null
  /// when the id is unknown.
  Future<Lead?> getLead(String id);

  /// Saves (or re-saves) a lead and returns the stored copy with `isSaved` and
  /// `savedAt` set.
  Future<Lead> saveLead(Lead lead);

  /// Saves several leads, preserving order.
  Future<List<Lead>> saveMany(Iterable<Lead> leads);

  /// Applies a partial CRM update. Returns the updated lead, or null when the id
  /// is not saved.
  Future<Lead?> updateLead(String id, LeadUpdate update);

  /// Removes leads by id; unknown ids are ignored.
  Future<void> deleteLeads(Iterable<String> ids);

  /// The user's lists with their live counts.
  Stream<List<LeadList>> watchLists();

  /// Creates a list; an existing name returns the existing list.
  Future<LeadList> createList(String name);

  /// Adds leads to a list, keeping the list's count in sync.
  Future<void> addToList(Iterable<String> leadIds, String listId);

  /// Number of saved leads.
  Future<int> savedCount();

  /// True when an equivalent lead is already saved (name + best phone/domain
  /// fingerprint). Used to implement `skipSaved`.
  Future<bool> existsBySignature(Lead lead);
}
