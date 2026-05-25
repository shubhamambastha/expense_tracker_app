import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
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
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = catalog.colorForName(category.name);
              final isSelected = category.name == _selectedCategory;

              return ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    CategoryIcons.iconForKey(category.iconKey),
                    color: color,
                    size: 18,
                  ),
                ),
                title: Text(
                  category.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
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
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            itemCount: widget.accounts.length,
            itemBuilder: (context, index) {
              final account = widget.accounts[index];
              final isSelected = account.id == _selectedAccount?.id;

              return ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary)
                        .withAlpha(28),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                title: Text(
                  account.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  account.type.label,
                  style: AppTextStyles.caption,
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
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
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.elevated,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.cardRadius,
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xs,
                        AppSpacing.xl,
                        AppSpacing.sm,
                      ),
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
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization:
                                TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Coffee, groceries, rent…',
                              prefixIcon: Icon(
                                Icons.notes_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            validator: validateExpenseName,
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
                          const SizedBox(height: AppSpacing.md),
                          _PickerField(
                            label: 'Account',
                            value: _selectedAccount == null
                                ? 'Select account'
                                : '${_selectedAccount!.name} · ${_selectedAccount!.type.label}',
                            helperText: widget.accounts.isEmpty
                                ? 'Add accounts from Profile'
                                : null,
                            leading: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onTap: _openAccountPicker,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ExpenseTypeSelector(
                            selectedType: _selectedType,
                            onChanged: (value) {
                              setState(() => _selectedType = value);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _DateTile(
                                  label: 'Date',
                                  value: DateFormat.MMMd()
                                      .format(_selectedDate),
                                  icon: Icons.calendar_today_rounded,
                                  onTap: () => _pickDate(context, false),
                                ),
                              ),
                              if (_selectedType ==
                                  ExpenseType.recurring) ...[
                                const SizedBox(width: AppSpacing.sm),
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
      ),
    )
        .animate()
        .fadeIn(duration: AppDurations.short)
        .scaleXY(
          begin: 0.96,
          end: 1.0,
          duration: AppDurations.page,
          curve: AppCurves.spring,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withAlpha(36),
            AppColors.secondary.withAlpha(14),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withAlpha(48),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withAlpha(80)),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.add_card_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.surfaceSecondary,
          ],
        ),
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount · $currencyCode',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textInputAction: TextInputAction.next,
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              prefixText: prefix,
              hintText: hint,
              prefixStyle: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textSecondary.withAlpha(140),
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              errorStyle: AppTextStyles.caption.copyWith(
                color: AppColors.danger,
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.inputRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadii.inputRadius,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md + 2,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTextStyles.label),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(helperText!, style: AppTextStyles.caption),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.buttonRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTile(
              icon: Icons.event_available_rounded,
              label: 'One-time',
              selected: selectedType == ExpenseType.oneTime,
              onTap: () => onChanged(ExpenseType.oneTime),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentTile(
              icon: Icons.autorenew_rounded,
              label: 'Recurring',
              selected: selectedType == ExpenseType.recurring,
              onTap: () => onChanged(ExpenseType.recurring),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withAlpha(32) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadii.inputRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.inputRadius,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onSave,
            icon: Icon(
              isEditing ? Icons.check_rounded : Icons.add_rounded,
              size: 20,
            ),
            label: Text(isEditing ? 'Save changes' : 'Add expense'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
