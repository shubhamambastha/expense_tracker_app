import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../services/guest_migration_service.dart';

/// Reviewable-diff confirm dialog shown before replaying guest data into a
/// freshly authenticated account.
Future<bool> showGuestMigrationDialog(
  BuildContext context, {
  required GuestMigrationSummary summary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GuestMigrationDialog(summary: summary),
  );
  return confirmed == true;
}

class _GuestMigrationDialog extends StatelessWidget {
  const _GuestMigrationDialog({required this.summary});

  final GuestMigrationSummary summary;

  String get _dateRange {
    if (summary.earliestDate == null || summary.latestDate == null) {
      return 'No dated transactions';
    }
    final formatter = DateFormat('MMM d, y');
    final start = formatter.format(summary.earliestDate!);
    final end = formatter.format(summary.latestDate!);
    return start == end ? start : '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.isSupportedCode(summary.currencyCode)
        ? summary.currencyCode
        : CurrencySettings.instance.currencyCode;
    final totalFormatted = NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 2,
    ).format(summary.totalExpense);

    return AlertDialog(
      title: const Text('Bring in your guest data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You added data while using this app as a guest. Import it into '
            'your account now?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(label: 'Transactions', value: '${summary.transactionCount}'),
          _SummaryRow(label: 'Accounts', value: '${summary.accountCount}'),
          _SummaryRow(label: 'Date range', value: _dateRange),
          _SummaryRow(label: 'Total spent', value: totalFormatted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You can also do this later from Settings — nothing is deleted '
            'if you skip it now.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
