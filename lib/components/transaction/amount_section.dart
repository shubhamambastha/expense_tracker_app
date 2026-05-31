import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';

/// Hero amount display for add-transaction. Uses the parent-owned in-app
/// [AmountNumericKeypad] instead of the system decimal pad.
class AmountSection extends StatefulWidget {
  const AmountSection({
    super.key,
    required this.controller,
    required this.keypadOpen,
    required this.onKeypadOpenChanged,
    required this.accent,
    required this.onChangeCurrency,
    this.helperText = 'Tap amount · Done on keypad when finished',
  });

  final TextEditingController controller;
  final bool keypadOpen;
  final ValueChanged<bool> onKeypadOpenChanged;
  final Color accent;
  final VoidCallback onChangeCurrency;
  final String helperText;

  @override
  State<AmountSection> createState() => _AmountSectionState();
}

class _AmountSectionState extends State<AmountSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _toggleKeypad() {
    widget.onKeypadOpenChanged(!widget.keypadOpen);
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final displayValue = hasValue
        ? widget.controller.text
        : (currency.decimalDigits == 0 ? '0' : '0.00');
    final valueStyle = AppTextStyles.displayLarge.copyWith(
      fontSize: 56,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: hasValue
          ? AppColors.textPrimary
          : AppColors.textSecondary.withAlpha(160),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleKeypad,
              borderRadius: AppRadii.cardRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.symbol,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(displayValue, style: valueStyle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CurrencyPill(
            code: currency.currencyCode,
            accent: widget.accent,
            onTap: widget.onChangeCurrency,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.helperText, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.code,
    required this.accent,
    required this.onTap,
  });

  final String code;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: accent.withAlpha(28),
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: accent.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              code,
              style: AppTextStyles.label.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}
