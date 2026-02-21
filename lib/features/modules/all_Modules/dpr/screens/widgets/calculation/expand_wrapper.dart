import 'package:flutter/material.dart';

import 'cat_wrapper.dart';

class ExpandableMaterialCard extends StatelessWidget {
  final Widget child;
  final String? categoryId;
  final bool isEditMode;
  final ValueChanged<String>? onCategoryChanged;

  const ExpandableMaterialCard({
    super.key,
    required this.child,
    required this.categoryId,
    required this.isEditMode,
    this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
          child: child,
        ),

        MaterialCategoryWrapper(
          categoryId: categoryId,
          isEditMode: isEditMode,
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}
