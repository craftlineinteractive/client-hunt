import '../entitlements/feature_gate.dart';
import '../models/models.dart';
import '../repositories/lead_repository.dart';

/// What a save or unsave did.
///
/// [limitReached] means the Free saved-lead cap refused the write and **nothing
/// changed**; every caller answers that with the paywall, never with a partial
/// save.
enum LeadSaveOutcome {
  /// The lead is now saved.
  saved,

  /// The lead was removed from the saved store.
  unsaved,

  /// The Free saved-lead cap is full; nothing was written.
  limitReached,
}

/// The one place a lead is saved, unsaved or auto-saved before a CRM edit.
///
/// Results (bookmark), Lead Detail (bookmark plus auto-save on the first CRM
/// edit) and, later, Saved all go through this, so the cap rule and the paywall
/// reason exist once. It is deliberately not a Riverpod notifier: it is a small
/// value built from the repository and the gate, which keeps it unit-testable
/// without a container.
class LeadSaveController {
  const LeadSaveController({required this.repository, required this.gate});

  /// The only writer.
  final LeadRepository repository;

  /// Supplies the saved-lead cap.
  final FeatureGate gate;

  /// Saves [lead] when there is room, or reports [LeadSaveOutcome.limitReached].
  ///
  /// Re-saving an already saved lead is a plain write (the CRM data is kept by
  /// the caller's copy), so it never consumes another slot.
  Future<LeadSaveOutcome> save(Lead lead) async {
    if (!lead.isSaved) {
      final int savedCount = await repository.savedCount();
      if (!gate.canSaveMore(savedCount)) {
        return LeadSaveOutcome.limitReached;
      }
    }
    await repository.saveLead(lead);
    return LeadSaveOutcome.saved;
  }

  /// Saves an unsaved lead before a CRM edit; a no-op when it is already saved.
  ///
  /// This is the auto-save rule: an edit on a lead opened from Results must not
  /// be lost, so the lead is stored first — subject to the same cap. A refused
  /// save leaves both the lead and the edit untouched.
  Future<LeadSaveOutcome> ensureSaved(Lead lead) {
    if (lead.isSaved) {
      return Future<LeadSaveOutcome>.value(LeadSaveOutcome.saved);
    }
    return save(lead);
  }

  /// Removes [leadId] from the saved store.
  Future<LeadSaveOutcome> unsave(String leadId) async {
    await repository.deleteLeads(<String>[leadId]);
    return LeadSaveOutcome.unsaved;
  }

  /// Flips the bookmark for [lead].
  Future<LeadSaveOutcome> toggle(Lead lead) {
    if (lead.isSaved) {
      return unsave(lead.id);
    }
    return save(lead);
  }

  /// True when [lead] may be saved right now (used to pre-disable a control).
  Future<bool> canSave(Lead lead) async {
    if (lead.isSaved) {
      return true;
    }
    return gate.canSaveMore(await repository.savedCount());
  }
}
