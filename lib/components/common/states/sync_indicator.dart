import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'app_loading_indicator.dart';
import 'sync_status.dart';

/// Subtle inline sync badge — avoids noisy popups.
///
/// Use in headers, settings rows, or list footers. Pair with [SyncStatus]
/// from your sync service layer.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({
    super.key,
    required this.status,
    this.onTap,
    this.compact = false,
  });

  final SyncStatus status;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = status.accent;
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: accent.withAlpha(28),
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.showsSpinner) ...[
            const AppLoadingIndicator(
              style: AppLoadingStyle.inline,
            ),
            SizedBox(width: compact ? 4 : AppSpacing.xs),
          ] else
            Icon(
              status.icon,
              size: compact ? 12 : 14,
              color: accent,
            ),
          SizedBox(width: compact ? 4 : AppSpacing.xs),
          Text(
            status.label,
            style: AppTextStyles.label.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: child,
      ),
    );
  }
}

/// Lightweight processing row for AI/OCR/voice/bank flows.
class ProcessingStateIndicator extends StatelessWidget {
  const ProcessingStateIndicator({
    super.key,
    this.kind = ProcessingStateKind.generic,
  });

  final ProcessingStateKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: AppColors.secondary.withAlpha(48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingIndicator(style: AppLoadingStyle.dots),
          const SizedBox(width: AppSpacing.sm),
          Icon(kind.icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            kind.loadingHint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
