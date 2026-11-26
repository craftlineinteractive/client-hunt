import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A chip input for keywords and tags.
///
/// Tags render as 8 px-radius chips with mono 13 text and a remove button; the
/// inline field submits on Enter and clears itself. The container keeps the
/// 12 px radius, 1 px border and 44 px minimum height of the mockups.
class TagInput extends StatefulWidget {
  const TagInput({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
    this.hintText = 'Type and press enter',
    this.semanticLabel,
    super.key,
  });

  /// Current tags.
  final List<String> tags;

  /// Called with the trimmed new tag.
  final ValueChanged<String> onAdd;

  /// Called with the tag to remove.
  final ValueChanged<String> onRemove;

  /// Placeholder for the inline field.
  final String hintText;

  /// Accessibility label for the field.
  final String? semanticLabel;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return;
    }
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.all(AppSpacing.sm - 2),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.sm - 2,
        runSpacing: AppSpacing.sm - 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final String tag in widget.tags)
            Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm + 2,
                right: AppSpacing.xs,
                top: 3,
                bottom: 3,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    tag,
                    style: AppTypography.monoSm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: 'Remove $tag',
                    child: Semantics(
                      button: true,
                      label: 'Remove $tag',
                      child: InkWell(
                        onTap: () => widget.onRemove(tag),
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            AppIcons.close,
                            size: 14,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
            child: Semantics(
              label: widget.semanticLabel ?? widget.hintText,
              textField: true,
              child: TextField(
                controller: _controller,
                onSubmitted: _submit,
                textInputAction: TextInputAction.done,
                style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
                cursorColor: colors.primary,
                decoration: InputDecoration.collapsed(
                  hintText: widget.hintText,
                  hintStyle: AppTypography.bodySm.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
