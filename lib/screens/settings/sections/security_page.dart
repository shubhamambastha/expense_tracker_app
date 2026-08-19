import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// App-lock and session controls.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'Security',
          subtitle: 'Lightweight controls — biometrics and PIN coming soon.',
          children: [
            SettingsSection(
              title: 'App Lock',
              children: [
                SettingsSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Lock',
                  subtitle: 'Fingerprint or face unlock on launch',
                  value: prefs.appLockEnabled,
                  onChanged: prefs.setAppLockEnabled,
                ),
                SettingsTile(
                  icon: Icons.pin_rounded,
                  title: 'App PIN',
                  subtitle: 'Optional secondary lock',
                  futureReady: true,
                  onTap: () => SnackbarHelper.showMessage(
                    context,
                    'App PIN is coming soon',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Session',
              children: const [
                SettingsInfoTile(
                  icon: Icons.devices_rounded,
                  title: 'Session',
                  subtitle: 'Signed in with Auth0 on this device',
                  valueLabel: 'This device',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
