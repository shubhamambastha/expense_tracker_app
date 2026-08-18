import 'package:flutter/material.dart';

import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';

/// Haptics and motion / density toggles.
///
/// Theme lives in the Appearance page and app lock in the root Security
/// group — this page is just the remaining interaction feel settings.
class AppPreferencesPage extends StatelessWidget {
  const AppPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'App Preferences',
          subtitle: 'Haptics and how dense the transaction list feels.',
          children: [
            SettingsSection(
              title: 'Look & feel',
              children: [
                SettingsSwitchTile(
                  icon: Icons.density_small_rounded,
                  title: 'Compact Mode',
                  subtitle: 'Denser transaction list',
                  value: prefs.compactModeEnabled,
                  onChanged: prefs.setCompactModeEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Interactions',
              children: [
                SettingsSwitchTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  subtitle: 'Subtle taps on interactions',
                  value: prefs.hapticEnabled,
                  onChanged: prefs.setHapticEnabled,
                ),
                SettingsSwitchTile(
                  icon: Icons.animation_rounded,
                  title: 'Animations',
                  subtitle: 'Turn off to reduce motion',
                  value: prefs.animationsEnabled,
                  onChanged: prefs.setAnimationsEnabled,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
