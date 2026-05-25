import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';

/// Big, centred amount display. Tapping anywhere on the row focuses the
/// underlying invisible text field so the numeric keypad opens instantly —
/// that single tap is the difference between "fast" and "slow" expense
/// entry in this screen.
///
/// The widget intentionally has no border / fill of its own — the amount is
/// the hero element on the screen so it floats over the background.
class AmountSection extends StatefulWidget {
  const AmountSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.onChangeCurrency,
    this.helperText = 'Tap to edit · numeric keypad',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
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

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final displayValue = hasValue
        ? widget.controller.text
        : (currency.decimalDigits == 0 ? '0' : '0.00');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Row(
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
                    child: Text(
                      displayValue,
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: hasValue
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withAlpha(160),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _CurrencyPill(
              code: currency.currencyCode,
              accent: widget.accent,
              onTap: widget.onChangeCurrency,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.helperText,
              style: AppTextStyles.caption,
            ),
            SizedBox(
              height: 0,
              width: 0,
              child: Offstage(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  showCursor: false,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    _SingleDotFormatter(),
                  ],
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prevents the user from entering multiple decimal separators.
class _SingleDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final dots = '.'.allMatches(newValue.text).length;
    if (dots <= 1) return newValue;
    return oldValue;
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
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}
