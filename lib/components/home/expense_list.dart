import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../services/currency_settings.dart';
import '../../models/expense.dart';
import '../../services/category_catalog.dart';
import '../../utils/constants.dart';
import 'expense_list_item.dart';

/// Expense list component - displays expenses with filters and search.
class ExpenseList extends StatefulWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.accounts,
    required this.isLoading,
    this.onEdit,
    this.onDelete,
  });

  final List<Expense> expenses;
  final List<Account> accounts;
  final bool isLoading;
  final void Function(Expense expense)? onEdit;
  final void Function(Expense expense)? onDelete;

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final TextEditingController _searchController = TextEditingController();
  String? _categoryFilter;
  AccountType? _accountFilter;
  ExpenseType? _typeFilter;
  DateTime? _startDate;
  DateTime? _endDate;


  List<Expense> get _filteredExpenses {
    final query = _searchController.text.toLowerCase().trim();
    return widget.expenses.where((expense) {
      if (_categoryFilter != null &&
          _categoryFilter!.isNotEmpty &&
          expense.category != _categoryFilter) {
        return false;
      }
      final account = _accountForExpense(expense);
      if (_accountFilter != null && account?.type != _accountFilter) {
        return false;
      }
      if (_typeFilter != null && expense.type != _typeFilter) return false;
      if (_startDate != null && expense.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && expense.date.isAfter(_endDate!)) return false;
      if (query.isEmpty) return true;

      final accountLabel = _accountLabelForExpense(account).toLowerCase();
      return expense.name.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query) ||
          accountLabel.contains(query);
    }).toList();
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _categoryFilter != null ||
        _accountFilter != null ||
        _typeFilter != null ||
        _startDate != null ||
        _endDate != null;
  }

  double get _filteredTotal {
    return _filteredExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  int get _filteredRecurringCount {
    return _filteredExpenses.where((expense) => expense.isRecurring).length;
  }

  Color _colorForCategory(String category) =>
      CategoryCatalog.instance.colorForName(category);

  Account? _accountForExpense(Expense expense) {
    final accountId = expense.accountId;
    if (accountId != null) {
      for (final account in widget.accounts) {
        if (account.id == accountId) return account;
      }
    }
    return null;
  }

  String _accountLabelForExpense(Account? account) {
    return account?.name ?? 'Unknown account';
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _categoryFilter = null;
      _accountFilter = null;
      _typeFilter = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        String? localCategory = _categoryFilter;
        AccountType? localAccount = _accountFilter;
        ExpenseType? localType = _typeFilter;
        DateTime? localStart = _startDate;
        DateTime? localEnd = _endDate;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickStart() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localStart ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setLocalState(() => localStart = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localEnd ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setLocalState(() => localEnd = picked);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Reset filters',
                        onPressed: () {
                          setLocalState(() {
                            localCategory = null;
                            localAccount = null;
                            localType = null;
                            localStart = null;
                            localEnd = null;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: localCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    items: [null, ...CategoryCatalog.instance.names]
                        .map(
                          (category) => DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category ?? 'All categories'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setLocalState(() => localCategory = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AccountType?>(
                    initialValue: localAccount,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [null, ...AccountType.values]
                        .map(
                          (account) => DropdownMenuItem<AccountType?>(
                            value: account,
                            child: Text(account?.label ?? 'All accounts'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setLocalState(() => localAccount = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ExpenseType?>(
                    initialValue: localType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: [null, ...ExpenseType.values]
                        .map(
                          (type) => DropdownMenuItem<ExpenseType?>(
                            value: type,
                            child: Text(type?.label ?? 'All types'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setLocalState(() => localType = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DateFilterField(
                          label: 'From',
                          value: localStart,
                          onTap: pickStart,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateFilterField(
                          label: 'To',
                          value: localEnd,
                          onTap: pickEnd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _categoryFilter = localCategory;
                              _accountFilter = localAccount;
                              _typeFilter = localType;
                              _startDate = localStart;
                              _endDate = localEnd;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.expenses.isEmpty) {
      return const _EmptyExpensesCard();
    }

    final rows = _filteredExpenses;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _ExpenseOverviewCard(
            total: _filteredTotal,
            count: rows.length,
            recurringCount: _filteredRecurringCount,
            isFiltered: _hasActiveFilters,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: _ExpenseSearchBar(
            controller: _searchController,
            hasActiveFilters: _hasActiveFilters,
            onChanged: (_) => setState(() {}),
            onFilterPressed: _openFilterSheet,
            onResetPressed: _resetFilters,
          ),
        ),
        if (_hasActiveFilters) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(child: _ActiveFilterChips(filters: _filterLabels)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        if (rows.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _NoMatchingExpensesCard(),
          )
        else
          SliverList.separated(
            itemCount: rows.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) {
              final expense = rows[index];
              final account = _accountForExpense(expense);
              return ExpenseListItem(
                expense: expense,
                categoryColor: _colorForCategory(expense.category),
                account: account,
                onEdit: () => widget.onEdit?.call(expense),
                onDelete: () => widget.onDelete?.call(expense),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<String> get _filterLabels {
    final labels = <String>[];
    if (_categoryFilter != null) labels.add(_categoryFilter!);
    if (_accountFilter != null) labels.add(_accountFilter!.label);
    if (_typeFilter != null) labels.add(_typeFilter!.label);
    if (_startDate != null || _endDate != null) {
      final start = _startDate == null
          ? 'Any'
          : DateFormat.MMMd().format(_startDate!);
      final end = _endDate == null
          ? 'Any'
          : DateFormat.MMMd().format(_endDate!);
      labels.add('$start - $end');
    }
    if (_searchController.text.trim().isNotEmpty) {
      labels.add('"${_searchController.text.trim()}"');
    }
    return labels;
  }
}

class _ExpenseOverviewCard extends StatelessWidget {
  const _ExpenseOverviewCard({
    required this.total,
    required this.count,
    required this.recurringCount,
    required this.isFiltered,
  });

  final double total;
  final int count;
  final int recurringCount;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceSecondary,
          ],
        ),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isFiltered ? 'Filtered spend' : 'Expense ledger',
                  style: AppTextStyles.label,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            currency.format(total),
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _MiniStat(label: 'entries', value: count.toString()),
              const SizedBox(width: AppSpacing.sm),
              _MiniStat(label: 'recurring', value: recurringCount.toString()),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppDurations.page)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppDurations.page,
          curve: AppCurves.spring,
        );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSearchBar extends StatelessWidget {
  const _ExpenseSearchBar({
    required this.controller,
    required this.hasActiveFilters,
    required this.onChanged,
    required this.onFilterPressed,
    required this.onResetPressed,
  });

  final TextEditingController controller;
  final bool hasActiveFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onResetPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: 'Search expenses',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SquareIconButton(
          tooltip: 'Filters',
          icon: Icons.tune_rounded,
          onPressed: onFilterPressed,
          accent: hasActiveFilters,
        ),
        if (hasActiveFilters) ...[
          const SizedBox(width: AppSpacing.xs),
          _SquareIconButton(
            tooltip: 'Reset',
            icon: Icons.close_rounded,
            onPressed: onResetPressed,
          ),
        ],
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.buttonRadius,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent
                ? AppColors.primary.withAlpha(28)
                : AppColors.surface,
            borderRadius: AppRadii.buttonRadius,
            border: Border.all(
              color: accent ? AppColors.primary.withAlpha(80) : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: accent ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filters});

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters.map((filter) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(28),
            borderRadius: AppRadii.pillRadius,
            border: Border.all(color: AppColors.primary.withAlpha(70)),
          ),
          child: Text(
            filter,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(value == null ? 'Any' : DateFormat.yMMMd().format(value!)),
      ),
    );
  }
}

class _EmptyExpensesCard extends StatelessWidget {
  const _EmptyExpensesCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppConstants.noExpensesMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchingExpensesCard extends StatelessWidget {
  const _NoMatchingExpensesCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No matching expenses', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Try a lighter search or filter.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
