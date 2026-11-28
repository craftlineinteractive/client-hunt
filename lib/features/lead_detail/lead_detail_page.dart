import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/ads/ad_policy.dart';
import '../../domain/leads/crm_rules.dart';
import '../../domain/models/models.dart';
import '../../shared/widgets/shared.dart';
import 'lead_detail_controller.dart';
import 'lead_detail_state.dart';

/// All distinct tags across the saved leads, for the "Add tag" sheet.
final StreamProvider<List<String>> allTagsProvider =
    StreamProvider<List<String>>(
      (Ref ref) => ref.watch(leadRepositoryProvider).watchAllTags(),
    );

/// The Lead Detail screen.
///
/// A pushed route (`/lead/:id`) with no bottom navigation and no sticky bar:
/// everything scrolls, and the actions that matter sit at the top. Every value
/// comes from [LeadDetailController]; this file only presents it and performs the
/// one-shot events a controller cannot (dialogs, snackbars, navigation, the ad
/// break).
///
/// Leaving — system back or the app bar arrow — always goes through [_close]:
/// flush the note, pop, then ask for an interstitial only when the visit
/// contained a CRM edit, a save or a contact action.
class LeadDetailPage extends ConsumerStatefulWidget {
  const LeadDetailPage({required this.leadId, super.key});

  /// The lead to show.
  final String leadId;

  @override
  ConsumerState<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends ConsumerState<LeadDetailPage>
    with WidgetsBindingObserver {
  late final ProviderContainer _container;
  StreamSubscription<LeadDetailUiEvent>? _events;
  late final TextEditingController _noteController;
  final FocusNode _noteFocus = FocusNode();
  bool _isLeaving = false;

  LeadDetailController get _controller =>
      _container.read(leadDetailControllerProvider(widget.leadId).notifier);

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _noteController = TextEditingController();
    _events = _controller.events.listen(_onEvent);
    WidgetsBinding.instance.addObserver(this);
    _noteFocus.addListener(_onNoteFocus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteFocus.removeListener(_onNoteFocus);
    _noteFocus.dispose();
    _events?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The debounce must not wait for a process that may never come back.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.flushNote());
    }
  }

  void _onNoteFocus() {
    if (!_noteFocus.hasFocus) {
      return;
    }
    // Keep the field above the keyboard instead of under it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_noteFocus.hasFocus) {
        return;
      }
      final BuildContext? fieldContext = _noteFocus.context;
      if (fieldContext == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.5,
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _onEvent(LeadDetailUiEvent event) {
    if (!mounted) {
      return;
    }
    switch (event) {
      case LeadDetailMessage(:final String text):
        _showSnack(text);
      case LeadDetailOpenPro(:final String reason):
        _openPro(reason);
      case LeadDetailConfirmUnsave():
        unawaited(_confirmUnsave());
      case LeadDetailConfirmRemove():
        unawaited(_confirmRemove());
      case LeadDetailRemoved():
        unawaited(_finishRemoval());
      case LeadDetailAdBreak():
        break;
    }
  }

  void _showSnack(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmUnsave() async {
    final Object? answer = await showAppDialog(
      context,
      title: LeadDetailStrings.unsaveTitle,
      body: LeadDetailStrings.unsaveBody,
      actions: const <AppDialogAction>[
        AppDialogAction(label: CommonStrings.cancel),
        AppDialogAction(
          label: LeadDetailStrings.unsaveConfirm,
          style: AppDialogActionStyle.primary,
          value: true,
        ),
      ],
    );
    if (answer == true && mounted) {
      await _controller.unsaveNow();
    }
  }

  Future<void> _confirmRemove() async {
    final Object? answer = await showAppDialog(
      context,
      title: LeadDetailStrings.removeTitle,
      body: LeadDetailStrings.removeBody,
      actions: const <AppDialogAction>[
        AppDialogAction(label: CommonStrings.cancel),
        AppDialogAction(
          label: LeadDetailStrings.removeConfirm,
          style: AppDialogActionStyle.primary,
          value: true,
        ),
      ],
    );
    if (answer == true && mounted) {
      await _controller.removeLead();
    }
  }

  /// Pops after a delete and reports it on the screen underneath.
  Future<void> _finishRemoval() async {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;
    await _controller.leave();
    if (!mounted) {
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(LeadDetailStrings.removedToast)),
      );
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _openPro(String reason) {
    if (!mounted) {
      return;
    }
    unawaited(AppNavigator.openPro(context, reason: reason));
  }

  /// Flushes, pops, then runs the interstitial rule.
  Future<void> _close() async {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;
    FocusScope.of(context).unfocus();
    final bool worthABreak = await _controller.leave();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    if (!worthABreak) {
      return;
    }
    await _container
        .read(adCoordinatorProvider)
        .maybeShowInterstitial(AdTrigger.leadDetailClosed);
  }

  // ---------------------------------------------------------------------------
  // Sheets
  // ---------------------------------------------------------------------------

  Future<void> _showMoreMenu() async {
    final LeadDetailState state = _controller.current;
    final _MenuAction? action = await showModalBottomSheet<_MenuAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _Sheet(
        title: LeadDetailStrings.title,
        children: <Widget>[
          _SheetRow(
            label: LeadDetailStrings.copyAllDetails,
            icon: AppIcons.copyStack,
            onTap: () => Navigator.of(context).pop(_MenuAction.copyAll),
          ),
          _SheetRow(
            label: LeadDetailStrings.saveToContacts,
            icon: AppIcons.saveContact,
            onTap: () => Navigator.of(context).pop(_MenuAction.saveContact),
          ),
          if (state.isSaved)
            _SheetRow(
              label: LeadDetailStrings.removeLead,
              icon: AppIcons.delete,
              onTap: () => Navigator.of(context).pop(_MenuAction.remove),
            ),
        ],
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _MenuAction.copyAll:
        await _controller.copyAll();
      case _MenuAction.saveContact:
        await _controller.saveToContacts();
      case _MenuAction.remove:
        _controller.requestRemove();
    }
  }

  Future<void> _addTag() async {
    final List<String> existing = _controller.current.tags;
    final String? raw = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => _AddTagSheet(
        existing: existing,
        suggestions: ref.read(allTagsProvider).value ?? const <String>[],
        onAdd: _controller.addTag,
      ),
    );
    if (raw == null || !mounted) {
      return;
    }
    // The sheet already validated the tag and added it; a repository failure is
    // reported by the controller and the chip disappears again.
  }

  Future<void> _showFollowUpSheet() async {
    if (_controller.current.followUp == null) {
      await _pickFollowUp();
      return;
    }
    final _FollowUpAction? action = await showModalBottomSheet<_FollowUpAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _Sheet(
        title: LeadDetailStrings.followUpDate,
        children: <Widget>[
          _SheetRow(
            label: LeadDetailStrings.changeDate,
            icon: AppIcons.schedule,
            onTap: () => Navigator.of(context).pop(_FollowUpAction.change),
          ),
          _SheetRow(
            label: LeadDetailStrings.followUpClear,
            icon: AppIcons.close,
            onTap: () => Navigator.of(context).pop(_FollowUpAction.clear),
          ),
        ],
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _FollowUpAction.change:
        await _pickFollowUp();
      case _FollowUpAction.clear:
        await _controller.clearFollowUp();
    }
  }

  Future<void> _pickFollowUp() async {
    final DateTime now = DateTime.now();
    final DateTime? current = _controller.current.followUp;
    final DateTime initial = current ?? now.add(const Duration(days: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: LeadDetailStrings.followUpDate,
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 10, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (!mounted) {
      return;
    }
    final TimeOfDay chosen = time ?? const TimeOfDay(hour: 10, minute: 0);
    await _controller.setFollowUp(
      DateTime(date.year, date.month, date.day, chosen.hour, chosen.minute),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final LeadDetailState state = ref.watch(
      leadDetailControllerProvider(widget.leadId),
    );
    _syncNoteField(state);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_close());
        }
      },
      child: Scaffold(
        appBar: AppTopBar.pushed(
          title: LeadDetailStrings.title,
          onLeading: _close,
          actions: <Widget>[
            AppIconButton(
              icon: state.isSaved ? AppIcons.saved : AppIcons.savedOutline,
              tooltip: state.isSaved
                  ? LeadDetailStrings.unsaveTooltip
                  : LeadDetailStrings.bookmarkTooltip,
              onPressed: state.phase == LeadDetailPhase.loaded
                  ? () => unawaited(_controller.toggleSave())
                  : null,
            ),
            AppIconButton(
              icon: AppIcons.share,
              tooltip: LeadDetailStrings.shareTooltip,
              onPressed: state.phase == LeadDetailPhase.loaded
                  ? () => unawaited(_controller.share())
                  : null,
            ),
            AppIconButton(
              icon: AppIcons.more,
              tooltip: CommonStrings.moreTooltip,
              onPressed: state.phase == LeadDetailPhase.loaded
                  ? _showMoreMenu
                  : null,
            ),
          ],
        ),
        body: switch (state.phase) {
          LeadDetailPhase.loading => const _LeadDetailSkeleton(),
          LeadDetailPhase.notFound => _NotFound(onBack: _close),
          LeadDetailPhase.loaded => _Loaded(
            state: state,
            noteController: _noteController,
            noteFocus: _noteFocus,
            onCall: _controller.call,
            onWhatsApp: _controller.whatsApp,
            onEmail: _controller.email,
            onDirections: _controller.directions,
            onSaveToContacts: _controller.saveToContacts,
            onCopy: _controller.copyValue,
            onCopyAll: _controller.copyAll,
            onOpenWebsite: _controller.openWebsite,
            onOpenSocial: _controller.openSocial,
            onAddTag: _addTag,
            onRemoveTag: _controller.removeTag,
            onNoteChanged: _controller.setNote,
            onStatusChanged: _controller.setStatus,
            onFollowUp: _showFollowUpSheet,
            onRemove: _controller.requestRemove,
          ),
        },
      ),
    );
  }

  /// Pushes the controller's note into the field when the lead resolves.
  ///
  /// Never while the draft is being edited: the field owns the text then.
  void _syncNoteField(LeadDetailState state) {
    if (_noteFocus.hasFocus) {
      return;
    }
    if (_noteController.text != state.noteDraft) {
      _noteController.value = TextEditingValue(
        text: state.noteDraft,
        selection: TextSelection.collapsed(offset: state.noteDraft.length),
      );
    }
  }
}

enum _MenuAction { copyAll, saveContact, remove }

enum _FollowUpAction { change, clear }

// -----------------------------------------------------------------------------
// Loaded layout
// -----------------------------------------------------------------------------

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.noteController,
    required this.noteFocus,
    required this.onCall,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onDirections,
    required this.onSaveToContacts,
    required this.onCopy,
    required this.onCopyAll,
    required this.onOpenWebsite,
    required this.onOpenSocial,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onNoteChanged,
    required this.onStatusChanged,
    required this.onFollowUp,
    required this.onRemove,
  });

  final LeadDetailState state;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final Future<void> Function() onCall;
  final Future<void> Function() onWhatsApp;
  final Future<void> Function() onEmail;
  final Future<void> Function() onDirections;
  final Future<void> Function() onSaveToContacts;
  final Future<void> Function(String value) onCopy;
  final Future<void> Function() onCopyAll;
  final Future<void> Function() onOpenWebsite;
  final Future<void> Function(LeadSource source) onOpenSocial;
  final Future<void> Function() onAddTag;
  final Future<void> Function(String tag) onRemoveTag;
  final ValueChanged<String> onNoteChanged;
  final Future<void> Function(LeadStatus status) onStatusChanged;
  final Future<void> Function() onFollowUp;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Lead lead = state.lead!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          _HeroCard(lead: lead),
          const SizedBox(height: AppSpacing.md),
          _QuickActions(
            state: state,
            onCall: onCall,
            onWhatsApp: onWhatsApp,
            onEmail: onEmail,
            onDirections: onDirections,
            onSaveToContacts: onSaveToContacts,
          ),
          const SizedBox(height: AppSpacing.md),
          _ContactCard(
            lead: lead,
            onCopy: onCopy,
            onDirections: onDirections,
            onOpenWebsite: onOpenWebsite,
          ),
          if (state.hasSocials || state.canViewSocial) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _ProfilesCard(state: state, onOpen: onOpenSocial),
          ],
          if (state.hasBusinessDetails) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _BusinessCard(lead: lead),
          ],
          const SizedBox(height: AppSpacing.md),
          _NotesCard(
            state: state,
            noteController: noteController,
            noteFocus: noteFocus,
            onAddTag: onAddTag,
            onRemoveTag: onRemoveTag,
            onNoteChanged: onNoteChanged,
            onStatusChanged: onStatusChanged,
            onFollowUp: onFollowUp,
          ),
          const SizedBox(height: AppSpacing.md),
          _FooterActions(
            isSaved: state.isSaved,
            onCopyAll: onCopyAll,
            onRemove: onRemove,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String where = <String>[
      if (lead.area.trim().isNotEmpty) lead.area.trim(),
      if (lead.city.trim().isNotEmpty) lead.city.trim(),
    ].join(', ');
    final String subtitle = <String>[
      lead.category.trim(),
      where,
    ].where((String part) => part.isNotEmpty).join(' · ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InitialsAvatar(
                initials: LeadCard.initialsOf(lead.name),
                size: 64,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lead.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSm.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (lead.rating != null ||
              lead.sources.isNotEmpty ||
              (lead.isOpenNow ?? false)) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (lead.rating != null)
                  RatingBadge(
                    rating: lead.rating!,
                    reviewCount: lead.reviewCount ?? 0,
                    isPill: true,
                  ),
                for (final LeadSource source in lead.sources)
                  SourceBadge(label: source.displayName),
                if (lead.isOpenNow ?? false)
                  const AppChip(
                    label: LeadDetailStrings.openNow,
                    size: AppChipSize.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.state,
    required this.onCall,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onDirections,
    required this.onSaveToContacts,
  });

  final LeadDetailState state;
  final Future<void> Function() onCall;
  final Future<void> Function() onWhatsApp;
  final Future<void> Function() onEmail;
  final Future<void> Function() onDirections;
  final Future<void> Function() onSaveToContacts;

  @override
  Widget build(BuildContext context) {
    final bool hasDirections = state.lead!.address.trim().isNotEmpty;
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AppIconButton(
              icon: AppIcons.phone,
              tooltip: LeadDetailStrings.callTooltip,
              size: 52,
              outlined: true,
              onPressed: state.canCall ? () => unawaited(onCall()) : null,
            ),
            AppIconButton(
              icon: AppIcons.whatsapp,
              tooltip: LeadDetailStrings.whatsAppTooltip,
              size: 52,
              outlined: true,
              onPressed: state.canWhatsApp
                  ? () => unawaited(onWhatsApp())
                  : null,
            ),
            AppIconButton(
              icon: AppIcons.email,
              tooltip: LeadDetailStrings.emailTooltip,
              size: 52,
              outlined: true,
              onPressed: state.canEmail ? () => unawaited(onEmail()) : null,
            ),
            AppIconButton(
              icon: AppIcons.directions,
              tooltip: LeadDetailStrings.directionsTooltip,
              size: 52,
              outlined: true,
              onPressed: hasDirections ? () => unawaited(onDirections()) : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: LeadDetailStrings.saveToContacts,
          icon: AppIcons.saveContact,
          onPressed: () => unawaited(onSaveToContacts()),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.lead,
    required this.onCopy,
    required this.onDirections,
    required this.onOpenWebsite,
  });

  final Lead lead;
  final Future<void> Function(String value) onCopy;
  final Future<void> Function() onDirections;
  final Future<void> Function() onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final List<Widget> rows = <Widget>[];

    for (final PhoneContact phone in lead.phones) {
      rows
        ..add(
          ContactRow(
            icon: phone.kind == PhoneKind.mobile
                ? AppIcons.mobile
                : AppIcons.phone,
            label: phone.kind.displayName,
            value: phone.value,
            onCopy: () => unawaited(onCopy(phone.value)),
          ),
        )
        ..addAll(_provenance(context, phone.foundOnUrl));
    }

    for (final EmailContact email in lead.emails) {
      rows
        ..add(
          ContactRow(
            icon: AppIcons.email,
            label: LeadDetailStrings.emailLabel,
            value: email.value,
            onCopy: () => unawaited(onCopy(email.value)),
          ),
        )
        ..addAll(_provenance(context, email.foundOnUrl));
    }

    final String? website = lead.website;
    if (website != null && website.trim().isNotEmpty) {
      rows.add(
        ContactRow(
          icon: AppIcons.website,
          label: LeadDetailStrings.websiteLabel,
          value: website,
          onCopy: () => unawaited(onCopy(website)),
          extraIcon: AppIcons.externalLink,
          extraTooltip: LeadDetailStrings.openWebsiteTooltip,
          onExtra: () => unawaited(onOpenWebsite()),
        ),
      );
    }

    if (lead.address.trim().isNotEmpty) {
      rows.add(
        ContactRow(
          icon: AppIcons.location,
          label: LeadDetailStrings.addressLabel,
          value: lead.address,
          onCopy: () => unawaited(onCopy(lead.address)),
          extraIcon: AppIcons.directions,
          extraTooltip: LeadDetailStrings.directionsTooltip,
          onExtra: () => unawaited(onDirections()),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: SectionHeader(title: LeadDetailStrings.publicContactDetails),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                LeadDetailStrings.noContactDetails,
                style: AppTypography.bodySm.copyWith(color: colors.textMuted),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Column(children: rows),
            ),
          if (lead.emails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                LeadDetailStrings.notVerifiedNote,
                style: AppTypography.bodySm.copyWith(color: colors.textMuted),
              ),
            )
          else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  /// A muted "Found on domain" line, only when the contact says where it came
  /// from — never a claim that the value was checked.
  List<Widget> _provenance(BuildContext context, String? foundOnUrl) {
    if (foundOnUrl == null || foundOnUrl.trim().isEmpty) {
      return const <Widget>[];
    }
    final String host = Uri.tryParse(foundOnUrl)?.host ?? '';
    if (host.isEmpty) {
      return const <Widget>[];
    }
    final AppColors colors = AppColors.of(context);
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(
          left: 44,
          right: AppSpacing.lg,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          '${LeadDetailStrings.foundOnPrefix} $host',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySm.copyWith(color: colors.textMuted),
        ),
      ),
    ];
  }
}

class _ProfilesCard extends StatelessWidget {
  const _ProfilesCard({required this.state, required this.onOpen});

  final LeadDetailState state;
  final Future<void> Function(LeadSource source) onOpen;

  @override
  Widget build(BuildContext context) {
    final Map<LeadSource, String> socials = state.socials;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: SectionHeader(
              title: LeadDetailStrings.profiles,
              trailing: ProBadge(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: <Widget>[
                for (final LeadSource source in socialProfileSources)
                  _ProfileRow(
                    source: source,
                    url: socials[source],
                    canView: state.canViewSocial,
                    onOpen: () => unawaited(onOpen(source)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.source,
    required this.url,
    required this.canView,
    required this.onOpen,
  });

  final LeadSource source;
  final String? url;
  final bool canView;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool found = url != null && url!.trim().isNotEmpty;
    final String detail;
    if (!found) {
      detail = LeadDetailStrings.notFound;
    } else if (!canView) {
      detail = LeadDetailStrings.profileFound;
    } else {
      detail = _handleOf(url!);
    }

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(_iconFor(source), size: 22, color: colors.textPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              source.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: found && canView
                  ? AppTypography.monoSm.copyWith(color: colors.textSecondary)
                  : AppTypography.bodySm.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (found)
            Icon(
              canView ? AppIcons.externalLink : AppIcons.lock,
              size: canView ? 20 : 18,
              color: colors.textMuted,
            ),
        ],
      ),
    );

    if (!found) {
      return row;
    }
    return Semantics(
      button: true,
      label: canView
          ? '${source.displayName}, ${LeadDetailStrings.openLinkTooltip}'
          : '${source.displayName}, ${LeadDetailStrings.lockedProLabel}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: row,
      ),
    );
  }

  static String _handleOf(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return url;
    }
    final String path = uri.path.replaceAll('/', '').trim();
    if (path.isNotEmpty) {
      return '@$path';
    }
    return uri.host.isNotEmpty ? uri.host : url;
  }

  static IconData _iconFor(LeadSource source) => switch (source) {
    LeadSource.instagram => AppIcons.instagram,
    LeadSource.linkedin => AppIcons.linkedin,
    LeadSource.facebook => AppIcons.facebook,
    LeadSource.x => AppIcons.x,
    _ => AppIcons.public,
  };
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> facts = <(String, String)>[
      if (lead.rating != null)
        (LeadDetailStrings.factRating, lead.rating!.toStringAsFixed(1)),
      if (lead.reviewCount != null)
        (LeadDetailStrings.factReviews, '${lead.reviewCount}'),
      if (lead.openingHours?.trim().isNotEmpty ?? false)
        (LeadDetailStrings.factHours, lead.openingHours!.trim()),
      if (lead.isOpenNow ?? false)
        (LeadDetailStrings.factStatus, LeadDetailStrings.openNow),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(title: LeadDetailStrings.businessDetails),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double tileWidth =
                  (constraints.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  for (final (String label, String value) in facts)
                    SizedBox(
                      width: tileWidth,
                      child: _FactTile(label: label, value: value),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.state,
    required this.noteController,
    required this.noteFocus,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onNoteChanged,
    required this.onStatusChanged,
    required this.onFollowUp,
  });

  final LeadDetailState state;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final Future<void> Function() onAddTag;
  final Future<void> Function(String tag) onRemoveTag;
  final ValueChanged<String> onNoteChanged;
  final Future<void> Function(LeadStatus status) onStatusChanged;
  final Future<void> Function() onFollowUp;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: LeadDetailStrings.myNotes,
            icon: AppIcons.lock,
            trailingText: LeadDetailStrings.onlyOnDevice,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final String tag in state.tags)
                _TagPill(tag: tag, onRemove: () => unawaited(onRemoveTag(tag))),
              ActionChip(
                avatar: Icon(AppIcons.add, size: 16, color: colors.textMuted),
                label: const Text(LeadDetailStrings.addTag),
                labelStyle: AppTypography.labelSm.copyWith(
                  color: colors.textSecondary,
                ),
                side: BorderSide(color: colors.border),
                backgroundColor: Colors.transparent,
                onPressed: () => unawaited(onAddTag()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NoteField(
            controller: noteController,
            focusNode: noteFocus,
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSegmentedControl<LeadStatus>(
            options: <AppSegmentOption<LeadStatus>>[
              for (final LeadStatus status in LeadStatus.values)
                AppSegmentOption<LeadStatus>(
                  value: status,
                  label: status.displayName,
                ),
            ],
            selected: state.status,
            onChanged: (LeadStatus status) =>
                unawaited(onStatusChanged(status)),
            style: AppSegmentedStyle.filled,
          ),
          const SizedBox(height: AppSpacing.md),
          _FollowUpRow(
            value: state.followUp,
            onTap: () => unawaited(onFollowUp()),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            tag,
            style: AppTypography.labelSm.copyWith(color: colors.textPrimary),
          ),
          Semantics(
            button: true,
            label: '${LeadDetailStrings.tagRemoveTooltip} $tag',
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(AppIcons.close, size: 14, color: colors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? _) {
        final bool showCounter =
            value.text.length > CrmRules.noteCounterThreshold;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          minLines: 3,
          maxLines: 6,
          maxLength: CrmRules.maxNoteLength,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: LeadDetailStrings.noteHint,
            hintStyle: AppTypography.bodyMd.copyWith(color: colors.textMuted),
            filled: true,
            fillColor: colors.cardSubtle,
            counterText: showCounter
                ? '${value.text.length}/${CrmRules.maxNoteLength}'
                : '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.textPrimary),
            ),
          ),
        );
      },
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  const _FollowUpRow({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);
    final String text = value == null
        ? LeadDetailStrings.followUpNotSet
        : '${l10n.formatMediumDate(value!)} · '
              '${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(value!))}';

    return Semantics(
      button: true,
      label: '${LeadDetailStrings.followUpDate}, $text',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.alarm, size: 20, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  LeadDetailStrings.followUpDate,
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySm.copyWith(
                    color: value == null
                        ? colors.textMuted
                        : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronRight, size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.isSaved,
    required this.onCopyAll,
    required this.onRemove,
  });

  final bool isSaved;
  final Future<void> Function() onCopyAll;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: LeadDetailStrings.copyAllDetails,
            icon: AppIcons.copyStack,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(onCopyAll()),
          ),
        ),
        if (isSaved) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: LeadDetailStrings.removeLead,
              icon: AppIcons.delete,
              variant: AppButtonVariant.secondary,
              onPressed: onRemove,
            ),
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// States
// -----------------------------------------------------------------------------

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.searchOff,
      title: LeadDetailStrings.notFoundTitle,
      body: LeadDetailStrings.notFoundBody,
      actionLabel: LeadDetailStrings.notFoundAction,
      onAction: onBack,
    );
  }
}

/// Hero, action row and one card as static blocks.
///
/// The pulse is decoration, so it stops entirely when the system asks for
/// reduced motion — the screen then shows the same blocks at a fixed opacity
/// instead of nothing at all.
class _LeadDetailSkeleton extends StatefulWidget {
  const _LeadDetailSkeleton();

  @override
  State<_LeadDetailSkeleton> createState() => _LeadDetailSkeletonState();
}

class _LeadDetailSkeletonState extends State<_LeadDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool animate = !MediaQuery.disableAnimationsOf(context);
    final Widget content = ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              _Block(
                width: 64,
                height: 64,
                radius: 16,
                color: colors.cardSubtle,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Block(width: 180, height: 18, color: colors.cardSubtle),
                    const SizedBox(height: AppSpacing.sm),
                    _Block(width: 120, height: 13, color: colors.cardSubtle),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              _Block(
                width: 52,
                height: 52,
                radius: AppRadius.tile,
                color: colors.cardSubtle,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Block(width: 160, height: 16, color: colors.cardSubtle),
              const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < 3; i++) ...<Widget>[
                _Block(
                  width: double.infinity,
                  height: 14,
                  color: colors.cardSubtle,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );

    if (!animate) {
      return Opacity(opacity: 0.6, child: content);
    }
    return Semantics(
      label: CommonStrings.loading,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) =>
            Opacity(opacity: 0.4 + _controller.value * 0.5, child: child),
        child: content,
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 6,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sheets
// -----------------------------------------------------------------------------

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
            ),
          ),
          for (final Widget child in children) child,
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small sheet that validates a tag before handing it back.
class _AddTagSheet extends StatefulWidget {
  const _AddTagSheet({
    required this.existing,
    required this.suggestions,
    required this.onAdd,
  });

  final List<String> existing;
  final List<String> suggestions;

  /// Validates and adds; returns the reason when refused.
  final Future<TagError?> Function(String raw) onAdd;

  @override
  State<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<_AddTagSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isBusy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isBusy) {
      return;
    }
    final String raw = _controller.text;
    final TagError? immediate = CrmRules.validateTag(
      raw,
      existing: widget.existing,
    );
    if (immediate != null) {
      setState(() => _error = _messageFor(immediate));
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final TagError? failure = await widget.onAdd(raw);
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop(raw);
      return;
    }
    setState(() {
      _isBusy = false;
      _error = _messageFor(failure);
    });
  }

  static String _messageFor(TagError error) => switch (error) {
    TagError.empty || TagError.tooShort => LeadDetailStrings.tagErrorEmpty,
    TagError.tooLong => LeadDetailStrings.tagErrorTooLong,
    TagError.tooManyTags => LeadDetailStrings.tagErrorLimit,
    TagError.duplicate => LeadDetailStrings.tagErrorDuplicate,
    TagError.invalidCharacters => LeadDetailStrings.tagErrorInvalid,
  };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final List<String> available = <String>[
      for (final String tag in widget.suggestions)
        if (!widget.existing.contains(tag)) tag,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LeadDetailStrings.addTagTitle,
            style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _controller,
            hintText: LeadDetailStrings.addTagHint,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_submit()),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
            ),
          ],
          if (available.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              LeadDetailStrings.addTagSuggestions,
              style: AppTypography.labelSm.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String tag in available.take(8))
                  AppChip(
                    label: tag,
                    size: AppChipSize.compact,
                    onTap: () => _controller.value = TextEditingValue(
                      text: tag,
                      selection: TextSelection.collapsed(offset: tag.length),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: LeadDetailStrings.addTagAction,
            isLoading: _isBusy,
            onPressed: () => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
