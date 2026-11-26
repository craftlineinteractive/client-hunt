import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// One cell of a [StatsStrip].
@immutable
class StatItem {
  const StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  /// 16 px rounded icon.
  final IconData icon;

  /// Numeric value, rendered at 14/700.
  final String value;

  /// Unit label ("Leads", "Emails", "Phones").
  final String label;
}

/// A 48 px summary strip: "42 Leads | 31 Emails | 40 Phones".
///
/// White card, 1 px border, 12 px radius, cells split by 1 px dividers. Used at
/// the top of search results. Counts are plain text so they can be tested; only
/// the values are bold.
class StatsStrip extends StatelessWidget {
  const StatsStrip({required this.items, super.key});

  /// Two to four cells; the mockup uses three.
  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0)
              Container(width: 1, height: 24, color: colors.divider),
            Expanded(
              child: Semantics(
                label: '${items[index].value} ${items[index].label}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      items[index].icon,
                      size: 16,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm - 2),
                    Text(
                      items[index].value,
                      style: AppTypography.titleSm.copyWith(
                        color: colors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 1),
                    Text(
                      items[index].label,
                      style: AppTypography.labelMd.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
