import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/lead_search_engine.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

/// Icon and word for one source state.
///
/// State is never colour: an icon plus a word ("Blocked", "Pro only") carries it,
/// which keeps the monochrome rule and works for a screen reader.
(IconData, String) sourceStatusVisual(SourceStatus status) {
  return switch (status) {
    SourceStatus.pending => (AppIcons.schedule, ResultsStrings.sourcePending),
    SourceStatus.running => (AppIcons.search, ResultsStrings.sourceRunning),
    SourceStatus.done => (AppIcons.checkCircle, ResultsStrings.sourceDone),
    SourceStatus.skippedPro => (AppIcons.lock, ResultsStrings.sourceSkippedPro),
    SourceStatus.blocked => (AppIcons.block, ResultsStrings.sourceBlocked),
    SourceStatus.failed => (AppIcons.warning, ResultsStrings.sourceFailed),
  };
}

/// Stage copy for the progress card and the slim header.
String stageLabel(SearchStage? stage) {
  return switch (stage) {
    null || SearchStage.querying => ResultsStrings.loadingQuerying,
    SearchStage.parsing => ResultsStrings.loadingParsing,
    SearchStage.enriching => ResultsStrings.loadingEnriching,
    SearchStage.validating => ResultsStrings.loadingValidating,
    SearchStage.deduplicating => ResultsStrings.loadingDeduplicating,
  };
}

/// The loading card shown while the first batch has not arrived.
///
/// Shows what the engine is doing, how each source is doing and how many leads
/// exist so far, with a Cancel action — never a bare spinner.
class ResultsProgressCard extends StatelessWidget {
  const ResultsProgressCard({
    required this.stage,
    required this.sources,
    required this.statuses,
    required this.foundSoFar,
    required this.onCancel,
    super.key,
  });

  /// Current pipeline stage.
  final SearchStage? stage;

  /// Sources being attempted, in display order.
  final List<LeadSource> sources;

  /// Live per-source state.
  final Map<LeadSource, SourceStatus> statuses;

  /// Leads the engine reports so far.
  final int foundSoFar;

  /// Cancels the run (the page then leaves the screen).
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return AppCard(
      key: const Key('results-progress-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  stageLabel(stage),
                  style: AppTypography.titleSm.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (sources.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            for (final LeadSource source in sources)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                child: _SourceRow(
                  source: source,
                  status: statuses[source] ?? SourceStatus.pending,
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            ResultsStrings.foundSoFar(foundSoFar),
            style: AppTypography.bodySm.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: CommonStrings.cancel,
            onPressed: onCancel,
            variant: AppButtonVariant.secondary,
            expand: false,
            icon: AppIcons.close,
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.status});

  final LeadSource source;
  final SourceStatus status;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final (IconData icon, String word) = sourceStatusVisual(status);
    return Semantics(
      label: '${source.displayName}: $word',
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              source.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(color: colors.textPrimary),
            ),
          ),
          Text(
            word,
            style: AppTypography.bodySm.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A static placeholder card with a subtle opacity pulse.
///
/// The pulse stops when the platform asks for reduced motion
/// (`MediaQuery.disableAnimations`), where the card renders at a fixed opacity.
class ResultsSkeletonCard extends StatefulWidget {
  const ResultsSkeletonCard({super.key});

  @override
  State<ResultsSkeletonCard> createState() => _ResultsSkeletonCardState();
}

class _ResultsSkeletonCardState extends State<ResultsSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  bool _isPulsing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      if (_isPulsing) {
        _controller.stop();
        _isPulsing = false;
      }
      _controller.value = 1;
      return;
    }
    if (!_isPulsing) {
      _controller.repeat(reverse: true);
      _isPulsing = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color block = colors.dividerSubtle;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: block, borderRadius: AppRadius.smAll),
      ),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: AppCard(
        showShadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      bar(0.6, 12),
                      const SizedBox(height: AppSpacing.sm),
                      bar(0.4, 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            bar(0.5, 10),
            const SizedBox(height: AppSpacing.sm),
            bar(0.75, 10),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(child: bar(1, 40)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: bar(1, 40)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: bar(1, 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The one-line header pinned above the list while batches still append.
class ResultsProgressHeader extends StatelessWidget {
  const ResultsProgressHeader({
    required this.stage,
    required this.foundSoFar,
    super.key,
  });

  /// Current pipeline stage.
  final SearchStage? stage;

  /// Leads reported so far.
  final int foundSoFar;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      key: const Key('results-progress-header'),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  stageLabel(stage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                ResultsStrings.foundSoFar(foundSoFar),
                style: AppTypography.monoSm.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: colors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliver wrapper for [ResultsProgressHeader].
class ResultsProgressHeaderDelegate extends SliverPersistentHeaderDelegate {
  const ResultsProgressHeaderDelegate({
    required this.stage,
    required this.foundSoFar,
  });

  /// Current stage.
  final SearchStage? stage;

  /// Leads reported so far.
  final int foundSoFar;

  static const double _extent = 48;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: _extent,
      child: ResultsProgressHeader(stage: stage, foundSoFar: foundSoFar),
    );
  }

  @override
  bool shouldRebuild(ResultsProgressHeaderDelegate oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.foundSoFar != foundSoFar;
}
