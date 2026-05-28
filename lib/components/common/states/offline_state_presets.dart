import 'package:flutter/material.dart';

import 'offline_banner.dart';

/// Product-ready offline messaging presets.
abstract final class OfflineStatePresets {
  OfflineStatePresets._();

  static const offlineModeTitle = 'Offline Mode';
  static const offlineModeSubtitle = 'Changes will sync automatically';

  static const dashboardTitle = 'You\'re offline';
  static const dashboardSubtitle =
      'Showing locally available financial data.';

  static const savedOfflineTitle = 'Saved offline';
  static const savedOfflineSubtitle = 'Will sync automatically later.';

  /// Slim header strip for global offline awareness.
  static Widget subtleBanner() {
    return const OfflineBanner(
      title: offlineModeTitle,
      subtitle: offlineModeSubtitle,
      style: OfflineBannerStyle.subtle,
    );
  }

  /// Dashboard-area contextual reassurance.
  static Widget dashboardContext() {
    return const OfflineBanner(
      title: dashboardTitle,
      subtitle: dashboardSubtitle,
      style: OfflineBannerStyle.contextual,
    );
  }

  /// Inline confirmation after saving while offline.
  static Widget transactionSavedOffline() {
    return const OfflineSavedNotice();
  }
}
