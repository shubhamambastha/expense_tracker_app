import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import 'detail/transaction_detail_content.dart';
import 'detail/transaction_detail_view_data.dart';

Future<void> showTransactionDetailSheet({
  required BuildContext context,
  required Transaction transaction,
  required Account? account,
  Account? transferToAccount,
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onConvertToRecurring,
  VoidCallback? onDelete,
}) {
  final data = TransactionDetailViewData.from(
    transaction: transaction,
    account: account,
    transferToAccount: transferToAccount,
  );

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SafeArea(
            top: false,
            child: TransactionDetailContent(
              data: data,
              scrollController: scrollController,
              onEdit: onEdit == null
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onEdit();
                    },
              onDuplicate: onDuplicate == null
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onDuplicate();
                    },
              onConvertToRecurring: onConvertToRecurring == null
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onConvertToRecurring();
                    },
              onDelete: onDelete == null
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onDelete();
                    },
            ),
          );
        },
      );
    },
  );
}
