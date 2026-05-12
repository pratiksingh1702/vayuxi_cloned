import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/structure_pm_entry_model.dart';

const _kBrown = Color(0xFF7B3F00);

class StructurePmResourceCard extends StatefulWidget {
  final StructurePmResourceRow row;
  final ValueChanged<double> onActualQtyChanged;
  final ValueChanged<String> onRemarksChanged;

  const StructurePmResourceCard({
    super.key,
    required this.row,
    required this.onActualQtyChanged,
    required this.onRemarksChanged,
  });

  @override
  State<StructurePmResourceCard> createState() =>
      _StructurePmResourceCardState();
}

class _StructurePmResourceCardState extends State<StructurePmResourceCard> {
  late TextEditingController _qtyController;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.row.actualQty > 0
          ? widget.row.actualQty.toStringAsFixed(
              widget.row.actualQty.truncateToDouble() == widget.row.actualQty
                  ? 0
                  : 2)
          : '',
    );
    _remarksController = TextEditingController(text: widget.row.remarks);
  }

  @override
  void didUpdateWidget(covariant StructurePmResourceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.actualQty != widget.row.actualQty) {
      final newText = widget.row.actualQty > 0
          ? widget.row.actualQty.toStringAsFixed(
              widget.row.actualQty.truncateToDouble() == widget.row.actualQty
                  ? 0
                  : 2)
          : '';
      if (_qtyController.text != newText) {
        _qtyController.text = newText;
      }
    }
    if (oldWidget.row.remarks != widget.row.remarks) {
      if (_remarksController.text != widget.row.remarks) {
        _remarksController.text = widget.row.remarks;
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gap = widget.row.gap;
    final gapColor = gap <= 0 ? Colors.green : (gap > 0 ? Colors.red : Colors.amber);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resource Name + UOM
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.row.resourceName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.row.uom,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Required / Actual / Gap row
          Row(
            children: [
              _InfoChip(
                label: 'Required',
                value: widget.row.requiredQty.toStringAsFixed(0),
                color: Colors.blue,
                cs: cs,
              ),
              const SizedBox(width: 8),
              // Actual Qty Input
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Actual',
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: cs.outlineVariant, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: _kBrown, width: 1.5),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0;
                      widget.onActualQtyChanged(parsed);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Gap',
                value: gap.toStringAsFixed(0),
                color: gapColor,
                cs: cs,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Remarks Input
          SizedBox(
            height: 44,
            child: TextField(
              controller: _remarksController,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Remarks...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withOpacity(0.6),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: cs.outlineVariant, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _kBrown, width: 1.5),
                ),
                isDense: true,
              ),
              onChanged: widget.onRemarksChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
