import 'package:flutter/material.dart';
import '../isar/assembly_card_isar.dart';

class AssemblyCardWidget extends StatefulWidget {
  final AssemblyCardIsar card;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(String mark, double qty)? onUpdate;

  const AssemblyCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onDelete,
    this.onUpdate,
  });

  @override
  State<AssemblyCardWidget> createState() => _AssemblyCardWidgetState();
}

class _AssemblyCardWidgetState extends State<AssemblyCardWidget> {
  late TextEditingController _markController;
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _markController = TextEditingController(text: widget.card.assemblyMark);
    _qtyController =
        TextEditingController(text: widget.card.quantity.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _markController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const blueFill = Color(0xFFD0EAFD);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Header Row (Matches Header in PipingCard)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.card.description.isNotEmpty
                        ? widget.card.description
                        : "No Type Description",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Optional: Action column or delete button
              ],
            ),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                // LEFT COLUMN: Image & Actions
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSmartImage(cs),
                        const SizedBox(height: 12),
                        // Action row (Edit, Copy, Delete)
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionIcon(Icons.edit_rounded,
                                  cs.primary, () => widget.onTap?.call()),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionIcon(
                                  Icons.delete_outline_rounded,
                                  cs.error,
                                  () => widget.onDelete?.call()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT COLUMN: Fields
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBlueField(
                          label: "Mark",
                          controller: _markController,
                          fillColor: blueFill,
                          onChanged: (v) => _triggerUpdate(),
                        ),
                        const SizedBox(height: 12),
                        _buildMainField(
                          label: "Quantity",
                          controller: _qtyController,
                          fillColor: cs.surfaceContainerHighest,
                          onChanged: (v) => _triggerUpdate(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("Available",
                    widget.card.availableQty.toStringAsFixed(0), cs.primary),
                _buildStat(
                    "Used", widget.card.usedQty.toStringAsFixed(0), cs.error),
                _buildStat("Remaining",
                    widget.card.remainingQty.toStringAsFixed(0), cs.secondary),
              ],
            ),
          ),
          // Dimensions wrap
          if (widget.card.length != null ||
              widget.card.width != null ||
              widget.card.height != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (widget.card.length != null)
                    _buildDimChip(context, "L", "${widget.card.length}m"),
                  if (widget.card.width != null)
                    _buildDimChip(context, "W", "${widget.card.width}m"),
                  if (widget.card.height != null)
                    _buildDimChip(context, "H", "${widget.card.height}m"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _triggerUpdate() {
    if (widget.onUpdate != null) {
      widget.onUpdate!(
        _markController.text,
        double.tryParse(_qtyController.text) ?? 0,
      );
    }
  }

  Widget _buildSmartImage(ColorScheme cs) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Icon(Icons.image_not_supported, color: cs.onSurfaceVariant, size: 32),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildBlueField({
    required String label,
    required TextEditingController controller,
    required Color fillColor,
    Function(String)? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 23,
          width: 50,
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.normal,
                color: Colors.black),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainField({
    required String label,
    required TextEditingController controller,
    required Color fillColor,
    Function(String)? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 60,
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.black54)),
      ],
    );
  }

  Widget _buildDimChip(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
            fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }
}
