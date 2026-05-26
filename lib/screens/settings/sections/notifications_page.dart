import 'package:flutter/material.dart';

import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';

/// Reminders, alerts, and insight pings — plus when they fire.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'Notifications & Reminders',
          subtitle:
              'Pick which pings you want. Timing applies to recurring and '
              'budget reminders.',
          children: [
            SettingsSection(
              title: 'Pings',
              children: [
                SettingsSwitchTile(
                  icon: Icons.event_repeat_rounded,
                  title: 'Recurring Payment Reminders',
                  subtitle: 'EMIs, bills, subscriptions',
                  value: prefs.notifRecurringEnabled,
                  onChanged: prefs.setNotifRecurringEnabled,
                ),
                SettingsSwitchTile(
                  icon: Icons.work_history_rounded,
                  title: 'Salary Reminder',
                  subtitle: 'Ping when your salary is expected',
                  value: prefs.notifSalaryEnabled,
                  onChanged: prefs.setNotifSalaryEnabled,
                ),
                SettingsSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Budget Alerts',
                  subtitle: 'Nearing limits & overspending',
                  value: prefs.notifBudgetEnabled,
                  onChanged: prefs.setNotifBudgetEnabled,
                ),
                SettingsSwitchTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Smart Insights',
                  subtitle: 'Unusual spending & monthly summaries',
                  value: prefs.notifInsightsEnabled,
                  onChanged: prefs.setNotifInsightsEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Timing',
              children: [
                SettingsTile(
                  icon: Icons.alarm_rounded,
                  title: 'Notification Timing',
                  subtitle: 'When reminders fire',
                  valueLabel: prefs.notifTiming.label,
                  onTap: () => _pickTiming(context, prefs),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTiming(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      showSettingsOptionSheet<NotificationTiming>(
        context: context,
        title: 'Notification timing',
        subtitle: 'When recurring & budget reminders fire.',
        current: prefs.notifTiming,
        options: NotificationTiming.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setNotifTiming,
      );
}
