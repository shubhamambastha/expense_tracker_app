import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/expense_category.dart';
import '../../services/category_catalog.dart';
import '../../utils/category_style.dart';
import '../../utils/snackbar_helper.dart';
import 'profile_manage_card.dart';

/// Profile entry for expense categories (compact; list in See all sheet).
class CategoriesSettingsSection extends StatelessWidget {
  const CategoriesSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CategoryCatalog.instance,
      builder: (context, _) {
        final catalog = CategoryCatalog.instance;
        final count = catalog.categories.length;
        final subtitle = count == 0
            ? 'No categories yet'
            : count == 1
                ? '1 category'
                : '$count categories';

        return ProfileManageCard(
          title: 'Categories',
          subtitle: subtitle,
          seeAllLabel: 'See all',
          addLabel: 'Add',
          onSeeAll: () => _openAllCategoriesSheet(context),
          onAdd: () => _openAddCategorySheet(context),
        );
      },
    );
  }

  Future<void> _openAddCategorySheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => const _AddCategorySheet(),
    );

    if (added == true && context.mounted) {
      SnackbarHelper.showSuccess(context, 'Category added');
    }
  }

  Future<void> _openAllCategoriesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

        return ListenableBuilder(
          listenable: CategoryCatalog.instance,
          builder: (context, _) {
            final categories = CategoryCatalog.instance.categories;

            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xs,
                        AppSpacing.xl,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        'All categories',
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Text(
                        'Default categories cannot be removed.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: categories.isEmpty
                          ? Center(
                              child: Text(
                                'No categories yet. Tap Add on Profile.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _CategoryRow(
                                  category: category,
                                  color: CategoryCatalog.instance
                                      .colorForName(category.name),
                                  icon: CategoryCatalog.instance
                                      .iconForName(category.name),
                                  onDelete: category.isDefault
                                      ? null
                                      : () => _confirmDelete(
                                            context,
                                            sheetContext,
                                            category,
                                          ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BuildContext sheetContext,
    ExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
          'Remove "${category.name}"? Expenses already using it will keep the label.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await CategoryCatalog.instance.deleteCategory(category);
      if (sheetContext.mounted && CategoryCatalog.instance.categories.isEmpty) {
        Navigator.of(sheetContext).pop();
      }
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Category removed');
      }
    } catch (error) {
      if (context.mounted) {
        SnackbarHelper.showMessage(context, error.toString());
      }
    }
  }
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late final TextEditingController _nameController;
  String _selectedIconKey = CategoryIcons.pickerOptions.first.key;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await CategoryCatalog.instance.addCategory(
        name: _nameController.text,
        iconKey: _selectedIconKey,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarHelper.showMessage(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(
                  'New category',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Subscriptions',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: Text(
                  'Icon',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemCount: CategoryIcons.pickerOptions.length,
                itemBuilder: (context, index) {
                  final option = CategoryIcons.pickerOptions[index];
                  final selected = option.key == _selectedIconKey;

                  return Material(
                    color: selected
                        ? AppColors.primary.withAlpha(40)
                        : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedIconKey = option.key);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withAlpha(110)
                                : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          option.icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF003328),
                          ),
                        )
                      : const Text('Save category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.color,
    required this.icon,
    this.onDelete,
  });

  final ExpenseCategory category;
  final Color color;
  final IconData icon;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          category.name,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: category.isDefault
            ? Text('Default', style: AppTextStyles.caption)
            : null,
        trailing: onDelete != null
            ? IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              )
            : null,
      ),
    );
  }
}
