import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Visual weight of an [AppDialogAction].
enum AppDialogActionStyle {
  /// Filled with `primary` — the action the dialog recommends.
  primary,

  /// Outlined on `card` — a real alternative ("Go Pro").
  secondary,

  /// Text only — the quiet way out ("Cancel").
  ghost,
}

/// One button in an [AppDialog].
///
/// Actions are stacked full width in the order given, so a three-action dialog
/// (primary, alternative, cancel) never squeezes its labels. [value] is what
/// `showAppDialog` resolves with; [onDismissed] runs after the dialog closes, for
/// side effects such as navigating to the paywall.
@immutable
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.style = AppDialogActionStyle.secondary,
    this.value,
    this.onDismissed,
  }) : assert(label.length > 0, 'An action needs a label');

  /// Button label.
  final String label;

  /// Visual weight.
  final AppDialogActionStyle style;

  /// Value `showAppDialog` resolves with when this action is tapped.
  final Object? value;

  /// Runs after the dialog is closed (navigation, analytics).
  final VoidCallback? onDismissed;
}

/// The app's confirmation and decision dialog.
///
/// A 20 px radius card on `card`, a title in `titleMd`, one short paragraph of
/// body copy, and full-width stacked actions. No colored buttons: hierarchy comes
/// from fill, border and weight. Every dialog in the app goes through
/// [showAppDialog] so `showDialog` is not scattered across screens.
///
/// ```dart
/// final Object? choice = await showAppDialog(
///   context,
///   title: AdsStrings.rewardedTitle,
///   body: AdsStrings.rewardedBody,
///   actions: <AppDialogAction>[
///     AppDialogAction(label: AdsStrings.rewardedWatch, style: AppDialogActionStyle.primary, value: 'watch'),
///     AppDialogAction(label: CommonStrings.cancel, style: AppDialogActionStyle.ghost),
///   ],
/// );
/// ```
Future<Object?> showAppDialog(
  BuildContext context, {
  required String title,
  required String body,
  required List<AppDialogAction> actions,
  bool barrierDismissible = true,
}) {
  return showDialog<Object?>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) =>
        AppDialog(title: title, body: body, actions: actions),
  );
}

/// The dialog body; prefer [showAppDialog], which also returns the tapped action.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.body,
    required this.actions,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// One or two sentences explaining the decision.
  final String body;

  /// Actions, stacked top to bottom.
  final List<AppDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.titleMd.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            for (int index = 0; index < actions.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: actions[index].label,
                variant: switch (actions[index].style) {
                  AppDialogActionStyle.primary => AppButtonVariant.primary,
                  AppDialogActionStyle.secondary => AppButtonVariant.secondary,
                  AppDialogActionStyle.ghost => AppButtonVariant.ghost,
                },
                onPressed: () {
                  Navigator.of(context).pop(actions[index].value);
                  actions[index].onDismissed?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
