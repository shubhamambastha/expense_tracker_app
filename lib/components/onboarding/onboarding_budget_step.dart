import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import 'onboarding_step_scaffold.dart';

/// Step 3/5 — monthly budget, with a live per-day preview as the user
/// types. Deliberately NOT the real `SpendingRoomCard`/`spendableToday` —
/// that figure is computed from actual logged transactions and recurring
/// commitments, which a brand-new user doesn't have yet; showing it here
/// would be either $0 or actively misleading. This preview only ever
/// claims what it can honestly compute: the typed number divided across
/// the days left in the month, styled to match the dashboard's card
/// language so it still reads as a real, connected part of the app.
class OnboardingBudgetStep extends StatefulWidget {
  const OnboardingBudgetStep({
    super.key,
    required this.onSkip,
    required this.onNext,
    this.onBack,
  });

  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  State<OnboardingBudgetStep> createState() => _OnboardingBudgetStepState();
}

class _OnboardingBudgetStepState extends State<OnboardingBudgetStep> {
  late final TextEditingController _controller;
  double? _value;

  @override
  void initState() {
    super.initState();
    final existing = SettingsPreferences.instance.monthlySpendingLimit;
    _controller = TextEditingController(
      text: existing == null ? '' : existing.toStringAsFixed(0),
    );
    _value = existing;
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _value = double.tryParse(_controller.text.trim()));
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final value = _value;
    if (value != null && value > 0) {
      await SettingsPreferences.instance.setMonthlySpendingLimit(value);
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final value = _value;
    final perDay = (value != null && value > 0 && daysLeft > 0)
        ? value / daysLeft
        : null;

    return OnboardingStepScaffold(
      heading: "What's your monthly budget?",
      subtext: 'A soft cap — we\'ll warn you before you cross it.',
      onSkip: widget.onSkip,
      onBack: widget.onBack,
      onNext: _next,
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
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Text('≈ per day', style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    )),
                    const Spacer(),
                    Text(
                      perDay == null ? '—' : currency.format(perDay),
                      style: AppTextStyles.headingSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
