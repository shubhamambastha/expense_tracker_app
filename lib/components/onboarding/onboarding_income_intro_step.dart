import 'package:flutter/material.dart';

import '../../components/settings/settings_picker_helpers.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart' show AccountTypeLabel;
import '../../services/auth_service.dart';
import '../../services/currency_settings.dart';
import 'onboarding_step_scaffold.dart';

/// Step 4/5 — monthly income, entered inline (same screen, no extra push)
/// and saved as a recurring transaction directly on Next. Trust microcopy
/// split by path (design-review 3A), directly tied to the founder's own
/// reason for leaving Mint. Includes an account picker (defaulting to the
/// first account) so the saved transaction lands where the user expects
/// instead of silently always going to whichever account happened to be
/// first in the list.
class OnboardingIncomeStep extends StatefulWidget {
  const OnboardingIncomeStep({
    super.key,
    required this.accounts,
    required this.onSkip,
    required this.onNext,
    this.onBack,
  });

  final List<Account> accounts;
  final VoidCallback onSkip;

  /// Called with the parsed amount (null if left blank/invalid) and the
  /// chosen account id (null if no accounts exist yet) when the user taps
  /// Next. The parent owns actually saving it.
  final void Function(double? amount, int? accountId) onNext;

  final VoidCallback? onBack;

  @override
  State<OnboardingIncomeStep> createState() => _OnboardingIncomeStepState();
}

class _OnboardingIncomeStepState extends State<OnboardingIncomeStep> {
  final _controller = TextEditingController();
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accounts.isEmpty
        ? null
        : widget.accounts.first.id;
  }

  @override
  void didUpdateWidget(covariant OnboardingIncomeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stillValid = widget.accounts.any((a) => a.id == _selectedAccountId);
    if (!stillValid) {
      _selectedAccountId = widget.accounts.isEmpty
          ? null
          : widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Account? get _selectedAccount {
    if (widget.accounts.isEmpty) return null;
    return widget.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => widget.accounts.first,
    );
  }

  Future<void> _pickAccount() async {
    final picked = await showModalBottomSheet<Account>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('Income goes to', style: AppTextStyles.headingSmall),
              ),
              for (final account in widget.accounts) ...[
                SettingsAccountPickerRow(
                  title: account.name,
                  subtitle: account.type.label,
                  selected: account.id == _selectedAccountId,
                  icon: iconForAccountType(account.type),
                  onTap: () => Navigator.of(sheetContext).pop(account),
                ),
                if (account != widget.accounts.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedAccountId = picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final isGuest = AuthService.instance.isGuest.value;
    final trustLine = isGuest
        ? 'Stays on this device, never shared.'
        : 'Stays on your account, never shared with anyone else.';
    final account = _selectedAccount;

    return OnboardingStepScaffold(
      heading: "What's your monthly income?",
      subtext: 'Optional — helps us show an accurate spending picture.',
      onSkip: widget.onSkip,
      onNext: () => widget.onNext(
        double.tryParse(_controller.text.trim()),
        _selectedAccountId,
      ),
      onBack: widget.onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              prefixText: currency.inputPrefix,
              hintText: '0',
            ),
          ),
          if (account != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: _pickAccount,
              borderRadius: AppRadii.cardRadius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconForAccountType(account.type),
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Goes to ${account.name}',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  trustLine,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
