import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Compact label + value row for the Add Transaction primary form block.
///
/// Use [value] + [onTap] for picker rows, or [child] for inline inputs
/// (e.g. merchant TextField). No card chrome — dividers only.
class TransactionFormRow extends StatelessWidget {
  const TransactionFormRow({
    super.key,
    required this.label,
    this.value,
    this.placeholder,
    this.child,
    this.onTap,
    this.showDivider = true,
    this.showChevron = true,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final Widget? child;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final displayValue = hasValue ? value! : (placeholder ?? 'Select');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: child == null ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        label,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: child ??
                          Text(
                            displayValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasValue
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasValue ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                    ),
                    if (child == null && showChevron && onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: AppColors.border,
          ),
      ],
    );
  }
}
