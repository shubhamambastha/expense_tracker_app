import 'package:flutter/material.dart';

/// Compact profile card with See all / Add actions (no inline list).
class ProfileManageCard extends StatelessWidget {
  const ProfileManageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
    required this.onAdd,
    this.seeAllLabel = 'See all',
    this.addLabel = 'Add',
  });

  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;
  final VoidCallback onAdd;
  final String seeAllLabel;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSeeAll,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.list_rounded, size: 17),
                    label: Text(seeAllLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(addLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
