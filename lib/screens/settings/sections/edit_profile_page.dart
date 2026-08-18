import 'package:flutter/material.dart';
import '../../../components/profile/edit_profile_header.dart';
import '../../../components/profile/profile_form_field.dart';
import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../components/transaction/sticky_bottom_cta.dart';
import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart';
import '../../../services/currency_settings.dart';
import '../../../services/settings_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../utils/profile_identity.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../utils/timezone_options.dart';

/// Personal financial identity, preferences, and account defaults.
///
/// Single scrollable form with grouped sections and explicit Save / Cancel.
/// Changes stay in a local draft until the user saves.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.accounts});

  final List<Account> accounts;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late _ProfileDraft _draft;
  late _ProfileDraft _baseline;
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
    final currency = CurrencySettings.instance;

    final email = ProfileIdentity.emailFor(session);
    final storedName = prefs.displayName.trim().isNotEmpty
        ? prefs.displayName.trim()
        : (ProfileIdentity.sessionDisplayName(session) ??
              ProfileIdentity.displayNameFromEmail(email));
    final phone = prefs.phoneNumber.trim();

    _nameController.text = storedName;
    _emailController.text = email;
    _phoneController.text = phone;

    _draft = _ProfileDraft(
      currencyCode: currency.currencyCode,
      multiCurrencyEnabled: prefs.multiCurrencyEnabled,
      defaultExpenseAccountId: prefs.defaultExpenseAccountId,
      defaultIncomeAccountId: prefs.defaultIncomeAccountId,
      defaultTransactionType: prefs.defaultTransactionType,
      timezoneId: prefs.timezoneId,
      compactModeEnabled: prefs.compactModeEnabled,
      animationsEnabled: prefs.animationsEnabled,
      hapticEnabled: prefs.hapticEnabled,
      appLockEnabled: prefs.appLockEnabled,
      avatarRemoved: prefs.avatarRemoved,
    );
    _baseline = _draft.copyWith();
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
    return _draft != _baseline;
  }

  void _markDirty() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final prefs = SettingsPreferences.instance;
    final currency = CurrencySettings.instance;
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
                      summaryLines: _summaryLines(currency, prefs),
                      onAvatarTap: _showAvatarSheet,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _personalInfoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _financialPreferencesSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _localizationSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _appPersonalizationSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _securitySection(),
                    const SizedBox(height: AppSpacing.lg),
                    _dataPreferencesSection(),
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

  List<String> _summaryLines(
    CurrencySettings currency,
    SettingsPreferences prefs,
  ) {
    final lines = <String>['Primary Currency: ${_draft.currencyCode}'];
    if (prefs.monthlySpendingLimit != null) {
      lines.add('Monthly Budget Active');
    }
    return lines;
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

  Widget _financialPreferencesSection() {
    return SettingsSection(
      title: 'Financial Preferences',
      footnote: 'Defaults that shape analytics, budgets, and Add Transaction.',
      children: [
        SettingsTile(
          icon: Icons.payments_rounded,
          title: 'Primary Currency',
          subtitle: 'Analytics, budgets & dashboard amounts',
          valueLabel: _draft.currencyCode,
          onTap: _pickCurrency,
        ),
        SettingsSwitchTile(
          icon: Icons.swap_horiz_rounded,
          title: 'Multi-Currency',
          subtitle: 'Track foreign currencies on entries',
          value: _draft.multiCurrencyEnabled,
          onChanged: (v) {
            setState(() => _draft = _draft.copyWith(multiCurrencyEnabled: v));
          },
        ),
        SettingsTile(
          icon: Icons.outbox_rounded,
          title: 'Default Expense Account',
          subtitle: 'Preselected on Add Transaction',
          valueLabel: _accountLabel(_draft.defaultExpenseAccountId) ?? 'Auto',
          onTap: () => _pickAccount(
            title: 'Default expense account',
            currentId: _draft.defaultExpenseAccountId,
            onPicked: (id) => setState(
              () => _draft = _draft.copyWith(defaultExpenseAccountId: id),
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.inbox_rounded,
          title: 'Default Income Account',
          subtitle: 'Destination for new income',
          valueLabel: _accountLabel(_draft.defaultIncomeAccountId) ?? 'Auto',
          onTap: () => _pickAccount(
            title: 'Default income account',
            currentId: _draft.defaultIncomeAccountId,
            onPicked: (id) => setState(
              () => _draft = _draft.copyWith(defaultIncomeAccountId: id),
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.compare_arrows_rounded,
          title: 'Default Transaction Type',
          subtitle: 'Starting tab on Add Transaction',
          valueLabel: _draft.defaultTransactionType.label,
          onTap: () => showSettingsOptionSheet<DefaultTransactionType>(
            context: context,
            title: 'Default transaction type',
            current: _draft.defaultTransactionType,
            options: DefaultTransactionType.values,
            labelFor: (v) => v.label,
            onPicked: (v) async {
              setState(
                () => _draft = _draft.copyWith(defaultTransactionType: v),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _localizationSection() {
    final deviceTz = DateTime.now().timeZoneName;
    return SettingsSection(
      title: 'Localization',
      footnote: 'Used to group activity by day across the app.',
      children: [
        SettingsTile(
          icon: Icons.schedule_rounded,
          title: 'Timezone',
          subtitle: 'Reminders, recurring payments & analytics',
          valueLabel: TimezoneOptions.labelFor(
            _draft.timezoneId,
            deviceLabel: deviceTz,
          ),
          onTap: () => showSettingsOptionSheet<String>(
            context: context,
            title: 'Timezone',
            subtitle: 'Used when grouping activity by day.',
            current: _draft.timezoneId,
            options: TimezoneOptions.all(
              deviceLabel: deviceTz,
            ).map((o) => o.id).toList(),
            labelFor: (id) =>
                TimezoneOptions.labelFor(id, deviceLabel: deviceTz),
            onPicked: (v) async {
              setState(() => _draft = _draft.copyWith(timezoneId: v));
            },
          ),
        ),
      ],
    );
  }

  Widget _appPersonalizationSection() {
    return SettingsSection(
      title: 'App Personalization',
      children: [
        SettingsSwitchTile(
          icon: Icons.density_small_rounded,
          title: 'Compact Mode',
          subtitle: 'Denser transaction list',
          value: _draft.compactModeEnabled,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(compactModeEnabled: v)),
        ),
        SettingsSwitchTile(
          icon: Icons.animation_rounded,
          title: 'Animations',
          subtitle: 'Turn off to reduce motion',
          value: _draft.animationsEnabled,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(animationsEnabled: v)),
        ),
        SettingsSwitchTile(
          icon: Icons.vibration_rounded,
          title: 'Haptic Feedback',
          subtitle: 'Subtle taps on interactions',
          value: _draft.hapticEnabled,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(hapticEnabled: v)),
        ),
      ],
    );
  }

  Widget _securitySection() {
    const sessionSubtitle = 'Signed in with Auth0 on this device';

    return SettingsSection(
      title: 'Security',
      footnote: 'Lightweight controls — biometrics and PIN coming soon.',
      children: [
        SettingsSwitchTile(
          icon: Icons.fingerprint_rounded,
          title: 'Biometric Lock',
          subtitle: 'Fingerprint or face unlock on launch',
          value: _draft.appLockEnabled,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(appLockEnabled: v)),
        ),
        SettingsTile(
          icon: Icons.pin_rounded,
          title: 'App PIN',
          subtitle: 'Optional secondary lock',
          futureReady: true,
          onTap: () =>
              SnackbarHelper.showMessage(context, 'App PIN is coming soon'),
        ),
        SettingsInfoTile(
          icon: Icons.devices_rounded,
          title: 'Session',
          subtitle: sessionSubtitle,
          valueLabel: 'This device',
        ),
      ],
    );
  }

  Widget _dataPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: 'Data Preferences',
          children: [
            SettingsTile(
              icon: Icons.file_download_rounded,
              title: 'Export Data',
              subtitle: 'Download your transactions',
              futureReady: true,
              onTap: () => SnackbarHelper.showMessage(
                context,
                'Export data is coming soon',
              ),
            ),
            const SettingsInfoTile(
              icon: Icons.cloud_done_rounded,
              title: 'Sync Status',
              subtitle: 'All changes synced',
              statusPill: 'Synced',
            ),
            const SettingsInfoTile(
              icon: Icons.offline_bolt_rounded,
              title: 'Offline Data',
              subtitle:
                  'Reads and writes work offline — synced when you reconnect',
              statusPill: 'Local-first',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCurrency() async {
    final codes = CurrencySettings.supported.map((c) => c.code).toList();
    final picked = await selectFromList<String>(
      context: context,
      title: 'Primary currency',
      subtitle: 'Used for analytics, budgets, and dashboard totals.',
      current: _draft.currencyCode,
      options: codes,
      labelFor: (code) {
        final opt = CurrencySettings.supported.firstWhere(
          (c) => c.code == code,
        );
        return '${opt.name} (${opt.code})';
      },
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(currencyCode: picked));
    }
  }

  Future<void> _pickAccount({
    required String title,
    required int? currentId,
    required void Function(int?) onPicked,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Text(title, style: AppTextStyles.headingSmall),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      SettingsAccountPickerRow(
                        title: 'Auto',
                        subtitle: 'Most recently used account',
                        selected: currentId == null,
                        icon: Icons.auto_awesome_rounded,
                        onTap: () {
                          onPicked(null);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...widget.accounts.map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SettingsAccountPickerRow(
                            title: account.name,
                            subtitle: account.type.label,
                            selected: currentId == account.id,
                            icon: iconForAccountType(account.type),
                            onTap: () {
                              onPicked(account.id);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                    setState(() {
                      _draft = _draft.copyWith(avatarRemoved: true);
                    });
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

  String? _accountLabel(int? id) {
    if (id == null) return null;
    for (final a in widget.accounts) {
      if (a.id == id) return a.name;
    }
    return null;
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
      final currency = CurrencySettings.instance;

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await prefs.setDisplayName(name);
      await prefs.setPhoneNumber(phone);
      await prefs.setMultiCurrencyEnabled(_draft.multiCurrencyEnabled);
      await prefs.setDefaultExpenseAccountId(_draft.defaultExpenseAccountId);
      await prefs.setDefaultIncomeAccountId(_draft.defaultIncomeAccountId);
      await prefs.setDefaultTransactionType(_draft.defaultTransactionType);
      await prefs.setTimezoneId(_draft.timezoneId);
      await prefs.setCompactModeEnabled(_draft.compactModeEnabled);
      await prefs.setAnimationsEnabled(_draft.animationsEnabled);
      await prefs.setHapticEnabled(_draft.hapticEnabled);
      await prefs.setAppLockEnabled(_draft.appLockEnabled);
      await prefs.setAvatarRemoved(_draft.avatarRemoved);

      if (_draft.currencyCode != currency.currencyCode &&
          CurrencySettings.isSupportedCode(_draft.currencyCode)) {
        await currency.setCurrency(_draft.currencyCode);
      }

      if (mounted) {
        _baseline = _draft.copyWith();
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

/// Local draft of profile + preference fields (equality drives dirty state).
class _ProfileDraft {
  const _ProfileDraft({
    required this.currencyCode,
    required this.multiCurrencyEnabled,
    required this.defaultExpenseAccountId,
    required this.defaultIncomeAccountId,
    required this.defaultTransactionType,
    required this.timezoneId,
    required this.compactModeEnabled,
    required this.animationsEnabled,
    required this.hapticEnabled,
    required this.appLockEnabled,
    required this.avatarRemoved,
  });

  final String currencyCode;
  final bool multiCurrencyEnabled;
  final int? defaultExpenseAccountId;
  final int? defaultIncomeAccountId;
  final DefaultTransactionType defaultTransactionType;
  final String timezoneId;
  final bool compactModeEnabled;
  final bool animationsEnabled;
  final bool hapticEnabled;
  final bool appLockEnabled;
  final bool avatarRemoved;

  _ProfileDraft copyWith({
    String? currencyCode,
    bool? multiCurrencyEnabled,
    int? defaultExpenseAccountId,
    bool clearDefaultExpenseAccountId = false,
    int? defaultIncomeAccountId,
    bool clearDefaultIncomeAccountId = false,
    DefaultTransactionType? defaultTransactionType,
    String? timezoneId,
    bool? compactModeEnabled,
    bool? animationsEnabled,
    bool? hapticEnabled,
    bool? appLockEnabled,
    bool? avatarRemoved,
  }) {
    return _ProfileDraft(
      currencyCode: currencyCode ?? this.currencyCode,
      multiCurrencyEnabled: multiCurrencyEnabled ?? this.multiCurrencyEnabled,
      defaultExpenseAccountId: clearDefaultExpenseAccountId
          ? null
          : (defaultExpenseAccountId ?? this.defaultExpenseAccountId),
      defaultIncomeAccountId: clearDefaultIncomeAccountId
          ? null
          : (defaultIncomeAccountId ?? this.defaultIncomeAccountId),
      defaultTransactionType:
          defaultTransactionType ?? this.defaultTransactionType,
      timezoneId: timezoneId ?? this.timezoneId,
      compactModeEnabled: compactModeEnabled ?? this.compactModeEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      avatarRemoved: avatarRemoved ?? this.avatarRemoved,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _ProfileDraft &&
        other.currencyCode == currencyCode &&
        other.multiCurrencyEnabled == multiCurrencyEnabled &&
        other.defaultExpenseAccountId == defaultExpenseAccountId &&
        other.defaultIncomeAccountId == defaultIncomeAccountId &&
        other.defaultTransactionType == defaultTransactionType &&
        other.timezoneId == timezoneId &&
        other.compactModeEnabled == compactModeEnabled &&
        other.animationsEnabled == animationsEnabled &&
        other.hapticEnabled == hapticEnabled &&
        other.appLockEnabled == appLockEnabled &&
        other.avatarRemoved == avatarRemoved;
  }

  @override
  int get hashCode => Object.hashAll([
    currencyCode,
    multiCurrencyEnabled,
    defaultExpenseAccountId,
    defaultIncomeAccountId,
    defaultTransactionType,
    timezoneId,
    compactModeEnabled,
    animationsEnabled,
    hapticEnabled,
    appLockEnabled,
    avatarRemoved,
  ]);
}
