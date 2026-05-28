import 'package:flutter/material.dart';

import 'error_state.dart';

/// Product-ready error states with calm, recoverable messaging.
abstract final class ErrorStatePresets {
  ErrorStatePresets._();

  static Widget failedTransactionSave({required VoidCallback onRetry}) {
    return ErrorState(
      title: 'Couldn\'t save transaction',
      subtitle: 'Your changes are still available locally.',
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
      layout: ErrorStateLayout.inline,
    );
  }

  static Widget failedSync({required VoidCallback onRetryNow}) {
    return ErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Sync paused',
      subtitle: 'We\'ll retry automatically when connection improves.',
      primaryActionLabel: 'Retry Now',
      onPrimaryAction: onRetryNow,
      layout: ErrorStateLayout.banner,
      animate: false,
    );
  }

  static Widget analyticsFailed({required VoidCallback onReload}) {
    return ErrorState(
      icon: Icons.insights_rounded,
      title: 'Unable to load analytics',
      subtitle: 'Please try again in a moment.',
      primaryActionLabel: 'Reload',
      onPrimaryAction: onReload,
    );
  }

  static Widget paymentReminderFailure({required VoidCallback onTryAgain}) {
    return ErrorState(
      icon: Icons.notifications_off_outlined,
      title: 'Reminder couldn\'t be scheduled',
      primaryActionLabel: 'Try Again',
      onPrimaryAction: onTryAgain,
      layout: ErrorStateLayout.inline,
    );
  }

  static Widget aiAssistantFailure({required VoidCallback onRetry}) {
    return ErrorState(
      icon: Icons.smart_toy_outlined,
      title: 'AI assistant unavailable',
      subtitle: 'Please try again later.',
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
      layout: ErrorStateLayout.inline,
    );
  }
}
