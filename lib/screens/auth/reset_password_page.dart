import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/auth/auth_page_scaffold.dart';
import '../../config/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';

/// Two steps: email → (code + new password). The emailed code signs the
/// user in, so on success AuthGate (under this route) switches to the app.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = AuthService.instance;
    final email = _email.text.trim();
    try {
      if (!_codeSent) {
        await auth.sendPasswordReset(email);
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        return;
      }
      await auth.resetPassword(email, _code.text.trim(), _password.text);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Password updated');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      heading: 'Reset password',
      subtext: _codeSent
          ? 'Enter the code we sent to ${_email.text.trim()} and choose a new password'
          : "We'll email you a code to reset it",
      body: Form(
        key: _formKey,
        // Lets iOS pair the new password with the email for Keychain updates.
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'Email'),
                validator: validateEmail,
                textInputAction: _codeSent
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) => _codeSent ? null : _submit(),
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Code'),
                  validator: validateCode,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'New password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: validateNewPassword,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthSubmitButton(
                label: _codeSent ? 'Set new password' : 'Send code',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
