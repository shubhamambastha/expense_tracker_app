import 'package:flutter/material.dart';

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

/// Shows a dialog to name an account and pick its [AccountType].
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
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(addAccountDialogTitle(_selectedType)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Account name',
              hintText: 'HDFC Credit Card',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Account type',
            ),
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
        ],
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
            Navigator.of(context).pop();
            await widget.onSave(Account(name: name, type: _selectedType));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
