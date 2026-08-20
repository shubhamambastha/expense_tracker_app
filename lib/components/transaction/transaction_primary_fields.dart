import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/dialogs/add_account_dialog.dart';
import '../../components/dialogs/add_category_sheet.dart';
import '../../components/settings/settings_picker_helpers.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../models/income_category.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../utils/income_flow_helpers.dart';
import '../../utils/subscription_catalog.dart';
import 'subscription_picker_sheet.dart';
import 'transaction_form_row.dart';

/// Compact primary field block for Add Transaction — no cards, no horizontal
/// scroll. Kind-aware rows with bottom-sheet pickers.
class TransactionPrimaryFields extends StatelessWidget {
  const TransactionPrimaryFields({
    super.key,
    required this.kind,
    required this.merchantController,
    required this.merchantFocus,
    required this.categoryName,
    required this.accountId,
    required this.transferToAccountId,
    required this.date,
    required this.accounts,
    required this.recentCategoryNames,
    required this.recentIncomeCategoryNames,
    required this.onCategoryChanged,
    required this.onSubscriptionPicked,
    required this.onAccountChanged,
    required this.onTransferToChanged,
    required this.onPickDate,
    this.onAddAccount,
  });

  final TransactionKind kind;
  final TextEditingController merchantController;
  final FocusNode merchantFocus;
  final String? categoryName;
  final int? accountId;
  final int? transferToAccountId;
  final DateTime date;
  final List<Account> accounts;
  final List<String> recentCategoryNames;
  final List<String> recentIncomeCategoryNames;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<SubscriptionEntry> onSubscriptionPicked;
  final ValueChanged<Account> onAccountChanged;
  final ValueChanged<Account> onTransferToChanged;
  final Future<void> Function() onPickDate;
  final OnAddAccount? onAddAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: switch (kind) {
        TransactionKind.expense => _ExpenseFields(
            merchantController: merchantController,
            merchantFocus: merchantFocus,
            categoryName: categoryName,
            accountId: accountId,
            date: date,
            accounts: accounts,
            recentCategoryNames: recentCategoryNames,
            onCategoryChanged: onCategoryChanged,
            onSubscriptionPicked: onSubscriptionPicked,
            onAccountChanged: onAccountChanged,
            onPickDate: onPickDate,
            onAddAccount: onAddAccount,
          ),
        TransactionKind.income => _IncomeFields(
            merchantController: merchantController,
            merchantFocus: merchantFocus,
            categoryName: categoryName,
            accountId: accountId,
            date: date,
            accounts: accounts,
            recentIncomeCategoryNames: recentIncomeCategoryNames,
            onCategoryChanged: onCategoryChanged,
            onAccountChanged: onAccountChanged,
            onPickDate: onPickDate,
            onAddAccount: onAddAccount,
          ),
        TransactionKind.transfer => _TransferFields(
            accountId: accountId,
            transferToAccountId: transferToAccountId,
            date: date,
            accounts: accounts,
            onAccountChanged: onAccountChanged,
            onTransferToChanged: onTransferToChanged,
            onPickDate: onPickDate,
            onAddAccount: onAddAccount,
          ),
      },
    );
  }
}

class _ExpenseFields extends StatelessWidget {
  const _ExpenseFields({
    required this.merchantController,
    required this.merchantFocus,
    required this.categoryName,
    required this.accountId,
    required this.date,
    required this.accounts,
    required this.recentCategoryNames,
    required this.onCategoryChanged,
    required this.onSubscriptionPicked,
    required this.onAccountChanged,
    required this.onPickDate,
    this.onAddAccount,
  });

  final TextEditingController merchantController;
  final FocusNode merchantFocus;
  final String? categoryName;
  final int? accountId;
  final DateTime date;
  final List<Account> accounts;
  final List<String> recentCategoryNames;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<SubscriptionEntry> onSubscriptionPicked;
  final ValueChanged<Account> onAccountChanged;
  final Future<void> Function() onPickDate;
  final OnAddAccount? onAddAccount;

  Future<void> _pickSubscription(BuildContext context) async {
    final picked = await showSubscriptionPickerSheet(
      context: context,
      selectedName: merchantController.text,
    );
    if (picked != null) onSubscriptionPicked(picked);
  }

  Future<void> _pickCategory(BuildContext context) async {
    final catalog = CategoryCatalog.instance;
    final names = _orderedExpenseNames(catalog.categories, recentCategoryNames);

    final picked = await _showCategoryPicker(
      context: context,
      title: 'Category',
      categories: names,
      selected: categoryName,
      addCategoryTitle: 'Add category',
      iconFor: catalog.iconForName,
      colorFor: catalog.colorForName,
      onAddCategory: (name, iconKey) =>
          catalog.addCategory(name: name, iconKey: iconKey),
    );
    if (picked != null) onCategoryChanged(picked);
  }

  Future<void> _pickAccount(BuildContext context) async {
    await _showAccountPicker(
      context: context,
      title: 'Account',
      accounts: accounts,
      selectedId: accountId,
      onAddAccount: onAddAccount,
      onPicked: onAccountChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = _accountById(accounts, accountId);

    return Column(
      children: [
        TransactionFormRow(
          label: 'Merchant',
          showChevron: false,
          child: Row(
            children: [
              Semantics(
                label: 'Pick subscription from list',
                button: true,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.list_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _pickSubscription(context),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: merchantController,
                  focusNode: merchantFocus,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => merchantFocus.unfocus(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  decoration: InputDecoration(
                    hintText: 'Swiggy',
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        TransactionFormRow(
          label: 'Category',
          value: categoryName,
          placeholder: 'Food',
          onTap: () => _pickCategory(context),
        ),
        TransactionFormRow(
          label: 'Account',
          value: account?.name,
          placeholder: 'Select account',
          onTap: accounts.isEmpty && onAddAccount != null
              ? () => onAddAccount!()
              : () => _pickAccount(context),
        ),
        TransactionFormRow(
          label: 'Date',
          value: _dateLabel(date),
          onTap: onPickDate,
          showDivider: false,
        ),
      ],
    );
  }
}

class _IncomeFields extends StatelessWidget {
  const _IncomeFields({
    required this.merchantController,
    required this.merchantFocus,
    required this.categoryName,
    required this.accountId,
    required this.date,
    required this.accounts,
    required this.recentIncomeCategoryNames,
    required this.onCategoryChanged,
    required this.onAccountChanged,
    required this.onPickDate,
    this.onAddAccount,
  });

  final TextEditingController merchantController;
  final FocusNode merchantFocus;
  final String? categoryName;
  final int? accountId;
  final DateTime date;
  final List<Account> accounts;
  final List<String> recentIncomeCategoryNames;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Account> onAccountChanged;
  final Future<void> Function() onPickDate;
  final OnAddAccount? onAddAccount;

  Future<void> _pickCategory(BuildContext context) async {
    final catalog = IncomeCategoryCatalog.instance;
    final names =
        _orderedIncomeNames(catalog.categories, recentIncomeCategoryNames);

    final picked = await _showCategoryPicker(
      context: context,
      title: 'Income category',
      categories: names,
      selected: categoryName,
      addCategoryTitle: 'Add income category',
      iconFor: catalog.iconForName,
      colorFor: catalog.colorForName,
      onAddCategory: (name, iconKey) =>
          catalog.addCategory(name: name, iconKey: iconKey),
    );
    if (picked != null) onCategoryChanged(picked);
  }

  Future<void> _pickAccount(BuildContext context) async {
    await _showAccountPicker(
      context: context,
      title: 'Deposit to',
      accounts: accounts,
      selectedId: accountId,
      onAddAccount: onAddAccount,
      onPicked: onAccountChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = _accountById(accounts, accountId);
    final payerLabel = IncomeFlowHelpers.payerFieldLabel(categoryName);
    final payerHint = IncomeFlowHelpers.payerFieldHint(categoryName);

    return Column(
      children: [
        TransactionFormRow(
          label: 'Category',
          value: categoryName,
          placeholder: 'Salary',
          onTap: () => _pickCategory(context),
        ),
        TransactionFormRow(
          label: 'Deposit to',
          value: account?.name,
          placeholder: 'Select account',
          onTap: accounts.isEmpty && onAddAccount != null
              ? () => onAddAccount!()
              : () => _pickAccount(context),
        ),
        TransactionFormRow(
          label: payerLabel,
          showChevron: false,
          child: TextField(
            controller: merchantController,
            focusNode: merchantFocus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => merchantFocus.unfocus(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              hintText: payerHint,
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        TransactionFormRow(
          label: 'Date',
          value: _dateLabel(date),
          onTap: onPickDate,
          showDivider: false,
        ),
      ],
    );
  }
}

class _TransferFields extends StatelessWidget {
  const _TransferFields({
    required this.accountId,
    required this.transferToAccountId,
    required this.date,
    required this.accounts,
    required this.onAccountChanged,
    required this.onTransferToChanged,
    required this.onPickDate,
    this.onAddAccount,
  });

  final int? accountId;
  final int? transferToAccountId;
  final DateTime date;
  final List<Account> accounts;
  final ValueChanged<Account> onAccountChanged;
  final ValueChanged<Account> onTransferToChanged;
  final Future<void> Function() onPickDate;
  final OnAddAccount? onAddAccount;

  Future<void> _pickFrom(BuildContext context) async {
    await _showAccountPicker(
      context: context,
      title: 'From account',
      accounts: accounts,
      selectedId: accountId,
      onAddAccount: onAddAccount,
      onPicked: onAccountChanged,
    );
  }

  Future<void> _pickTo(BuildContext context) async {
    await _showAccountPicker(
      context: context,
      title: 'To account',
      accounts: accounts,
      selectedId: transferToAccountId,
      onAddAccount: onAddAccount,
      onPicked: onTransferToChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final from = _accountById(accounts, accountId);
    final to = _accountById(accounts, transferToAccountId);

    return Column(
      children: [
        TransactionFormRow(
          label: 'From',
          value: from?.name,
          placeholder: 'Select account',
          onTap: accounts.isEmpty && onAddAccount != null
              ? () => onAddAccount!()
              : () => _pickFrom(context),
        ),
        TransactionFormRow(
          label: 'To',
          value: to?.name,
          placeholder: 'Select account',
          onTap: accounts.isEmpty && onAddAccount != null
              ? () => onAddAccount!()
              : () => _pickTo(context),
        ),
        TransactionFormRow(
          label: 'Date',
          value: _dateLabel(date),
          onTap: onPickDate,
          showDivider: false,
        ),
      ],
    );
  }
}

Account? _accountById(List<Account> accounts, int? id) {
  if (id == null || accounts.isEmpty) return null;
  for (final a in accounts) {
    if (a.id == id) return a;
  }
  return accounts.first;
}

List<String> _orderedExpenseNames(
  List<ExpenseCategory> all,
  List<String> prioritisedNames,
) {
  if (prioritisedNames.isEmpty) return all.map((c) => c.name).toList();
  final byName = {for (final c in all) c.name: c.name};
  final ordered = <String>[];
  final seen = <String>{};
  for (final name in prioritisedNames) {
    if (byName.containsKey(name) && seen.add(name)) ordered.add(name);
  }
  for (final c in all) {
    if (seen.add(c.name)) ordered.add(c.name);
  }
  return ordered;
}

List<String> _orderedIncomeNames(
  List<IncomeCategory> all,
  List<String> prioritisedNames,
) {
  if (prioritisedNames.isEmpty) return all.map((c) => c.name).toList();
  final byName = {for (final c in all) c.name: c.name};
  final ordered = <String>[];
  final seen = <String>{};
  for (final name in prioritisedNames) {
    if (byName.containsKey(name) && seen.add(name)) ordered.add(name);
  }
  for (final c in all) {
    if (seen.add(c.name)) ordered.add(c.name);
  }
  return ordered;
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final selectedDay = DateTime(date.year, date.month, date.day);
  if (selectedDay == today) return 'Today';
  if (selectedDay == yesterday) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}

/// Category picker sheet with a trailing "Add category" row. Tapping it
/// opens [showAddCategorySheet] as a stacked overlay; on success both sheets
/// close and the picker resolves with the newly created category name, so
/// the caller can select it straight into the form field.
Future<String?> _showCategoryPicker({
  required BuildContext context,
  required String title,
  required List<String> categories,
  required String? selected,
  required String addCategoryTitle,
  required IconData Function(String name) iconFor,
  required Color Function(String name) colorFor,
  required Future<void> Function(String name, String iconKey) onAddCategory,
}) {
  return showModalBottomSheet<String>(
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
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return _AddCategoryRow(
                        onTap: () async {
                          String? createdName;
                          final saved = await showAddCategorySheet(
                            sheetContext,
                            title: addCategoryTitle,
                            onSave: (name, iconKey) async {
                              await onAddCategory(name, iconKey);
                              createdName = name.trim();
                            },
                          );
                          if (saved == true &&
                              createdName != null &&
                              sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(createdName);
                          }
                        },
                      );
                    }
                    final name = categories[index];
                    final isSelected = name == selected;
                    return SettingsSelectableRow(
                      label: name,
                      selected: isSelected,
                      icon: iconFor(name),
                      iconColor: colorFor(name),
                      onTap: () => Navigator.of(sheetContext).pop(name),
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

/// Trailing row in the category picker that opens the add-category overlay.
/// Styled distinctly from the plain [SettingsSelectableRow] options above it
/// — accent-colored text and a leading plus icon — so it reads as an action
/// rather than another category to pick.
class _AddCategoryRow extends StatelessWidget {
  const _AddCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withAlpha(28),
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
            border: Border.all(color: AppColors.primary.withAlpha(110)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add category',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAccountPicker({
  required BuildContext context,
  required String title,
  required List<Account> accounts,
  required int? selectedId,
  required ValueChanged<Account> onPicked,
  OnAddAccount? onAddAccount,
}) async {
  if (accounts.isEmpty) {
    if (onAddAccount != null) onAddAccount();
    return;
  }

  await showModalBottomSheet<void>(
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
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: accounts.length + (onAddAccount != null ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == accounts.length) {
                      return SettingsSelectableRow(
                        label: 'Add account',
                        selected: false,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onAddAccount!();
                        },
                      );
                    }
                    final account = accounts[index];
                    final selected = account.id == selectedId;
                    return SettingsAccountPickerRow(
                      title: account.name,
                      subtitle: account.type.label,
                      selected: selected,
                      icon: iconForAccountType(account.type),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onPicked(account);
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
}
