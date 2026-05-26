import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Sticky bottom action container.
///
/// Always reachable with the thumb, keyboard-aware (the parent wraps this in
/// the scaffold so `resizeToAvoidBottomInset` lifts it above the keyboard).
/// Primary CTA on top, secondary CTA underneath so even left-handed users
/// land on Save first.
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
              flex: showSaveAndAddAnother ? 3 : 1,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onSave,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF003328),
                          ),
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(saveLabel),
              ),
            ),
            if (showSaveAndAddAnother) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onSaveAndAddAnother,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    secondaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
