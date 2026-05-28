import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/design_tokens.dart';

/// Helper for showing premium top-anchored snackbars.
class SnackbarHelper {
  SnackbarHelper._();

  static OverlayEntry? _activeUndoEntry;
  static Timer? _activeUndoTimer;
  static AnimationController? _activeUndoController;

  static void showError(BuildContext context, Object error) {
    final message = error is AuthException ? error.message : error.toString();
    _showTopSnackBar(
      context,
      message,
      accent: AppColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      accent: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      accent: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showMessage(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      accent: AppColors.secondary,
      icon: Icons.info_outline_rounded,
    );
  }

  /// Success snackbar with an Undo action. Stays visible for [duration],
  /// then auto-dismisses. Replaces any previously visible undo snackbar.
  static void showWithUndo(
    BuildContext context, {
    required String message,
    required String undoLabel,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
    Color accent = AppColors.success,
  }) {
    _dismissActiveUndo();

    final overlayState = Overlay.of(context);
    final tickerProvider = _SnackbarTickerProvider();

    final controller = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 280),
    );
    _activeUndoController = controller;

    final slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).chain(CurveTween(curve: AppCurves.spring)).animate(controller);

    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    void dismiss({bool animate = true}) {
      if (_activeUndoEntry == null) return;

      _activeUndoTimer?.cancel();
      _activeUndoTimer = null;

      if (!animate) {
        _dismissActiveUndo();
        return;
      }

      final activeController = _activeUndoController;
      if (activeController == null) {
        _dismissActiveUndo();
        return;
      }

      activeController.reverse().whenComplete(_dismissActiveUndo);
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: MediaQuery.of(overlayContext).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: AppRadii.chipRadius,
                    border: Border.all(color: accent.withAlpha(80), width: 1),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(40),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          dismiss(animate: false);
                          onUndo();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          undoLabel,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeUndoEntry = entry;
    overlayState.insert(entry);
    controller.forward();

    _activeUndoTimer = Timer(duration, () => dismiss());
  }

  static void _dismissActiveUndo() {
    _activeUndoTimer?.cancel();
    _activeUndoTimer = null;
    _activeUndoEntry?.remove();
    _activeUndoEntry = null;
    _activeUndoController?.dispose();
    _activeUndoController = null;
  }

  static void _showTopSnackBar(
    BuildContext context,
    String message, {
    required Color accent,
    required IconData icon,
  }) {
    final overlayState = Overlay.of(context);

    final tickerProvider = _SnackbarTickerProvider();
    final controller = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 2400),
    );

    final animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: AppCurves.spring)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 64,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.4))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
    ]).animate(controller);

    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 64),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 18),
    ]).animate(controller);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: animation,
              child: FadeTransition(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: AppRadii.chipRadius,
                    border: Border.all(color: accent.withAlpha(80), width: 1),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(40),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, color: accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
