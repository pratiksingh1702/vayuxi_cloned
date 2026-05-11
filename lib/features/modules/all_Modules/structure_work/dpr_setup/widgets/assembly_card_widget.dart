import 'package:flutter/material.dart';
import '../isar/assembly_card_isar.dart';

class AssemblyCardWidget extends StatefulWidget {
  final AssemblyCardIsar card;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(String mark, double qty)? onUpdate;
  final VoidCallback? onCopy;
  final VoidCallback? onRemark;
  final bool readOnly;
  final bool allowMarkEdit;
  final bool allowQtyEdit;

  const AssemblyCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onDelete,
    this.onUpdate,
    this.onCopy,
    this.onRemark,
    this.readOnly = false,
    this.allowMarkEdit = true,
    this.allowQtyEdit = true,
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
    // Default to 1 if quantity is 0 and it's a new card (not readOnly)
    double initialQty = widget.card.quantity;
    if (initialQty == 0 && widget.allowQtyEdit && !widget.readOnly) {
      initialQty = 1;
    }
    _qtyController =
        TextEditingController(text: initialQty.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant AssemblyCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.assemblyMark != widget.card.assemblyMark) {
      _markController.text = widget.card.assemblyMark;
    }
    if (oldWidget.card.quantity != widget.card.quantity) {
      _qtyController.text = widget.card.quantity.toStringAsFixed(0);
    }
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
                if (widget.onRemark != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onRemark,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 78,
                        maxWidth: 110,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withOpacity(0.7),
                        border: Border.all(color: cs.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.card.remarks?.isNotEmpty == true
                            ? widget.card.remarks!
                            : 'Remark',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
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
                              child: _buildActionIcon(Icons.copy_rounded,
                                  Colors.green, () => widget.onCopy?.call()),
                            ),
                            if (!widget.readOnly) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionIcon(
                                    Icons.delete_outline_rounded,
                                    cs.error,
                                    () => widget.onDelete?.call()),
                              ),
                            ],
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
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _blueBox(
                                label: "Mark No.",
                                controller: _markController,
                                enabled: widget.allowMarkEdit && !widget.readOnly,
                                hintText: widget.card.assemblyMark.isEmpty
                                    ? "Add mark"
                                    : "Enter mark",
                                onChanged: (v) => _triggerUpdate(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _blueBox(
                                label: "Qty",
                                controller: _qtyController,
                                enabled: widget.allowQtyEdit && !widget.readOnly,
                                isNumber: true,
                                onChanged: (v) => _triggerUpdate(),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildMainField(
                          label: "Weight (kg)",
                          value: (widget.card.netWeightPerUnit ?? 0)
                              .toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _triggerUpdate() {
    if (widget.onUpdate != null) {
      // Use normalized mark for the lookup/update callback
      final String markForLookup = _markController.text.trim().toLowerCase();
      
      double enteredQty = double.tryParse(_qtyController.text) ?? 0;

      // Validate quantity against BOQ available/remaining quantity
      final double maxAllowed = widget.card.remainingQty > 0
          ? widget.card.remainingQty
          : (widget.card.availableQty > 0 ? widget.card.availableQty : 0.0);

      if (maxAllowed > 0 && enteredQty > maxAllowed) {
        // Show error and clamp to max allowed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Qty cannot exceed ${maxAllowed.toStringAsFixed(0)} for ${widget.card.assemblyMark}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        enteredQty = maxAllowed;
        _qtyController.text = enteredQty.toStringAsFixed(0);
        _qtyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _qtyController.text.length),
        );
      }

      widget.onUpdate!(
        markForLookup,
        enteredQty,
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
        image: const DecorationImage(
          image: AssetImage('assets/images/structure_default.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
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

  Widget _blueBox({
    required String label,
    required TextEditingController controller,
    String hintText = "",
    bool isNumber = false,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    const blueFill = Color(0xFFD0EAFD);
    const darkBlueFill = Color(0xFF1E3A5F);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 26,
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            enabled: enabled,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              filled: true,
              fillColor: enabled ? (isDark ? darkBlueFill : blueFill) : cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(
                fontSize: 9,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _buildMainField({
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
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
