import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
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

  static const _categoryColors = <Color>[
    Color(0xFF4F8EF7),
    Color(0xFF47B881),
    Color(0xFFF8B229),
    Color(0xFF8E5AF7),
    Color(0xFFF15C5C),
    Color(0xFF3FB0AC),
    Color(0xFFF88D42),
  ];

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

  Color _colorForCategory(String category) {
    final index = AppConstants.expenseCategories.indexOf(category);
    if (index >= 0 && index < _categoryColors.length) {
      return _categoryColors[index];
    }
    return _categoryColors[category.hashCode.abs() % _categoryColors.length];
  }

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
                    items: [null, ...AppConstants.expenseCategories]
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency();

    return Card(
      elevation: 1,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isFiltered ? 'Filtered spend' : 'Expense ledger',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currency.format(total),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(label: 'entries', value: count.toString()),
                const SizedBox(width: 10),
                _MiniStat(label: 'recurring', value: recurringCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(115),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search expenses',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(95),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Filters',
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune_rounded),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Reset',
            onPressed: onResetPressed,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filters});

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        return Chip(
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
          backgroundColor: colorScheme.primary.withAlpha(20),
          label: Text(filter),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.noExpensesMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatchingExpensesCard extends StatelessWidget {
  const _NoMatchingExpensesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 38, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            'No matching expenses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a lighter search or filter.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
