import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/design_tokens.dart';

/// In-app amount keypad — avoids iOS decimal-pad dismiss / TUIKeyplane issues.
class AmountNumericKeypad extends StatelessWidget {
  const AmountNumericKeypad({
    super.key,
    required this.controller,
    required this.maxDecimalDigits,
    required this.onDone,
    required this.accent,
  });

  final TextEditingController controller;
  final int maxDecimalDigits;
  final VoidCallback onDone;
  final Color accent;

  void _onKey(String key) {
    HapticFeedback.selectionClick();
    AmountKeypadInput.apply(
      controller: controller,
      key: key,
      maxDecimalDigits: maxDecimalDigits,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDecimal = maxDecimalDigits > 0;

    return Material(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text('Enter amount', style: AppTextStyles.caption),
                const Spacer(),
                TextButton(
                  onPressed: onDone,
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              children: [
                _KeyRow(keys: const ['1', '2', '3'], onKey: _onKey),
                _KeyRow(keys: const ['4', '5', '6'], onKey: _onKey),
                _KeyRow(keys: const ['7', '8', '9'], onKey: _onKey),
                _KeyRow(
                  keys: [showDecimal ? '.' : '', '0', 'backspace'],
                  onKey: _onKey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keypad input rules shared with tests if needed later.
class AmountKeypadInput {
  AmountKeypadInput._();

  static void apply({
    required TextEditingController controller,
    required String key,
    required int maxDecimalDigits,
  }) {
    var text = controller.text;

    if (key == 'backspace') {
      if (text.isEmpty) return;
      controller.text = text.substring(0, text.length - 1);
      return;
    }

    if (key == '.') {
      if (maxDecimalDigits == 0 || text.contains('.')) return;
      controller.text = text.isEmpty ? '0.' : '$text.';
      return;
    }

    if (text.contains('.')) {
      final fraction = text.split('.').last;
      if (fraction.length >= maxDecimalDigits) return;
    }

    if (text == '0') {
      controller.text = key;
      return;
    }

    controller.text = text + key;
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys, required this.onKey});

  final List<String> keys;
  final void Function(String key) onKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: keys.map((key) {
          if (key.isEmpty) {
            return const Expanded(child: SizedBox());
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _KeyButton(label: key, onPressed: () => onKey(key)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == 'backspace';

    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadii.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.buttonRadius,
        child: SizedBox(
          height: 52,
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  )
                : Text(
                    label,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
