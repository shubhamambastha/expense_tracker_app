import '../services/settings_preferences.dart';

/// Common timezone choices for the Edit Profile localization section.
class TimezoneOption {
  const TimezoneOption({required this.id, required this.label});

  final String id;
  final String label;
}

class TimezoneOptions {
  TimezoneOptions._();

  static List<TimezoneOption> all({required String deviceLabel}) => [
        TimezoneOption(
          id: SettingsPreferences.deviceTimezoneId,
          label: 'Device ($deviceLabel)',
        ),
        const TimezoneOption(id: 'Asia/Kolkata', label: 'India (IST)'),
        const TimezoneOption(id: 'America/New_York', label: 'US Eastern'),
        const TimezoneOption(id: 'America/Los_Angeles', label: 'US Pacific'),
        const TimezoneOption(id: 'Europe/London', label: 'UK (GMT/BST)'),
        const TimezoneOption(id: 'Europe/Berlin', label: 'Central Europe'),
        const TimezoneOption(id: 'Asia/Singapore', label: 'Singapore'),
        const TimezoneOption(id: 'UTC', label: 'UTC'),
      ];

  static String labelFor(String id, {required String deviceLabel}) {
    for (final o in all(deviceLabel: deviceLabel)) {
      if (o.id == id) return o.label;
    }
    return id;
  }
}
