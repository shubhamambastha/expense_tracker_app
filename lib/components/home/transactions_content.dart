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
    this.onConvertToRecurring,
    this.onAddTransaction,
    this.onTagSubscription,
    this.taggingTransactionId,
  });

  final List<Transaction> transactions;
  final List<Account> accounts;
  final bool isLoading;
  final void Function(Transaction transaction)? onEdit;
  final void Function(Transaction transaction)? onDelete;
  final void Function(Transaction transaction)? onDuplicate;
  final void Function(Transaction transaction)? onConvertToRecurring;
  final VoidCallback? onAddTransaction;
  final void Function(Transaction transaction)? onTagSubscription;
  final int? taggingTransactionId;

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen(
      transactions: transactions,
      accounts: accounts,
      isLoading: isLoading,
      onEdit: onEdit,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onConvertToRecurring: onConvertToRecurring,
      onAddTransaction: onAddTransaction,
      onTagSubscription: onTagSubscription,
      taggingTransactionId: taggingTransactionId,
    );
  }
}
