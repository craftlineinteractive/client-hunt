import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/relative_time.dart';
import '../../domain/catalogs/city_catalog.dart';
import '../../domain/catalogs/niche_catalog.dart';
import '../../domain/entitlements/entitlements.dart';
import '../../domain/entitlements/feature_gate.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../shared/widgets/shared.dart';
import 'home_controller.dart';
import 'home_state.dart';

/// **Search (Home) — the first tab.**
///
/// A form, not a search: niche + city + sources + filters become a
/// [SearchRequest], the quota is *checked*, and a Free user confirms a rewarded
/// ad before Results opens. Nothing is consumed and no history is written here
/// (B2 owns both, only after a search returns leads).
///
/// Layout follows `home_screen` top to bottom, minus the mockup's ad block, which
/// the product does not have (README section 3.9). All copy lives in
/// `app_strings.dart`; every color comes from `AppColors`.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _niche = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final FocusNode _nicheFocus = FocusNode(debugLabel: 'home-niche');
  final FocusNode _cityFocus = FocusNode(debugLabel: 'home-city');
  final LayerLink _nicheLink = LayerLink();
  final LayerLink _cityLink = LayerLink();
  final GlobalKey _fieldsKey = GlobalKey(debugLabel: 'home-fields');
  final ScrollController _scroll = ScrollController();

  OverlayEntry? _suggestions;
  bool _nicheTouched = false;
  bool _cityTouched = false;

  @override
  void initState() {
    super.initState();
    _nicheFocus.addListener(_handleFocusChange);
    _cityFocus.addListener(_handleFocusChange);
    _scroll.addListener(_removeSuggestions);
    // Warm the rewarded ad so the next Find Leads tap does not wait on a load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adCoordinatorProvider).preloadRewarded();
      }
    });
  }

  @override
  void dispose() {
    _removeSuggestions();
    _nicheFocus.removeListener(_handleFocusChange);
    _cityFocus.removeListener(_handleFocusChange);
    _scroll.dispose();
    _niche.dispose();
    _city.dispose();
    _nicheFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Field focus, typeahead and validation
  // ---------------------------------------------------------------------------

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }
    if (!_nicheFocus.hasFocus && _niche.text.isNotEmpty) {
      _nicheTouched = true;
    }
    if (!_cityFocus.hasFocus && _city.text.isNotEmpty) {
      _cityTouched = true;
    }
    if (_nicheFocus.hasFocus || _cityFocus.hasFocus) {
      _refreshSuggestions();
    } else {
      _removeSuggestions();
    }
    setState(() {});
  }

  void _refreshSuggestions() {
    final bool isNiche = _nicheFocus.hasFocus;
    final String query = isNiche ? _niche.text : _city.text;
    if (query.trim().isEmpty) {
      _removeSuggestions();
      return;
    }
    final List<_Suggestion> items = isNiche
        ? <_Suggestion>[
            for (final Niche niche in NicheCatalog.suggest(query))
              _Suggestion(label: niche.name),
          ]
        : <_Suggestion>[
            for (final City city in CityCatalog.suggest(query))
              _Suggestion(label: city.name, detail: city.state),
          ];
    if (items.isEmpty) {
      _removeSuggestions();
      return;
    }
    _insertSuggestions(items, isNiche: isNiche);
  }

  void _insertSuggestions(List<_Suggestion> items, {required bool isNiche}) {
    _removeSuggestions();
    final RenderBox? box =
        _fieldsKey.currentContext?.findRenderObject() as RenderBox?;
    final double width =
        box?.size.width ?? MediaQuery.sizeOf(context).width - AppSpacing.xxl;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        final AppColors colors = AppColors.of(overlayContext);
        return Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: isNiche ? _nicheLink : _cityLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: SizedBox(
              width: width,
              child: Material(
                key: const Key('home-suggestions'),
                color: colors.card,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                  side: BorderSide(color: colors.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 232),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final _Suggestion item = items[index];
                      return InkWell(
                        onTap: () => _applySuggestion(item.label, isNiche),
                        child: SizedBox(
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  isNiche ? AppIcons.niche : AppIcons.location,
                                  size: 18,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (item.detail != null)
                                  Text(
                                    item.detail!,
                                    style: AppTypography.bodySm.copyWith(
                                      color: colors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
    _suggestions = entry;
  }

  void _removeSuggestions() {
    _suggestions?.remove();
    _suggestions = null;
  }

  void _applySuggestion(String value, bool isNiche) {
    ref
        .read(homeControllerProvider.notifier)
        .applySuggestion(value, isNiche: isNiche);
    if (isNiche) {
      _nicheFocus.unfocus();
      _cityFocus.requestFocus();
    } else {
      _cityFocus.unfocus();
      FocusScope.of(context).unfocus();
    }
    _removeSuggestions();
    setState(() {});
  }

  void _syncField(
    TextEditingController controller,
    String? previous,
    String next,
  ) {
    if (previous == next || controller.text == next) {
      return;
    }
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onFindLeads() async {
    FocusScope.of(context).unfocus();
    _removeSuggestions();
    final HomeSubmitResult result = await ref
        .read(homeControllerProvider.notifier)
        .start();
    await _handleSubmit(result);
  }

  Future<void> _handleSubmit(HomeSubmitResult result) async {
    if (!mounted) {
      return;
    }
    switch (result.stage) {
      case HomeSubmitStage.invalid:
      case HomeSubmitStage.inFlight:
      case HomeSubmitStage.cancelled:
        return;
      case HomeSubmitStage.quotaExhausted:
        ref.read(homeControllerProvider.notifier).cancelSubmission();
        await AppNavigator.openPro(
          context,
          reason: LockReason.dailySearchLimitReached.name,
        );
      case HomeSubmitStage.needsRewardedPrompt:
        await _showRewardedDialog();
      case HomeSubmitStage.ready:
        final SearchRequest? request = result.request;
        if (request != null) {
          await AppNavigator.goToResults(context, request: request);
        }
    }
  }

  Future<void> _showRewardedDialog() async {
    final Object? choice = await showAppDialog(
      context,
      title: AdsStrings.rewardedTitle,
      body: AdsStrings.rewardedBody,
      actions: const <AppDialogAction>[
        AppDialogAction(
          label: AdsStrings.rewardedWatch,
          style: AppDialogActionStyle.primary,
          value: _RewardedChoice.watch,
        ),
        AppDialogAction(
          label: AdsStrings.rewardedGoPro,
          value: _RewardedChoice.goPro,
        ),
        AppDialogAction(
          label: CommonStrings.cancel,
          style: AppDialogActionStyle.ghost,
          value: _RewardedChoice.cancel,
        ),
      ],
    );
    if (!mounted) {
      return;
    }

    final HomeController controller = ref.read(homeControllerProvider.notifier);
    switch (choice) {
      case _RewardedChoice.watch:
        final HomeSubmitResult result = await controller.confirmRewarded();
        if (!mounted) {
          return;
        }
        if (result.stage == HomeSubmitStage.cancelled) {
          _showSnack(AdsStrings.rewardedDismissed);
        }
        await _handleSubmit(result);
      case _RewardedChoice.goPro:
        controller.cancelSubmission();
        await AppNavigator.openPro(
          context,
          reason: LockReason.adFreeRequiresPro.name,
        );
      default:
        controller.cancelSubmission();
    }
  }

  Future<void> _onUseLocation() async {
    FocusScope.of(context).unfocus();
    final HomeLocationOutcome outcome = await ref
        .read(homeControllerProvider.notifier)
        .useCurrentLocation();
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case HomeLocationOutcome.found:
      case HomeLocationOutcome.busy:
        return;
      case HomeLocationOutcome.denied:
        _showSnack(HomeStrings.locationDenied);
      case HomeLocationOutcome.unavailable:
        _showSnack(HomeStrings.locationUnavailable);
    }
  }

  Future<void> _onSourceTap(LeadSource source) async {
    final SourceToggleResult result = ref
        .read(homeControllerProvider.notifier)
        .toggleSource(source);
    switch (result) {
      case SourceToggleResult.locked:
        await AppNavigator.openPro(
          context,
          reason: LockReason.sourceRequiresPro.name,
        );
      case SourceToggleResult.lastSelected:
        _showSnack(HomeStrings.lastSourceRequired);
      case SourceToggleResult.selected:
      case SourceToggleResult.deselected:
        return;
    }
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final SearchFilters? filters = await AppNavigator.openFilters(
      context,
      initial: ref.read(homeControllerProvider).filters,
    );
    if (filters != null && mounted) {
      ref.read(homeControllerProvider.notifier).applyFilters(filters);
    }
  }

  Future<void> _confirmClearRecent() async {
    final Object? choice = await showAppDialog(
      context,
      title: HomeStrings.clearRecentTitle,
      body: HomeStrings.clearRecentBody,
      actions: const <AppDialogAction>[
        AppDialogAction(
          label: CommonStrings.cancel,
          style: AppDialogActionStyle.ghost,
        ),
        AppDialogAction(
          label: HomeStrings.clearRecentConfirm,
          style: AppDialogActionStyle.primary,
          value: true,
        ),
      ],
    );
    if (choice != true || !mounted) {
      return;
    }
    await ref.read(homeControllerProvider.notifier).clearRecent();
    if (mounted) {
      _showSnack(HomeStrings.clearRecentToast);
    }
  }

  Future<void> _onRecentTap(SearchHistoryEntry entry) async {
    FocusScope.of(context).unfocus();
    _removeSuggestions();
    final HomeSubmitResult result = await ref
        .read(homeControllerProvider.notifier)
        .rerun(entry);
    await _handleSubmit(result);
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<HomeState>(homeControllerProvider, (
      HomeState? previous,
      HomeState next,
    ) {
      _syncField(_niche, previous?.niche, next.niche);
      _syncField(_city, previous?.location, next.location);
    });

    final AppColors colors = AppColors.of(context);
    final HomeState state = ref.watch(homeControllerProvider);
    final FeatureGate gate = ref.watch(featureGateProvider);
    final int? remaining = ref.watch(remainingSearchesProvider).value;
    final HomeQuotaStatus quota = ref
        .watch(homeControllerProvider.notifier)
        .quotaStatus(remaining);
    final List<SearchHistoryEntry> recent =
        ref.watch(recentSearchesProvider).value ?? const <SearchHistoryEntry>[];
    final bool exhausted = quota == HomeQuotaStatus.exhausted;
    final bool showNicheError =
        _nicheTouched && _niche.text.isNotEmpty && state.nicheIssue != null;
    final bool showCityError =
        _cityTouched && _city.text.isNotEmpty && state.locationIssue != null;

    return Scaffold(
      appBar: AppTopBar.tab(
        title: AppStrings.wordmark,
        showWordmark: true,
        actions: <Widget>[
          _ProPill(isPro: gate.entitlements.isPro),
          AppIconButton(
            icon: AppIcons.settings,
            tooltip: CommonStrings.settingsTab,
            onPressed: () => AppNavigator.goToTab(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _headlineRow(quota: quota, remaining: remaining),
              const SizedBox(height: AppSpacing.sm),
              Text(
                HomeStrings.question,
                style: AppTypography.headlineLg.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _searchCard(
                state: state,
                showNicheError: showNicheError,
                showCityError: showCityError,
              ),
              const SizedBox(height: AppSpacing.lg),
              _popularChips(state),
              const SizedBox(height: AppSpacing.xl),
              _sourcesSection(gate),
              const SizedBox(height: AppSpacing.lg),
              _quickFilterRow(state),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                key: const Key('home-find-leads'),
                label: exhausted
                    ? HomeStrings.dailyLimitReached
                    : HomeStrings.findLeads,
                icon: exhausted ? AppIcons.lock : AppIcons.search,
                size: AppButtonSize.large,
                onPressed: exhausted
                    ? () => AppNavigator.openPro(
                        context,
                        reason: LockReason.dailySearchLimitReached.name,
                      )
                    : (!state.canSearch || state.isSubmitting
                          ? null
                          : _onFindLeads),
              ),
              if (recent.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: HomeStrings.recent,
                  trailingText: CommonStrings.clearAll,
                  onTrailingTap: _confirmClearRecent,
                ),
                const SizedBox(height: AppSpacing.sm),
                _recentCard(recent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headlineRow({
    required HomeQuotaStatus quota,
    required int? remaining,
  }) {
    final AppColors colors = AppColors.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            HomeStrings.overline,
            style: AppTypography.labelMd.copyWith(color: colors.textSecondary),
          ),
        ),
        _QuotaChip(
          quota: quota,
          remaining: remaining,
          onExhaustedTap: () => AppNavigator.openPro(
            context,
            reason: LockReason.dailySearchLimitReached.name,
          ),
        ),
      ],
    );
  }

  Widget _searchCard({
    required HomeState state,
    required bool showNicheError,
    required bool showCityError,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppFieldGroup(
            key: _fieldsKey,
            children: <Widget>[
              CompositedTransformTarget(
                link: _nicheLink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppTextField(
                      key: const Key('home-niche-field'),
                      variant: AppTextFieldVariant.grouped,
                      controller: _niche,
                      focusNode: _nicheFocus,
                      hintText: HomeStrings.nicheHint,
                      semanticLabel: HomeStrings.nicheSemantic,
                      leadingIcon: AppIcons.niche,
                      textInputAction: TextInputAction.next,
                      onChanged: (String value) {
                        ref
                            .read(homeControllerProvider.notifier)
                            .setNiche(value);
                        setState(() {});
                        _refreshSuggestions();
                      },
                      onSubmitted: (_) => _cityFocus.requestFocus(),
                      trailing: _niche.text.isEmpty
                          ? null
                          : _ClearButton(
                              tooltip: HomeStrings.clearNiche,
                              onPressed: () {
                                ref
                                    .read(homeControllerProvider.notifier)
                                    .setNiche('');
                                _niche.clear();
                                setState(() {});
                                _refreshSuggestions();
                              },
                            ),
                    ),
                    if (showNicheError)
                      _FieldHint(message: _issueMessage(state.nicheIssue!)),
                  ],
                ),
              ),
              CompositedTransformTarget(
                link: _cityLink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppTextField(
                      key: const Key('home-location-field'),
                      variant: AppTextFieldVariant.grouped,
                      controller: _city,
                      focusNode: _cityFocus,
                      hintText: HomeStrings.locationHint,
                      semanticLabel: HomeStrings.locationSemantic,
                      leadingIcon: AppIcons.location,
                      textInputAction: TextInputAction.search,
                      onChanged: (String value) {
                        ref
                            .read(homeControllerProvider.notifier)
                            .setLocation(value);
                        setState(() {});
                        _refreshSuggestions();
                      },
                      onSubmitted: (_) {
                        if (ref.read(homeControllerProvider).canSearch) {
                          _onFindLeads();
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_city.text.isNotEmpty)
                            _ClearButton(
                              tooltip: HomeStrings.clearLocation,
                              onPressed: () {
                                ref
                                    .read(homeControllerProvider.notifier)
                                    .setLocation('');
                                _city.clear();
                                setState(() {});
                                _refreshSuggestions();
                              },
                            ),
                          if (state.isLocating)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            AppIconButton(
                              icon: AppIcons.myLocation,
                              tooltip: HomeStrings.useMyLocation,
                              onPressed: _onUseLocation,
                            ),
                        ],
                      ),
                    ),
                    if (showCityError)
                      _FieldHint(message: _issueMessage(state.locationIssue!)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _issueMessage(PlaceIssue issue) => switch (issue) {
    PlaceIssue.tooShort => HomeStrings.tooShortHint,
    PlaceIssue.tooLong => HomeStrings.tooLongHint,
    PlaceIssue.invalidCharacters => HomeStrings.invalidCharactersHint,
  };

  Widget _popularChips(HomeState state) {
    final String current = NicheCatalog.normalize(state.niche).toLowerCase();
    final List<Niche> popular = NicheCatalog.popular;
    // No gradient fade: the design rules ban gradients, so the row simply clips
    // at the screen edge (README discrepancy o).
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: popular.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Niche niche = popular[index];
          return Center(
            child: AppChip(
              label: niche.name,
              isSelected: niche.name.toLowerCase() == current,
              onTap: () {
                ref
                    .read(homeControllerProvider.notifier)
                    .applySuggestion(niche.name, isNiche: true);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  Widget _sourcesSection(FeatureGate gate) {
    final AppColors colors = AppColors.of(context);
    final HomeState state = ref.watch(homeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Both labels are flexible: at 1.3 text scale on a 360 px phone the
        // pair no longer fits, and an ellipsized hint beats an overflow.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                HomeStrings.sources,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLg.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(AppIcons.lock, size: 14, color: colors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      HomeStrings.proSources,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: Entitlements.selectableSources.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: AppSpacing.xs + 2),
            itemBuilder: (BuildContext context, int index) {
              final LeadSource source = Entitlements.selectableSources[index];
              final bool selected = state.sources.contains(source);
              final bool locked = !gate.canUseSource(source);
              final Widget chip = AppChip(
                label: source.displayName,
                size: AppChipSize.large,
                leadingIcon: _sourceIcon(source),
                isSelected: selected,
                isLocked: locked,
                showCheckWhenSelected: true,
                onTap: () => _onSourceTap(source),
              );
              return Center(
                child: locked
                    ? Semantics(
                        button: true,
                        label:
                            '${source.displayName}, '
                            '${HomeStrings.lockedSourceSemantics}',
                        child: ExcludeSemantics(child: chip),
                      )
                    : chip,
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _sourceIcon(LeadSource source) => switch (source) {
    LeadSource.maps => AppIcons.maps,
    LeadSource.instagram => AppIcons.instagram,
    LeadSource.linkedin => AppIcons.linkedin,
    LeadSource.facebook => AppIcons.facebook,
    LeadSource.x => AppIcons.x,
    LeadSource.web => AppIcons.public,
  };

  Widget _quickFilterRow(HomeState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                AppChip(
                  label: ResultsStrings.filterEmail,
                  leadingIcon: AppIcons.email,
                  size: AppChipSize.compact,
                  isSelected: state.filters.hasEmail,
                  onTap: () => ref
                      .read(homeControllerProvider.notifier)
                      .toggleQuick(HomeQuickFilter.email),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                AppChip(
                  label: ResultsStrings.filterPhone,
                  leadingIcon: AppIcons.phone,
                  size: AppChipSize.compact,
                  isSelected: state.filters.hasPhone,
                  onTap: () => ref
                      .read(homeControllerProvider.notifier)
                      .toggleQuick(HomeQuickFilter.phone),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                AppChip(
                  label: ResultsStrings.filterWebsite,
                  leadingIcon: AppIcons.website,
                  size: AppChipSize.compact,
                  isSelected: state.filters.hasWebsite,
                  onTap: () => ref
                      .read(homeControllerProvider.notifier)
                      .toggleQuick(HomeQuickFilter.website),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FiltersButton(
          key: const Key('home-filters-button'),
          activeCount: state.activeFilterCount,
          onTap: _openFilters,
        ),
      ],
    );
  }

  Widget _recentCard(List<SearchHistoryEntry> recent) {
    final AppColors colors = AppColors.of(context);
    return AppCard(
      key: const Key('home-recent'),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < recent.length; index++) ...<Widget>[
            if (index > 0) Divider(height: 1, color: colors.divider),
            _RecentRow(
              entry: recent[index],
              onTap: () => _onRecentTap(recent[index]),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small private widgets
// -----------------------------------------------------------------------------

enum _RewardedChoice { watch, goPro, cancel }

class _Suggestion {
  const _Suggestion({required this.label, this.detail});

  final String label;
  final String? detail;
}

/// The Pro pill in the top bar: tappable for Free (opens the paywall), a quiet
/// outlined badge for Pro users (per README, not a control).
class _ProPill extends StatelessWidget {
  const _ProPill({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget pill = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isPro ? Colors.transparent : colors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isPro) ...<Widget>[
            Icon(AppIcons.pro, size: 16, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            HomeStrings.proLabel,
            style: AppTypography.labelMd.copyWith(
              color: isPro ? colors.textSecondary : colors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    if (isPro) {
      return Center(child: pill);
    }
    return Center(
      child: Semantics(
        button: true,
        label: HomeStrings.proTooltip,
        child: Tooltip(
          message: HomeStrings.proTooltip,
          child: InkWell(
            onTap: () => AppNavigator.openPro(context),
            borderRadius: AppRadius.pillAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(child: pill),
            ),
          ),
        ),
      ),
    );
  }
}

/// \"3/5 free today\" (bolt) or \"Unlimited\" on Pro.
///
/// Exhausted shows 0/5 and becomes tappable, opening the paywall. Height is
/// padding-driven, not fixed, so it survives a 1.3 text scale.
class _QuotaChip extends ConsumerWidget {
  const _QuotaChip({
    required this.quota,
    required this.remaining,
    required this.onExhaustedTap,
  });

  final HomeQuotaStatus quota;
  final int? remaining;
  final VoidCallback onExhaustedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = AppColors.of(context);
    // Falls back to the Free constant only if a plan ever removes the limit
    // without the quota stream having emitted yet.
    final int limit =
        ref.watch(featureGateProvider).entitlements.freeSearchesPerDay ??
        freeEntitlements.freeSearchesPerDay ??
        0;
    final bool unlimited = quota == HomeQuotaStatus.unlimited;
    final int shownRemaining = remaining ?? limit;
    final String label = unlimited
        ? HomeStrings.unlimited
        : '$shownRemaining/$limit ${HomeStrings.quotaSuffix}';
    final bool tappable = quota == HomeQuotaStatus.exhausted;

    final Widget chip = Container(
      key: const Key('home-quota-chip'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs - 1,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(AppIcons.bolt, size: 14, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Tooltip(
      message: HomeStrings.quotaTooltip,
      child: tappable
          ? Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: onExhaustedTap,
                borderRadius: AppRadius.pillAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: Center(child: chip),
                ),
              ),
            )
          : chip,
    );
  }
}

/// A 48 px tap-target clear button that sits inside the 52 px field row.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.close,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

/// Validation helper: info icon + plain text. No red — the palette has no hue.
class _FieldHint extends StatelessWidget {
  const _FieldHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 30,
        right: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.info, size: 16, color: colors.textMuted),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined Filters button with a live count bubble, pinned at the row's right.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({
    required this.activeCount,
    required this.onTap,
    super.key,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String semantics = activeCount == 0
        ? HomeStrings.filtersChip
        : '${HomeStrings.filtersChip}, $activeCount';

    return Semantics(
      button: true,
      label: semantics,
      child: Tooltip(
        message: HomeStrings.filtersBadgeTooltip,
        child: Material(
          color: colors.card,
          shape: StadiumBorder(side: BorderSide(color: colors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: colors.overlayPressed,
            highlightColor: colors.overlayHover,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        AppIcons.filters,
                        size: 15,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        HomeStrings.filtersChip,
                        style: AppTypography.labelLg.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (activeCount > 0) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs + 2),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: AppRadius.pillAll,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$activeCount',
                            style: AppTypography.labelSm.copyWith(
                              color: colors.onPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One Recent row: history icon, \"Niche in City\", meta line, chevron.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry, required this.onTap});

  final SearchHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String sources = entry.query.sources
        .map((LeadSource source) => source.displayName)
        .join(', ');
    final String meta = <String>[
      '${entry.resultCount} ${HomeStrings.recentLeadsSuffix}',
      if (sources.isNotEmpty) sources,
      relativeTime(entry.searchedAt),
    ].join(HomeStrings.metaSeparator);

    return InkWell(
      onTap: onTap,
      splashColor: colors.overlayPressed,
      highlightColor: colors.overlayHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Icon(AppIcons.history, size: 20, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.query.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(AppIcons.chevronRight, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
