import 'package:flutter/material.dart';

import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// Theme, biometric lock, haptics, and motion / density toggles.
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
          subtitle:
              'Theme, lock, haptics, and how dense the transaction list '
              'feels.',
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
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Security',
              children: [
                SettingsTile(
                  icon: Icons.lock_rounded,
                  title: 'App Lock',
                  subtitle: 'Biometrics or PIN on launch',
                  futureReady: true,
                  onTap: () => _stub(context, 'App lock'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }
}
