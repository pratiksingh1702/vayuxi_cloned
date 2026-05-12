import 'package:flutter/material.dart';
import '../models/structure_pm_entry_model.dart';
import 'structure_pm_resource_card.dart';

const _kBrown = Color(0xFF7B3F00);

class StructurePmCategorySection extends StatelessWidget {
  final String categoryName;
  final List<StructurePmResourceRow> rows;
  final ValueChanged<MapEntry<String, double>> onActualQtyChanged;
  final ValueChanged<MapEntry<String, String>> onRemarksChanged;

  const StructurePmCategorySection({
    super.key,
    required this.categoryName,
    required this.rows,
    required this.onActualQtyChanged,
    required this.onRemarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sorted = List<StructurePmResourceRow>.from(rows)
      ..sort((a, b) {
        int cmp = a.unitCode.compareTo(b.unitCode);
        if (cmp != 0) return cmp;
        cmp = a.templateRowNo.compareTo(b.templateRowNo);
        if (cmp != 0) return cmp;
        cmp = a.sortOrder.compareTo(b.sortOrder);
        if (cmp != 0) return cmp;
        return a.resourceName
            .toLowerCase()
            .compareTo(b.resourceName.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kBrown.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBrown.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.category_rounded, size: 16, color: _kBrown),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kBrown.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sorted.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Resource Cards
        ...sorted.map((row) => StructurePmResourceCard(
              row: row,
              onActualQtyChanged: (qty) =>
                  onActualQtyChanged(MapEntry(row.id, qty)),
              onRemarksChanged: (remarks) =>
                  onRemarksChanged(MapEntry(row.id, remarks)),
            )),
      ],
    );
  }
}
