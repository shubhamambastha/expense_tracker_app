import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Minimal top app bar for the Add Transaction screen.
///
/// Left = back, centre = title, right = mic placeholder for future voice
/// input. Kept inside [SafeArea] so the host page can scroll cleanly under
/// it without dealing with status-bar padding.
class TransactionAppBar extends StatelessWidget {
  const TransactionAppBar({
    super.key,
    this.title = 'Add Transaction',
    this.onBack,
    this.onMic,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                _AppBarIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _AppBarIconButton(
                  icon: Icons.mic_none_rounded,
                  tooltip: 'Voice entry (soon)',
                  onTap: onMic,
                  muted: onMic == null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final fg = muted ? AppColors.textSecondary : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.buttonRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}
