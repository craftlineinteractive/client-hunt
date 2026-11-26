import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../shared/widgets/app_button.dart';

/// **Debug only — a labelled stand-in for a real ad.**
///
/// The fake [AdService] presents this instead of an SDK. It is deliberately
/// plain and unmistakably a test: no fake advertiser, no fake offer, no
/// celebrity, nothing a user could mistake for real content. It never ships
/// visible: prompt E replaces the fake with AdMob and this page disappears.
///
/// Rewarded: a 5-second countdown, then Close becomes available; closing before
/// the countdown runs out (only when [allowEarlyClose] simulates the user backing
/// out) resolves with `false` so the search must not run. Interstitial: closes
/// immediately and resolves with `true`.
class TestAdPage extends StatefulWidget {
  const TestAdPage({
    required this.isRewarded,
    this.allowEarlyClose = false,
    this.countdown = const Duration(seconds: 5),
    super.key,
  });

  /// Rewarded (countdown, reward on close) or interstitial (close immediately).
  final bool isRewarded;

  /// Simulates the user closing a rewarded ad early. The page then offers Close
  /// at once and resolves with `false`.
  final bool allowEarlyClose;

  /// Length of the rewarded countdown.
  final Duration countdown;

  @override
  State<TestAdPage> createState() => _TestAdPageState();
}

class _TestAdPageState extends State<TestAdPage> {
  late int _remainingSeconds = widget.countdown.inSeconds;
  Timer? _timer;

  bool get _isRewarded => widget.isRewarded;
  bool get _canClose => !_isRewarded || _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    if (_isRewarded && !widget.allowEarlyClose) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _remainingSeconds = (_remainingSeconds - 1).clamp(0, 999);
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    // Closing before the countdown only happens in the simulated early-dismiss
    // case, where no reward was earned.
    final bool earned = _isRewarded && !widget.allowEarlyClose;
    Navigator.of(context).pop(earned);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return PopScope(
      canPop: _canClose,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(AppIcons.info, size: 16, color: colors.textMuted),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      AdsStrings.testAdLabel.toUpperCase(),
                      style: AppTypography.monoSm.copyWith(
                        color: colors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: AppRadius.lgAll,
                            border: Border.all(color: colors.border),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _isRewarded ? AppIcons.bolt : AppIcons.public,
                            size: 40,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          _isRewarded
                              ? AdsStrings.testAdRewardedHeadline
                              : AdsStrings.testAdInterstitialHeadline,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AdsStrings.testAdBody,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isRewarded) ...<Widget>[
                  Text(
                    AdsStrings.testAdRewardNote,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$_remainingSeconds${AdsStrings.testAdSecondsSuffix}',
                    textAlign: TextAlign.center,
                    style: AppTypography.monoMd.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppButton(
                  label: AdsStrings.testAdClose,
                  icon: _canClose ? AppIcons.close : AppIcons.lock,
                  size: AppButtonSize.large,
                  onPressed: _canClose ? _close : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
