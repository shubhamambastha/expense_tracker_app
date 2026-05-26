import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'sections/account_payment_section.dart';
import 'sections/actions_section.dart';
import 'sections/activity_metadata_section.dart';
import 'sections/hero_amount_section.dart';
import 'sections/meta_info_section.dart';
import 'sections/notes_tags_section.dart';
import 'sections/recurring_details_section.dart';
import 'transaction_detail_view_data.dart';

/// Scrollable body for the transaction detail bottom sheet.
class TransactionDetailContent extends StatelessWidget {
  const TransactionDetailContent({
    super.key,
    required this.data,
    required this.scrollController,
    this.onEdit,
    this.onDuplicate,
    this.onConvertToRecurring,
    this.onDelete,
    this.extensionSections = const [],
  });

  final TransactionDetailViewData data;
  final ScrollController scrollController;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onConvertToRecurring;
  final VoidCallback? onDelete;

  /// Future slots for receipts, AI insights, split transactions, etc.
  final List<Widget> extensionSections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        HeroAmountSection(data: data),
        const SizedBox(height: AppSpacing.xl),
        MetaInfoSection(data: data),
        const SizedBox(height: AppSpacing.lg),
        AccountPaymentSection(data: data),
        if (data.tx.isRecurring) ...[
          const SizedBox(height: AppSpacing.lg),
          RecurringDetailsSection(data: data),
        ],
        if (data.showNotesSection) ...[
          const SizedBox(height: AppSpacing.lg),
          NotesTagsSection(data: data),
        ],
        ...extensionSections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: section,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ActivityMetadataSection(data: data),
        const SizedBox(height: AppSpacing.xl),
        ActionsSection(
          isRecurring: data.tx.isRecurring,
          onEdit: onEdit,
          onDuplicate: onDuplicate,
          onConvertToRecurring: onConvertToRecurring,
          onDelete: onDelete,
        ),
      ],
    );
  }
}
