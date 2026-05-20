import 'package:flutter/material.dart';

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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(
                        'All categories',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Default categories cannot be removed.',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Theme.of(sheetContext)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: categories.isEmpty
                          ? Center(
                              child: Text(
                                'No categories yet. Tap Add on Profile.',
                                style:
                                    Theme.of(sheetContext).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: categories.length,
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'New category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Subscriptions',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Icon',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: CategoryIcons.pickerOptions.length,
                itemBuilder: (context, index) {
                  final option = CategoryIcons.pickerOptions[index];
                  final selected = option.key == _selectedIconKey;
                  final colorScheme = Theme.of(context).colorScheme;

                  return Material(
                    color: selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedIconKey = option.key);
                      },
                      child: Icon(
                        option.icon,
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withAlpha(36),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        category.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: category.isDefault
          ? Text(
              'Default',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: onDelete != null
          ? IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
            )
          : null,
    );
  }
}
