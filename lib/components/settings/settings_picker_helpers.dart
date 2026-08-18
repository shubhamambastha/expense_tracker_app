import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';

/// Shared bottom-sheet pickers and small row widgets used across Settings
/// sub-screens. Extracted out of `SettingsPage` so each sub-screen can pick
/// without duplicating sheet plumbing.

/// Show a labelled list of options. Returns the picked option (or `null` if
/// the user dismissed the sheet).
Future<T?> selectFromList<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required T? current,
  required List<T> options,
  required String Function(T) labelFor,
  IconData Function(T)? iconFor,
  Color Function(T)? colorFor,
}) {
  return showModalBottomSheet<T>(
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
                child: Text(title, style: AppTextStyles.headingSmall),
              ),
              if (subtitle != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(subtitle, style: AppTextStyles.caption),
                ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = current != null && option == current;
                    return SettingsSelectableRow(
                      label: labelFor(option),
                      selected: selected,
                      icon: iconFor?.call(option),
                      iconColor: colorFor?.call(option),
                      onTap: () => Navigator.of(sheetContext).pop(option),
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

/// Convenience wrapper around [selectFromList] that immediately persists the
/// picked value through [onPicked].
Future<void> showSettingsOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required T current,
  required List<T> options,
  required String Function(T) labelFor,
  IconData Function(T)? iconFor,
  Color Function(T)? colorFor,
  required Future<void> Function(T) onPicked,
}) async {
  final picked = await selectFromList<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    current: current,
    options: options,
    labelFor: labelFor,
    iconFor: iconFor,
    colorFor: colorFor,
  );
  if (picked != null) {
    await onPicked(picked);
  }
}

/// Material icon used to represent an [AccountType] in picker / list rows.
IconData iconForAccountType(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return Icons.account_balance_rounded;
    case AccountType.creditCard:
      return Icons.credit_card_rounded;
    case AccountType.cash:
      return Icons.savings_rounded;
    case AccountType.other:
      return Icons.account_balance_wallet_rounded;
  }
}

/// Pill-style selectable row used by [selectFromList].
class SettingsSelectableRow extends StatelessWidget {
  const SettingsSelectableRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional leading icon avatar — used by category pickers so each option
  /// carries its own icon/color instead of reading as plain text.
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;
    return Material(
      color: selected
          ? AppColors.primary.withAlpha(28)
          : AppColors.surfaceSecondary,
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
            border: Border.all(
              color: selected
                  ? AppColors.primary.withAlpha(110)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withAlpha(selected ? 48 : 28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tint, size: 17),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet row representing one account option in default-account
/// pickers. Supports an icon + title + subtitle and a selected check.
class SettingsAccountPickerRow extends StatelessWidget {
  const SettingsAccountPickerRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withAlpha(28)
          : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withAlpha(110)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact card row that lists an existing [Account] (read-only).
class SettingsAccountListRow extends StatelessWidget {
  const SettingsAccountListRow({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final icon = iconForAccountType(account.type);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          account.name,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(account.type.label, style: AppTextStyles.caption),
      ),
    );
  }
}
