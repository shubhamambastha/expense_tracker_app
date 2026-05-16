import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../utils/validators.dart';

/// Dialog for adding a new expense
class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({
    super.key,
    required this.categories,
    required this.onSave,
  });

  final List<String> categories;
  final void Function(Expense expense) onSave;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategory;
  AccountType _selectedAccount = AccountType.bank;
  ExpenseType _selectedType = ExpenseType.oneTime;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
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
      initialDate: isEndDate ? (_selectedEndDate ?? DateTime.now()) : _selectedDate,
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
    final amount = double.tryParse(_amountController.text) ?? 0;

    widget.onSave(
      Expense(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        accountType: _selectedAccount,
        endDate: _selectedType == ExpenseType.recurring ? _selectedEndDate : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: validateExpenseName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: validateAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: widget.categories
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                initialValue: _selectedAccount,
                items: AccountType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAccount = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Account type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseType>(
                initialValue: _selectedType,
                items: ExpenseType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Expense type'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                    ),
                  ),
                ],
              ),
              if (_selectedType == ExpenseType.recurring) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(context, true),
                        child: Text(_selectedEndDate == null
                            ? 'Select end date'
                            : 'Ends: ${DateFormat.yMMMd().format(_selectedEndDate!)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
