import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

typedef SubmitCallback = Future<void> Function();

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isRegistering,
    required this.isLoading,
    required this.onSubmit,
    required this.onToggleRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isRegistering;
  final bool isLoading;
  final SubmitCallback onSubmit;
  final VoidCallback onToggleRegister;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@domain.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter email';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'At least 6 characters',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF003328),
                      ),
                    )
                  : Text(isRegistering ? 'Create account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: isLoading ? null : onToggleRegister,
            child: Text(
              isRegistering
                  ? 'Already have an account? Sign in'
                  : 'Create a new account',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
