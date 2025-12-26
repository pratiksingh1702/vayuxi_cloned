import 'package:flutter/material.dart';

class DynamicItemCard extends StatefulWidget {
  final String quantity;
  final String size;
  final String length;
  final String floor;
  final String moc;
  final String? image;
  final String sizeLabel;
  final String lengthLabel;
  final String sizePlaceholder;
  final String lengthPlaceholder;
  final Function(String) onQtyChanged;
  final Function(String) onSizeChanged;
  final Function(String) onLengthChanged;
  final Function(String) onFloorChanged;
  final Function(String) onMocChanged;
  final VoidCallback? onDelete;
  final VoidCallback onRemark;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy; // NEW: Copy callback
  final VoidCallback? onAdd;
  final bool isEditable;

  const DynamicItemCard({
    required this.quantity,
    required this.size,
    required this.length,
    required this.floor,
    required this.moc,
    this.image,
    required this.sizeLabel,
    required this.lengthLabel,
    required this.sizePlaceholder,
    required this.lengthPlaceholder,
    required this.onQtyChanged,
    required this.onSizeChanged,
    required this.onLengthChanged,
    required this.onFloorChanged,
    required this.onMocChanged,
    this.onDelete,
    required this.onRemark,
    this.onEdit,
    this.onCopy, // NEW: Copy callback parameter
    this.onAdd,
    required this.isEditable,
    super.key,
  });

  @override
  State<DynamicItemCard> createState() => _DynamicItemCardState();
}

class _DynamicItemCardState extends State<DynamicItemCard>
    with AutomaticKeepAliveClientMixin {

  // Controllers to preserve state
  late TextEditingController _quantityController;
  late TextEditingController _sizeController;
  late TextEditingController _lengthController;
  late TextEditingController _floorController;
  late TextEditingController _mocController;
  late TextEditingController _uomController;
  late FocusNode _uomFocusNode;

  @override
  bool get wantKeepAlive => true; // This preserves state when widget is hidden

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _quantityController = TextEditingController(text: widget.quantity);
    _sizeController = TextEditingController(text: widget.size);
    _lengthController = TextEditingController(text: widget.length);
    _floorController = TextEditingController(text: widget.floor);
    _mocController = TextEditingController(text: widget.moc);
    _uomController = TextEditingController(text: "");

    _uomFocusNode = FocusNode();

    // Listen for changes and propagate to parent
    _quantityController.addListener(_onQuantityChanged);
    _sizeController.addListener(_onSizeChanged);
    _lengthController.addListener(_onLengthChanged);
    _floorController.addListener(_onFloorChanged);
    _mocController.addListener(_onMocChanged);
  }

  @override
  void didUpdateWidget(DynamicItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers when parent provides new values
    if (widget.quantity != oldWidget.quantity &&
        widget.quantity != _quantityController.text) {
      _quantityController.text = widget.quantity;
    }
    if (widget.size != oldWidget.size &&
        widget.size != _sizeController.text) {
      _sizeController.text = widget.size;
    }
    if (widget.length != oldWidget.length &&
        widget.length != _lengthController.text) {
      _lengthController.text = widget.length;
    }
    if (widget.floor != oldWidget.floor &&
        widget.floor != _floorController.text) {
      _floorController.text = widget.floor;
    }
    if (widget.moc != oldWidget.moc &&
        widget.moc != _mocController.text) {
      _mocController.text = widget.moc;
    }
  }

  void _onQuantityChanged() {
    if (_quantityController.text != widget.quantity) {
      widget.onQtyChanged(_quantityController.text);
    }
  }

  void _onSizeChanged() {
    if (_sizeController.text != widget.size) {
      widget.onSizeChanged(_sizeController.text);
    }
  }

  void _onLengthChanged() {
    if (_lengthController.text != widget.length) {
      widget.onLengthChanged(_lengthController.text);
    }
  }

  void _onFloorChanged() {
    if (_floorController.text != widget.floor) {
      widget.onFloorChanged(_floorController.text);
    }
  }

  void _onMocChanged() {
    if (_mocController.text != widget.moc) {
      widget.onMocChanged(_mocController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      onTap: () {
        if (widget.isEditable) {
          _uomFocusNode.requestFocus();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.lengthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: widget.onRemark,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0EAFD),
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Remark",
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // ───────── LEFT COLUMN (50% width) - NAME & IMAGE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // ✅ BOUNDED IMAGE (NO Expanded)
                        if (widget.image != null)
                          SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: Image.asset(
                              widget.image!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print(error);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            ),
                          ),

                        if (widget.isEditable &&
                            (widget.onAdd != null || widget.onEdit != null || widget.onDelete != null || widget.onCopy != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                // Edit button
                                if (widget.onEdit != null) ...[
                                  Expanded(
                                    child: IconButton(
                                      onPressed: widget.onEdit,
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: Colors.blue,
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(6),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: Colors.blue, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Copy button
                                if (widget.onCopy != null) ...[
                                  Expanded(
                                    child: IconButton(
                                      onPressed: widget.onCopy,
                                      icon: const Icon(Icons.copy, size: 18),
                                      color: Colors.green,
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(6),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: Colors.green, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Delete button
                                if (widget.onDelete != null)
                                  Expanded(
                                    child: IconButton(
                                      onPressed: widget.onDelete,
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: Colors.red,
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(6),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: Colors.red, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],

                    ),

                  ),
                ),
                // ───────── RIGHT COLUMN (50% width) - INPUT FIELDS
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    children: [
                      // 2x2 Grid of Blue Input Fields
                      Row(
                        children: [
                          Expanded(child: _blueBox("Floor", _floorController)),
                          const SizedBox(width: 8),
                          Expanded(child: _blueBox("Size", _sizeController)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _blueBox("MOC", _mocController)),
                          const SizedBox(width: 8),
                          Expanded(child: _blueBox("Qty", _quantityController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Length Field with Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _blueBox("UOM", _uomController, isUOM: true, focusNode: _uomFocusNode),
                        ],
                      ),
                      // Action Buttons - Only show when editable

                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────── Blue Input Field with White Hint Text
  Widget _blueBox(String label, TextEditingController controller, {bool isUOM = false, FocusNode? focusNode}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            isUOM ? "$label ( ${widget.lengthPlaceholder} )" : label,
            style: TextStyle(
              fontSize: isUOM ? 14 : 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        // Input field
        SizedBox(
          height: isUOM ? 60 : 23,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isUOM ? 14 : 8,
              fontWeight: isUOM ? FontWeight.w500 : FontWeight.normal,
              color: isUOM ? Colors.black : (widget.lengthPlaceholder == 'UOM' ? Colors.grey[600] : Colors.black),
            ),
            enabled: widget.isEditable,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: isUOM ? 12 : 4,
                horizontal: isUOM ? 8 : 2,
              ),
              filled: true,
              fillColor: isUOM
                  ? Colors.transparent
                  : (widget.isEditable ? const Color(0xFFD0EAFD) : Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isUOM ? 8 : 4),
                borderSide: BorderSide(
                  color: isUOM ? Colors.grey[300]! : Colors.transparent,
                  width: isUOM ? 1 : 0,
                ),
              ),
              hintStyle: TextStyle(
                fontSize: isUOM ? 13 : 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _quantityController.dispose();
    _sizeController.dispose();
    _lengthController.dispose();
    _floorController.dispose();
    _mocController.dispose();
    _uomController.dispose();
    _uomFocusNode.dispose();
    super.dispose();
  }
}