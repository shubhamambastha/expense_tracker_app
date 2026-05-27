import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../utils/snackbar_helper.dart';

/// Opens the add-account dialog from Settings, home, or Add Transaction.
typedef OnAddAccount = void Function({AccountType initialType});

String addAccountDialogTitle(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return 'Add bank account';
    case AccountType.creditCard:
      return 'Add credit card';
    case AccountType.cash:
      return 'Add cash wallet';
    case AccountType.other:
      return 'Add account';
  }
}

/// Shows a dialog to name an account, pick its [AccountType], and capture
/// optional balance / credit limit / due-day fields used by the dashboard's
/// Account Overview section.
Future<void> showAddAccountDialog(
  BuildContext context, {
  required Future<void> Function(Account account) onSave,
  AccountType initialType = AccountType.bank,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AddAccountDialog(
      initialType: initialType,
      onSave: onSave,
    ),
  );
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog({
    required this.initialType,
    required this.onSave,
  });

  final AccountType initialType;
  final Future<void> Function(Account account) onSave;

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _dueDayController;
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
    _creditLimitController = TextEditingController();
    _dueDayController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _selectedType == AccountType.creditCard;

    return AlertDialog(
      title: Text(addAccountDialogTitle(_selectedType)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'HDFC Credit Card',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: AccountType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
            ),
            if (!isCard) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Opening balance (optional)',
                  hintText: '0',
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _creditLimitController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Credit limit (optional)',
                  hintText: '100000',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _dueDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bill due day (1-31, optional)',
                  hintText: '12',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              SnackbarHelper.showMessage(
                context,
                'Enter an account name',
              );
              return;
            }

            final isCard = _selectedType == AccountType.creditCard;
            final balanceRaw = _balanceController.text.trim();
            final creditRaw = _creditLimitController.text.trim();
            final dueDayRaw = _dueDayController.text.trim();

            double opening = 0;
            if (!isCard && balanceRaw.isNotEmpty) {
              final parsed = double.tryParse(balanceRaw);
              if (parsed == null) {
                SnackbarHelper.showMessage(
                  context,
                  'Opening balance must be a number',
                );
                return;
              }
              opening = parsed;
            }

            double? creditLimit;
            if (isCard && creditRaw.isNotEmpty) {
              final parsed = double.tryParse(creditRaw);
              if (parsed == null || parsed <= 0) {
                SnackbarHelper.showMessage(
                  context,
                  'Credit limit must be a positive number',
                );
                return;
              }
              creditLimit = parsed;
            }

            int? dueDay;
            if (isCard && dueDayRaw.isNotEmpty) {
              final parsed = int.tryParse(dueDayRaw);
              if (parsed == null || parsed < 1 || parsed > 31) {
                SnackbarHelper.showMessage(
                  context,
                  'Due day must be between 1 and 31',
                );
                return;
              }
              dueDay = parsed;
            }

            Navigator.of(context).pop();
            await widget.onSave(
              Account(
                name: name,
                type: _selectedType,
                openingBalance: opening,
                creditLimit: creditLimit,
                dueDay: dueDay,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
