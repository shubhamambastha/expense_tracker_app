import 'package:flutter/material.dart';

import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';

/// Theme (Light/Dark) and brand accent color, driving [AppColors] app-wide.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'Appearance',
          children: [
            SettingsSection(
              title: 'Theme',
              children: [
                _ThemeRow(
                  label: 'Light',
                  selected: prefs.themeMode == ThemeMode.light,
                  onTap: () => prefs.setThemeMode(ThemeMode.light),
                ),
                _ThemeRow(
                  label: 'Dark',
                  selected: prefs.themeMode == ThemeMode.dark,
                  onTap: () => prefs.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Accent Color',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      for (final accent in AppAccent.values) ...[
                        _AccentSwatch(
                          accent: accent,
                          selected: prefs.accentColor == accent,
                          onTap: () => prefs.setAccentColor(accent),
                        ),
                        if (accent != AppAccent.values.last)
                          const SizedBox(width: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      title: label,
      onTap: onTap,
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.primary)
          : const SizedBox.shrink(),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: accent.label,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
