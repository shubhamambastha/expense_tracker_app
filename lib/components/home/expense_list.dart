import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../utils/constants.dart';

/// Expense list component - displays expenses in a table with filters and search
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

  List<Expense> get _filteredExpenses {
    final q = _searchController.text.toLowerCase().trim();
    return widget.expenses.where((e) {
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty && e.category != _categoryFilter) {
        return false;
      }
      if (_accountFilter != null && e.accountType != _accountFilter) return false;
      if (_typeFilter != null && e.type != _typeFilter) return false;
      if (_startDate != null && e.date.isBefore(_startDate!)) return false;
      if (_endDate != null && e.date.isAfter(_endDate!)) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) || e.category.toLowerCase().contains(q);
    }).toList();
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
      builder: (context) {
        // use StatefulBuilder to manage local state in the sheet before applying
        String? localCategory = _categoryFilter;
        AccountType? localAccount = _accountFilter;
        ExpenseType? localType = _typeFilter;
        DateTime? localStart = _startDate;
        DateTime? localEnd = _endDate;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(builder: (context, setLocalState) {
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

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        // reset local filters
                        setLocalState(() {
                          localCategory = null;
                          localAccount = null;
                          localType = null;
                          localStart = null;
                          localEnd = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: localCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [null, ...AppConstants.expenseCategories]
                      .map((c) => DropdownMenuItem<String?>(value: c, child: Text(c ?? 'All')))
                      .toList(),
                  onChanged: (v) => setLocalState(() => localCategory = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AccountType?>(
                  initialValue: localAccount,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [null, ...AccountType.values]
                      .map((a) => DropdownMenuItem<AccountType?>(value: a, child: Text(a?.label ?? 'All')))
                      .toList(),
                  onChanged: (v) => setLocalState(() => localAccount = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExpenseType?>(
                  initialValue: localType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [null, ...ExpenseType.values]
                      .map((t) => DropdownMenuItem<ExpenseType?>(value: t, child: Text(t?.label ?? 'All')))
                      .toList(),
                  onChanged: (v) => setLocalState(() => localType = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: pickStart,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Start date'),
                          child: Text(localStart == null ? 'Any' : DateFormat.yMMMd().format(localStart!)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: pickEnd,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'End date'),
                          child: Text(localEnd == null ? 'Any' : DateFormat.yMMMd().format(localEnd!)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // apply local filters to parent state
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
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
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
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    if (widget.expenses.isEmpty) {
      return Center(
        child: Text(
          AppConstants.noExpensesMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final rows = _filteredExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or category',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openFilterSheet,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filters'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                  const Spacer(),
                  if (_startDate != null || _endDate != null)
                    Text(
                      '${_startDate != null ? DateFormat.yMMMd().format(_startDate!) : ''}${_startDate != null && _endDate != null ? ' - ' : ''}${_endDate != null ? DateFormat.yMMMd().format(_endDate!) : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _PaginatedExpenseTable(
                expenses: rows,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginatedExpenseTable extends StatefulWidget {
  const _PaginatedExpenseTable({required this.expenses});

  final List<Expense> expenses;

  @override
  State<_PaginatedExpenseTable> createState() => _PaginatedExpenseTableState();
}

class _PaginatedExpenseTableState extends State<_PaginatedExpenseTable> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  final bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final source = ExpenseDataSource(widget.expenses, context);
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: PaginatedDataTable(
        header: const Text('Expenses'),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Amount')),
        ],
        source: source,
        rowsPerPage: _rowsPerPage,
        onRowsPerPageChanged: (r) {
          if (r == null) return;
          setState(() => _rowsPerPage = r);
        },
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
      ),
    );
  }
}

class ExpenseDataSource extends DataTableSource {
  ExpenseDataSource(this._expenses, this.context);

  final List<Expense> _expenses;
  final BuildContext context;

  @override
  DataRow? getRow(int index) {
    if (index >= _expenses.length) return null;
    final e = _expenses[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(DateFormat.yMMMd().format(e.date))),
        DataCell(Text(e.name)),
        DataCell(Text(e.category)),
        DataCell(Text(e.accountType.label)),
        DataCell(Text(e.type.label)),
        DataCell(Text(NumberFormat.currency(symbol: '\$').format(e.amount))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _expenses.length;

  @override
  int get selectedRowCount => 0;
}
