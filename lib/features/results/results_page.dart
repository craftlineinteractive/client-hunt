import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/ads/ad_coordinator.dart';
import '../../domain/ads/ad_policy.dart';
import '../../domain/entitlements/entitlements.dart';
import '../../domain/entitlements/feature_gate.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/contact_launcher.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../domain/results/contact_rules.dart';
import '../../domain/results/results_filter.dart';
import '../../shared/widgets/app_checkbox.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_icon_button.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/info_note.dart';
import '../../shared/widgets/lead_card.dart';
import '../../shared/widgets/mono_text.dart';
import '../../shared/widgets/stats_strip.dart';
import 'results_controller.dart';
import 'results_state.dart';
import 'widgets/results_progress.dart';

/// **Search results** (`/results`).
///
/// A pushed screen driven entirely by the engine's event stream: no networking,
/// no storage and no ads SDK. It owns the quota and history rule through
/// [ResultsController], shows search progress, partial results, empty and error
/// states, filters and sorts the list locally, and hands selected ids to Export
/// or a lead id to Lead Detail.
///
/// If the route is restored without a [SearchRequest] (Android process death, a
/// deep link) the screen shows a safe fallback rather than throwing.
class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({this.request, super.key});

  /// The request Home validated and passed as the route extra.
  final SearchRequest? request;

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  StreamSubscription<ResultsUiEvent>? _eventSubscription;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// Set when the controller asks for an interstitial; consumed by the back
  /// handler *after* the pop, so the ad never covers the screen being left.
  bool _adBreakPending = false;

  SearchRequest get _request => widget.request!;

  ResultsController get _controller =>
      ref.read(resultsControllerProvider(_request).notifier);

  ResultsState get _state => ref.read(resultsControllerProvider(_request));

  @override
  void initState() {
    super.initState();
    final SearchRequest? request = widget.request;
    if (request == null) {
      return;
    }
    // The controller is auto-disposed, so it must be created by the first build
    // (`ref.watch`) rather than here: a read before any listener would be torn
    // down at the end of the frame and the search would start twice. Subscribe
    // to its events once that first build has happened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _eventSubscription ??= ref
          .read(resultsControllerProvider(request).notifier)
          .events
          .listen(_onUiEvent);
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUiEvent(ResultsUiEvent event) {
    if (!mounted) {
      return;
    }
    switch (event) {
      case ResultsMessage(:final String text):
        _showSnack(text);
      case ResultsOpenPro(:final String reason):
        AppNavigator.openPro(context, reason: reason);
      case ResultsAdBreak():
        _adBreakPending = true;
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------------------------------------------------------------------------
  // Leaving
  // ---------------------------------------------------------------------------

  /// Back, system back and the app-bar arrow all land here.
  ///
  /// While a search runs the run is cancelled silently: no snackbar, no ad.
  /// Otherwise the controller records the completed action and asks for an
  /// interstitial, which is shown **after** the pop using the root container so
  /// the disposed screen is not touched.
  Future<void> _handleClose() async {
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final bool wasRunning = _state.isRunning;
    _adBreakPending = false;
    // The return value is authoritative: the event stream is asynchronous, so a
    // listener cannot answer the "may I show an ad?" question before the pop.
    final bool wantsAd = _controller.leave() || _adBreakPending;
    _adBreakPending = false;

    if (mounted) {
      Navigator.of(context).pop();
    }
    if (wasRunning || !wantsAd) {
      return;
    }
    final AdCoordinator coordinator = container.read(adCoordinatorProvider);
    await coordinator.maybeShowInterstitial(AdTrigger.resultsClosed);
  }

  /// Cancel: stop the run and go back without an ad.
  Future<void> _handleCancelSearch() async {
    await _controller.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Header actions
  // ---------------------------------------------------------------------------

  void _openSearchMode() {
    _controller.setSearchMode(true);
    _searchFocus.requestFocus();
  }

  void _closeSearchMode() {
    _searchController.clear();
    _controller
      ..setSearchMode(false)
      ..clearQuery();
    _searchFocus.unfocus();
  }

  Future<void> _openFilters() async {
    final SearchFilters? updated = await AppNavigator.openFilters(
      context,
      initial: _state.activeFilters,
    );
    if (!mounted || updated == null) {
      return;
    }
    _controller.applyFilters(updated);
  }

  Future<void> _showSortSheet() async {
    final SortOption? selected = await showModalBottomSheet<SortOption>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _Sheet(
        title: ResultsStrings.sortBy,
        children: <Widget>[
          for (final SortOption option in ResultsSort.menuOptions)
            _SheetRow(
              label: _sortLabel(option),
              isSelected: option == _state.sort,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
    if (selected != null && mounted) {
      _controller.setSort(selected);
    }
  }

  Future<void> _showMoreSheet() async {
    final _MoreAction? action = await showModalBottomSheet<_MoreAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _Sheet(
        title: _state.request.query.displayTitle,
        children: <Widget>[
          _SheetRow(
            label: ResultsStrings.sortBy,
            icon: AppIcons.sort,
            onTap: () => Navigator.of(context).pop(_MoreAction.sort),
          ),
          _SheetRow(
            label: CommonStrings.selectAll,
            icon: AppIcons.checkbox,
            onTap: () => Navigator.of(context).pop(_MoreAction.selectAll),
          ),
          _SheetRow(
            label: ResultsStrings.export,
            icon: AppIcons.download,
            isEnabled: _canExport(_state),
            onTap: () => Navigator.of(context).pop(_MoreAction.export),
          ),
          _SheetRow(
            label: ResultsStrings.searchAgain,
            icon: AppIcons.refresh,
            onTap: () => Navigator.of(context).pop(_MoreAction.searchAgain),
          ),
        ],
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _MoreAction.sort:
        await _showSortSheet();
      case _MoreAction.selectAll:
        _controller.selectAllVisible();
      case _MoreAction.export:
        _exportLeads();
      case _MoreAction.searchAgain:
        _controller.retry();
    }
  }

  Future<void> _showCopySheet() async {
    final ResultsState state = _state;
    final List<Lead> leads = state.hasSelection
        ? state.selectedLeads
        : state.visibleLeads;
    final List<String> emails = <String>[
      for (final Lead lead in leads)
        if (lead.hasEmail) lead.primaryEmail!.value,
    ];
    final List<String> phones = <String>[
      for (final Lead lead in leads)
        if (lead.hasPhone) lead.primaryPhone!.value,
    ];

    final _CopyKind? choice = await showModalBottomSheet<_CopyKind>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _Sheet(
        title: ResultsStrings.copyAllTooltip,
        children: <Widget>[
          _SheetRow(
            label: ResultsStrings.copyEmails(emails.length),
            icon: AppIcons.email,
            isEnabled: emails.isNotEmpty,
            onTap: () => Navigator.of(context).pop(_CopyKind.emails),
          ),
          _SheetRow(
            label: ResultsStrings.copyPhones(phones.length),
            icon: AppIcons.phone,
            isEnabled: phones.isNotEmpty,
            onTap: () => Navigator.of(context).pop(_CopyKind.phones),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    final List<String> values = choice == _CopyKind.emails ? emails : phones;
    if (values.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: values.join('\n')));
    if (!mounted) {
      return;
    }
    _showSnack(
      choice == _CopyKind.emails
          ? ResultsStrings.copiedEmailsToast
          : ResultsStrings.copiedPhonesToast,
    );
  }

  void _exportLeads() {
    final ResultsState state = _state;
    final List<Lead> leads = state.hasSelection
        ? state.selectedLeads
        : state.visibleLeads;
    if (leads.isEmpty) {
      return;
    }
    AppNavigator.openExport(
      context,
      args: ExportArgs(
        title: state.request.query.displayTitle,
        leadIds: <String>[for (final Lead lead in leads) lead.id],
        scope: state.hasSelection
            ? ExportScope.selectedOnly
            : ExportScope.allLeads,
        resultCount: state.totalCount,
        withEmail: state.withEmailCount,
        withPhone: state.withPhoneCount,
      ),
    );
  }

  Future<void> _showSourceDetails() async {
    final ResultsState state = _state;
    final Map<LeadSource, SourceStatus> statuses = <LeadSource, SourceStatus>{
      for (final LeadSource source in state.sources)
        source:
            state.sourceStatuses[source] ??
            state.summary?.perSource[source]?.status ??
            SourceStatus.pending,
    };
    final String body = statuses.entries
        .map(
          (MapEntry<LeadSource, SourceStatus> entry) =>
              '${entry.key.displayName}: ${sourceStatusVisual(entry.value).$2}',
        )
        .join('\n');
    await showAppDialog(
      context,
      title: ResultsStrings.sourceDetailsTitle,
      body: body.isEmpty ? ResultsStrings.sourceDetailsBody : body,
      actions: const <AppDialogAction>[
        AppDialogAction(
          label: CommonStrings.done,
          style: AppDialogActionStyle.primary,
          value: 'done',
        ),
      ],
    );
  }

  bool _canExport(ResultsState state) =>
      !state.isRunning && state.leads.isNotEmpty;

  String _sortLabel(SortOption option) {
    return switch (option) {
      SortOption.relevance => ResultsStrings.sortRelevance,
      SortOption.rating => ResultsStrings.sortRating,
      SortOption.reviews => ResultsStrings.sortReviews,
      SortOption.name => ResultsStrings.sortNameAZ,
      SortOption.newest => ResultsStrings.sortNewest,
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final SearchRequest? request = widget.request;
    if (request == null) {
      return const _MissingRequestScaffold();
    }

    final ResultsState state = ref.watch(resultsControllerProvider(request));
    final Entitlements entitlements = ref
        .watch(featureGateProvider)
        .entitlements;
    // Filtering and sorting once per frame, not once per widget that needs it.
    final List<Lead> visible = state.visibleLeads;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        unawaited(_handleClose());
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).canvas,
        appBar: _buildAppBar(context, state),
        body: _buildBody(context, state, entitlements, visible),
        bottomNavigationBar: _buildBottomBar(context, state, visible),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ResultsState state) {
    final AppColors colors = AppColors.of(context);

    if (state.isSearchMode) {
      return AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: ResultsStrings.closeSearchTooltip,
          onPressed: _closeSearchMode,
        ),
        titleSpacing: 0,
        title: TextField(
          key: const Key('results-search-field'),
          controller: _searchController,
          focusNode: _searchFocus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
          cursorColor: colors.textPrimary,
          decoration: InputDecoration(
            hintText: ResultsStrings.searchHint,
            hintStyle: AppTypography.titleSm.copyWith(color: colors.textMuted),
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (String value) => _controller.setQuery(value),
        ),
        actions: <Widget>[
          if (state.filter.hasText)
            IconButton(
              icon: const Icon(AppIcons.close),
              tooltip: ResultsStrings.clearSearchTooltip,
              onPressed: () {
                _searchController.clear();
                _controller.clearQuery();
              },
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      );
    }

    return AppTopBar.pushed(
      title: state.request.query.displayTitle,
      subtitle: _subtitle(state),
      onLeading: () => unawaited(_handleClose()),
      actions: <Widget>[
        AppIconButton(
          key: const Key('results-search-toggle'),
          icon: AppIcons.search,
          tooltip: ResultsStrings.searchInResults,
          onPressed: _openSearchMode,
        ),
        AppIconButton(
          key: const Key('results-more'),
          icon: AppIcons.more,
          tooltip: CommonStrings.moreTooltip,
          onPressed: () => unawaited(_showMoreSheet()),
        ),
      ],
    );
  }

  String _subtitle(ResultsState state) {
    if (state.isRunning) {
      return ResultsStrings.searchingEllipsis;
    }
    final List<LeadSource> sources = state.sources.isEmpty
        ? state.request.query.sources.toList()
        : state.sources;
    final String names = sources
        .map((LeadSource source) => source.displayName)
        .join(' · ');
    final String leads = ResultsStrings.leadsCount(state.totalCount);
    return names.isEmpty ? leads : '$leads · $names';
  }

  Widget _buildBody(
    BuildContext context,
    ResultsState state,
    Entitlements entitlements,
    List<Lead> visible,
  ) {
    final bool isFirstLoad = state.isRunning && state.leads.isEmpty;
    final bool isEngineEmpty = state.phase == ResultsPhase.empty;
    final bool isFatalError =
        state.phase == ResultsPhase.failed && state.leads.isEmpty;
    final bool isLocallyEmpty = state.leads.isNotEmpty && visible.isEmpty;

    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _buildHeader(context, state, entitlements, visible),
        ),
        if (state.isRunning && state.leads.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: ResultsProgressHeaderDelegate(
              stage: state.stage,
              foundSoFar: state.foundSoFar,
            ),
          ),
        if (isFirstLoad) ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: ResultsProgressCard(
                stage: state.stage,
                sources: state.sources,
                statuses: state.sourceStatuses,
                foundSoFar: state.foundSoFar,
                onCancel: () => unawaited(_handleCancelSearch()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            sliver: SliverList.builder(
              itemCount: 4,
              itemBuilder: (BuildContext context, int index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: ResultsSkeletonCard(),
              ),
            ),
          ),
        ] else if (isEngineEmpty)
          SliverToBoxAdapter(child: _buildEngineEmpty(context))
        else if (isFatalError)
          SliverToBoxAdapter(child: _buildErrorState(state))
        else if (isLocallyEmpty)
          SliverToBoxAdapter(child: _buildLocalEmpty(context))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int index) {
                final Lead lead = visible[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ResultLeadCard(
                    key: ValueKey<String>(lead.id),
                    request: _request,
                    lead: lead,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ResultsState state,
    Entitlements entitlements,
    List<Lead> visible,
  ) {
    final bool showCapNote =
        !entitlements.isPro &&
        state.totalCount == entitlements.maxResultsPerSearch &&
        state.phase == ResultsPhase.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StatsStrip(
                items: <StatItem>[
                  StatItem(
                    icon: AppIcons.group,
                    value: '${state.totalCount}',
                    label: ResultsStrings.statsLeads,
                  ),
                  StatItem(
                    icon: AppIcons.email,
                    value: '${state.withEmailCount}',
                    label: ResultsStrings.statsEmails,
                  ),
                  StatItem(
                    icon: AppIcons.phone,
                    value: '${state.withPhoneCount}',
                    label: ResultsStrings.statsPhones,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!state.isNoteDismissed)
                InfoNote(
                  key: const Key('results-unverified-note'),
                  text: ResultsStrings.unverifiedNotice,
                  onDismiss: _controller.dismissNote,
                ),
              if (showCapNote)
                InfoNote(
                  key: const Key('results-cap-note'),
                  text: ResultsStrings.capNote(
                    entitlements.maxResultsPerSearch,
                    proEntitlements.maxResultsPerSearch,
                  ),
                  actionLabel: ResultsStrings.goPro,
                  onAction: () => AppNavigator.openPro(
                    context,
                    reason: LockReason.maxResultsRequiresPro.name,
                  ),
                ),
              if (state.hasSourceProblem)
                InfoNote(
                  key: const Key('results-source-note'),
                  icon: AppIcons.warning,
                  text: ResultsStrings.partialSourcesNote,
                  actionLabel: ResultsStrings.detailsAction,
                  onAction: () => unawaited(_showSourceDetails()),
                ),
              if (state.filtersChanged)
                InfoNote(
                  key: const Key('results-filter-note'),
                  text: ResultsStrings.filtersChangedNote,
                  actionLabel: ResultsStrings.searchAgain,
                  onAction: _controller.retry,
                ),
              if (state.phase == ResultsPhase.failed && state.leads.isNotEmpty)
                InfoNote(
                  key: const Key('results-error-note'),
                  icon: AppIcons.warning,
                  text: state.error?.message ?? CommonStrings.genericErrorBody,
                  actionLabel: CommonStrings.retry,
                  onAction: _controller.retry,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildChips(context, state),
        _buildSelectRow(context, state, visible),
      ],
    );
  }

  Widget _buildChips(BuildContext context, ResultsState state) {
    const List<(ResultsChip, String)> chips = <(ResultsChip, String)>[
      (ResultsChip.all, ResultsStrings.filterAll),
      (ResultsChip.email, ResultsStrings.filterEmail),
      (ResultsChip.phone, ResultsStrings.filterPhone),
      (ResultsChip.website, ResultsStrings.filterWebsite),
      (ResultsChip.whatsApp, ResultsStrings.filterWhatsApp),
      (ResultsChip.rating4Plus, ResultsStrings.filterRating4),
      (ResultsChip.saved, ResultsStrings.filterSaved),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const Key('results-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: chips.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final (ResultsChip chip, String label) = chips[index];
          return AppChip(
            label: label,
            isSelected: state.filter.chip == chip,
            onTap: () => _controller.setChip(chip),
          );
        },
      ),
    );
  }

  Widget _buildSelectRow(
    BuildContext context,
    ResultsState state,
    List<Lead> visible,
  ) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          AppCheckbox(
            key: const Key('results-select-all'),
            value: state.allVisibleSelected,
            onChanged: visible.isEmpty
                ? null
                : (bool _) => _controller.selectAllVisible(),
            semanticLabel: ResultsStrings.selectAll,
          ),
          Expanded(
            child: Text(
              ResultsStrings.selectAll,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (state.hasSelection)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                ResultsStrings.selectedCount(state.selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTypography.monoSm.copyWith(color: colors.textMuted),
              ),
            ),
          AppIconButton(
            key: const Key('results-sort-button'),
            icon: AppIcons.sort,
            tooltip: ResultsStrings.sortBy,
            onPressed: () => unawaited(_showSortSheet()),
          ),
          AppIconButton(
            key: const Key('results-filters-button'),
            icon: AppIcons.filters,
            tooltip: CommonStrings.filtersTooltip,
            onPressed: () => unawaited(_openFilters()),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineEmpty(BuildContext context) {
    final bool hasFilters = _state.isFiltered;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: EmptyState(
        key: const Key('results-empty'),
        icon: AppIcons.searchOff,
        title: ResultsStrings.emptyTitle,
        body: ResultsStrings.emptyBody,
        actionLabel: ResultsStrings.emptyAction,
        onAction: () => unawaited(_handleClose()),
        secondaryActionLabel: hasFilters ? ResultsStrings.clearFilters : null,
        onSecondaryAction: hasFilters
            ? () {
                _controller.clearLocalFilters();
                _controller.applyFilters(const SearchFilters());
              }
            : null,
      ),
    );
  }

  Widget _buildLocalEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: EmptyState(
        key: const Key('results-local-empty'),
        icon: AppIcons.filters,
        title: ResultsStrings.localEmptyTitle,
        body: ResultsStrings.localEmptyBody,
        actionLabel: ResultsStrings.clearFilters,
        onAction: () {
          _searchController.clear();
          _controller.clearLocalFilters();
          _controller.applyFilters(const SearchFilters());
        },
      ),
    );
  }

  Widget _buildErrorState(ResultsState state) {
    final SearchError? error = state.error;
    final (IconData icon, String title, String body) = switch (error?.type) {
      SearchErrorType.noNetwork => (
        AppIcons.noNetwork,
        CommonStrings.noNetworkTitle,
        CommonStrings.noNetworkBody,
      ),
      SearchErrorType.rateLimited => (
        AppIcons.hourglass,
        ResultsStrings.rateLimitedTitle,
        ResultsStrings.rateLimitedBody,
      ),
      SearchErrorType.sourceBlocked => (
        AppIcons.block,
        ResultsStrings.sourceBlockedTitle,
        ResultsStrings.sourceBlockedBody,
      ),
      SearchErrorType.cancelled => (
        AppIcons.stop,
        ResultsStrings.cancelledTitle,
        ResultsStrings.cancelledBody,
      ),
      _ => (
        AppIcons.warning,
        CommonStrings.genericErrorTitle,
        CommonStrings.genericErrorBody,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: EmptyState(
        key: const Key('results-error'),
        icon: icon,
        title: title,
        body: body,
        actionLabel: CommonStrings.retry,
        onAction: _controller.retry,
        secondaryActionLabel: ResultsStrings.emptyAction,
        onSecondaryAction: () => unawaited(_handleClose()),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ResultsState state,
    List<Lead> visible,
  ) {
    final bool hidden =
        state.phase == ResultsPhase.empty ||
        state.phase == ResultsPhase.cancelled ||
        (state.phase == ResultsPhase.failed && state.leads.isEmpty);
    if (hidden) {
      return const SizedBox.shrink();
    }

    final bool isEnabled = _canExport(state);
    final int count = state.hasSelection ? state.selectedCount : visible.length;

    return BottomActionBar(
      primaryLabel: ResultsStrings.exportLeads,
      primaryIcon: AppIcons.download,
      onPrimary: isEnabled && count > 0 ? _exportLeads : null,
      isSecondaryTrailing: true,
      secondaryIcon: AppIcons.copy,
      secondaryTooltip: ResultsStrings.copyAllTooltip,
      onSecondary: isEnabled && count > 0
          ? () => unawaited(_showCopySheet())
          : null,
      trailing: _CountPill(count: count),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

enum _MoreAction { sort, selectAll, export, searchAgain }

enum _CopyKind { emails, phones }

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      key: const Key('results-export-count'),
      height: 32,
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: MonoText('$count', style: AppTypography.monoSm),
    );
  }
}

/// The sheet shell used by sort, more and copy: a title and 52 px rows.
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
            ),
          ),
          ...children,
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: label,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.4,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        color: colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(AppIcons.check, size: 20, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One result card.
///
/// A [ConsumerWidget] so a selection or bookmark change rebuilds only the card it
/// affects: the two `select`s are the per-item subscriptions that keep the rest of
/// the list untouched.
class _ResultLeadCard extends ConsumerWidget {
  const _ResultLeadCard({required this.request, required this.lead, super.key});

  final SearchRequest request;
  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelected = ref.watch(
      resultsControllerProvider(
        request,
      ).select((ResultsState state) => state.selectedIds.contains(lead.id)),
    );
    final bool isSaved = ref.watch(
      resultsControllerProvider(request).select(
        (ResultsState state) =>
            state.savedIds.contains(lead.id) || lead.isSaved,
      ),
    );
    final Lead shown = isSaved == lead.isSaved
        ? lead
        : lead.copyWith(isSaved: isSaved);
    final ResultsController controller = ref.read(
      resultsControllerProvider(request).notifier,
    );
    final PhoneContact? phone = ContactRules.primaryPhone(lead);
    final EmailContact? email = ContactRules.primaryEmail(lead);
    final PhoneContact? whatsAppPhone = ContactRules.whatsAppPhone(lead);

    return LeadCard(
      lead: shown,
      isSelected: isSelected,
      showCheckbox: true,
      onCheckbox: (bool _) => controller.toggleSelect(lead.id),
      onTap: () => AppNavigator.goToLead(context, lead.id),
      onBookmark: () => controller.toggleSave(shown),
      actions: <LeadCardAction>[
        LeadCardAction(
          icon: AppIcons.phone,
          label: ResultsStrings.callTooltip,
          onPressed: ContactRules.canCall(lead)
              ? () => _launch(context, ref, _ContactAction.call(phone!.value))
              : null,
        ),
        LeadCardAction(
          icon: AppIcons.whatsapp,
          label: ResultsStrings.whatsAppTooltip,
          onPressed: ContactRules.canWhatsApp(lead)
              ? () => _launch(
                  context,
                  ref,
                  _ContactAction.whatsApp(whatsAppPhone!.value),
                )
              : null,
        ),
        LeadCardAction(
          icon: AppIcons.email,
          label: ResultsStrings.emailTooltip,
          onPressed: ContactRules.canEmail(lead)
              ? () => _launch(context, ref, _ContactAction.email(email!.value))
              : null,
        ),
        LeadCardAction(
          icon: AppIcons.copy,
          label: ResultsStrings.copyContactTooltip,
          onPressed: ContactRules.canCopy(lead)
              ? () => _copyContact(context, ref)
              : null,
        ),
      ],
    );
  }

  Future<void> _launch(
    BuildContext context,
    WidgetRef ref,
    _ContactAction action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ContactLauncher launcher = ref.read(contactLauncherProvider);
    final ContactLaunchResult result = await action.run(launcher);
    if (result == ContactLaunchResult.launched) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == ContactLaunchResult.unavailable
                ? ResultsStrings.contactUnavailable
                : ResultsStrings.contactFailed,
          ),
        ),
      );
  }

  Future<void> _copyContact(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<String> values = <String>[
      if (lead.primaryPhone != null) lead.primaryPhone!.value,
      if (lead.primaryEmail != null) lead.primaryEmail!.value,
    ];
    if (values.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(ResultsStrings.nothingToCopy)),
        );
      return;
    }
    await Clipboard.setData(ClipboardData(text: values.join('\n')));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(ResultsStrings.copiedToast)));
  }
}

/// A contact action with its target, so the card does not repeat the call shape.
sealed class _ContactAction {
  const _ContactAction();

  const factory _ContactAction.call(String phone) = _CallAction;
  const factory _ContactAction.whatsApp(String phone) = _WhatsAppAction;
  const factory _ContactAction.email(String address) = _EmailAction;

  Future<ContactLaunchResult> run(ContactLauncher launcher);
}

final class _CallAction extends _ContactAction {
  const _CallAction(this.phone);

  final String phone;

  @override
  Future<ContactLaunchResult> run(ContactLauncher launcher) =>
      launcher.call(phone);
}

final class _WhatsAppAction extends _ContactAction {
  const _WhatsAppAction(this.phone);

  final String phone;

  @override
  Future<ContactLaunchResult> run(ContactLauncher launcher) =>
      launcher.whatsApp(phone);
}

final class _EmailAction extends _ContactAction {
  const _EmailAction(this.address);

  final String address;

  @override
  Future<ContactLaunchResult> run(ContactLauncher launcher) =>
      launcher.email(address);
}

/// Shown when the route has no `SearchRequest` (restored route, deep link).
class _MissingRequestScaffold extends StatelessWidget {
  const _MissingRequestScaffold();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: const AppTopBar.pushed(title: ResultsStrings.title),
      body: Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: AppIcons.searchOff,
            title: ResultsStrings.missingRequestTitle,
            body: ResultsStrings.missingRequestBody,
            actionLabel: ResultsStrings.backToSearch,
            onAction: () => AppNavigator.goToTab(context, AppRoutes.search),
          ),
        ),
      ),
    );
  }
}
