import 'package:flutter/material.dart';

import '../../components/accounts/account_swipe_tile.dart';
import '../../components/accounts/accounts_empty_state.dart';
import '../../components/accounts/accounts_header.dart';
import '../../components/accounts/accounts_section.dart';
import '../../components/accounts/accounts_summary_card.dart';
import '../../components/accounts/bank_account_card.dart';
import '../../components/accounts/credit_card_card.dart'
    show CreditCardCard, CreditCardQuickAction;
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../components/accounts/show_add_account_sheet.dart';
import '../../components/accounts/wallet_account_card.dart';
import '../../components/common/states/loading_state.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/recurring_event.dart';
import '../../services/supabase_service.dart';
import '../../utils/account_management.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/transaction_subtype_helpers.dart';
import 'account_detail_page.dart';
import 'add_edit_account_page.dart';
import 'credit_card_detail_page.dart';

/// Main accounts overview — pushed route from the home dashboard.
class AccountsListPage extends StatefulWidget {
  const AccountsListPage({
    super.key,
    required this.initialAccounts,
    required this.initialTransactions,
    required this.onMutation,
    this.onAddTransaction,
    this.onOpenRecurring,
    this.onTapTransaction,
    this.onViewAllTransactions,
  });

  final List<Account> initialAccounts;
  final List<Transaction> initialTransactions;
  final Future<void> Function() onMutation;
  final Future<void> Function(TransactionDraft draft)? onAddTransaction;
  final VoidCallback? onOpenRecurring;
  final void Function(Transaction transaction)? onTapTransaction;
  final VoidCallback? onViewAllTransactions;

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

class _AccountsListPageState extends State<AccountsListPage> {
  late List<Account> _accounts;
  late List<Transaction> _transactions;
  List<RecurringEvent> _events = const [];
  bool _isLoading = true;
  AccountSortMode _sortMode = AccountSortMode.name;

  @override
  void initState() {
    super.initState();
    _accounts = List<Account>.from(widget.initialAccounts);
    _transactions = List<Transaction>.from(widget.initialTransactions);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final events = await SupabaseService.fetchRecurringEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, error);
    }
  }

  Future<void> _refreshAll() async {
    try {
      final results = await Future.wait([
        SupabaseService.fetchAccounts(),
        SupabaseService.fetchTransactions(),
        SupabaseService.fetchRecurringEvents(),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = results[0] as List<Account>;
        _transactions = results[1] as List<Transaction>;
        _events = results[2] as List<RecurringEvent>;
      });
      await widget.onMutation();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  AccountManagementSnapshot get _snapshot =>
      AccountManagement.buildSnapshot(
        accounts: _accounts,
        transactions: _transactions,
      );

  List<Account> _sorted(List<Account> list) => AccountManagement.sortAccounts(
        accounts: list,
        transactions: _transactions,
        mode: _sortMode,
      );

  Future<void> _openAddAccount({AddAccountChoice? choice}) async {
    final picked = choice ?? await showAddAccountSheet(context);
    if (picked == null || !mounted) return;

    final isWallet = picked == AddAccountChoice.wallet;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddEditAccountPage(
          accounts: _accounts,
          transactions: _transactions,
          initialType: accountTypeForChoice(picked),
          initialWallet: isWallet,
          onSave: _saveAccount,
        ),
      ),
    );
    await _refreshAll();
  }

  Future<void> _saveAccount(Account account) async {
    if (account.id == null) {
      await SupabaseService.insertAccount(account);
    } else {
      await SupabaseService.updateAccount(account);
    }
    if (mounted) {
      SnackbarHelper.showSuccess(context, 'Account saved');
    }
  }

  Future<void> _editAccount(Account account) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddEditAccountPage(
          accounts: _accounts,
          transactions: _transactions,
          account: account,
          onSave: _saveAccount,
        ),
      ),
    );
    await _refreshAll();
  }

  Future<void> _archiveAccount(Account account) async {
    try {
      await SupabaseService.archiveAccount(account);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, '${account.displayName} archived');
      await _refreshAll();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    }
  }

  void _openAccountDetail(Account account) {
    if (account.isCreditCard) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CreditCardDetailPage(
            account: account,
            accounts: _accounts,
            transactions: _transactions,
            events: _events,
            onMutation: _refreshAll,
            onEdit: () => _editAccount(account),
            onArchive: () => _archiveAccount(account),
            onPayBill: () => _payCreditBill(account),
            onAddEmi: () => _addEmi(account),
            onManageEmi: widget.onOpenRecurring,
            onTapTransaction: widget.onTapTransaction,
            onViewAllTransactions: widget.onViewAllTransactions,
          ),
        ),
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AccountDetailPage(
            account: account,
            accounts: _accounts,
            transactions: _transactions,
            events: _events,
            onMutation: _refreshAll,
            onEdit: () => _editAccount(account),
            onArchive: () => _archiveAccount(account),
            onAddTransaction: widget.onAddTransaction,
            onTapTransaction: widget.onTapTransaction,
            onViewAllTransactions: widget.onViewAllTransactions,
          ),
        ),
      );
    }
  }

  Future<void> _payCreditBill(Account account) async {
    final draft = TransactionDraft(
      kind: TransactionKind.expense,
      accountId: account.linkedAccountId ?? account.id,
    );
    draft.merchant = '${account.displayName} bill payment';
    if (widget.onAddTransaction != null) {
      await widget.onAddTransaction!(draft);
      await _refreshAll();
    }
  }

  Future<void> _addEmi(Account account) async {
    final draft = TransactionDraft(
      kind: TransactionKind.expense,
      accountId: account.id,
    );
    TransactionSubtypeHelpers.applyExpenseSubtype(
      draft,
      TransactionSubtypeHelpers.expenseCategoryEmi,
    );
    if (widget.onAddTransaction != null) {
      await widget.onAddTransaction!(draft);
      await _refreshAll();
    } else if (widget.onOpenRecurring != null) {
      widget.onOpenRecurring!();
    }
  }

  void _handleCreditQuickAction(
    Account account,
    CreditCardQuickAction action,
  ) {
    switch (action) {
      case CreditCardQuickAction.edit:
        _editAccount(account);
      case CreditCardQuickAction.payBill:
        _payCreditBill(account);
      case CreditCardQuickAction.addEmi:
        _addEmi(account);
    }
  }

  Future<void> _openManageSheet() async {
    final picked = await showAccountsManageSheet(
      context,
      currentSort: _sortMode,
      showArchived: false,
    );
    if (picked != null && mounted) {
      setState(() => _sortMode = picked);
    }
  }

  Widget _swipeWrap(Account account, Widget child) {
    return AccountSwipeTile(
      dismissKey: ValueKey('swipe_${account.id}'),
      onAction: (action) {
        switch (action) {
          case AccountSwipeAction.edit:
            _editAccount(account);
          case AccountSwipeAction.archive:
            _archiveAccount(account);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Accounts')),
        body: const LoadingState(label: 'Loading accounts…'),
      );
    }

    final snapshot = _snapshot;
    final banks = _sorted(snapshot.bankAccounts);
    final cards = _sorted(snapshot.creditCards);
    final wallets = _sorted(snapshot.walletsAndCash);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      floatingActionButton: snapshot.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddAccount,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add account'),
            ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: snapshot.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AccountsHeader(
                    accountCount: 0,
                    onManageTap: _openManageSheet,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AccountsEmptyState(
                    onAddAccount: () => _openAddAccount(),
                  ),
                ],
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        AccountsHeader(
                          accountCount: _accounts
                              .where((a) => !a.isArchived)
                              .length,
                          onManageTap: _openManageSheet,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AccountsSummaryCard(
                          totalAvailable: snapshot.totalAvailable,
                          totalCreditUsed: snapshot.totalCreditUsed,
                          cashAvailable: snapshot.cashAvailable,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AccountsSection(
                          title: 'Bank accounts',
                          emptyTitle: 'No bank accounts yet',
                          emptyActionLabel: 'Add bank account',
                          onEmptyAction: () => _openAddAccount(
                            choice: AddAccountChoice.bank,
                          ),
                          children: [
                            for (final account in banks)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _swipeWrap(
                                  account,
                                  BankAccountCard(
                                    account: account,
                                    transactions: _transactions,
                                    accounts: _accounts,
                                    onTap: () => _openAccountDetail(account),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AccountsSection(
                          title: 'Credit cards',
                          actionLabel: cards.isEmpty ? null : null,
                          emptyTitle: 'No credit cards added',
                          emptyActionLabel: 'Add credit card',
                          onEmptyAction: () => _openAddAccount(
                            choice: AddAccountChoice.creditCard,
                          ),
                          children: [
                            for (final account in cards)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _swipeWrap(
                                  account,
                                  CreditCardCard(
                                    account: account,
                                    transactions: _transactions,
                                    accounts: _accounts,
                                    onTap: () => _openAccountDetail(account),
                                    onQuickAction: (action) =>
                                        _handleCreditQuickAction(
                                      account,
                                      action,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AccountsSection(
                          title: 'Wallets & cash',
                          emptyTitle: 'No wallets or cash added',
                          emptyActionLabel: 'Add wallet',
                          onEmptyAction: () => _openAddAccount(
                            choice: AddAccountChoice.wallet,
                          ),
                          children: [
                            for (final account in wallets)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _swipeWrap(
                                  account,
                                  WalletAccountCard(
                                    account: account,
                                    transactions: _transactions,
                                    accounts: _accounts,
                                    onTap: () => _openAccountDetail(account),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
