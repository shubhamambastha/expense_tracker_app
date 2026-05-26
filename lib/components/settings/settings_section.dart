import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// A labelled settings group: small uppercase header above a single
/// rounded card containing a column of rows separated by hairline dividers.
///
/// Tiles passed in [children] are expected to be `SettingsTile`,
/// `SettingsSwitchTile`, `SettingsInfoTile`, or any other row widget that
/// renders its own internal padding.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footnote,
  });

  final String title;
  final List<Widget> children;

  /// Optional small caption rendered under the card (e.g. nuance / hint).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _interleaveDividers(children),
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(footnote!, style: AppTextStyles.caption),
          ),
        ],
      ],
    );
  }

  List<Widget> _interleaveDividers(List<Widget> rows) {
    if (rows.length <= 1) return rows;
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i != rows.length - 1) {
        out.add(const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border,
        ));
      }
    }
    return out;
  }
}
