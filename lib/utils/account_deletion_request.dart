import 'package:url_launcher/url_launcher.dart';

import '../config/app_info.dart';

/// Outcome of [launchAccountDeletionRequest] — three distinct shapes, all
/// handled explicitly by the caller (never a silent failure).
enum AccountDeletionRequestResult {
  /// The OS opened a mail compose screen. Doesn't guarantee the user hits
  /// Send — this is a client-composed mailto:, not a delivery receipt.
  launched,

  /// `launchUrl` returned `false` — no app on the device can handle a
  /// mailto: intent. Common on Android with no mail app configured.
  noMailApp,

  /// `launchUrl` threw (e.g. `PlatformException`).
  failed,
}

/// Opens the OS mail composer addressed to [AppInfo.supportEmail] with the
/// requesting user's identity pre-filled, so a human can act on the request
/// manually (per docs/BACKLOG.md's request-based, not self-service design).
Future<AccountDeletionRequestResult> launchAccountDeletionRequest({
  required String userEmail,
  required String userId,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppInfo.supportEmail,
    query:
        'subject=${Uri.encodeComponent('Account deletion request')}'
        '&body=${Uri.encodeComponent(
          'Please delete my account.\n\n'
          'Account email: $userEmail\n'
          'User ID: $userId',
        )}',
  );

  try {
    final launched = await launchUrl(uri);
    return launched
        ? AccountDeletionRequestResult.launched
        : AccountDeletionRequestResult.noMailApp;
  } catch (_) {
    return AccountDeletionRequestResult.failed;
  }
}
