import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../utils/validators.dart';

/// Dialog for adding a new expense
class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({
    super.key,
    required this.categories,
    required this.accounts,
    required this.onSave,
  });

  final List<String> categories;
  final List<Account> accounts;
  final void Function(Expense expense) onSave;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategory;
  Account? _selectedAccount;
  ExpenseType _selectedType = ExpenseType.oneTime;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
    _selectedAccount = widget.accounts.isEmpty ? null : widget.accounts.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isEndDate) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: isEndDate
          ? (_selectedEndDate ?? DateTime.now())
          : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate == null) return;
    setState(() {
      if (isEndDate) {
        _selectedEndDate = newDate;
      } else {
        _selectedDate = newDate;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an account from Profile first.')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;

    widget.onSave(
      Expense(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        accountId: _selectedAccount!.id,
        endDate: _selectedType == ExpenseType.recurring
            ? _selectedEndDate
            : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 14, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New expense',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.MMMMEEEEd().format(_selectedDate),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(95),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          hintText: '0.00',
                          labelText: 'Amount',
                          border: InputBorder.none,
                        ),
                        validator: validateAmount,
                      ),
                      Divider(color: colorScheme.outlineVariant),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.edit_note_rounded),
                          hintText: 'What was this for?',
                          labelText: 'Description',
                          border: InputBorder.none,
                        ),
                        validator: validateExpenseName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Account?>(
                  initialValue: _selectedAccount,
                  items: widget.accounts
                      .map(
                        (account) => DropdownMenuItem<Account?>(
                          value: account,
                          child: Text(
                            '${account.name} • ${account.type.label}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccount = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Account',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                    ),
                    helperText: widget.accounts.isEmpty
                        ? 'Add named accounts from Profile'
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                _ExpenseTypeSelector(
                  selectedType: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Date',
                        value: DateFormat.MMMd().format(_selectedDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: () => _pickDate(context, false),
                      ),
                    ),
                    if (_selectedType == ExpenseType.recurring) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateTile(
                          label: 'Ends',
                          value: _selectedEndDate == null
                              ? 'Choose'
                              : DateFormat.MMMd().format(_selectedEndDate!),
                          icon: Icons.event_busy_rounded,
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpenseTypeSelector extends StatelessWidget {
  const _ExpenseTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final ExpenseType selectedType;
  final ValueChanged<ExpenseType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExpenseType>(
      segments: const [
        ButtonSegment(
          value: ExpenseType.oneTime,
          icon: Icon(Icons.event_available_rounded),
          label: Text('One-time'),
        ),
        ButtonSegment(
          value: ExpenseType.recurring,
          icon: Icon(Icons.autorenew_rounded),
          label: Text('Recurring'),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
