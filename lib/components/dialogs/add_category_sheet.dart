import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/category_style.dart';
import '../../utils/snackbar_helper.dart';

/// Bottom sheet to create an expense or income category.
Future<bool?> showAddCategorySheet(
  BuildContext context, {
  required String title,
  required Future<void> Function(String name, String iconKey) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => _AddCategorySheet(
      title: title,
      onSave: onSave,
    ),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({
    required this.title,
    required this.onSave,
  });

  final String title;
  final Future<void> Function(String name, String iconKey) onSave;

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
      await widget.onSave(_nameController.text, _selectedIconKey);
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
                  widget.title,
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
