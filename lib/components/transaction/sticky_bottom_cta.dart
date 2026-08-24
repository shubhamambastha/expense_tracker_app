import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Primary save action pinned above the keyboard.
///
/// Renders a single full-width gradient button by default. Set
/// [showSaveAndAddAnother] for a secondary outlined action (settings forms).
class StickyBottomCTA extends StatelessWidget {
  const StickyBottomCTA({
    super.key,
    required this.onSave,
    this.onSaveAndAddAnother,
    this.saveLabel = 'Save Transaction',
    this.secondaryLabel = 'Save & Add Another',
    this.isBusy = false,
    this.showSaveAndAddAnother = false,
  });

  final VoidCallback onSave;
  final VoidCallback? onSaveAndAddAnother;
  final String saveLabel;
  final String secondaryLabel;
  final bool isBusy;
  final bool showSaveAndAddAnother;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: showSaveAndAddAnother && onSaveAndAddAnother != null
            ? Row(
                children: [
                  Expanded(
                    child: _PrimarySaveButton(
                      label: saveLabel,
                      isBusy: isBusy,
                      onTap: onSave,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SecondaryButton(
                      label: secondaryLabel,
                      isBusy: isBusy,
                      onTap: onSaveAndAddAnother!,
                    ),
                  ),
                ],
              )
            : _PrimarySaveButton(
                label: saveLabel,
                isBusy: isBusy,
                onTap: onSave,
              ),
      ),
    );
  }
}

class _PrimarySaveButton extends StatelessWidget {
  const _PrimarySaveButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBusy
                  ? [
                      AppColors.primary.withAlpha(140),
                      AppColors.secondary.withAlpha(140),
                    ]
                  : [AppColors.primary, AppColors.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: AppRadii.buttonRadius,
            boxShadow: isBusy
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(64),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onAccent,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppRadii.buttonRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
