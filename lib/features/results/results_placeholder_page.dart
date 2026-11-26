import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/empty_state.dart';

/// **Placeholder for the Results screen (prompt B2).**
///
/// It exists for one reason: to prove the Home → Results hand-off. It renders the
/// `SearchRequest` carried in the route extra — niche, city, sources, active
/// filter count and the result cap — so a test and a device run can check that
/// what Home validated is exactly what Results received.
///
/// When the route is restored without an extra (Android process death, a deep
/// link), it shows a safe fallback instead of throwing.
class ResultsPlaceholderPage extends StatelessWidget {
  const ResultsPlaceholderPage({this.request, super.key});

  /// The request passed from Home, or `null` when the route was restored.
  final SearchRequest? request;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final SearchRequest? request = this.request;

    return Scaffold(
      appBar: AppTopBar.pushed(
        title: ResultsStrings.title,
        subtitle: request?.query.displayTitle,
      ),
      body: SafeArea(
        child: request == null
            ? const Center(
                child: EmptyState(
                  icon: AppIcons.search,
                  title: ResultsStrings.handoffTitle,
                  body: ResultsStrings.handoffMissing,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  Text(
                    ResultsStrings.handoffTitle,
                    style: AppTypography.titleSm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ResultsStrings.handoffCaption,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Row(
                    label: ResultsStrings.nicheLabel,
                    value: request.query.niches.join(', '),
                  ),
                  _Row(
                    label: ResultsStrings.locationLabel,
                    value: request.query.locations.join(', '),
                  ),
                  _Row(
                    label: ResultsStrings.sourcesLabel,
                    value: request.query.sources
                        .map((LeadSource source) => source.displayName)
                        .join(', '),
                  ),
                  _Row(
                    label: ResultsStrings.filtersLabel,
                    value: request.filters.activeFilterCount == 0
                        ? ResultsStrings.filtersNone
                        : '${request.filters.activeFilterCount}',
                  ),
                  _Row(
                    label: 'Max results',
                    value: '${request.filters.maxResults}',
                  ),
                ],
              ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
