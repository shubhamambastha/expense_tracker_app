import 'package:flutter/material.dart';

import '../../utils/subscription_catalog.dart';

/// Solid brand-color square with the subscription's first letter — the
/// shared "brand mark" used everywhere a subscription's icon renders
/// (transaction list, recurring cards, analytics, home dashboard, and the
/// picker sheet itself). Placeholder mark, not a traced logo.
///
/// No asset I/O, so no failure mode to guard: this always renders.
class SubscriptionBadge extends StatelessWidget {
  const SubscriptionBadge({super.key, required this.entry, this.size = 40});

  final SubscriptionEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: entry.color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        entry.name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
  }
}
