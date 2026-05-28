import 'package:flutter/material.dart';

import '../../components/accounts/account_transactions_preview.dart';
import '../../components/accounts/credit_auto_payments_section.dart';
import '../../components/accounts/credit_billing_section.dart';
import '../../components/accounts/credit_card_actions_section.dart';
import '../../components/accounts/credit_emi_section.dart';
import '../../components/accounts/credit_usage_overview.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';

/// Specialized detail view for credit cards.
class CreditCardDetailPage extends StatelessWidget {
  const CreditCardDetailPage({
    super.key,
    required this.account,
    required this.accounts,
    required this.transactions,
    this.events = const [],
    required this.onMutation,
    required this.onEdit,
    required this.onArchive,
    this.onPayBill,
    this.onAddEmi,
    this.onManageEmi,
    this.onTapTransaction,
    this.onViewAllTransactions,
  });

  final Account account;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<RecurringEvent> events;
  final Future<void> Function() onMutation;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final Future<void> Function()? onPayBill;
  final Future<void> Function()? onAddEmi;
  final VoidCallback? onManageEmi;
  final void Function(Transaction transaction)? onTapTransaction;
  final VoidCallback? onViewAllTransactions;

  Future<void> _handleAction(
    BuildContext context,
    CreditCardAction action,
  ) async {
    switch (action) {
      case CreditCardAction.edit:
        onEdit();
      case CreditCardAction.payBill:
        await onPayBill?.call();
        await onMutation();
      case CreditCardAction.addEmi:
        await onAddEmi?.call();
        await onMutation();
      case CreditCardAction.archive:
        onArchive();
        if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(account.displayName),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          CreditUsageOverview(
            account: account,
            transactions: transactions,
          ),
          const SizedBox(height: AppSpacing.lg),
          CreditBillingSection(
            account: account,
            accounts: accounts,
            transactions: transactions,
          ),
          const SizedBox(height: AppSpacing.lg),
          CreditEmiSection(
            account: account,
            transactions: transactions,
            events: events,
            accounts: accounts,
            onManageEmi: onManageEmi,
          ),
          const SizedBox(height: AppSpacing.lg),
          AccountTransactionsPreview(
            account: account,
            transactions: transactions,
            onViewAll: onViewAllTransactions,
            onTapTransaction: onTapTransaction,
          ),
          const SizedBox(height: AppSpacing.lg),
          CreditAutoPaymentsSection(
            account: account,
            transactions: transactions,
            events: events,
            accounts: accounts,
          ),
          const SizedBox(height: AppSpacing.lg),
          CreditCardActionsSection(
            onAction: (action) => _handleAction(context, action),
          ),
        ],
      ),
    );
  }
}
