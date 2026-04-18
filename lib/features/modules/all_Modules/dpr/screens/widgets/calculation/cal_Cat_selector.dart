import 'package:flutter/material.dart';

import 'calculation_Cat.dart';


class CalculationCategorySelector extends StatelessWidget {
  final String? selectedId;
  final String? expandedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggle;

  const CalculationCategorySelector({
    super.key,
    required this.selectedId,
    required this.expandedId,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Determines how price is calculated for this material',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),

        ...kCalculationCategories.map((category) {
          final isSelected = selectedId == category.id;
          final isExpanded = expandedId == category.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => onSelect(category.id),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                category.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          onTap: () => onToggle(category.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isExpanded ? "Show Less" : "Know More",
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 15)
                        .copyWith(bottom: 15),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.fullDetails.example,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
              ],
            ),
          );
        }),

        if (selectedId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Calculation category is required",
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
