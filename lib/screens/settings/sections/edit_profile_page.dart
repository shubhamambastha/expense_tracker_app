import 'package:flutter/material.dart';
import '../../../components/profile/edit_profile_header.dart';
import '../../../components/profile/profile_form_field.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/transaction/sticky_bottom_cta.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../utils/profile_identity.dart';
import '../../../utils/snackbar_helper.dart';

/// Personal identity — name, email, phone, avatar.
///
/// Everything else that used to live here (currency, defaults, app
/// personalization, security, data) is a general app setting, not a
/// personal-profile field — it lives in the Settings hub and its
/// subpages instead, with a single source of truth.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _avatarRemoved = false;
  late bool _baselineAvatarRemoved;
  late String _baselineName;
  late String _baselinePhone;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  void _loadDraft() {
    final session = AuthService.instance.currentSession;
    final prefs = SettingsPreferences.instance;

    final email = ProfileIdentity.emailFor(session);
    final storedName = prefs.displayName.trim().isNotEmpty
        ? prefs.displayName.trim()
        : (ProfileIdentity.sessionDisplayName(session) ??
              ProfileIdentity.displayNameFromEmail(email));
    final phone = prefs.phoneNumber.trim();

    _nameController.text = storedName;
    _emailController.text = email;
    _phoneController.text = phone;

    _avatarRemoved = prefs.avatarRemoved;
    _baselineAvatarRemoved = _avatarRemoved;
    _baselineName = storedName;
    _baselinePhone = phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_nameController.text.trim() != _baselineName) return true;
    if (_phoneController.text.trim() != _baselinePhone) return true;
    return _avatarRemoved != _baselineAvatarRemoved;
  }

  void _markDirty() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : ProfileIdentity.displayNameFromEmail(email);
    final initial = ProfileIdentity.initialFor(displayName, email);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _EditProfileAppBar(
              onBack: () async {
                if (!_hasUnsavedChanges) {
                  Navigator.of(context).maybePop();
                  return;
                }
                final leave = await _confirmDiscard();
                if (leave && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EditProfileHeader(
                      initial: initial,
                      displayName: displayName,
                      email: email,
                      summaryLines: const [],
                      onAvatarTap: _showAvatarSheet,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _personalInfoSection(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            StickyBottomCTA(
              saveLabel: 'Save Changes',
              secondaryLabel: 'Cancel',
              isBusy: _isSaving,
              showSaveAndAddAnother: true,
              onSave: _save,
              onSaveAndAddAnother: () async {
                if (!_hasUnsavedChanges) {
                  Navigator.of(context).maybePop();
                  return;
                }
                final leave = await _confirmDiscard();
                if (leave && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalInfoSection() {
    return SettingsSection(
      title: 'Personal Information',
      footnote: 'Used for greetings and a more personal experience.',
      children: [
        ProfileFormField(
          label: 'Full Name',
          hint: 'How we address you',
          controller: _nameController,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _markDirty(),
        ),
        Divider(height: 1, thickness: 1, color: AppColors.border),
        ProfileFormField(
          label: 'Email Address',
          hint: 'you@domain.com',
          controller: _emailController,
          readOnly: true,
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          helperText: 'Managed by Auth0 — update in your Auth0 account.',
          onChanged: (_) {},
        ),
        Divider(height: 1, thickness: 1, color: AppColors.border),
        ProfileFormField(
          label: 'Phone Number',
          hint: '+91 98765 43210',
          controller: _phoneController,
          optional: true,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          helperText: 'Optional — for reminders and SMS parsing later.',
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }

  Future<void> _showAvatarSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Profile photo', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Optional — a photo helps personalize your space.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Change photo'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    SnackbarHelper.showMessage(
                      context,
                      'Photo upload is coming soon',
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger.withAlpha(220),
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: AppColors.danger.withAlpha(220)),
                  ),
                  onTap: () {
                    setState(() => _avatarRemoved = true);
                    Navigator.of(sheetContext).pop();
                    SnackbarHelper.showMessage(
                      context,
                      'Photo removed — initials will show',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved edits. Leaving now will lose them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final prefs = SettingsPreferences.instance;

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await prefs.setDisplayName(name);
      await prefs.setPhoneNumber(phone);
      await prefs.setAvatarRemoved(_avatarRemoved);

      if (mounted) {
        _baselineAvatarRemoved = _avatarRemoved;
        _baselineName = name;
        _baselinePhone = phone;
        SnackbarHelper.showSuccess(context, 'Profile saved');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Could not save profile');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _EditProfileAppBar extends StatelessWidget {
  const _EditProfileAppBar({required this.onBack});

  final VoidCallback onBack;

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
                Tooltip(
                  message: 'Back',
                  child: InkWell(
                    onTap: onBack,
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
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Edit Profile',
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
