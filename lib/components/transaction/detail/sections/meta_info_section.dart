import 'package:flutter/material.dart';

import '../../../../models/transaction_filters.dart';
import '../transaction_detail_view_data.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_section_card.dart';

class MetaInfoSection extends StatelessWidget {
  const MetaInfoSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'Details',
      child: Column(
        children: [
          DetailInfoRow(
            icon: Icons.storefront_outlined,
            label: data.tx.isIncome ? 'Source' : 'Merchant',
            value: data.metaMerchantLabel,
          ),
          DetailInfoRow(
            icon: Icons.label_outline_rounded,
            label: 'Category',
            value: data.tx.category ?? '—',
          ),
          DetailInfoRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: data.displayType.label,
          ),
        ],
      ),
    );
  }
}
