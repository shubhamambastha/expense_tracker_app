import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/validators.dart';
import 'auth_page_scaffold.dart';

/// Email + password form for both signing in and creating an account.
/// UI-only: the page decides what [onSubmit] does.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.isSignUp,
    required this.isLoading,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onForgotPassword,
  });

  final bool isSignUp;
  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onToggleMode;
  final void Function(String email) onForgotPassword;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: [
                widget.isSignUp
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Password',
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
              validator: widget.isSignUp
                  ? validateNewPassword
                  : validatePassword,
            ),
            if (!widget.isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onForgotPassword(_email.text.trim()),
                  child: const Text('Forgot password?'),
                ),
              )
            else
              const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: widget.isSignUp ? 'Create account' : 'Sign in',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: widget.isLoading ? null : widget.onToggleMode,
              child: Text(
                widget.isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
