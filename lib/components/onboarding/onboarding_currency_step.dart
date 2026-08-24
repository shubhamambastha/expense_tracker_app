import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/onboarding_locale_currency.dart';
import 'onboarding_step_scaffold.dart';

/// Step 2/5 — currency, locale-prefilled (USD fallback), a one-tap confirm
/// for most users. Must run before the budget step so the budget preview
/// shows a real currency symbol (design-review D1).
class OnboardingCurrencyStep extends StatefulWidget {
  const OnboardingCurrencyStep({
    super.key,
    required this.onSkip,
    required this.onNext,
    this.onBack,
  });

  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  State<OnboardingCurrencyStep> createState() =>
      _OnboardingCurrencyStepState();
}

class _OnboardingCurrencyStepState extends State<OnboardingCurrencyStep> {
  late String _code;

  @override
  void initState() {
    super.initState();
    _code = CurrencySettings.instance.currencyCode;
    if (_code == CurrencySettings.defaultCode) {
      // Only override if the user hasn't already picked something —
      // avoids clobbering a prior explicit choice on a resumed wizard.
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      _code = currencyCodeForLocale(locale);
    }
  }

  Future<void> _next() async {
    await CurrencySettings.instance.setCurrency(_code);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      heading: 'Default currency',
      subtext: "We picked this from your device — change it if it's wrong.",
      onSkip: widget.onSkip,
      onNext: _next,
      onBack: widget.onBack,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.inputRadius,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _code,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            items: [
              for (final option in CurrencySettings.supported)
                DropdownMenuItem(
                  value: option.code,
                  child: Text('${option.symbol}  ${option.name} (${option.code})'),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _code = value);
            },
          ),
        ),
      ),
    );
  }
}
