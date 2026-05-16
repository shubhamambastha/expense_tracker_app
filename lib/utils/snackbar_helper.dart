import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for showing snackbars
class SnackbarHelper {
  SnackbarHelper._();

  static void showError(BuildContext context, Object error) {
    final message = error is AuthException ? error.message : error.toString();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
        ),
      );
  }

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
