import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/design_tokens.dart';

/// Lightweight labeled field for profile/settings forms inside a card.
class ProfileFormField extends StatelessWidget {
  const ProfileFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.readOnly = false,
    this.optional = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.helperText,
    this.prefixIcon,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool readOnly;
  final bool optional;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 6),
                Text(
                  'Optional',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            readOnly: readOnly,
            enabled: !readOnly,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            inputFormatters: keyboardType == TextInputType.phone
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]'))]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              filled: true,
              fillColor: readOnly
                  ? AppColors.surfaceSecondary.withAlpha(160)
                  : AppColors.surfaceSecondary,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(helperText!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
