import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/common/compact_header.dart';
import '../../config/design_tokens.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';

/// Error screen shown when app fails to initialize.
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const CompactHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 36,
                        color: AppColors.danger,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: AppDurations.page,
                          curve: AppCurves.spring,
                        ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppConstants.errorAppInitFailed,
                      style: AppTextStyles.headingSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadii.cardRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        AppConstants.errorAppInitInstructions,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
