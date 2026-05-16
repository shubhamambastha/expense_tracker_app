import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../utils/constants.dart';

/// Expense list component - displays expenses with filters and search.
class ExpenseList extends StatefulWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.isLoading,
  });

  final List<Expense> expenses;
  final bool isLoading;

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
      if (_accountFilter != null && expense.accountType != _accountFilter) {
        return false;
      }
      if (_typeFilter != null && expense.type != _typeFilter) return false;
      if (_startDate != null && expense.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && expense.date.isAfter(_endDate!)) return false;
      if (query.isEmpty) return true;

      return expense.name.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query);
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
              return _ExpenseRowCard(
                expense: expense,
                categoryColor: _colorForCategory(expense.category),
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

class _ExpenseRowCard extends StatelessWidget {
  const _ExpenseRowCard({required this.expense, required this.categoryColor});

  final Expense expense;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 52,
          ),
          child: Row(
            children: [
              Tooltip(
                message: expense.category,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: categoryColor.withAlpha(28),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    _iconForCategory(expense.category),
                    color: categoryColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 108,
                child: Text(
                  expense.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _InlineMeta(
                icon: _iconForType(expense.type),
                label: _shortTypeLabel(expense.type),
                tooltip: expense.type.label,
                color: expense.isRecurring
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              if (expense.isRecurring) ...[
                _IconOnlyMeta(
                  icon: Icons.repeat_rounded,
                  tooltip: expense.endDate == null
                      ? 'Recurring'
                      : 'Recurring until ${DateFormat.MMMd().format(expense.endDate!)}',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
              ],
              _IconOnlyMeta(
                icon: _iconForAccount(expense.accountType),
                tooltip: expense.accountType.label,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat.MMMd().format(expense.date),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                NumberFormat.simpleCurrency().format(expense.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  IconData _iconForType(ExpenseType type) {
    switch (type) {
      case ExpenseType.oneTime:
        return Icons.event_available_rounded;
      case ExpenseType.recurring:
        return Icons.autorenew_rounded;
    }
  }

  IconData _iconForAccount(AccountType accountType) {
    switch (accountType) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String _shortTypeLabel(ExpenseType type) {
    switch (type) {
      case ExpenseType.oneTime:
        return 'Once';
      case ExpenseType.recurring:
        return 'Recur';
    }
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOnlyMeta extends StatelessWidget {
  const _IconOnlyMeta({
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
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
