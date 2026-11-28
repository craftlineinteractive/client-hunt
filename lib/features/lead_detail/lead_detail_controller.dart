import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/ads/ad_policy.dart';
import '../../domain/entitlements/feature_gate.dart';
import '../../domain/leads/crm_rules.dart';
import '../../domain/leads/lead_save_controller.dart';
import '../../domain/leads/lead_text_formatter.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/results/contact_rules.dart';
import '../results/lead_session.dart';
import 'lead_detail_state.dart';

/// One-shot things the Lead Detail screen must do but the controller must not.
///
/// Same contract as Results: no `BuildContext`, no navigator, no snackbar here —
/// the page subscribes and performs. Confirmations are events too, because only
/// the page can show a dialog.
sealed class LeadDetailUiEvent {
  const LeadDetailUiEvent();
}

/// Show a snackbar with [text].
final class LeadDetailMessage extends LeadDetailUiEvent {
  const LeadDetailMessage(this.text);

  final String text;
}

/// Open the paywall with [reason] (a `LockReason` name).
final class LeadDetailOpenPro extends LeadDetailUiEvent {
  const LeadDetailOpenPro(this.reason);

  final String reason;
}

/// Ask before unsaving, because the lead carries private CRM data.
final class LeadDetailConfirmUnsave extends LeadDetailUiEvent {
  const LeadDetailConfirmUnsave();
}

/// Ask before removing a saved lead from the device.
final class LeadDetailConfirmRemove extends LeadDetailUiEvent {
  const LeadDetailConfirmRemove();
}

/// The lead is gone: the page pops and shows [LeadDetailStrings.removedToast]
/// on the screen underneath through the root messenger.
final class LeadDetailRemoved extends LeadDetailUiEvent {
  const LeadDetailRemoved();
}

/// The user left; the page runs the interstitial when `true`.
final class LeadDetailAdBreak extends LeadDetailUiEvent {
  const LeadDetailAdBreak(this.trigger);

  final AdTrigger trigger;
}

/// Drives one Lead Detail screen.
///
/// **Auto-save.** Every CRM edit (status, tag, note, follow-up date) on a lead
/// that is not saved yet saves it first through [LeadSaveController], so a lead
/// opened from Results keeps what the user typed. When the Free saved-lead cap
/// refuses that save, the edit is rolled back and the paywall opens with
/// [LockReason.savedLeadLimitReached]; nothing is written.
///
/// **The note is debounced**, not written per keystroke: 600 ms after the last
/// change, and flushed immediately on back, on dispose and when the app goes to
/// the background.
class LeadDetailController extends Notifier<LeadDetailState> {
  LeadDetailController(this.leadId);

  /// The id from `/lead/:id`.
  final String leadId;

  /// Debounce for the note field.
  static const Duration noteDebounce = Duration(milliseconds: 600);

  final StreamController<LeadDetailUiEvent> _events =
      StreamController<LeadDetailUiEvent>.broadcast();

  StreamSubscription<List<Lead>>? _savedSubscription;
  Timer? _noteTimer;

  /// True while the note draft differs from the stored note.
  bool _noteDirty = false;

  /// True once anything worth an ad break happened during the visit.
  bool _hadActivity = false;

  bool _disposed = false;

  /// The session copy, kept so an unsaved lead can still be shown after the
  /// saved copy is deleted.
  Lead? _sessionLead;

  // Captured in `build`: `ref` may not be used from `onDispose`, and the last
  // note flush happens exactly there.
  late final LeadRepository _repository;
  late FeatureGate _gate;

  /// The last state written, mirrored for `onDispose`, where `state` itself may
  /// not be read.
  LeadDetailState? _mirror;

  /// One-shot events; the page subscribes in `initState`.
  Stream<LeadDetailUiEvent> get events => _events.stream;

  /// The current state, for the page's sheet builders (which run outside
  /// `build` and so cannot `watch`).
  LeadDetailState get current => state;

  /// True when a CRM edit, save or contact action happened during the visit.
  bool get hadActivity => _hadActivity;

  @override
  LeadDetailState build() {
    ref.onDispose(_onDispose);
    final FeatureGate gate = ref.read(featureGateProvider);
    _gate = gate;
    _repository = ref.read(leadRepositoryProvider);
    _sessionLead = ref.read(leadSessionProvider)?.leadById(leadId);

    // The saved store is the live copy: bookmark state and CRM fields follow it,
    // so Results and Saved update too.
    _savedSubscription = _repository.watchSavedLeads().listen(
      _onSavedLeads,
      onError: (Object error) =>
          debugPrint('[lead] saved-lead watch failed: $error'),
    );

    ref.listen<FeatureGate>(featureGateProvider, (
      FeatureGate? _,
      FeatureGate next,
    ) {
      _gate = next;
      if (_disposed) {
        return;
      }
      _set(state.copyWith(canViewSocial: next.canViewSocialProfiles));
    });

    unawaited(_resolve());

    final LeadDetailState initial = LeadDetailState(
      leadId: leadId,
      canViewSocial: gate.canViewSocialProfiles,
    );
    _mirror = initial;
    return initial;
  }

  // ---------------------------------------------------------------------------
  // Actions: save
  // ---------------------------------------------------------------------------

  /// Toggles the bookmark.
  ///
  /// Unsaving a lead that carries notes, tags, a status or a follow-up date asks
  /// first ([LeadDetailConfirmUnsave]); a plain bookmark is removed immediately.
  Future<void> toggleSave() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    if (lead.isSaved) {
      if (CrmRules.hasCrmData(lead)) {
        _emit(const LeadDetailConfirmUnsave());
        return;
      }
      await unsaveNow();
      return;
    }

    final LeadSaveOutcome outcome = await _saver.ensureSaved(lead);
    if (outcome == LeadSaveOutcome.limitReached) {
      _emit(LeadDetailOpenPro(LockReason.savedLeadLimitReached.name));
      return;
    }
    _markActivity();
    _emit(const LeadDetailMessage(LeadDetailStrings.savedToast));
  }

  /// Runs the unsave after the page's confirmation.
  Future<void> unsaveNow() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    await _saver.unsave(lead.id);
    if (_disposed) {
      return;
    }
    _saveLead(_clearedForUnsaved(lead));
    _emit(const LeadDetailMessage(LeadDetailStrings.unsavedToast));
  }

  /// Asks the page to confirm removing a saved lead.
  void requestRemove() {
    if (!state.isSaved) {
      return;
    }
    _emit(const LeadDetailConfirmRemove());
  }

  /// Deletes the lead after the page's confirmation.
  Future<void> removeLead() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    await _repository.deleteLeads(<String>[lead.id]);
    if (_disposed) {
      return;
    }
    _markActivity();
    _emit(const LeadDetailRemoved());
  }

  // ---------------------------------------------------------------------------
  // Actions: CRM
  // ---------------------------------------------------------------------------

  /// Sets the CRM stage, optimistically.
  Future<void> setStatus(LeadStatus status) async {
    final Lead? lead = state.lead;
    if (lead == null || lead.status == status) {
      return;
    }
    final LeadDetailState previous = state;
    _saveLead(lead.copyWith(status: status));
    final bool ok = await _persistEdit(
      LeadUpdate(status: status),
      optimisticLead: lead.copyWith(status: status),
    );
    if (!ok) {
      _restore(previous);
    }
  }

  /// Adds a tag, optimistically, after the shared validation.
  ///
  /// Returns the reason it was refused, or `null` when it was added — the sheet
  /// shows the message inline instead of a snackbar.
  Future<TagError?> addTag(String raw) async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return TagError.empty;
    }
    final TagError? error = CrmRules.validateTag(raw, existing: lead.tags);
    if (error != null) {
      return error;
    }
    final List<String> nextTags = <String>[
      ...lead.tags,
      CrmRules.normalizeTag(raw),
    ];
    final LeadDetailState previous = state;
    _saveLead(lead.copyWith(tags: nextTags));
    final bool ok = await _persistEdit(
      LeadUpdate(tags: nextTags),
      optimisticLead: lead.copyWith(tags: nextTags),
    );
    if (!ok) {
      _restore(previous);
    }
    return null;
  }

  /// Removes a tag, optimistically.
  Future<void> removeTag(String tag) async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final List<String> nextTags = <String>[
      for (final String existing in lead.tags)
        if (existing != tag) existing,
    ];
    if (nextTags.length == lead.tags.length) {
      return;
    }
    final LeadDetailState previous = state;
    _saveLead(lead.copyWith(tags: nextTags));
    final bool ok = await _persistEdit(
      LeadUpdate(tags: nextTags),
      optimisticLead: lead.copyWith(tags: nextTags),
    );
    if (!ok) {
      _restore(previous);
    }
  }

  /// Updates the note draft and restarts the debounce.
  void setNote(String raw) {
    final String note = CrmRules.clampNote(raw);
    _noteDirty = note != (state.lead?.note ?? '');
    _set(state.copyWith(noteDraft: note));
    _noteTimer?.cancel();
    if (!_noteDirty) {
      return;
    }
    _noteTimer = Timer(noteDebounce, () => unawaited(flushNote()));
  }

  /// Writes the note now: on back, on dispose, on background, on explicit save.
  Future<void> flushNote() async {
    _noteTimer?.cancel();
    _noteTimer = null;
    if (!_noteDirty) {
      return;
    }
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final String note = state.noteDraft;
    if (note == lead.note) {
      _noteDirty = false;
      return;
    }
    final bool ok = await _persistEdit(LeadUpdate(note: note));
    if (ok) {
      _noteDirty = false;
    } else if (!_disposed) {
      // The draft stays in the field so the user can retry; the stored note is
      // unchanged, which the stream will confirm.
      _emit(const LeadDetailMessage(LeadDetailStrings.saveFailedToast));
    }
  }

  /// Stores a follow-up date and time.
  Future<void> setFollowUp(DateTime when) async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final LeadDetailState previous = state;
    final Lead next = _withFollowUp(lead, when);
    _saveLead(next);
    final bool ok = await _persistEdit(
      LeadUpdate(reminderAt: when),
      optimisticLead: next,
    );
    if (!ok) {
      _restore(previous);
      return;
    }
    _emit(const LeadDetailMessage(LeadDetailStrings.followUpSetToast));
  }

  /// Removes the follow-up date.
  Future<void> clearFollowUp() async {
    final Lead? lead = state.lead;
    if (lead == null || lead.reminderAt == null) {
      return;
    }
    final LeadDetailState previous = state;
    final Lead next = _withFollowUp(lead, null);
    _saveLead(next);
    final bool ok = await _persistEdit(
      const LeadUpdate(clearReminder: true),
      optimisticLead: next,
    );
    if (!ok) {
      _restore(previous);
      return;
    }
    _emit(const LeadDetailMessage(LeadDetailStrings.followUpClearedToast));
  }

  // ---------------------------------------------------------------------------
  // Actions: contact and sharing
  // ---------------------------------------------------------------------------

  /// Dials the primary phone.
  Future<void> call() async {
    final PhoneContact? phone = state.lead?.primaryPhone;
    if (phone == null) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.call(phone.value),
      CommonStrings.launchingCall,
    );
  }

  /// Opens WhatsApp for the primary mobile number.
  Future<void> whatsApp() async {
    final PhoneContact? phone = ContactRules.whatsAppPhone(state.lead!);
    if (phone == null) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.whatsApp(phone.value),
      CommonStrings.launchingWhatsApp,
    );
  }

  /// Composes an email to the primary address.
  Future<void> email() async {
    final EmailContact? address = state.lead?.primaryEmail;
    if (address == null) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.email(address.value),
      CommonStrings.launchingEmail,
    );
  }

  /// Opens the website in a browser.
  Future<void> openWebsite() async {
    final String? website = state.lead?.website;
    if (website == null || website.isEmpty) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.openUrl(_withScheme(website)),
      LeadDetailStrings.openWebsiteTooltip,
    );
  }

  /// Opens one social profile.
  ///
  /// Free users cannot read the handle or follow the link: the tap opens the
  /// paywall instead, with the same reason the locked row announces.
  Future<void> openSocial(LeadSource source) async {
    if (!state.canViewSocial) {
      _emit(LeadDetailOpenPro(LockReason.socialProfilesRequirePro.name));
      return;
    }
    final String? url = state.socials[source];
    if (url == null || url.trim().isEmpty) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.openUrl(_withScheme(url)),
      LeadDetailStrings.openLinkTooltip,
    );
  }

  /// Opens a maps app at the address, or at the coordinates when they exist.
  Future<void> directions() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final String query = lead.latitude != null && lead.longitude != null
        ? '${lead.latitude},${lead.longitude}'
        : _addressOf(lead);
    if (query.isEmpty) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.openMaps(query),
      LeadDetailStrings.directionsToast,
    );
  }

  /// Inserts the lead into the device address book.
  Future<void> saveToContacts() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    await _launch(
      (ContactLauncher launcher) => launcher.saveToContacts(lead),
      LeadDetailStrings.saveContactToast,
    );
  }

  /// Copies one value to the clipboard.
  Future<void> copyValue(String value) async {
    final String text = value.trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _markActivity();
    _emit(const LeadDetailMessage(LeadDetailStrings.copiedToast));
  }

  /// Copies the whole lead as text; social links only when the plan allows them.
  Future<void> copyAll() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final String text = LeadTextFormatter.format(
      lead,
      includeSocialLinks: state.canViewSocial,
    );
    await Clipboard.setData(ClipboardData(text: text));
    _markActivity();
    _emit(const LeadDetailMessage(LeadDetailStrings.allDetailsCopied));
  }

  /// Opens the platform share sheet with the same block.
  Future<void> share() async {
    final Lead? lead = state.lead;
    if (lead == null) {
      return;
    }
    final String text = LeadTextFormatter.format(
      lead,
      includeSocialLinks: state.canViewSocial,
    );
    _markActivity();
    final ContactLaunchResult result = await ref
        .read(shareServiceProvider)
        .shareText(text);
    if (result != ContactLaunchResult.launched && !_disposed) {
      _emit(const LeadDetailMessage(LeadDetailStrings.shareFailedToast));
    }
  }

  // ---------------------------------------------------------------------------
  // Leaving
  // ---------------------------------------------------------------------------

  /// Flushes the note and reports whether the visit earned an ad break.
  ///
  /// The prompt's rule: only a CRM edit, a save or a contact action counts — not
  /// opening the screen. The page calls this before popping and shows the
  /// interstitial with `AdTrigger.leadDetailClosed` when it returns true.
  Future<bool> leave() async {
    await flushNote();
    return _hadActivity;
  }

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  Future<void> _resolve() async {
    Lead? saved;
    try {
      saved = await _repository.getLead(leadId);
    } catch (error) {
      debugPrint('[lead] could not resolve $leadId: $error');
    }
    if (_disposed) {
      return;
    }
    final Lead? lead = saved ?? _sessionLead;
    if (lead == null) {
      _set(state.copyWith(phase: LeadDetailPhase.notFound));
      return;
    }
    _applyResolved(lead);
  }

  void _onSavedLeads(List<Lead> leads) {
    if (_disposed) {
      return;
    }
    Lead? saved;
    for (final Lead lead in leads) {
      if (lead.id == leadId) {
        saved = lead;
        break;
      }
    }
    if (saved != null) {
      _applyResolved(saved);
      return;
    }
    final Lead? current = state.lead;
    if (current != null && current.isSaved) {
      // Unsaved or removed elsewhere: keep showing the session copy without the
      // private data the delete just took with it.
      final Lead base = _sessionLead ?? current;
      _saveLead(_clearedForUnsaved(base));
      _set(state.copyWith(noteDraft: ''));
    }
  }

  void _applyResolved(Lead lead) {
    final bool keepDraft = _noteDirty || state.pendingSave;
    _set(
      state.copyWith(
        phase: LeadDetailPhase.loaded,
        lead: lead,
        noteDraft: keepDraft ? state.noteDraft : lead.note,
        pendingSave: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------------

  LeadSaveController get _saver =>
      LeadSaveController(repository: _repository, gate: _gate);

  /// Writes one CRM change, auto-saving the lead first when it is not saved.
  ///
  /// Returns false when nothing was written: the cap refused the save, the store
  /// rejected the update, or it threw. The caller restores its optimistic copy.
  Future<bool> _persistEdit(LeadUpdate update, {Lead? optimisticLead}) async {
    final Lead? lead = optimisticLead ?? state.lead;
    if (lead == null) {
      return false;
    }
    _set(state.copyWith(pendingSave: true));
    try {
      if (!state.lead!.isSaved) {
        final LeadSaveOutcome outcome = await _saver.ensureSaved(
          optimisticLead ?? state.lead!,
        );
        if (outcome == LeadSaveOutcome.limitReached) {
          if (!_disposed) {
            _set(state.copyWith(pendingSave: false));
            _emit(LeadDetailOpenPro(LockReason.savedLeadLimitReached.name));
          }
          return false;
        }
      }
      final Lead? updated = await ref
          .read(leadRepositoryProvider)
          .updateLead(leadId, update);
      if (_disposed) {
        return true;
      }
      _set(state.copyWith(pendingSave: false));
      if (updated == null) {
        return false;
      }
      _saveLead(updated);
      _markActivity();
      return true;
    } catch (error) {
      debugPrint('[lead] could not save the edit: $error');
      if (!_disposed) {
        _set(state.copyWith(pendingSave: false));
      }
      return false;
    }
  }

  void _restore(LeadDetailState previous) {
    if (_disposed) {
      return;
    }
    _set(previous.copyWith(pendingSave: false));
    _emit(const LeadDetailMessage(LeadDetailStrings.saveFailedToast));
  }

  /// Records a meaningful action for the ad policy and the leave rule.
  void _markActivity() {
    _hadActivity = true;
    ref.read(adPolicyProvider).recordUserAction();
  }

  Future<void> _launch(
    Future<ContactLaunchResult> Function(ContactLauncher launcher) action,
    String successText,
  ) async {
    _hadActivity = true;
    final ContactLaunchResult result = await action(
      ref.read(contactLauncherProvider),
    );
    if (_disposed) {
      return;
    }
    final String message = switch (result) {
      ContactLaunchResult.launched => successText,
      ContactLaunchResult.unavailable => CommonStrings.contactUnavailable,
      ContactLaunchResult.failed => CommonStrings.contactFailed,
    };
    _emit(LeadDetailMessage(message));
  }

  void _saveLead(Lead lead) => _set(state.copyWith(lead: lead));

  void _set(LeadDetailState next) {
    if (_disposed) {
      return;
    }
    _mirror = next;
    state = next;
  }

  void _emit(LeadDetailUiEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  void _onDispose() {
    // `_repository` and `_gate` were captured in `build`: a pending note draft
    // still has to reach the store, and `ref` is unusable from here on.
    final LeadSaveController saver = _saver;
    final LeadRepository repository = _repository;
    final LeadDetailState? last = _mirror;
    final Lead? lead = _noteDirty ? last?.lead : null;
    final String note = last?.noteDraft ?? '';

    _disposed = true;
    _noteTimer?.cancel();
    _noteTimer = null;

    // The note is not lost when the user leaves without waiting for the
    // debounce: a pending draft is written before the controller goes away.
    if (lead != null) {
      unawaited(_flushOnDispose(saver, repository, lead, note));
    }
    _savedSubscription?.cancel();
    _savedSubscription = null;
    _events.close();
  }

  /// The last-chance note write after the screen is gone.
  static Future<void> _flushOnDispose(
    LeadSaveController saver,
    LeadRepository repository,
    Lead lead,
    String note,
  ) async {
    try {
      final LeadSaveOutcome outcome = await saver.ensureSaved(lead);
      if (outcome == LeadSaveOutcome.saved) {
        await repository.updateLead(lead.id, LeadUpdate(note: note));
      }
    } catch (error) {
      debugPrint('[lead] could not flush the note: $error');
    }
  }

  /// A copy with the private CRM data cleared, for after an unsave.
  static Lead _clearedForUnsaved(Lead lead) {
    return Lead(
      id: lead.id,
      name: lead.name,
      category: lead.category,
      address: lead.address,
      area: lead.area,
      city: lead.city,
      state: lead.state,
      latitude: lead.latitude,
      longitude: lead.longitude,
      phones: lead.phones,
      emails: lead.emails,
      website: lead.website,
      socialLinks: lead.socialLinks,
      rating: lead.rating,
      reviewCount: lead.reviewCount,
      isOpenNow: lead.isOpenNow,
      openingHours: lead.openingHours,
      sources: lead.sources,
      confidenceScore: lead.confidenceScore,
      discoveredAt: lead.discoveredAt,
    );
  }

  static Lead _withFollowUp(Lead lead, DateTime? when) {
    final Lead cleared = when == null ? lead.withoutReminder() : lead;
    if (when == null) {
      return cleared;
    }
    return Lead(
      id: cleared.id,
      name: cleared.name,
      category: cleared.category,
      address: cleared.address,
      area: cleared.area,
      city: cleared.city,
      state: cleared.state,
      country: cleared.country,
      latitude: cleared.latitude,
      longitude: cleared.longitude,
      phones: cleared.phones,
      emails: cleared.emails,
      website: cleared.website,
      socialLinks: cleared.socialLinks,
      rating: cleared.rating,
      reviewCount: cleared.reviewCount,
      isOpenNow: cleared.isOpenNow,
      openingHours: cleared.openingHours,
      sources: cleared.sources,
      confidenceScore: cleared.confidenceScore,
      discoveredAt: cleared.discoveredAt,
      isSaved: cleared.isSaved,
      savedAt: cleared.savedAt,
      status: cleared.status,
      tags: cleared.tags,
      note: cleared.note,
      reminderAt: when,
      listIds: cleared.listIds,
    );
  }

  static String _addressOf(Lead lead) {
    final String address = lead.address.trim();
    if (address.isNotEmpty) {
      return address;
    }
    return <String>[
      lead.name,
      if (lead.area.isNotEmpty) lead.area,
      if (lead.city.isNotEmpty) lead.city,
    ].join(', ');
  }

  static String _withScheme(String url) {
    final String value = url.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }
}

/// One controller per lead id, alive only while the screen watches it.
final leadDetailControllerProvider = NotifierProvider.autoDispose
    .family<LeadDetailController, LeadDetailState, String>(
      LeadDetailController.new,
    );
