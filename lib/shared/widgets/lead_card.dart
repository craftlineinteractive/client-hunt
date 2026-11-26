import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/models.dart';
import 'app_icon_button.dart';
import 'contact_row.dart';
import 'initials_avatar.dart';
import 'rating_badge.dart';
import 'source_badge.dart';

/// The lead card shared by Results and Saved.
///
/// One card, two contexts: the results list shows rating, source and open state
/// plus every contact line; the saved list adds a checkbox and relies on the
/// caller's trailing widgets. Missing contact data is **shown**, not hidden — an
/// italic "No email found" is honest and keeps the rows aligned.
///
/// Monochrome: selection is a 1.5 px `primary` border, never a color accent.
class LeadCard extends StatelessWidget {
  const LeadCard({
    required this.lead,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onTap,
    this.onBookmark,
    this.trailing,
    super.key,
  });

  /// The lead to render.
  final Lead lead;

  /// Selected state: stronger border.
  final bool isSelected;

  /// Reserve the checkbox gutter (Saved list).
  final bool showCheckbox;

  /// Tapping the card body (opens lead detail).
  final VoidCallback? onTap;

  /// Bookmark handler; `null` hides the bookmark button.
  final VoidCallback? onBookmark;

  /// Extra trailing widget in the header row (for example a [StatusPill]).
  final Widget? trailing;

  /// First letters of the first two words, e.g. "Northline Dental Studio" → ND.
  static String initialsOf(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String subtitle = <String>[
      lead.category,
      lead.area.isEmpty ? lead.city : lead.area,
    ].where((String part) => part.isNotEmpty).join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        splashColor: colors.overlayPressed,
        highlightColor: colors.overlayHover,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: <BoxShadow>[
              if (!colors.isDark)
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (showCheckbox) ...<Widget>[
                    Icon(
                      isSelected ? AppIcons.checkbox : AppIcons.checkboxBlank,
                      size: 20,
                      color: isSelected ? colors.primary : colors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  InitialsAvatar(initials: initialsOf(lead.name)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          lead.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSm.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                  if (onBookmark != null)
                    AppIconButton(
                      icon: lead.isSaved
                          ? AppIcons.saved
                          : AppIcons.savedOutline,
                      tooltip: lead.isSaved
                          ? ResultsStrings.removeSavedTooltip
                          : ResultsStrings.saveLeadTooltip,
                      onPressed: onBookmark,
                      iconSize: 20,
                    ),
                ],
              ),
              if (lead.rating != null || lead.sources.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    // Rating and reviews exist only for Maps leads; show both
                    // or neither, never a zero placeholder.
                    if (lead.rating != null && lead.reviewCount != null)
                      RatingBadge(
                        rating: lead.rating!,
                        reviewCount: lead.reviewCount!,
                      ),
                    if (lead.sources.isNotEmpty)
                      SourceBadge(label: lead.sources.first.displayName),
                    if (lead.isOpenNow != null)
                      Text(
                        lead.isOpenNow!
                            ? ResultsStrings.openNow
                            : ResultsStrings.closedNow,
                        style: AppTypography.bodySm.copyWith(
                          color: lead.isOpenNow!
                              ? colors.textPrimary
                              : colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (lead.hasPhone)
                ContactRow(
                  icon: AppIcons.phone,
                  value: lead.primaryPhone!.value,
                  isCompact: true,
                )
              else
                const ContactRow(
                  icon: AppIcons.phone,
                  value: '',
                  isCompact: true,
                  isMissing: true,
                  missingText: ResultsStrings.noPhoneFound,
                ),
              const SizedBox(height: AppSpacing.xs + 2),
              if (lead.hasEmail)
                ContactRow(
                  icon: AppIcons.email,
                  value: lead.primaryEmail!.value,
                  isCompact: true,
                )
              else
                const ContactRow(
                  icon: AppIcons.email,
                  value: '',
                  isCompact: true,
                  isMissing: true,
                  missingText: ResultsStrings.noEmailFound,
                ),
              const SizedBox(height: AppSpacing.xs + 2),
              if (lead.hasWebsite)
                ContactRow(
                  icon: AppIcons.website,
                  value: lead.website!,
                  isCompact: true,
                )
              else
                const ContactRow(
                  icon: AppIcons.website,
                  value: '',
                  isCompact: true,
                  isMissing: true,
                  missingText: ResultsStrings.noWebsiteFound,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
