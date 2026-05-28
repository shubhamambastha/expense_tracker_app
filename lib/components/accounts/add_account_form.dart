import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/currency_settings.dart';
import '../profile/profile_form_field.dart';

/// Dynamic form fields for add/edit account.
class AddAccountForm extends StatelessWidget {
  const AddAccountForm({
    super.key,
    required this.selectedType,
    required this.isWallet,
    required this.nameController,
    required this.providerController,
    required this.nicknameController,
    required this.openingBalanceController,
    required this.outstandingController,
    required this.creditLimitController,
    required this.statementDayController,
    required this.dueDayController,
    required this.notesController,
    required this.selectedWalletProvider,
    required this.selectedLinkedBankId,
    required this.bankAccounts,
    required this.onWalletProviderChanged,
    required this.onLinkedBankChanged,
    this.isEditing = false,
    this.hasTransactions = false,
    this.computedOutstanding,
    this.isArchived = false,
    this.onArchivedChanged,
  });

  final AccountType selectedType;
  final bool isWallet;
  final TextEditingController nameController;
  final TextEditingController providerController;
  final TextEditingController nicknameController;
  final TextEditingController openingBalanceController;
  final TextEditingController outstandingController;
  final TextEditingController creditLimitController;
  final TextEditingController statementDayController;
  final TextEditingController dueDayController;
  final TextEditingController notesController;
  final WalletProvider? selectedWalletProvider;
  final int? selectedLinkedBankId;
  final List<Account> bankAccounts;
  final ValueChanged<WalletProvider?> onWalletProviderChanged;
  final ValueChanged<int?> onLinkedBankChanged;
  final bool isEditing;
  final bool hasTransactions;
  final double? computedOutstanding;
  final bool isArchived;
  final ValueChanged<bool>? onArchivedChanged;

  bool get isCreditCard => selectedType == AccountType.creditCard;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEditing && hasTransactions)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(24),
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: Text(
              'This account has transactions. Changing the type may affect '
              'balance tracking.',
              style: AppTextStyles.caption,
            ),
          ),
        _SectionTitle(title: 'Basic information'),
        ProfileFormField(
          label: 'Account name',
          hint: 'HDFC Savings',
          controller: nameController,
        ),
        ProfileFormField(
          label: 'Bank / provider',
          hint: 'HDFC Bank',
          controller: providerController,
          optional: true,
        ),
        ProfileFormField(
          label: 'Nickname',
          hint: 'Main account',
          controller: nicknameController,
          optional: true,
        ),
        _SectionTitle(title: 'Financial information'),
        if (isCreditCard) ...[
          ProfileFormField(
            label: 'Credit limit',
            hint: '80000',
            controller: creditLimitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            optional: true,
          ),
          if (isEditing && computedOutstanding != null)
            ProfileFormField(
              label: 'Outstanding (computed)',
              controller: TextEditingController(
                text: currency.format(computedOutstanding!),
              ),
              readOnly: true,
              helperText: 'Updated by your transactions',
            )
          else if (!isEditing)
            ProfileFormField(
              label: 'Current outstanding',
              hint: '0',
              controller: outstandingController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              optional: true,
              helperText:
                  'Optional seed amount. Future charges update via transactions.',
            ),
          ProfileFormField(
            label: 'Statement day (1-31)',
            controller: statementDayController,
            keyboardType: TextInputType.number,
            optional: true,
          ),
          ProfileFormField(
            label: 'Due day (1-31)',
            controller: dueDayController,
            keyboardType: TextInputType.number,
            optional: true,
          ),
          _LinkedBankPicker(
            bankAccounts: bankAccounts,
            selectedId: selectedLinkedBankId,
            onChanged: onLinkedBankChanged,
          ),
        ] else if (isWallet) ...[
          _WalletProviderPicker(
            selected: selectedWalletProvider,
            onChanged: onWalletProviderChanged,
          ),
          ProfileFormField(
            label: 'Balance',
            hint: '0',
            controller: openingBalanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            optional: true,
          ),
          _LinkedBankPicker(
            bankAccounts: bankAccounts,
            selectedId: selectedLinkedBankId,
            onChanged: onLinkedBankChanged,
            optional: true,
          ),
        ] else ...[
          ProfileFormField(
            label: 'Opening balance',
            hint: '0',
            controller: openingBalanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            optional: true,
            helperText:
                'Starting balance. Current balance updates with transactions.',
          ),
        ],
        _SectionTitle(title: 'Optional metadata'),
        ProfileFormField(
          label: 'Notes',
          controller: notesController,
          optional: true,
        ),
        if (isEditing && onArchivedChanged != null)
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            title: const Text('Archived'),
            subtitle: const Text('Hide from account lists'),
            value: isArchived,
            onChanged: onArchivedChanged,
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _WalletProviderPicker extends StatelessWidget {
  const _WalletProviderPicker({
    required this.selected,
    required this.onChanged,
  });

  final WalletProvider? selected;
  final ValueChanged<WalletProvider?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet provider',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<WalletProvider>(
            initialValue: selected ?? WalletProvider.gpay,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: WalletProvider.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LinkedBankPicker extends StatelessWidget {
  const _LinkedBankPicker({
    required this.bankAccounts,
    required this.selectedId,
    required this.onChanged,
    this.optional = false,
  });

  final List<Account> bankAccounts;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    if (bankAccounts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Linked bank account',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 6),
                Text(
                  'Optional',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int?>(
            initialValue: selectedId,
            decoration: const InputDecoration(
              labelText: 'Pay from',
            ),
            items: [
              if (optional)
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
              ...bankAccounts.map(
                (a) => DropdownMenuItem<int?>(
                  value: a.id,
                  child: Text(a.displayName),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
