import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:expense_tracker_app/utils/account_deletion_request.dart';

/// Fake platform for [UrlLauncherPlatform.instance] — the documented way to
/// test url_launcher call sites without touching a real OS mail app.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform({required this.behavior});

  final _LaunchBehavior behavior;
  String? lastUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    switch (behavior) {
      case _LaunchBehavior.succeeds:
        return true;
      case _LaunchBehavior.noHandler:
        return false;
      case _LaunchBehavior.throws:
        throw PlatformException(code: 'launch_failed');
    }
  }
}

enum _LaunchBehavior { succeeds, noHandler, throws }

void main() {
  final originalPlatform = UrlLauncherPlatform.instance;

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  test('launched when the OS opens a mail composer', () async {
    final fake = _FakeUrlLauncherPlatform(behavior: _LaunchBehavior.succeeds);
    UrlLauncherPlatform.instance = fake;

    final result = await launchAccountDeletionRequest(
      userEmail: 'user@example.com',
      userId: 'auth0|abc123',
    );

    expect(result, AccountDeletionRequestResult.launched);
    expect(fake.lastUrl, startsWith('mailto:'));
    expect(fake.lastUrl, contains('user%40example.com'));
  });

  test('noMailApp when launchUrl returns false (no handler)', () async {
    UrlLauncherPlatform.instance =
        _FakeUrlLauncherPlatform(behavior: _LaunchBehavior.noHandler);

    final result = await launchAccountDeletionRequest(
      userEmail: 'user@example.com',
      userId: 'auth0|abc123',
    );

    expect(result, AccountDeletionRequestResult.noMailApp);
  });

  test('failed when the platform throws', () async {
    UrlLauncherPlatform.instance =
        _FakeUrlLauncherPlatform(behavior: _LaunchBehavior.throws);

    final result = await launchAccountDeletionRequest(
      userEmail: 'user@example.com',
      userId: 'auth0|abc123',
    );

    expect(result, AccountDeletionRequestResult.failed);
  });
}
