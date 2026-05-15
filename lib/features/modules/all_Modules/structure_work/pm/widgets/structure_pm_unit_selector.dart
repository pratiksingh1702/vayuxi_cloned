import 'package:flutter/material.dart';
import '../models/structure_pm_entry_model.dart';

const _kBrown = Color(0xFF7B3F00);

class StructurePmUnitSelector extends StatelessWidget {
  final List<StructurePmUnitSummary> units;
  final String? selectedUnitCode;
  final ValueChanged<String?> onUnitSelected;

  const StructurePmUnitSelector({
    super.key,
    required this.units,
    required this.selectedUnitCode,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _UnitChip(
            label: 'All',
            isSelected: selectedUnitCode == null,
            onTap: () => onUnitSelected(null),
            cs: cs,
          ),
          ...units.map((unit) => _UnitChip(
                label: unit.unitName.isNotEmpty ? unit.unitName : unit.unitCode,
                subtitle:
                    '${unit.actualQty.toStringAsFixed(0)}/${unit.requiredQty.toStringAsFixed(0)}',
                isSelected: selectedUnitCode == unit.unitCode,
                onTap: () => onUnitSelected(unit.unitCode),
                cs: cs,
              )),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _UnitChip({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _kBrown : cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _kBrown : cs.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kBrown.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : cs.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
