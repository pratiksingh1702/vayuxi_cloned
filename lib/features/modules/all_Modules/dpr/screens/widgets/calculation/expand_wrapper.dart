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
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: child,
          ),
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
