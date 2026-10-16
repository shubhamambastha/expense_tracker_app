import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/auth/auth_page_scaffold.dart';
import '../../config/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';

/// Enter the code Supabase emailed after sign-up. A correct code signs the
/// user in; AuthGate (under this route) then switches to the app.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _resendCooldown = 60;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;
  int _cooldown = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) t.cancel();
      setState(() => _cooldown--);
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.verifyEmailCode(
        widget.email,
        _code.text.trim(),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService.instance.resendSignupCode(widget.email);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'New code sent');
      _startCooldown();
    } catch (error) {
      if (mounted) SnackbarHelper.showError(context, error);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      heading: 'Check your email',
      subtext: 'Enter the code we sent to ${widget.email}',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium,
              decoration: const InputDecoration(hintText: '123456'),
              validator: validateCode,
              onFieldSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: 'Verify',
              isLoading: _isLoading,
              onPressed: _verify,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _cooldown > 0 || _isLoading || _resending
                  ? null
                  : _resend,
              child: Text(
                _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
