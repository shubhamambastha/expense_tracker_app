import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Wrapper for every Settings sub-screen (e.g. Financial Preferences).
///
/// Provides a minimal back-aware app bar that matches the rest of the
/// premium dark theme and a scrollable body with consistent padding. No
/// entrance animation of its own — the push route already slides/fades the
/// whole page in, so animating the body too just produces a blank flash.
class SettingsSubpageScaffold extends StatelessWidget {
  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _SettingsSubpageAppBar(title: title),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subtitle != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xs,
                        0,
                        AppSpacing.xs,
                        AppSpacing.md,
                      ),
                      child: Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSubpageAppBar extends StatelessWidget {
  const _SettingsSubpageAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                _AppBarIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.buttonRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
