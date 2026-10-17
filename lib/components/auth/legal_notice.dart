import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_info.dart';
import '../../config/design_tokens.dart';

/// "By continuing, you agree to…" line with tappable Terms / Privacy links.
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.caption,
        children: [
          const TextSpan(text: "By continuing, you agree to Jebbo's "),
          _link('Terms of Use', AppInfo.termsUrl),
          const TextSpan(text: ' and '),
          _link('Privacy Policy', AppInfo.privacyUrl),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // WidgetSpan + GestureDetector instead of a TapGestureRecognizer, which
  // would need a StatefulWidget just to dispose it.
  InlineSpan _link(String label, String url) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Semantics(
          link: true,
          child: GestureDetector(
            onTap: () => openLegalUrl(url),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

/// Opens a legal page in the external browser.
Future<void> openLegalUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
