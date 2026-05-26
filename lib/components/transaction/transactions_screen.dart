import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../models/transaction_filters.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/transaction_list_preferences.dart';
import '../../utils/transaction_filter_logic.dart';
import '../../utils/transaction_grouping.dart';
import '../settings/settings_picker_helpers.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_list_item.dart';

/// Full Transactions screen — app bar, sticky search/filters, summary, list.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.isLoading,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onAddTransaction,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final bool isLoading;
  final void Function(Transaction transaction)? onEdit;
  final void Function(Transaction transaction)? onDelete;
  final void Function(Transaction transaction)? onDuplicate;
  final VoidCallback? onAddTransaction;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _filters = TransactionFilterState();
  final _debounce = _Debouncer(const Duration(milliseconds: 280));

  List<String> _recentSearches = [];
  String _debouncedQuery = '';
  bool _fabVisible = true;
  double _lastScrollOffset = 0;
  int _visibleLimit = 50;
  bool _prefsLoaded = false;

  static const _pageSize = 40;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadPreferences() async {
    await TransactionListPreferences.instance.load();
    await TransactionListPreferences.instance.restoreFilterSnapshot(_filters);
    if (!mounted) return;
    setState(() {
      _recentSearches = TransactionListPreferences.instance.recentSearches;
      _debouncedQuery = _filters.searchQuery;
      _searchController.text = _filters.searchQuery;
      _prefsLoaded = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce.dispose();
    TransactionListPreferences.instance.saveFilterSnapshot(_filters);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _debounce.run(() {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = _searchController.text;
        _filters.searchQuery = _debouncedQuery;
        _visibleLimit = _pageSize;
      });
      if (_debouncedQuery.trim().isNotEmpty) {
        TransactionListPreferences.instance.rememberSearch(_debouncedQuery);
      }
      TransactionListPreferences.instance.saveFilterSnapshot(_filters);
    });
  }

  double get _stickyHeaderHeight {
    var height = 72.0;
    if (_activeChips.isNotEmpty) height += 44;
    if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) {
      height += 72;
    }
    return height;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > _lastScrollOffset + 8 && offset > 80) {
      if (_fabVisible) setState(() => _fabVisible = false);
    } else if (offset < _lastScrollOffset - 8) {
      if (!_fabVisible) setState(() => _fabVisible = true);
    }
    _lastScrollOffset = offset;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = _filtered.length;
    if (_visibleLimit >= total) return;
    setState(() => _visibleLimit += _pageSize);
  }

  void _applyFilters(VoidCallback mutate) {
    setState(() {
      mutate();
      _visibleLimit = _pageSize;
    });
    TransactionListPreferences.instance.saveFilterSnapshot(_filters);
  }

  List<Transaction> get _filtered {
    _filters.searchQuery = _debouncedQuery;
    return TransactionFilterLogic.apply(
      transactions: widget.transactions,
      filters: _filters,
      accounts: widget.accounts,
    );
  }

  double get _largeAmountThreshold {
    if (_filtered.isEmpty) return double.infinity;
    final sorted = List<double>.from(_filtered.map((e) => e.amount))..sort();
    final idx = (sorted.length * 0.9).floor().clamp(0, sorted.length - 1);
    return sorted[idx];
  }

  Account? _accountFor(Transaction tx) {
    final id = tx.accountId;
    if (id == null) return null;
    for (final a in widget.accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Account? _transferToAccountFor(Transaction tx) {
    final id = tx.transferToAccountId;
    if (id == null) return null;
    for (final a in widget.accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];

    if (_filters.datePreset != null) {
      chips.add(ActiveFilterChip(
        id: 'date',
        label: _filters.datePreset!.label,
        onRemove: () => _applyFilters(() => _filters.datePreset = null),
      ));
    }

    for (final type in _filters.types) {
      chips.add(ActiveFilterChip(
        id: 'type_${type.name}',
        label: type.label,
        onRemove: () => _applyFilters(() => _filters.types.remove(type)),
      ));
    }

    if (_filters.category != null) {
      chips.add(ActiveFilterChip(
        id: 'category',
        label: _filters.category!,
        onRemove: () => _applyFilters(() => _filters.category = null),
      ));
    }

    if (_filters.accountId != null) {
      Account? account;
      for (final a in widget.accounts) {
        if (a.id == _filters.accountId) {
          account = a;
          break;
        }
      }
      chips.add(ActiveFilterChip(
        id: 'account',
        label: account?.name ?? 'Account',
        onRemove: () => _applyFilters(() => _filters.accountId = null),
      ));
    }

    if (_filters.minAmount != null || _filters.maxAmount != null) {
      final min = _filters.minAmount;
      final max = _filters.maxAmount;
      final label = min != null && max != null
          ? '${CurrencySettings.instance.format(min)} – ${CurrencySettings.instance.format(max)}'
          : min != null
              ? '≥ ${CurrencySettings.instance.format(min)}'
              : '≤ ${CurrencySettings.instance.format(max!)}';
      chips.add(ActiveFilterChip(
        id: 'amount',
        label: label,
        onRemove: () => _applyFilters(() {
          _filters.minAmount = null;
          _filters.maxAmount = null;
        }),
      ));
    }

    if (_debouncedQuery.trim().isNotEmpty) {
      chips.add(ActiveFilterChip(
        id: 'search',
        label: '"$_debouncedQuery"',
        onRemove: () => _applyFilters(() {
          _searchController.clear();
          _debouncedQuery = '';
          _filters.searchQuery = '';
        }),
      ));
    }

    return chips;
  }

  Future<void> _openSortSheet() async {
    final picked = await selectFromList<TransactionSort>(
      context: context,
      title: 'Sort by',
      current: _filters.sort,
      options: TransactionSort.values,
      labelFor: (s) => s.label,
    );
    if (picked != null) {
      _applyFilters(() => _filters.sort = picked);
    }
  }

  Future<void> _openDateFilter() async {
    final picked = await selectFromList<DateFilterPreset>(
      context: context,
      title: 'Date',
      current: _filters.datePreset,
      options: DateFilterPreset.values,
      labelFor: (p) => p.label,
    );
    if (picked == null) return;

    if (picked == DateFilterPreset.custom) {
      final start = await showDatePicker(
        context: context,
        initialDate: _filters.customStart ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (start == null || !mounted) return;
      final end = await showDatePicker(
        context: context,
        initialDate: _filters.customEnd ?? start,
        firstDate: start,
        lastDate: DateTime(2100),
      );
      if (!mounted) return;
      _applyFilters(() {
        _filters.datePreset = DateFilterPreset.custom;
        _filters.customStart = start;
        _filters.customEnd = end;
      });
      return;
    }

    _applyFilters(() {
      _filters.datePreset = picked;
      _filters.customStart = null;
      _filters.customEnd = null;
    });
  }

  Future<void> _openTypeFilter() async {
    final local = Set<TransactionDisplayType>.from(_filters.types);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Type', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: kTransactionTypeFilterOptions.map((type) {
                        final selected = local.contains(type);
                        return FilterChip(
                          label: Text(type.label),
                          selected: selected,
                          onSelected: (_) {
                            setLocal(() {
                              if (selected) {
                                local.remove(type);
                              } else {
                                local.add(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        _applyFilters(() => _filters.types = local);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoryFilter() async {
    final categories = CategoryCatalog.instance.names;
    final picked = await selectFromList<String?>(
      context: context,
      title: 'Category',
      current: _filters.category,
      options: [null, ...categories],
      labelFor: (c) => c ?? 'All categories',
    );
    if (picked != null || _filters.category != null) {
      _applyFilters(() => _filters.category = picked);
    }
  }

  Future<void> _openAccountFilter() async {
    if (widget.accounts.isEmpty) return;
    final picked = await selectFromList<int?>(
      context: context,
      title: 'Account',
      current: _filters.accountId,
      options: [null, ...widget.accounts.map((a) => a.id!)],
      labelFor: (id) {
        if (id == null) return 'All accounts';
        return widget.accounts.firstWhere((a) => a.id == id).name;
      },
    );
    _applyFilters(() => _filters.accountId = picked);
  }

  Future<void> _openAmountFilter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return _AmountFilterSheet(
          initialMin: _filters.minAmount,
          initialMax: _filters.maxAmount,
          onApply: (min, max) {
            _applyFilters(() {
              _filters.minAmount = min;
              _filters.maxAmount = max;
            });
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _openFilterShortcut() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_rounded),
                title: const Text('Sort'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openSortSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Date'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openDateFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_vert_rounded),
                title: const Text('Type'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openTypeFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Category'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openCategoryFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Account'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAccountFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Amount'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAmountFilter();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _wrapWithFilterFab(Widget child) {
    return Stack(
      children: [
        child,
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: AnimatedSlide(
            duration: AppDurations.micro,
            offset: _fabVisible ? Offset.zero : const Offset(0, 2),
            child: AnimatedOpacity(
              duration: AppDurations.micro,
              opacity: _fabVisible ? 1 : 0,
              child: _TransactionsFilterFab(onTap: _openFilterShortcut),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded || widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.transactions.isEmpty) {
      return _wrapWithFilterFab(
        _EmptyTransactions(onAdd: widget.onAddTransaction),
      );
    }

    final filtered = _filtered;
    final windowed = filtered.take(_visibleLimit).toList();
    final groups = groupTransactionsByDate(windowed);
    final summaryExpenses = _summaryExpenses(filtered);
    final topCategory = TransactionFilterLogic.topCategory(summaryExpenses);
    final totalSpent = TransactionFilterLogic.totalSpent(summaryExpenses);
    final summaryCount =
        _filters.hasActiveFilters ? filtered.length : summaryExpenses.length;
    final hasFilters = _filters.hasActiveFilters;
    final showRecent =
        _searchController.text.isEmpty && _recentSearches.isNotEmpty;
    final itemCount = filtered.isEmpty ? 0 : _sliverItemCount(groups);

    return _wrapWithFilterFab(
      CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _TransactionsAppBar(
              onCalendar: _openDateFilter,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              extent: _stickyHeaderHeight,
              child: _StickySearchFilters(
                searchController: _searchController,
                recentSearches: _recentSearches,
                showRecent: showRecent,
                onRecentTap: (q) {
                  _searchController.text = q;
                  _debouncedQuery = q;
                  _filters.searchQuery = q;
                  setState(() {});
                },
                onClearRecent: () async {
                  await TransactionListPreferences.instance
                      .clearRecentSearches();
                  setState(() => _recentSearches = []);
                },
                onSearchClear: () {
                  _searchController.clear();
                  _debouncedQuery = '';
                  _filters.searchQuery = '';
                  setState(() {});
                },
                activeChips: _activeChips,
                onClearAll: () => _applyFilters(_filters.clear),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SummaryStrip(
              totalSpent: totalSpent,
              count: summaryCount,
              topCategory: topCategory,
              isFiltered: hasFilters,
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoResults(query: _debouncedQuery),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGroupedItem(groups, index),
                childCount: itemCount,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<Transaction> _summaryExpenses(List<Transaction> filtered) {
    if (_filters.hasActiveFilters) return filtered;
    final monthFilters = TransactionFilterState(
      datePreset: DateFilterPreset.thisMonth,
      searchQuery: _debouncedQuery,
    );
    return TransactionFilterLogic.apply(
      transactions: widget.transactions,
      filters: monthFilters,
      accounts: widget.accounts,
    );
  }

  int _sliverItemCount(List<TransactionGroup> groups) {
    var count = 0;
    for (final g in groups) {
      count += 1 + g.items.length; // header + rows
    }
    return count;
  }

  Widget _buildGroupedItem(List<TransactionGroup> groups, int index) {
    var cursor = 0;
    for (final group in groups) {
      if (index == cursor) {
        return _GroupHeader(label: group.label);
      }
      cursor++;
      for (final tx in group.items) {
        if (index == cursor) {
          return Column(
            children: [
              TransactionListItem(
                transaction: tx,
                account: _accountFor(tx),
                transferToAccount: _transferToAccountFor(tx),
                isLargeAmount: tx.amount >= _largeAmountThreshold,
                onTap: () => showTransactionDetailSheet(
                  context: context,
                  transaction: tx,
                  account: _accountFor(tx),
                  transferToAccount: _transferToAccountFor(tx),
                  onEdit: () => widget.onEdit?.call(tx),
                  onDuplicate: () => widget.onDuplicate?.call(tx),
                  onDelete: () => widget.onDelete?.call(tx),
                ),
                onEdit: () => widget.onEdit?.call(tx),
                onDuplicate: () => widget.onDuplicate?.call(tx),
                onDelete: () => widget.onDelete?.call(tx),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          );
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }
}

class _TransactionsAppBar extends StatelessWidget {
  const _TransactionsAppBar({required this.onCalendar});

  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Transactions', style: AppTextStyles.headingMedium),
          ),
          IconButton(
            tooltip: 'Export',
            onPressed: () {},
            icon: const Icon(Icons.upload_rounded),
          ),
          IconButton(
            tooltip: 'Calendar',
            onPressed: onCalendar,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
    );
  }
}

class _StickySearchFilters extends StatelessWidget {
  const _StickySearchFilters({
    required this.searchController,
    required this.recentSearches,
    required this.showRecent,
    required this.onRecentTap,
    required this.onClearRecent,
    required this.onSearchClear,
    required this.activeChips,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final List<String> recentSearches;
  final bool showRecent;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecent;
  final VoidCallback onSearchClear;
  final List<ActiveFilterChip> activeChips;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: 'Search merchants, categories, accounts…',
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: onSearchClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  : null,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              isDense: true,
            ),
          ),
          if (showRecent && recentSearches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('Recent', style: AppTextStyles.caption),
                const Spacer(),
                TextButton(
                  onPressed: onClearRecent,
                  child: const Text('Clear'),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: recentSearches.map((q) {
                return ActionChip(
                  label: Text(q),
                  onPressed: () => onRecentTap(q),
                );
              }).toList(),
            ),
          ],
          if (activeChips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...activeChips.map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: InputChip(
                        label: Text(chip.label),
                        onDeleted: chip.onRemove,
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      ),
                    );
                  }),
                  ActionChip(
                    label: const Text('Clear all'),
                    onPressed: onClearAll,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.totalSpent,
    required this.count,
    required this.topCategory,
    required this.isFiltered,
  });

  final double totalSpent;
  final int count;
  final String? topCategory;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final period = isFiltered ? 'in results' : 'this month';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SummaryPill(
              icon: Icons.payments_rounded,
              text: '${currency.format(totalSpent)} spent $period',
            ),
            const SizedBox(width: AppSpacing.sm),
            _SummaryPill(
              icon: Icons.receipt_long_rounded,
              text: '$count transactions',
            ),
            if (topCategory != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _SummaryPill(
                icon: Icons.pie_chart_outline_rounded,
                text: 'Top: $topCategory',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No transactions yet', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your financial activity will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final message = query.trim().isEmpty
        ? 'No matching transactions found'
        : "No transactions found for '$query'";

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
          Text(message, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Try a lighter search or adjust filters.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AmountFilterSheet extends StatefulWidget {
  const _AmountFilterSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  final double? initialMin;
  final double? initialMax;
  final void Function(double? min, double? max) onApply;

  @override
  State<_AmountFilterSheet> createState() => _AmountFilterSheetState();
}

class _AmountFilterSheetState extends State<_AmountFilterSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: widget.initialMin?.toStringAsFixed(0) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: widget.initialMax?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Amount', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _minCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Minimum',
              prefixIcon: Icon(Icons.arrow_downward_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _maxCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Maximum',
              prefixIcon: Icon(Icons.arrow_upward_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              widget.onApply(
                double.tryParse(_minCtrl.text.trim()),
                double.tryParse(_maxCtrl.text.trim()),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _TransactionsFilterFab extends StatelessWidget {
  const _TransactionsFilterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filters',
      child: Material(
        key: const ValueKey('transactions-filter-fab'),
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.extent != extent;
}

class _Debouncer {
  _Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
