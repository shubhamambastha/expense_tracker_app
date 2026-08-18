import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/snackbar_helper.dart';

/// Opens the base currency picker as a modal bottom sheet.
///
/// Behaviour mirrors the previous inline implementation in
/// `expense_home_page.dart` so the same UX is shared between Settings
/// and any other entry points (e.g. the Profile Header currency pill).
Future<void> showCurrencyPickerSheet(BuildContext context) {
  final settings = CurrencySettings.instance;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final currentCode = settings.currencyCode;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xl,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      'Base currency',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      'All amounts are entered and shown in this currency.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm,
                      ),
                      itemCount: CurrencySettings.supported.length,
                      itemBuilder: (context, index) {
                        final option = CurrencySettings.supported[index];
                        final selected = option.code == currentCode;

                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withAlpha(40)
                                  : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withAlpha(110)
                                    : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              option.symbol,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            option.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            option.code,
                            style: AppTextStyles.caption,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () async {
                            await settings.setCurrency(option.code);
                            setSheetState(() {});
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            if (!context.mounted) return;
                            SnackbarHelper.showSuccess(
                              context,
                              'Currency set to ${option.name}',
                            );
                          },
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
    },
  );
}
