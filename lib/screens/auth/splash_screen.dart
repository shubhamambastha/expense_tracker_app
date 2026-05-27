import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_tokens.dart';

/// Branded launch screen shown while the app restores the auth session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              _LogoMark()
                  .animate()
                  .fadeIn(duration: AppDurations.page)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: AppDurations.pageLong,
                    curve: AppCurves.spring,
                  ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Expense Tracker',
                style: AppTextStyles.headingLarge,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 80),
                    duration: AppDurations.page,
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: AppDurations.page,
                    curve: AppCurves.spring,
                  ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your money, clearly in view',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 140),
                    duration: AppDurations.page,
                  ),
              const Spacer(flex: 4),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 220),
                    duration: AppDurations.page,
                  ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(72),
            AppColors.secondary.withAlpha(40),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withAlpha(72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(48),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
        size: 42,
      ),
    );
  }
}
