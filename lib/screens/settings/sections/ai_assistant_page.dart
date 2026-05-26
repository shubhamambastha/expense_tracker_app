import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// Controls for the in-app AI assistant: enable/disable, suggested insights,
/// privacy explainer, and history clearing.
class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'AI Assistant',
          subtitle:
              'Toggle the assistant, pick which insights it surfaces, and '
              'manage local chat history.',
          children: [
            SettingsSection(
              title: 'Assistant',
              children: [
                SettingsSwitchTile(
                  icon: Icons.psychology_rounded,
                  title: 'AI Assistant',
                  subtitle: 'Enable AI features across the app',
                  value: prefs.aiAssistantEnabled,
                  onChanged: prefs.setAiAssistantEnabled,
                ),
                SettingsSwitchTile(
                  icon: Icons.lightbulb_rounded,
                  title: 'Suggested Insights',
                  subtitle:
                      'Spending analysis & saving recommendations',
                  value: prefs.aiInsightsEnabled,
                  onChanged: prefs.aiAssistantEnabled
                      ? prefs.setAiInsightsEnabled
                      : (_) {},
                  enabled: prefs.aiAssistantEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Privacy & data',
              children: [
                const SettingsInfoTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'AI Data Usage',
                  subtitle:
                      'AI only analyzes financial data inside the app. '
                      'Nothing leaves your account.',
                ),
                SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Clear AI Chat History',
                  subtitle: 'Remove past conversations from this device',
                  destructive: true,
                  onTap: () => _confirmClearAiHistory(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearAiHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear AI history'),
        content: const Text(
          'This removes all AI conversations stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      SnackbarHelper.showSuccess(context, 'AI chat history cleared');
    }
  }
}
