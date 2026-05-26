import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Row for a category in the "See all" bottom sheet.
class CategoryListRow extends StatelessWidget {
  const CategoryListRow({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
    this.onDelete,
  });

  final String name;
  final Color color;
  final IconData icon;
  final bool isDefault;
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
          name,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: isDefault
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
