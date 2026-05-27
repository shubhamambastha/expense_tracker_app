import 'dart:async';

import 'package:app_links/app_links.dart';

import 'app_launch_intent.dart';

/// Listens for `expensetracker://` links from the iOS widget (and other sources).
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Subscribe before reading initial link so the native side can replay it.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );

    await captureLinks();
  }

  /// Re-reads links from the platform (widget taps can arrive after startup).
  Future<void> captureLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
      final latest = await _appLinks.getLatestLink();
      if (latest != null) {
        _handleUri(latest);
      }
    } catch (_) {
      // Non-fatal: app still works without deep links.
    }
  }

  void _handleUri(Uri uri) {
    final intent = AppLaunchIntentHolder.fromUri(uri);
    if (intent != null) {
      AppLaunchIntentHolder.instance.set(intent);
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _started = false;
  }
}
