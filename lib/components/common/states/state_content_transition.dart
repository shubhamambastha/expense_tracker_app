import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// Fades content in when loading completes — avoids jarring swaps.
///
/// Pair with skeleton loaders: show [child] when [isReady], otherwise
/// [placeholder] (typically a loading skeleton).
class StateContentTransition extends StatelessWidget {
  const StateContentTransition({
    super.key,
    required this.isReady,
    required this.child,
    this.placeholder,
    this.duration = AppDurations.short,
  });

  final bool isReady;
  final Widget child;
  final Widget? placeholder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppCurves.easeOutQuint,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: isReady
          ? KeyedSubtree(key: const ValueKey('ready'), child: child)
          : KeyedSubtree(
              key: const ValueKey('loading'),
              child: placeholder ?? const SizedBox.shrink(),
            ),
    );
  }
}
