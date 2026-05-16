import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';

/// Single expense list item component
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
  });

  final Expense expense;

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(expense.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  NumberFormat.currency(symbol: '\$').format(expense.amount),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(expense.category, Icons.label_outline),
                _buildChip(expense.accountType.label, Icons.account_balance_wallet),
                _buildChip(expense.type.label, Icons.repeat),
                _buildChip(DateFormat.yMMMd().format(expense.date), Icons.calendar_month),
                if (expense.endDate != null)
                  _buildChip('Ends ${DateFormat.yMMMd().format(expense.endDate!)}', Icons.stop_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
