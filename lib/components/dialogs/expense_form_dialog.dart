import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../utils/category_style.dart';
import '../../utils/validators.dart';

/// Dialog for adding a new expense or editing an existing one.
class ExpenseFormDialog extends StatefulWidget {
  const ExpenseFormDialog({
    super.key,
    required this.accounts,
    required this.onSave,
    this.expense,
  });

  final List<Account> accounts;
  final void Function(Expense expense) onSave;
  final Expense? expense;

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  late String _selectedCategory;
  Account? _selectedAccount;
  ExpenseType _selectedType = ExpenseType.oneTime;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.expense;
    final currency = CurrencySettings.instance;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toStringAsFixed(
        currency.decimalDigits,
      );
      _selectedCategory = existing.category;
      _selectedAccount = widget.accounts.isEmpty
          ? null
          : widget.accounts.firstWhere(
              (a) => a.id == existing.accountId,
              orElse: () => widget.accounts.first,
            );
      _selectedType = existing.type;
      _selectedDate = existing.date;
      _selectedEndDate = existing.endDate;
    } else {
      _selectedAccount =
          widget.accounts.isEmpty ? null : widget.accounts.first;
    }
    _selectedCategory = _resolveInitialCategory(existing?.category);
  }

  String _resolveInitialCategory(String? existingName) {
    final catalog = CategoryCatalog.instance;
    if (existingName != null && catalog.findByName(existingName) != null) {
      return existingName;
    }
    if (catalog.names.isNotEmpty) return catalog.names.first;
    return DefaultCategories.seeds.first.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  String get _title => _isEditing ? 'Edit expense' : 'New expense';

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
        id: widget.expense?.id,
        userId: widget.expense?.userId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        accountId: _selectedAccount!.id!,
        endDate: _selectedType == ExpenseType.recurring
            ? _selectedEndDate
            : null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _openCategoryPicker() {
    final catalog = CategoryCatalog.instance;
    final categories = catalog.categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add categories from Profile first.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = catalog.colorForName(category.name);
              final isSelected = category.name == _selectedCategory;

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withAlpha(36),
                  child: Icon(
                    CategoryIcons.iconForKey(category.iconKey),
                    color: color,
                    size: 18,
                  ),
                ),
                title: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: color)
                    : null,
                onTap: () {
                  setState(() => _selectedCategory = category.name);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openAccountPicker() {
    if (widget.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an account from Profile first.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: widget.accounts.length,
            itemBuilder: (context, index) {
              final account = widget.accounts[index];
              final isSelected = account.id == _selectedAccount?.id;

              return ListTile(
                leading: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: isSelected
                      ? Theme.of(sheetContext).colorScheme.primary
                      : null,
                ),
                title: Text(account.name),
                subtitle: Text(account.type.label),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedAccount = account);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catalog = CategoryCatalog.instance;
    final currency = CurrencySettings.instance;
    final categoryColor = catalog.colorForName(_selectedCategory);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final width = math.min(440.0, MediaQuery.sizeOf(context).width - 32);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: width,
        height: maxHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(80),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _DialogHeader(
                  title: _title,
                  subtitle: DateFormat.MMMMEEEEd().format(_selectedDate),
                  isEditing: _isEditing,
                  accent: categoryColor,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AmountCard(
                          controller: _amountController,
                          focusNode: _amountFocus,
                          currencyCode: currency.currencyCode,
                          prefix: currency.inputPrefix,
                          hint: currency.decimalDigits == 0 ? '0' : '0.00',
                          accent: categoryColor,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Coffee, groceries, rent…',
                            prefixIcon: Icon(
                              Icons.notes_rounded,
                              color: colorScheme.primary,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withAlpha(90),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: validateExpenseName,
                        ),
                        const SizedBox(height: 14),
                        _PickerField(
                          label: 'Category',
                          value: _selectedCategory,
                          helperText: catalog.isEmpty
                              ? 'Add categories from Profile'
                              : null,
                          leading: _CategoryIcon(
                            iconKey: catalog
                                    .findByName(_selectedCategory)
                                    ?.iconKey ??
                                CategoryIcons.defaultKey,
                            color: categoryColor,
                          ),
                          onTap: _openCategoryPicker,
                        ),
                        const SizedBox(height: 12),
                        _PickerField(
                          label: 'Account',
                          value: _selectedAccount == null
                              ? 'Select account'
                              : '${_selectedAccount!.name} · ${_selectedAccount!.type.label}',
                          helperText: widget.accounts.isEmpty
                              ? 'Add accounts from Profile'
                              : null,
                          leading: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          onTap: _openAccountPicker,
                        ),
                        const SizedBox(height: 14),
                        _ExpenseTypeSelector(
                          selectedType: _selectedType,
                          onChanged: (value) {
                            setState(() => _selectedType = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DateTile(
                                label: 'Date',
                                value:
                                    DateFormat.MMMd().format(_selectedDate),
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
                                      ? 'Optional'
                                      : DateFormat.MMMd()
                                          .format(_selectedEndDate!),
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
                _DialogActions(
                  isEditing: _isEditing,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.isEditing,
    required this.accent,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final bool isEditing;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withAlpha(28),
            colorScheme.primary.withAlpha(14),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.add_card_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.focusNode,
    required this.currencyCode,
    required this.prefix,
    required this.hint,
    required this.accent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String currencyCode;
  final String prefix;
  final String hint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount · $currencyCode',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textInputAction: TextInputAction.next,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              prefixText: prefix,
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            validator: validateAmount,
          ),
        ],
      ),
    );
  }
}

/// Tappable field that opens a bottom sheet list (avoids dropdown layout bugs).
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.helperText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? leading;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fill = colorScheme.surfaceContainerHighest.withAlpha(90);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.iconKey, required this.color});

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        CategoryIcons.iconForKey(iconKey),
        color: color,
        size: 20,
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<ExpenseType>(
      segments: const [
        ButtonSegment(
          value: ExpenseType.oneTime,
          icon: Icon(Icons.event_available_rounded, size: 18),
          label: Text('One-time'),
        ),
        ButtonSegment(
          value: ExpenseType.recurring,
          icon: Icon(Icons.autorenew_rounded, size: 18),
          label: Text('Recurring'),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 10),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary.withAlpha(120)
                : colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
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

    return Material(
      color: colorScheme.surfaceContainerHighest.withAlpha(90),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(70)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onSave,
            icon: Icon(isEditing ? Icons.check_rounded : Icons.add_rounded),
            label: Text(isEditing ? 'Save changes' : 'Add expense'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
