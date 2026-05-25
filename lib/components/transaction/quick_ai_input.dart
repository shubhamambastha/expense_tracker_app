import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Small "Quick entry" input near the bottom of the screen.
///
/// User types a free-form line like `240 swiggy using hdfc` and we parse it
/// into the structured fields above. The parser itself is intentionally
/// pluggable — this widget just owns the input UX and surfaces the parsed
/// result back to the page.
class QuickAiInput extends StatefulWidget {
  const QuickAiInput({
    super.key,
    required this.onParse,
    this.hint = 'e.g. 240 swiggy using hdfc',
  });

  final ValueChanged<String> onParse;
  final String hint;

  @override
  State<QuickAiInput> createState() => _QuickAiInputState();
}

class _QuickAiInputState extends State<QuickAiInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    widget.onParse(raw);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: _submit,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
