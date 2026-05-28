import 'package:flutter/material.dart';

import '../../components/accounts/add_account_form.dart';
import '../../components/accounts/add_account_type_selector.dart';
import '../../components/transaction/sticky_bottom_cta.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/transaction.dart';
import '../../utils/account_management.dart';
import '../../utils/snackbar_helper.dart';

/// Full-page form to create or edit a financial account.
class AddEditAccountPage extends StatefulWidget {
  const AddEditAccountPage({
    super.key,
    required this.accounts,
    required this.transactions,
    this.account,
    this.initialType = AccountType.bank,
    this.initialWallet = false,
    required this.onSave,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final Account? account;
  final AccountType initialType;
  final bool initialWallet;
  final Future<void> Function(Account account) onSave;

  bool get isEditing => account != null;

  @override
  State<AddEditAccountPage> createState() => _AddEditAccountPageState();
}

class _AddEditAccountPageState extends State<AddEditAccountPage> {
  late AccountType _selectedType;
  late bool _isWallet;
  late bool _isArchived;
  WalletProvider? _walletProvider;
  int? _linkedBankId;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _providerController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _outstandingController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _statementDayController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final existing = widget.account;
    _selectedType = existing?.type ?? widget.initialType;
    _isWallet = existing?.isWallet ?? widget.initialWallet;
    _isArchived = existing?.isArchived ?? false;
    _walletProvider = existing?.walletProvider ?? WalletProvider.gpay;
    _linkedBankId = existing?.linkedAccountId;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _providerController =
        TextEditingController(text: existing?.providerName ?? '');
    _nicknameController =
        TextEditingController(text: existing?.nickname ?? '');
    _openingBalanceController = TextEditingController(
      text: existing != null && !existing.isCreditCard
          ? _formatNum(existing.openingBalance)
          : '',
    );
    _outstandingController = TextEditingController();
    _creditLimitController = TextEditingController(
      text: existing?.creditLimit != null
          ? _formatNum(existing!.creditLimit!)
          : '',
    );
    _statementDayController = TextEditingController(
      text: existing?.statementDay?.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: existing?.dueDay?.toString() ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _nicknameController.dispose();
    _openingBalanceController.dispose();
    _outstandingController.dispose();
    _creditLimitController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatNum(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  List<Account> get _bankAccounts =>
      widget.accounts.where((a) => a.type == AccountType.bank).toList();

  double? get _computedOutstanding {
    final account = widget.account;
    if (account == null || !account.isCreditCard) return null;
    return AccountManagement.creditOutstanding(
      account,
      widget.transactions,
    );
  }

  Account get _previewAccount => Account(
        name: _nameController.text.trim().isEmpty
            ? 'Account'
            : _nameController.text.trim(),
        type: _isWallet ? AccountType.other : _selectedType,
        walletProvider: _isWallet ? _walletProvider : null,
      );

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackbarHelper.showMessage(context, 'Enter an account name');
      return;
    }

    final type = _isWallet ? AccountType.other : _selectedType;
    final isCard = type == AccountType.creditCard;

    double opening = 0;
    if (!isCard) {
      final balanceRaw = _openingBalanceController.text.trim();
      if (balanceRaw.isNotEmpty) {
        final parsed = double.tryParse(balanceRaw);
        if (parsed == null) {
          SnackbarHelper.showMessage(
            context,
            'Opening balance must be a number',
          );
          return;
        }
        opening = parsed;
      }
    } else if (!widget.isEditing) {
      final outstandingRaw = _outstandingController.text.trim();
      if (outstandingRaw.isNotEmpty) {
        final parsed = double.tryParse(outstandingRaw);
        if (parsed == null || parsed < 0) {
          SnackbarHelper.showMessage(
            context,
            'Outstanding must be a non-negative number',
          );
          return;
        }
        opening = -parsed;
      }
    } else {
      opening = widget.account!.openingBalance;
    }

    double? creditLimit;
    final creditRaw = _creditLimitController.text.trim();
    if (isCard && creditRaw.isNotEmpty) {
      final parsed = double.tryParse(creditRaw);
      if (parsed == null || parsed <= 0) {
        SnackbarHelper.showMessage(
          context,
          'Credit limit must be a positive number',
        );
        return;
      }
      creditLimit = parsed;
    }

    int? statementDay;
    final stmtRaw = _statementDayController.text.trim();
    if (isCard && stmtRaw.isNotEmpty) {
      final parsed = int.tryParse(stmtRaw);
      if (parsed == null || parsed < 1 || parsed > 31) {
        SnackbarHelper.showMessage(
          context,
          'Statement day must be between 1 and 31',
        );
        return;
      }
      statementDay = parsed;
    }

    int? dueDay;
    final dueRaw = _dueDayController.text.trim();
    if (isCard && dueRaw.isNotEmpty) {
      final parsed = int.tryParse(dueRaw);
      if (parsed == null || parsed < 1 || parsed > 31) {
        SnackbarHelper.showMessage(
          context,
          'Due day must be between 1 and 31',
        );
        return;
      }
      dueDay = parsed;
    }

    final nickname = _nicknameController.text.trim();
    final provider = _providerController.text.trim();
    final notes = _notesController.text.trim();

    final account = (widget.account ?? Account(name: name, type: type)).copyWith(
      name: name,
      type: type,
      openingBalance: opening,
      creditLimit: creditLimit,
      statementDay: statementDay,
      dueDay: dueDay,
      nickname: nickname.isEmpty ? null : nickname,
      providerName: provider.isEmpty ? null : provider,
      notes: notes.isEmpty ? null : notes,
      isArchived: _isArchived,
      linkedAccountId: _linkedBankId,
      walletProvider: _isWallet ? _walletProvider : null,
      clearNickname: nickname.isEmpty,
      clearProviderName: provider.isEmpty,
      clearNotes: notes.isEmpty,
      clearCreditLimit: isCard && creditRaw.isEmpty,
      clearStatementDay: isCard && stmtRaw.isEmpty,
      clearDueDay: isCard && dueRaw.isEmpty,
      clearLinkedAccountId: _linkedBankId == null,
      clearWalletProvider: !_isWallet,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(account);
      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTx = widget.account != null &&
        AccountManagement.hasTransactionsForAccount(
          widget.account!,
          widget.transactions,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit account' : 'Add account'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddAccountTypeSelector(
                    selectedType: _selectedType,
                    isWallet: _isWallet,
                    enabled: !widget.isEditing || !hasTx,
                    onTypeChanged: (type, {wallet = false}) {
                      setState(() {
                        _selectedType = type;
                        _isWallet = wallet;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AccountTypeIconPreview(account: _previewAccount),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AddAccountForm(
                      selectedType: _selectedType,
                      isWallet: _isWallet,
                      nameController: _nameController,
                      providerController: _providerController,
                      nicknameController: _nicknameController,
                      openingBalanceController: _openingBalanceController,
                      outstandingController: _outstandingController,
                      creditLimitController: _creditLimitController,
                      statementDayController: _statementDayController,
                      dueDayController: _dueDayController,
                      notesController: _notesController,
                      selectedWalletProvider: _walletProvider,
                      selectedLinkedBankId: _linkedBankId,
                      bankAccounts: _bankAccounts,
                      onWalletProviderChanged: (value) {
                        setState(() => _walletProvider = value);
                      },
                      onLinkedBankChanged: (value) {
                        setState(() => _linkedBankId = value);
                      },
                      isEditing: widget.isEditing,
                      hasTransactions: hasTx,
                      computedOutstanding: _computedOutstanding,
                      isArchived: _isArchived,
                      onArchivedChanged: widget.isEditing
                          ? (value) => setState(() => _isArchived = value)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          StickyBottomCTA(
            saveLabel: widget.isEditing ? 'Save account' : 'Save account',
            secondaryLabel: 'Cancel',
            showSaveAndAddAnother: false,
            isBusy: _isSaving,
            onSave: _submit,
            onSaveAndAddAnother: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
