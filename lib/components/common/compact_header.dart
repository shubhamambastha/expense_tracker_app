import 'package:flutter/material.dart';

/// A compact header that preserves status bar spacing without a full AppBar.
class CompactHeader extends StatelessWidget {
  const CompactHeader({
    super.key,
    this.child,
    this.backgroundColor,
    this.elevation = 0,
  });

  final Widget? child;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: color,
      elevation: elevation,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
