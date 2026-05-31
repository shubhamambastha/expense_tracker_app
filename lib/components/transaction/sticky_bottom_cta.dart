import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Primary and secondary actions pinned above the keyboard. Icon-only buttons;
/// [saveLabel] and [secondaryLabel] are used for tooltips and accessibility.
class StickyBottomCTA extends StatelessWidget {
  const StickyBottomCTA({
    super.key,
    required this.onSave,
    required this.onSaveAndAddAnother,
    this.saveLabel = 'Save Transaction',
    this.secondaryLabel = 'Save & Add Another',
    this.isBusy = false,
    this.showSaveAndAddAnother = true,
  });

  final VoidCallback onSave;
  final VoidCallback onSaveAndAddAnother;
  final String saveLabel;
  final String secondaryLabel;
  final bool isBusy;
  final bool showSaveAndAddAnother;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: saveLabel,
                button: true,
                child: Tooltip(
                  message: saveLabel,
                  child: FilledButton(
                    onPressed: isBusy ? null : onSave,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF003328),
                              ),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 22),
                  ),
                ),
              ),
            ),
            if (showSaveAndAddAnother) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  label: secondaryLabel,
                  button: true,
                  child: Tooltip(
                    message: secondaryLabel,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : onSaveAndAddAnother,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
