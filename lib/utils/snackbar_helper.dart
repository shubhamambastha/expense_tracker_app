import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for showing snackbars
class SnackbarHelper {
  SnackbarHelper._();

  static void showError(BuildContext context, Object error) {
    final message = error is AuthException ? error.message : error.toString();
    _showTopSnackBar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
    );
  }

  static void showMessage(BuildContext context, String message) {
    _showTopSnackBar(context, message);
  }

  static void _showTopSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    final overlayState = Overlay.of(context);

    final tickerProvider = _SnackbarTickerProvider();
    final controller = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 2200),
    );

    final animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-1.2, 0))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(controller);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: animation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);

    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }
}

class _SnackbarTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
