import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';

/// Label/value row for read-only detail sections.
class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({
    super.key,
    required this.label,
    this.value = '',
    this.icon,
    this.valueWidget,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: valueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
          ),
        ],
      ),
    );
  }
}
