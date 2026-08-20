import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/subscription_catalog.dart';
import '../common/subscription_badge.dart';
import '../settings/settings_picker_helpers.dart';

/// Bottom sheet listing the curated subscription catalog, alphabetically
/// sorted — shaped like the category picker sheet (drag handle, title, 75%
/// max height), plus a trailing "Create new subscription" row matching the
/// category picker's "Add category" pattern: tapping it just closes the
/// sheet with no selection, so the caller's merchant field stays free-typed.
Future<SubscriptionEntry?> showSubscriptionPickerSheet({
  required BuildContext context,
  String? selectedName,
}) {
  final entries = [...SubscriptionCatalog.entries]
    ..sort((a, b) => a.name.compareTo(b.name));

  return showModalBottomSheet<SubscriptionEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text('Pick a subscription', style: AppTextStyles.headingSmall),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: entries.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == entries.length) {
                      return _CreateNewSubscriptionRow(
                        onTap: () => Navigator.of(sheetContext).pop(),
                      );
                    }
                    final entry = entries[index];
                    final isSelected = entry.name == selectedName;
                    return Semantics(
                      label: '${entry.name}, subscription',
                      button: true,
                      child: SettingsSelectableRow(
                        label: entry.name,
                        selected: isSelected,
                        leading: SubscriptionBadge(entry: entry, size: 32),
                        onTap: () => Navigator.of(sheetContext).pop(entry),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Trailing row — "none of these, I'll type my own." Styled distinctly
/// (accent-colored, plus icon) matching the category picker's "Add
/// category" row, but with no side effect beyond closing the sheet: the
/// catalog is fixed, there's nothing to add to it.
class _CreateNewSubscriptionRow extends StatelessWidget {
  const _CreateNewSubscriptionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withAlpha(28),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withAlpha(110)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Create new subscription',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
