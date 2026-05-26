import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/transaction.dart';
import '../transaction/transactions_screen.dart';

class TransactionsContent extends StatelessWidget {
  const TransactionsContent({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.isLoading,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onAddTransaction,
    this.onAddExpense,
    this.onAddIncome,
    this.onAddTransfer,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final bool isLoading;
  final void Function(Transaction transaction)? onEdit;
  final void Function(Transaction transaction)? onDelete;
  final void Function(Transaction transaction)? onDuplicate;
  final VoidCallback? onAddTransaction;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddTransfer;

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen(
      transactions: transactions,
      accounts: accounts,
      isLoading: isLoading,
      onEdit: onEdit,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onAddTransaction: onAddTransaction,
      onAddExpense: onAddExpense,
      onAddIncome: onAddIncome,
      onAddTransfer: onAddTransfer,
    );
  }
}
