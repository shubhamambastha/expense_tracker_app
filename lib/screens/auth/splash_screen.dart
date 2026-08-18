import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_tokens.dart';

/// Visual state for the splash surface.
enum SplashUiState { loading, error }

/// Branded launch screen shown while the app restores session and local state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.uiState = SplashUiState.loading,
    this.statusMessage = 'Preparing your finances…',
    this.errorMessage = 'Unable to load app',
    this.onRetry,
  });

  final SplashUiState uiState;
  final String statusMessage;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Animate(
                  effects: [
                    FadeEffect(duration: AppDurations.page),
                    ScaleEffect(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1),
                      duration: AppDurations.pageLong,
                      curve: AppCurves.spring,
                    ),
                  ],
                  child: Animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    effects: const [
                      ScaleEffect(
                        begin: Offset(1, 1),
                        end: Offset(1.02, 1.02),
                        duration: Duration(milliseconds: 2400),
                        curve: Curves.easeInOut,
                      ),
                    ],
                    child: const _LogoMark(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Expense Tracker',
                  style: AppTextStyles.headingLarge,
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 60),
                      duration: AppDurations.page,
                    )
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: AppDurations.page,
                      curve: AppCurves.spring,
                    ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Track smarter.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 120),
                      duration: AppDurations.page,
                    ),
                const Spacer(flex: 4),
                AnimatedSwitcher(
                  duration: AppDurations.short,
                  switchInCurve: AppCurves.easeOutQuint,
                  switchOutCurve: Curves.easeIn,
                  child: uiState == SplashUiState.error
                      ? _SplashErrorState(
                          key: const ValueKey('splash-error'),
                          message: errorMessage,
                          onRetry: onRetry,
                        )
                      : _SplashLoadingState(
                          key: const ValueKey('splash-loading'),
                          statusMessage: statusMessage,
                        ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.42),
          radius: 1.15,
          colors: [
            AppColors.primary.withAlpha(22),
            AppColors.background,
          ],
          stops: const [0.0, 0.72],
        ),
      ),
    );
  }
}

class _SplashLoadingState extends StatelessWidget {
  const _SplashLoadingState({
    super.key,
    required this.statusMessage,
  });

  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusMessage,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary.withAlpha(220),
          ),
        )
            .animate(key: ValueKey(statusMessage))
            .fadeIn(duration: AppDurations.micro)
            .slideY(begin: 0.12, end: 0, duration: AppDurations.micro),
        const SizedBox(height: AppSpacing.lg),
        const _SubtleLoadingDots(),
      ],
    );
  }
}

class _SplashErrorState extends StatelessWidget {
  const _SplashErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: AppDurations.page)
        .slideY(begin: 0.08, end: 0, duration: AppDurations.page);
  }
}

class _SubtleLoadingDots extends StatelessWidget {
  const _SubtleLoadingDots();

  static const _dotSize = 5.0;
  static const _stagger = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.sm),
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(180),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: AppDurations.micro, delay: _stagger * index)
              .then()
              .fade(
                begin: 1,
                end: 0.35,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
              )
              .then()
              .fade(
                begin: 0.35,
                end: 1,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(64),
            AppColors.secondary.withAlpha(36),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(64)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }
}
