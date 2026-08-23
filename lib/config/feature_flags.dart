import '../models/transaction_draft.dart';

/// Compile-time feature toggles. Flip flags here to show or hide UI entry points.
class FeatureFlags {
  FeatureFlags._();

  /// When false, transfer is hidden from quick actions, type picker, and filters.
  /// Existing transfer transactions still display and can be edited.
  static const bool transferVisible = false;

  /// When false, "Continue as guest" is hidden from the login screen and the
  /// guest data path in [SupabaseService] is never exercised. One-line kill
  /// switch, not a gradual rollout gate.
  static const bool guestModeEnabled = true;

  static List<TransactionKind> get selectableTransactionKinds {
    if (transferVisible) return TransactionKind.values;
    return const [TransactionKind.expense, TransactionKind.income];
  }

  static TransactionKind normalizeKind(TransactionKind kind) {
    if (!transferVisible && kind == TransactionKind.transfer) {
      return TransactionKind.expense;
    }
    return kind;
  }

  static bool showTransferInTypeSelector(TransactionKind current) =>
      transferVisible || current == TransactionKind.transfer;
}
