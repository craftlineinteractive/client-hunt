import 'package:flutter/foundation.dart';

import '../../domain/leads/crm_rules.dart';
import '../../domain/models/models.dart';
import '../../domain/results/contact_rules.dart';

/// Where a Lead Detail screen is in its lifecycle.
enum LeadDetailPhase {
  /// Resolving the id: skeleton.
  loading,

  /// The lead is here.
  loaded,

  /// The id resolves to nothing (a removed lead or a stale link).
  notFound,
}

/// The four social profiles the Profiles card shows, in display order.
const List<LeadSource> socialProfileSources = <LeadSource>[
  LeadSource.instagram,
  LeadSource.linkedin,
  LeadSource.facebook,
  LeadSource.x,
];

/// One lead, its editable CRM fields and the plan it is shown under.
///
/// The lead itself is the single source of truth for the CRM values: an edit
/// writes an optimistic copy here, the repository stream then confirms it, and a
/// failure restores the previous copy. [noteDraft] is the one exception — it is a
/// draft until the debounce flushes it, so typing never fights the stream.
@immutable
class LeadDetailState {
  const LeadDetailState({
    required this.leadId,
    this.phase = LeadDetailPhase.loading,
    this.lead,
    this.noteDraft = '',
    this.pendingSave = false,
    this.canViewSocial = false,
  });

  /// The id from the route.
  final String leadId;

  /// Lifecycle phase.
  final LeadDetailPhase phase;

  /// The resolved lead, with the optimistic copy while a write is in flight.
  final Lead? lead;

  /// What the note field shows; equals [Lead.note] once saved.
  final String noteDraft;

  /// True while a CRM write is in flight (no spinner is drawn for it).
  final bool pendingSave;

  /// True when social profile handles may be read (Pro).
  final bool canViewSocial;

  /// True when the lead is in the saved store.
  bool get isSaved => lead?.isSaved ?? false;

  /// The lead's tags, newest last.
  List<String> get tags => lead?.tags ?? const <String>[];

  /// The CRM stage.
  LeadStatus get status => lead?.status ?? LeadStatus.newLead;

  /// The follow-up date, when set.
  DateTime? get followUp => lead?.reminderAt;

  /// True when unsaving would delete private data.
  bool get hasCrmData => lead == null ? false : CrmRules.hasCrmData(lead!);

  /// True when there is a number to dial.
  bool get canCall => lead == null ? false : ContactRules.canCall(lead!);

  /// True when there is a mobile number for WhatsApp.
  bool get canWhatsApp =>
      lead == null ? false : ContactRules.canWhatsApp(lead!);

  /// True when there is an address to write to.
  bool get canEmail => lead == null ? false : ContactRules.canEmail(lead!);

  /// Profile URLs that exist, keyed by network.
  Map<LeadSource, String> get socials =>
      lead?.socialLinks ?? const <LeadSource, String>{};

  /// True when at least one network has a profile.
  bool get hasSocials => socials.entries.any(
    (MapEntry<LeadSource, String> entry) => entry.value.trim().isNotEmpty,
  );

  /// True when rating, reviews or opening hours exist (Maps data).
  bool get hasBusinessDetails =>
      lead?.rating != null ||
      lead?.reviewCount != null ||
      (lead?.openingHours?.trim().isNotEmpty ?? false);

  /// Copy with selected fields replaced.
  LeadDetailState copyWith({
    LeadDetailPhase? phase,
    Lead? lead,
    String? noteDraft,
    bool? pendingSave,
    bool? canViewSocial,
  }) {
    return LeadDetailState(
      leadId: leadId,
      phase: phase ?? this.phase,
      lead: lead ?? this.lead,
      noteDraft: noteDraft ?? this.noteDraft,
      pendingSave: pendingSave ?? this.pendingSave,
      canViewSocial: canViewSocial ?? this.canViewSocial,
    );
  }
}
