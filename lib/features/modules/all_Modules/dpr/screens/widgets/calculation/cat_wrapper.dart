import 'package:flutter/material.dart';

import 'calculation_Cat.dart';

class MaterialCategoryWrapper extends StatefulWidget {
  final String? categoryId;
  final bool isEditMode;
  final Function(String)? onChanged;

  const MaterialCategoryWrapper({
    super.key,
    required this.categoryId,
    this.isEditMode = false,
    this.onChanged,
  });

  @override
  State<MaterialCategoryWrapper> createState() =>
      _MaterialCategoryWrapperState();
}

class _MaterialCategoryWrapperState extends State<MaterialCategoryWrapper> {
  String? expandedId;

  @override
  Widget build(BuildContext context) {
    /// VIEW MODE → old behavior
    if (!widget.isEditMode) {
      if (widget.categoryId == null || widget.categoryId!.isEmpty) {
        return const SizedBox();
      }

      final category = kCalculationCategories
          .where((e) => e.id == widget.categoryId)
          .firstOrNull;

      if (category == null) return const SizedBox();

      return _buildTile(category, selected: true);
    }

    /// EDIT MODE → show all
    return Column(
      children: kCalculationCategories.map((cat) {
        final isSelected = cat.id == widget.categoryId;
        return _buildTile(cat, selected: isSelected);
      }).toList(),
    );
  }

  Widget _buildTile(CalculationCategory category, {required bool selected}) {
    final colorScheme = Theme.of(context).colorScheme;
    final expanded = expandedId == category.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.isEditMode) {
                widget.onChanged?.call(category.id);
              }
              setState(() {
                expandedId = expanded ? null : category.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  if (widget.isEditMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: colorScheme.primary,
                      ),
                    ),
                  Icon(
                    Icons.calculate,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Category ${category.id} — ${category.label}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    expanded ? "Hide" : "View",
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (expanded)
            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Formula",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant)),
                  Text(category.fullDetails.formula,
                      style: TextStyle(color: colorScheme.primary)),
                  const SizedBox(height: 6),
                  ...category.fullDetails.howItWorks.map(
                    (e) => Text(
                      "• $e",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
