import 'package:flutter/material.dart';

import '../../../components/settings/expense_categories_section.dart';
import '../../../components/settings/income_categories_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../config/design_tokens.dart';

/// Manage expense and income category labels used in transactions.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSubpageScaffold(
      title: 'Categories',
      subtitle:
          'Customise the labels shown when you log expenses and income. '
          'Default categories cannot be deleted.',
      children: [
        ExpenseCategoriesSection(),
        SizedBox(height: AppSpacing.md),
        IncomeCategoriesSection(),
      ],
    );
  }
}
