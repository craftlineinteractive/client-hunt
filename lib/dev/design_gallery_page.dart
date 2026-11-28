import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_mode_provider.dart';
import '../data/fake/fake.dart';
import '../domain/ads/ad_policy.dart';
import '../domain/models/models.dart';
import '../domain/repositories/lead_repository.dart';
import '../domain/repositories/lead_search_engine.dart';
import '../features/results/lead_session.dart';
import '../shared/widgets/shared.dart';
import 'test_ad_page.dart';

/// **Debug-only.** A visual harness for every shared widget and state.
///
/// Registered at `/dev/gallery` only when `kDebugMode` is true. It shows the
/// component library in light, dark and system modes so both themes can be
/// verified without leaving the app. Not part of the shipped UI.
class DesignGalleryPage extends ConsumerStatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  ConsumerState<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends ConsumerState<DesignGalleryPage> {
  int _chipIndex = 0;
  int _ratingIndex = 3;
  int _reviewsIndex = 1;
  int _segmentIndex = 0;
  int _statusIndex = 0;
  int _formatIndex = 0;
  int _navIndex = 0;
  bool _toggleA = true;
  bool _toggleB = false;
  bool _showNote = true;
  bool _sampleSaved = true;
  final List<String> _tags = <String>['implants', 'family'];

  static const List<(String, String)> _sampleLabels = <(String, String)>[
    ('Full data', DummyData.sampleFullLeadId),
    ('Landline only', DummyData.sampleLandlineLeadId),
    ('No email', DummyData.sampleNoEmailLeadId),
    ('No website', DummyData.sampleNoWebsiteLeadId),
    ('Maps, long text', DummyData.sampleMapsLongLeadId),
    ('Social only', DummyData.sampleSocialLeadId),
  ];

  /// Opens a sample lead the way Results or Saved would.
  ///
  /// Saved: the repository copy wins. Unsaved: the sample is published as the
  /// current search session, which is exactly how an unsaved result is opened.
  Future<void> _openSample(String id) async {
    final Lead? lead = ref.read(dummyDataSetProvider).leadById(id);
    if (lead == null) {
      return;
    }
    final LeadRepository repository = ref.read(leadRepositoryProvider);
    if (_sampleSaved) {
      await repository.saveLead(lead);
    } else {
      await repository.deleteLeads(<String>[id]);
    }
    ref
        .read(leadSessionProvider.notifier)
        .set(
          LeadSession(
            request: const SearchRequest(
              id: 'debug-lead-samples',
              query: SearchQuery(
                niches: <String>['Samples'],
                locations: <String>['Ahmedabad'],
              ),
            ),
            leads: <Lead>[lead],
            status: LeadSessionStatus.completed,
          ),
        );
    if (!mounted) {
      return;
    }
    await AppNavigator.goToLead(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final int? remainingToday = ref.watch(remainingSearchesProvider).value;
    final AdPolicy policy = ref.watch(adPolicyProvider);
    final int? lastInterstitial = policy.secondsSinceLastInterstitial;
    return Scaffold(
      appBar: const AppTopBar.pushed(
        title: 'Design gallery',
        subtitle: 'Shared components · light and dark',
        leadingIcon: AppIcons.close,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: <Widget>[
          _Section(
            title: 'Theme mode',
            child: AppSegmentedControl<ThemeMode>(
              options: const <AppSegmentOption<ThemeMode>>[
                AppSegmentOption<ThemeMode>(
                  value: ThemeMode.system,
                  label: 'System',
                ),
                AppSegmentOption<ThemeMode>(
                  value: ThemeMode.light,
                  label: 'Light',
                ),
                AppSegmentOption<ThemeMode>(
                  value: ThemeMode.dark,
                  label: 'Dark',
                ),
              ],
              selected: ref.watch(themeModeProvider),
              onChanged: (ThemeMode mode) =>
                  ref.read(themeModeProvider.notifier).set(mode),
            ),
          ),
          _Section(
            title: 'Fake data scenarios',
            subtitle:
                'Debug only: controls the next search and the pretend '
                'subscription.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final FakeScenario scenario in FakeScenario.values)
                      AppChip(
                        label: scenario.displayName,
                        isSelected: ref.watch(fakeScenarioProvider) == scenario,
                        onTap: () => ref
                            .read(fakeScenarioProvider.notifier)
                            .set(scenario),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ToggleRow(
                  label: 'Pretend Pro subscription',
                  icon: AppIcons.pro,
                  value: ref.watch(fakeProEnabledProvider),
                  onChanged: (bool value) =>
                      ref.read(fakeProEnabledProvider.notifier).set(value),
                ),
                const SizedBox(height: AppSpacing.sm),
                MonoText(
                  'Effective plan: '
                  '${ref.watch(featureGateProvider).entitlements.isPro ? 'Pro' : 'Free'}'
                  ' · max ${ref.watch(featureGateProvider).entitlements.maxResultsPerSearch}'
                  ' results · ads '
                  '${ref.watch(featureGateProvider).showsAds ? 'on' : 'off'}',
                  style: AppTypography.monoSm,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Lead detail samples (B3)',
            subtitle:
                'Debug only: opens one branch of Lead Detail by id, saved or '
                'as a fresh result.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ToggleRow(
                  label: 'Open the sample as saved',
                  icon: AppIcons.saved,
                  value: _sampleSaved,
                  onChanged: (bool value) =>
                      setState(() => _sampleSaved = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final (String label, String id) in _sampleLabels)
                      AppChip(label: label, onTap: () => _openSample(id)),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Search, quota and ads (B1)',
            subtitle:
                'Debug only: the Home form’s cold-start states and every ad '
                'outcome.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Free searches left today',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (int remaining = 0; remaining <= 5; remaining++)
                      AppChip(
                        label: '$remaining',
                        isSelected: remainingToday == remaining,
                        onTap: () {
                          (ref.read(quotaRepositoryProvider)
                                  as FakeQuotaRepository)
                              .setRemaining(remaining);
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    AppButton(
                      label: 'Clear recents',
                      onPressed: () {
                        ref.read(searchHistoryRepositoryProvider).clear();
                      },
                      variant: AppButtonVariant.secondary,
                      expand: false,
                    ),
                    AppButton(
                      label: 'Restore recents',
                      onPressed: () {
                        (ref.read(searchHistoryRepositoryProvider)
                                as FakeSearchHistoryRepository)
                            .restore();
                        setState(() {});
                      },
                      variant: AppButtonVariant.secondary,
                      expand: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Location outcome',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final FakeLocationOutcome outcome
                        in FakeLocationOutcome.values)
                      AppChip(
                        label: outcome.displayName,
                        isSelected:
                            ref.watch(fakeLocationOutcomeProvider) == outcome,
                        onTap: () => ref
                            .read(fakeLocationOutcomeProvider.notifier)
                            .set(outcome),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rewarded outcome',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final FakeRewardedOutcome outcome
                        in FakeRewardedOutcome.values)
                      AppChip(
                        label: outcome.displayName,
                        isSelected:
                            ref.watch(fakeAdConfigProvider).rewarded == outcome,
                        onTap: () => ref
                            .read(fakeAdConfigProvider.notifier)
                            .setRewarded(outcome),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Interstitial outcome',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final FakeInterstitialOutcome outcome
                        in FakeInterstitialOutcome.values)
                      AppChip(
                        label: outcome.displayName,
                        isSelected:
                            ref.watch(fakeAdConfigProvider).interstitial ==
                            outcome,
                        onTap: () => ref
                            .read(fakeAdConfigProvider.notifier)
                            .setInterstitial(outcome),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ToggleRow(
                  label: 'Force the next interstitial',
                  icon: AppIcons.tag,
                  value: ref.watch(forcedInterstitialProvider),
                  onChanged: (bool value) =>
                      ref.read(forcedInterstitialProvider.notifier).set(value),
                ),
                const SizedBox(height: AppSpacing.sm),
                MonoText(
                  'Policy · ${policy.actionsSinceLastInterstitial} actions · '
                  'last interstitial '
                  '${lastInterstitial == null ? 'never' : '${lastInterstitial}s'}'
                  ' · session ${policy.secondsSinceStart}s',
                  style: AppTypography.monoSm,
                  color: colors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    AppButton(
                      label: 'Open test ad',
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const TestAdPage(isRewarded: true),
                        ),
                      ),
                      variant: AppButtonVariant.secondary,
                      expand: false,
                    ),
                    AppButton(
                      label: 'Try interstitial',
                      onPressed: _tryInterstitial,
                      variant: AppButtonVariant.secondary,
                      expand: false,
                    ),
                    AppButton(
                      label: 'Show opt-in dialog',
                      onPressed: _showOptInDialog,
                      variant: AppButtonVariant.secondary,
                      expand: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Selection and notes (B2)',
            subtitle:
                'The Results checkbox (48 px target around a 20 px mark) and a '
                'note with a trailing action.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _CheckboxDemo(),
                const SizedBox(height: AppSpacing.sm),
                InfoNote(
                  text: ResultsStrings.unverifiedNotice,
                  onDismiss: () {},
                ),
                InfoNote(
                  text: 'Filters changed. Search again to apply.',
                  actionLabel: 'Search again',
                  onAction: () {},
                ),
              ],
            ),
          ),
          _Section(
            title: 'Palette',
            subtitle: 'Every color is a role; no hue is allowed.',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _Swatch('background', colors.background, colors),
                _Swatch('canvas', colors.canvas, colors),
                _Swatch('surface', colors.surface, colors),
                _Swatch('card', colors.card, colors),
                _Swatch('cardSubtle', colors.cardSubtle, colors),
                _Swatch('border', colors.border, colors),
                _Swatch('divider', colors.divider, colors),
                _Swatch('primary', colors.primary, colors),
                _Swatch('textMuted', colors.textMuted, colors),
                _Swatch('disabled', colors.disabled, colors),
              ],
            ),
          ),
          _Section(
            title: 'Typography',
            subtitle:
                'Plus Jakarta Sans · Inter · JetBrains Mono, minimum 13 px',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TypeRow('headlineLg', AppTypography.headlineLg),
                _TypeRow('headlineMd', AppTypography.headlineMd),
                _TypeRow('headlineSm', AppTypography.headlineSm),
                _TypeRow('titleLg', AppTypography.titleLg),
                _TypeRow('titleMd', AppTypography.titleMd),
                _TypeRow('titleSm', AppTypography.titleSm),
                _TypeRow('titleXs', AppTypography.titleXs),
                _TypeRow('bodyLg', AppTypography.bodyLg),
                _TypeRow('bodyMd', AppTypography.bodyMd),
                _TypeRow('bodySm', AppTypography.bodySm),
                _TypeRow('labelLg', AppTypography.labelLg),
                _TypeRow('labelMd', AppTypography.labelMd),
                _TypeRow('labelSm', AppTypography.labelSm),
                _TypeRow('monoMd', AppTypography.monoMd),
                _TypeRow('monoSemibold', AppTypography.monoSemibold),
                _TypeRow('monoSm', AppTypography.monoSm),
                _TypeRow('button', AppTypography.button),
              ],
            ),
          ),
          _Section(
            title: 'Buttons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppButton(label: 'Find Leads', onPressed: () {}),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Find Leads',
                  onPressed: () {},
                  size: AppButtonSize.large,
                  icon: AppIcons.search,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Secondary',
                  onPressed: () {},
                  variant: AppButtonVariant.secondary,
                  icon: AppIcons.email,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Ghost action',
                  onPressed: () {},
                  variant: AppButtonVariant.ghost,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(label: 'Loading', onPressed: () {}, isLoading: true),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(label: 'Disabled'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    AppButton(
                      label: 'Compact',
                      onPressed: () {},
                      expand: false,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Outlined',
                      onPressed: () {},
                      expand: false,
                      variant: AppButtonVariant.secondary,
                      borderRadius: AppRadius.md,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Icon buttons',
            subtitle: 'Every one has a tooltip and a 48 px tap target.',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                AppIconButton(
                  icon: AppIcons.more,
                  tooltip: 'More options',
                  onPressed: () {},
                ),
                AppIconButton(
                  icon: AppIcons.copy,
                  tooltip: 'Copy',
                  onPressed: () {},
                  outlined: true,
                ),
                AppIconButton(
                  icon: AppIcons.download,
                  tooltip: 'Export',
                  onPressed: () {},
                  outlined: true,
                  size: 52,
                ),
                const AppIconButton(
                  icon: AppIcons.delete,
                  tooltip: 'Delete (disabled)',
                ),
              ],
            ),
          ),
          _Section(
            title: 'Chips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (int index = 0; index < 4; index++) ...<Widget>[
                        AppChip(
                          label: <String>[
                            'Dentists',
                            'Cafes',
                            'Salons',
                            'Gyms',
                          ][index],
                          isSelected: _chipIndex == index,
                          onTap: () => setState(() => _chipIndex = index),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      AppChip(
                        label: 'Maps',
                        isSelected: true,
                        showCheckWhenSelected: true,
                        leadingIcon: AppIcons.maps,
                        size: AppChipSize.large,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Instagram',
                        isLocked: true,
                        leadingIcon: AppIcons.instagram,
                        size: AppChipSize.large,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'LinkedIn',
                        isLocked: true,
                        leadingIcon: AppIcons.linkedin,
                        size: AppChipSize.large,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      AppChip(
                        label: 'All',
                        trailingCount: 128,
                        isSelected: true,
                        tone: AppChipTone.outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Hot leads',
                        trailingCount: 14,
                        tone: AppChipTone.outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: 'Follow up',
                        trailingCount: 9,
                        tone: AppChipTone.outlined,
                        leadingIcon: AppIcons.tag,
                        onTap: () {},
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const AppChip(
                        label: 'Disabled',
                        tone: AppChipTone.outlined,
                        isEnabled: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Badges and pills',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ProBadge(),
                FreeBadge(),
                SourceBadge(label: 'Maps'),
                SourceBadge(label: 'Instagram'),
                StatusPill(label: 'New'),
                StatusPill(label: 'Contacted'),
                StatusPill(label: 'Replied'),
                StatusPill(label: 'Closed'),
              ],
            ),
          ),
          _Section(
            title: 'Cards and headers',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SectionHeader(
                        title: 'Recent',
                        trailingText: 'Clear all',
                        onTrailingTap: () {},
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'A 16 px radius card with a 1 px border and a soft shadow '
                        'in light mode only.',
                        style: AppTypography.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: colors.cardSubtle,
                  showShadow: false,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: const Row(
                    children: <Widget>[
                      InitialsAvatar(initials: 'SD'),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Northline Dental Studio'),
                            SizedBox(height: 2),
                            MonoText('contact@northline-dental-studio.example'),
                          ],
                        ),
                      ),
                      RatingBadge(rating: 4.8, reviewCount: 184),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Inputs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFieldGroup(
                  children: <Widget>[
                    const AppTextField(
                      variant: AppTextFieldVariant.grouped,
                      hintText: HomeStrings.nicheHint,
                      leadingIcon: AppIcons.niche,
                    ),
                    AppTextField(
                      variant: AppTextFieldVariant.grouped,
                      hintText: HomeStrings.locationHint,
                      leadingIcon: AppIcons.location,
                      trailing: AppIconButton(
                        icon: AppIcons.myLocation,
                        tooltip: HomeStrings.useMyLocation,
                        onPressed: () {},
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const AppTextField(
                  hintText: 'dentists-ahmedabad-leads',
                  leadingIcon: AppIcons.file,
                  isMono: true,
                ),
                const SizedBox(height: AppSpacing.md),
                const AppTextField(
                  hintText: 'Use my location (disabled)',
                  leadingIcon: AppIcons.location,
                  isEnabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                TagInput(
                  tags: _tags,
                  hintText: 'Type keyword...',
                  semanticLabel: 'Must include keywords',
                  onAdd: (String tag) => setState(() => _tags.add(tag)),
                  onRemove: (String tag) => setState(() => _tags.remove(tag)),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Segmented controls',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSegmentedControl<int>(
                  options: const <AppSegmentOption<int>>[
                    AppSegmentOption<int>(value: 0, label: 'Any'),
                    AppSegmentOption<int>(value: 1, label: 'Open now'),
                  ],
                  selected: _segmentIndex,
                  onChanged: (int value) =>
                      setState(() => _segmentIndex = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSegmentedControl<int>(
                  options: const <AppSegmentOption<int>>[
                    AppSegmentOption<int>(value: 0, label: 'All', count: 128),
                    AppSegmentOption<int>(value: 1, label: 'New', count: 42),
                    AppSegmentOption<int>(
                      value: 2,
                      label: 'Contacted',
                      count: 38,
                    ),
                    AppSegmentOption<int>(
                      value: 3,
                      label: 'Replied',
                      count: 19,
                    ),
                    AppSegmentOption<int>(value: 4, label: 'Closed', count: 29),
                  ],
                  selected: _statusIndex,
                  onChanged: (int value) =>
                      setState(() => _statusIndex = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSegmentedControl<int>(
                  options: const <AppSegmentOption<int>>[
                    AppSegmentOption<int>(value: 0, label: 'New'),
                    AppSegmentOption<int>(value: 1, label: 'Contacted'),
                    AppSegmentOption<int>(value: 2, label: 'Replied'),
                    AppSegmentOption<int>(value: 3, label: 'Closed'),
                  ],
                  selected: _statusIndex % 4,
                  style: AppSegmentedStyle.filled,
                  onChanged: (int value) =>
                      setState(() => _statusIndex = value),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Option pills and tiles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Minimum rating',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                OptionPillRow<int>(
                  options: const <OptionPillOption<int>>[
                    OptionPillOption<int>(value: 0, label: 'Any'),
                    OptionPillOption<int>(value: 3, label: '3.0+'),
                    OptionPillOption<int>(value: 4, label: '4.0+'),
                    OptionPillOption<int>(value: 5, label: '4.5+'),
                  ],
                  selected: _ratingIndex,
                  onChanged: (int value) =>
                      setState(() => _ratingIndex = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Minimum reviews',
                  style: AppTypography.labelMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                OptionPillRow<int>(
                  options: const <OptionPillOption<int>>[
                    OptionPillOption<int>(value: 0, label: 'Any'),
                    OptionPillOption<int>(value: 10, label: '10+'),
                    OptionPillOption<int>(value: 50, label: '50+'),
                    OptionPillOption<int>(value: 100, label: '100+'),
                  ],
                  selected: _reviewsIndex,
                  onChanged: (int value) =>
                      setState(() => _reviewsIndex = value),
                ),
                const SizedBox(height: AppSpacing.md),
                RadioTile(
                  title: 'All leads',
                  subtitle: 'Every lead in this search',
                  isSelected: true,
                  trailingCount: 42,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                RadioTile(
                  title: 'Selected only',
                  trailingCount: 0,
                  isSelected: false,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                RadioTile(
                  title: 'Deep',
                  subtitle: 'Also scans websites for emails',
                  isSelected: false,
                  isLocked: true,
                  badge: const ProBadge(label: 'PRO'),
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableTile(
                        title: 'CSV',
                        subtitle: '.csv',
                        icon: AppIcons.document,
                        isSelected: _formatIndex == 0,
                        onTap: () => setState(() => _formatIndex = 0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SelectableTile(
                        title: 'Excel',
                        subtitle: '.xlsx',
                        icon: AppIcons.table,
                        isSelected: _formatIndex == 1,
                        onTap: () => setState(() => _formatIndex = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableTile(
                        title: 'PDF',
                        subtitle: '.pdf',
                        icon: AppIcons.pdf,
                        isSelected: _formatIndex == 2,
                        onTap: () => setState(() => _formatIndex = 2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SelectableTile(
                        title: 'VCF',
                        subtitle: '.vcf, contacts',
                        icon: AppIcons.contactFile,
                        isSelected: _formatIndex == 3,
                        onTap: () => setState(() => _formatIndex = 3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Settings rows',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SettingsGroup(
                  title: 'Appearance',
                  children: <Widget>[
                    SettingsRow(
                      label: 'Default country',
                      icon: AppIcons.globe,
                      value: 'India',
                      onTap: () {},
                    ),
                    SettingsRow(
                      label: 'Max results per search',
                      icon: AppIcons.numbers,
                      value: '50',
                      isMonoValue: true,
                      onTap: () {},
                    ),
                    ToggleRow(
                      label: 'Remove duplicates',
                      icon: AppIcons.copyStack,
                      value: _toggleA,
                      onChanged: (bool value) =>
                          setState(() => _toggleA = value),
                    ),
                    ToggleRow(
                      label: 'No website',
                      icon: AppIcons.website,
                      value: _toggleB,
                      badge: const ProBadge(label: 'PRO'),
                      isEnabled: false,
                      onChanged: (bool value) =>
                          setState(() => _toggleB = value),
                    ),
                    SettingsRow(
                      label: 'Privacy Policy',
                      icon: AppIcons.shield,
                      trailing: SettingsTrailing.external,
                      onTap: () {},
                    ),
                    const SettingsRow(
                      label: 'App version',
                      icon: AppIcons.version,
                      value: '1.0.0 (1)',
                      isMonoValue: true,
                      trailing: SettingsTrailing.none,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Contact rows and mono text',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ContactRow(
                      icon: AppIcons.phone,
                      label: 'Phone',
                      value: '+91 79 4020 1888',
                      copyTooltip: 'Copy phone',
                    ),
                  ),
                  Divider(height: 1, color: colors.divider),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ContactRow(
                      icon: AppIcons.email,
                      label: 'Email',
                      value: 'contact@northline-dental-studio.example',
                      copyTooltip: 'Copy email',
                    ),
                  ),
                  Divider(height: 1, color: colors.divider),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ContactRow(
                      icon: AppIcons.website,
                      value: '',
                      isMissing: true,
                      missingText: 'No website found',
                      copyTooltip: 'Copy website',
                    ),
                  ),
                  Divider(height: 1, color: colors.divider),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ContactRow(
                      icon: AppIcons.phone,
                      value: '+91 98250 44120',
                      isCompact: true,
                      copyTooltip: 'Copy phone',
                    ),
                  ),
                  Divider(height: 1, color: colors.divider),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const MonoText('monoMd  •  42 leads'),
                        const SizedBox(height: AppSpacing.xs),
                        MonoText(
                          'monoSm  •  Saved 2d ago',
                          style: AppTypography.monoSm,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Section(
            title: 'Stats, notes and empty states',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const StatsStrip(
                  items: <StatItem>[
                    StatItem(icon: AppIcons.group, value: '42', label: 'Leads'),
                    StatItem(
                      icon: AppIcons.email,
                      value: '31',
                      label: 'Emails',
                    ),
                    StatItem(
                      icon: AppIcons.phone,
                      value: '40',
                      label: 'Phones',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_showNote)
                  InfoNote(
                    text: ResultsStrings.unverifiedNotice,
                    onDismiss: () => setState(() => _showNote = false),
                  ),
                if (!_showNote)
                  TextButton(
                    onPressed: () => setState(() => _showNote = true),
                    child: const Text('Show the dismissed note again'),
                  ),
                const SizedBox(height: AppSpacing.md),
                const InfoNote(
                  text: 'Found on a public page, not verified.',
                  isEmphasized: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: EmptyState(
                    icon: AppIcons.savedOutline,
                    title: 'Nothing saved yet',
                    body:
                        'Save a lead from search results to start your '
                        'pipeline.',
                    actionLabel: 'Find leads',
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Pro upsell',
            child: ProUpsellCard(
              title: 'ClientHunt Pro',
              body: 'Unlock social sources and unlimited leads',
              onTap: () {},
            ),
          ),
          _Section(
            title: 'App bars',
            subtitle: 'Shown at 56 px; the real bars sit under the status bar.',
            child: Column(
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    height: AppSpacing.appBarHeight,
                    child: AppTopBar.tab(
                      title: AppStrings.wordmark,
                      showWordmark: true,
                      actions: <Widget>[
                        AppIconButton(
                          icon: AppIcons.settings,
                          tooltip: 'Settings',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    height: AppSpacing.appBarHeight,
                    child: AppTopBar.pushed(
                      title: 'Dentists in Ahmedabad',
                      subtitle: '42 leads · Maps',
                      actions: <Widget>[
                        AppIconButton(
                          icon: AppIcons.search,
                          tooltip: 'Search within leads',
                          onPressed: () {},
                        ),
                        AppIconButton(
                          icon: AppIcons.more,
                          tooltip: 'More options',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Action bars',
            child: Column(
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: BottomActionBar(
                    primaryLabel: 'Export Leads',
                    primaryIcon: AppIcons.download,
                    onPrimary: () {},
                    caption: 'CSV · Excel · PDF · VCF',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SelectionActionBar(
                  selectedCount: 1,
                  actions: <SelectionAction>[
                    SelectionAction(
                      icon: AppIcons.download,
                      tooltip: 'Export leads',
                      onTap: () {},
                    ),
                    SelectionAction(
                      icon: AppIcons.addToList,
                      tooltip: 'Add to list',
                      onTap: () {},
                    ),
                    SelectionAction(
                      icon: AppIcons.tag,
                      tooltip: 'Add tags',
                      onTap: () {},
                    ),
                    SelectionAction(
                      icon: AppIcons.delete,
                      tooltip: 'Delete',
                      onTap: () {},
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Bottom navigation',
            subtitle: 'Three tabs from the single navTabs constant.',
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: AppBottomNav(
                currentIndex: _navIndex,
                onTap: (int index) => setState(() => _navIndex = index),
              ),
            ),
          ),
          const _Section(
            title: 'Avatars and ratings',
            child: Row(
              children: <Widget>[
                InitialsAvatar(initials: 'SD'),
                SizedBox(width: AppSpacing.md),
                InitialsAvatar(initials: 'PS', size: 64, radius: 14),
                SizedBox(width: AppSpacing.lg),
                RatingBadge(rating: 4.8, reviewCount: 184, isPill: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Asks the coordinator for an interstitial, so the forced switch and the
  /// test ad page can be checked without a real trigger.
  Future<void> _tryInterstitial() async {
    final bool shown = await ref
        .read(adCoordinatorProvider)
        .maybeShowInterstitial(AdTrigger.resultsClosed);
    _note(shown ? 'Interstitial shown' : 'Interstitial skipped by policy');
  }

  /// Shows the real rewarded opt-in dialog and reports the choice, so `AppDialog`
  /// can be reviewed without walking a Free search.
  Future<void> _showOptInDialog() async {
    final Object? choice = await showAppDialog(
      context,
      title: AdsStrings.rewardedTitle,
      body: AdsStrings.rewardedBody,
      actions: const <AppDialogAction>[
        AppDialogAction(
          label: AdsStrings.rewardedWatch,
          style: AppDialogActionStyle.primary,
          value: 'watch',
        ),
        AppDialogAction(label: AdsStrings.rewardedGoPro, value: 'goPro'),
        AppDialogAction(
          label: CommonStrings.cancel,
          style: AppDialogActionStyle.ghost,
          value: 'cancel',
        ),
      ],
    );
    _note(switch (choice) {
      'watch' => 'Would play the rewarded ad',
      'goPro' => 'Would open the paywall',
      _ => 'Cancelled',
    });
  }

  void _note(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Demonstrates [AppCheckbox] checked, unchecked and disabled.
class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo();

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _isChecked = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AppCheckbox(
          value: _isChecked,
          onChanged: (bool value) => setState(() => _isChecked = value),
          semanticLabel: 'Select all',
        ),
        AppCheckbox(value: !_isChecked, onChanged: (bool _) {}),
        const AppCheckbox(value: false, semanticLabel: 'Disabled'),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Tap the first box: the mark is 20 px, the touch area is 48 px. '
            'The last box is disabled.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.of(context).textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.titleMd.copyWith(color: colors.textPrimary),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: AppTypography.bodySm.copyWith(color: colors.textMuted),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.token, this.style);

  final String token;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(
              token,
              style: AppTypography.monoSm.copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              'ClientHunt 0123',
              style: style.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.colors);

  final String name;
  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.xs + 2),
              border: Border.all(color: colors.border),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The route is registered only in debug builds; this makes the intent explicit
/// for anything that imports the page.
bool get galleryIsDebugOnly => kDebugMode;
