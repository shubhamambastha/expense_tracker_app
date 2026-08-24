import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/settings_preferences.dart';
import '../../utils/profile_identity.dart';
import 'onboarding_step_scaffold.dart';

/// Step 1/5 — name, pre-filled from the Auth0 session (or the email
/// local-part as a fallback), editable, saved to [SettingsPreferences].
class OnboardingNameStep extends StatefulWidget {
  const OnboardingNameStep({super.key, required this.onSkip, required this.onNext});

  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  State<OnboardingNameStep> createState() => _OnboardingNameStepState();
}

class _OnboardingNameStepState extends State<OnboardingNameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final session = AuthService.instance.currentSession;
    final prefs = SettingsPreferences.instance;
    final email = ProfileIdentity.emailFor(session);
    final initial = prefs.displayName.trim().isNotEmpty
        ? prefs.displayName.trim()
        : (ProfileIdentity.sessionDisplayName(session) ??
              ProfileIdentity.displayNameFromEmail(email));
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      await SettingsPreferences.instance.setDisplayName(trimmed);
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      heading: "What's your name?",
      subtext: "We'll use this to personalize the app.",
      onSkip: widget.onSkip,
      onNext: _next,
      body: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: AppTextStyles.headingSmall,
        decoration: const InputDecoration(hintText: 'Your name'),
      ),
    );
  }
}
