import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';

/// Opens the add-account dialog from Settings, home, or Add Transaction.
typedef OnAddAccount = void Function({AccountType initialType});

String addAccountDialogTitle(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return 'Add bank account';
    case AccountType.creditCard:
      return 'Add credit card';
    case AccountType.cash:
      return 'Add cash wallet';
    case AccountType.other:
      return 'Add account';
  }
}

String _namePlaceholder(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return 'e.g. HDFC Bank';
    case AccountType.creditCard:
      return 'e.g. HDFC Credit Card';
    case AccountType.cash:
      return 'e.g. Cash wallet';
    case AccountType.other:
      return 'e.g. Investment account';
  }
}

String _balanceLabel(AccountType type) {
  return type == AccountType.cash ? 'Current cash' : 'Current balance';
}

IconData _iconForType(AccountType type) {
  switch (type) {
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

/// Shows a dialog to name an account, pick its [AccountType], and capture
/// optional balance / credit limit / due-day fields used by the dashboard's
/// Account Overview section.
Future<void> showAddAccountDialog(
  BuildContext context, {
  required Future<void> Function(Account account) onSave,
  AccountType initialType = AccountType.bank,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AddAccountDialog(
      initialType: initialType,
      onSave: onSave,
    ),
  );
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog({
    required this.initialType,
    required this.onSave,
  });

  final AccountType initialType;
  final Future<void> Function(Account account) onSave;

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _dueDayController;
  late AccountType _selectedType;

  bool _nameError = false;
  String? _balanceError;
  String? _creditLimitError;
  String? _dueDayError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
    _creditLimitController = TextEditingController();
    _dueDayController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _selectType(AccountType type) {
    setState(() {
      _selectedType = type;
      _balanceError = null;
      _creditLimitError = null;
      _dueDayError = null;
    });
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    setState(() => _nameError = name.isEmpty);
    if (name.isEmpty) return;

    final isCard = _selectedType == AccountType.creditCard;
    final balanceRaw = _balanceController.text.trim();
    final creditRaw = _creditLimitController.text.trim();
    final dueDayRaw = _dueDayController.text.trim();

    double opening = 0;
    if (!isCard && balanceRaw.isNotEmpty) {
      final parsed = double.tryParse(balanceRaw);
      if (parsed == null) {
        setState(() => _balanceError = 'Enter a valid amount');
        return;
      }
      opening = parsed;
    }

    double? creditLimit;
    if (isCard && creditRaw.isNotEmpty) {
      final parsed = double.tryParse(creditRaw);
      if (parsed == null || parsed <= 0) {
        setState(() => _creditLimitError = 'Enter a positive amount');
        return;
      }
      creditLimit = parsed;
    }

    int? dueDay;
    if (isCard && dueDayRaw.isNotEmpty) {
      final parsed = int.tryParse(dueDayRaw);
      if (parsed == null || parsed < 1 || parsed > 31) {
        setState(() => _dueDayError = 'Enter a day between 1 and 31');
        return;
      }
      dueDay = parsed;
    }

    Navigator.of(context).pop();
    await widget.onSave(
      Account(
        name: name,
        type: _selectedType,
        openingBalance: opening,
        creditLimit: creditLimit,
        dueDay: dueDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _selectedType == AccountType.creditCard;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: 340,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionLabel('Account type'),
              const SizedBox(height: AppSpacing.sm),
              _buildTypeGrid(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionLabel('Account name'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_nameError) setState(() => _nameError = false);
                },
                decoration: _fieldDecoration(
                  hintText: _namePlaceholder(_selectedType),
                  prefixIcon: _iconForType(_selectedType),
                  errorText: _nameError ? 'Enter an account name' : null,
                ),
              ),
              if (!isCard) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel(_balanceLabel(_selectedType), optional: true),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (_) {
                    if (_balanceError != null) setState(() => _balanceError = null);
                  },
                  decoration: _fieldDecoration(
                    hintText: '0',
                    prefixIcon: Icons.currency_rupee_rounded,
                    errorText: _balanceError,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('Credit limit', optional: true),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _creditLimitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    if (_creditLimitError != null) {
                      setState(() => _creditLimitError = null);
                    }
                  },
                  decoration: _fieldDecoration(
                    hintText: '100000',
                    prefixIcon: Icons.currency_rupee_rounded,
                    errorText: _creditLimitError,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('Bill due day', optional: true),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _dueDayController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_dueDayError != null) setState(() => _dueDayError = null);
                  },
                  decoration: _fieldDecoration(
                    hintText: '12',
                    prefixIcon: Icons.event_rounded,
                    errorText: _dueDayError,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 48),
                      shape: AppRadii.buttonBorder,
                    ),
                    onPressed: _onSave,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(41),
            borderRadius: AppRadii.chipRadius,
          ),
          child: Icon(_iconForType(_selectedType), color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            addAccountDialogTitle(_selectedType),
            style: AppTextStyles.headingSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 16),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceSecondary,
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(30, 30),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, {bool optional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('Optional', style: AppTextStyles.caption),
        ],
      ],
    );
  }

  Widget _buildTypeGrid() {
    final types = AccountType.values;
    return Column(
      children: [
        for (var row = 0; row < types.length; row += 2)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: _typeChip(types[row])),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _typeChip(types[row + 1])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _typeChip(AccountType type) {
    final selected = type == _selectedType;
    final background = selected
        ? AppColors.primary.withAlpha(41)
        : AppColors.surfaceSecondary;
    final foreground = selected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: background,
      borderRadius: AppRadii.chipRadius,
      child: InkWell(
        borderRadius: AppRadii.chipRadius,
        onTap: () => _selectType(type),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadii.chipRadius,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForType(type), size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  type.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 20),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide(color: AppColors.danger, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }
}
