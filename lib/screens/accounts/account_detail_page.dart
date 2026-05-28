import 'package:flutter/material.dart';

import '../../components/accounts/account_actions_section.dart';
import '../../components/accounts/account_balance_overview.dart';
import '../../components/accounts/account_detail_header.dart';
import '../../components/accounts/account_linked_sources_section.dart';
import '../../components/accounts/account_transactions_preview.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../services/settings_preferences.dart';
import '../../utils/account_management.dart';
import '../../utils/snackbar_helper.dart';
import '../../components/transaction/detail/widgets/detail_section_card.dart';

/// Detail view for bank, cash, and wallet accounts.
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    super.key,
    required this.account,
    required this.accounts,
    required this.transactions,
    this.events = const [],
    required this.onMutation,
    required this.onEdit,
    required this.onArchive,
    this.onAddTransaction,
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
  final Future<void> Function(TransactionDraft draft)? onAddTransaction;
  final void Function(Transaction transaction)? onTapTransaction;
  final VoidCallback? onViewAllTransactions;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  Future<void> _setDefault() async {
    if (_account.id == null) return;
    await SettingsPreferences.instance
        .setDefaultExpenseAccountId(_account.id!);
    if (!mounted) return;
    SnackbarHelper.showSuccess(
      context,
      '${_account.displayName} is now your default account',
    );
    setState(() {});
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive account?'),
        content: Text(
          '${_account.displayName} will be hidden from your lists. '
          'Transactions stay intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onArchive();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _addTransaction() async {
    if (_account.id == null || widget.onAddTransaction == null) return;
    final draft = TransactionDraft(
      kind: TransactionKind.expense,
      accountId: _account.id,
    );
    await widget.onAddTransaction!(draft);
    await widget.onMutation();
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = AccountManagement.isDefaultAccount(_account.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_account.displayName),
        actions: [
          IconButton(
            onPressed: widget.onEdit,
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
          AccountDetailHeader(account: _account),
          const SizedBox(height: AppSpacing.lg),
          AccountBalanceOverview(
            account: _account,
            transactions: widget.transactions,
          ),
          const SizedBox(height: AppSpacing.lg),
          AccountTransactionsPreview(
            account: _account,
            transactions: widget.transactions,
            onViewAll: widget.onViewAllTransactions,
            onTapTransaction: widget.onTapTransaction,
          ),
          const SizedBox(height: AppSpacing.lg),
          AccountLinkedSourcesSection(
            account: _account,
            accounts: widget.accounts,
            transactions: widget.transactions,
            events: widget.events,
          ),
          if (_account.providerName != null ||
              (_account.notes != null && _account.notes!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.lg),
            DetailSectionCard(
              title: 'Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_account.providerName != null)
                    _MetaRow(
                      label: 'Provider',
                      value: _account.providerName!,
                    ),
                  if (_account.notes != null && _account.notes!.isNotEmpty)
                    _MetaRow(label: 'Notes', value: _account.notes!),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AccountActionsSection(
            isDefault: isDefault,
            onEdit: widget.onEdit,
            onArchive: _confirmArchive,
            onSetDefault: _account.id != null ? _setDefault : null,
            onAddTransaction:
                widget.onAddTransaction != null ? _addTransaction : null,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
