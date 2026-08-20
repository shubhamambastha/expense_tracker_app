import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/subscription_catalog.dart';
import '../common/subscription_badge.dart';
import '../settings/settings_picker_helpers.dart';

/// Bottom sheet listing the curated subscription catalog, alphabetically
/// sorted — shaped like the category picker sheet (drag handle, title, 75%
/// max height). No "add" row: unlike categories, this catalog is a fixed
/// const list, not user-editable.
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
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
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
