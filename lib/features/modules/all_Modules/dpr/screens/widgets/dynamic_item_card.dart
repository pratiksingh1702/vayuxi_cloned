import '../../../../../../core/utlis/widgets/shimmer.dart';
import 'package:flutter/material.dart';

import '../../models/rate_file_models.dart';

class DynamicItemCard extends StatefulWidget {
  final String quantity;
  final String size;
  final String length;
  final String floor;
  final String floorlabel;
  final String moc;
  final String image;
  final String sizeLabel;
  final String lengthLabel;
  final String? remark;

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
  final VoidCallback? onCopy;
  final VoidCallback? onAdd;
  final bool isEditable;

  const DynamicItemCard({
    required this.quantity,

    required this.size,

 this.floorlabel='Floor',
    required this.length,
    required this.floor,
    required this.moc,
    required this.image,
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
    this.remark,
    required this.onRemark,
    this.onEdit,
    this.onCopy,
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
  late TextEditingController _lengthController; // ✅ Using lengthController for length/UOM
  late TextEditingController _floorController;
  late TextEditingController _mocController;
  bool _isEditingLength = false;

  late FocusNode _lengthFocusNode; // ✅ Renamed from _uomFocusNode

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _quantityController = TextEditingController(text: widget.quantity);
    _sizeController = TextEditingController(text: widget.size);
    _lengthController = TextEditingController(text: widget.length); // ✅ Initialize with length
    _floorController = TextEditingController(text: widget.floor);
    _mocController = TextEditingController(text: widget.moc);

    _lengthFocusNode = FocusNode();

    _lengthFocusNode.addListener(() {
      _isEditingLength = _lengthFocusNode.hasFocus;

      // OPTIONAL: clean formatting on blur
      if (!_lengthFocusNode.hasFocus) {
        final val = double.tryParse(_lengthController.text);
        if (val != null && val % 1 == 0) {
          _lengthController.text = val.toInt().toString();
        }
      }
    });


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
    if (!_isEditingLength &&
        widget.length != oldWidget.length &&
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
    print('🔵 Quantity changed: ${_quantityController.text}');
    if (_quantityController.text != widget.quantity) {
      widget.onQtyChanged(_quantityController.text);
    }
  }

  void _onSizeChanged() {
    print('🔵 Size changed: ${_sizeController.text}');
    if (_sizeController.text != widget.size) {
      widget.onSizeChanged(_sizeController.text);
    }
  }

  void _onLengthChanged() {
    print('🔵 Length changed: ${_lengthController.text}');
    if (_lengthController.text != widget.length) {
      widget.onLengthChanged(_lengthController.text);
    }
  }

  void _onFloorChanged() {
    print('🔵 Floor changed: ${_floorController.text}');
    if (_floorController.text != widget.floor) {
      widget.onFloorChanged(_floorController.text);
    }
  }

  void _onMocChanged() {
    print('🔵 MOC changed: ${_mocController.text}');
    if (_mocController.text != widget.moc) {
      widget.onMocChanged(_mocController.text);
    }
  }

  Widget buildSmartImage({
    required String? image,
    double height = 100,
    double width = double.infinity,
    BoxFit fit = BoxFit.contain,
  }) {
    if (image == null || image.isEmpty) {
      print("emptyyyyyyyyyyyyyyyyyyyyyyyy");
      return _imagePlaceholder(height, width);
    }
    final isAsset = image.startsWith('assets/');
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');

    print('🖼️ Image URL: $image');
    print('🌐 Is Network: $isNetwork');
    print('📦 Is Asset: $isAsset');


    return SizedBox(
      height: height,
      width: width,
      child: isNetwork
          ? Image.network(
        image,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _imagePlaceholder(height, width),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ShimmerImage(
            height: height,
            width: width,
            borderRadius: 8,
          );
        },
      )
          : Image.asset(
        image,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _imagePlaceholder(height, width),
      ),
    );
  }

  Widget _imagePlaceholder(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: () {
        if (widget.isEditable) {
          _lengthFocusNode.requestFocus();
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: widget.onRemark,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 50, // Adjust this value as needed
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0EAFD),
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.remark?.isNotEmpty == true ? widget.remark! : 'Remark',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                )

              ],
            ),
            Row(
              children: [
                // LEFT COLUMN - IMAGE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        if (widget.image != null)
                          buildSmartImage(
                            image: widget.image,
                            height: 100,
                          ),

                        if (widget.isEditable &&
                            (widget.onAdd != null || widget.onEdit != null || widget.onDelete != null || widget.onCopy != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
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

                                if (widget.onDelete != null)
                                  Expanded(
                                    child: IconButton(
                                      onPressed: widget.onDelete,
                                      icon: const Icon(Icons.delete_outline, size: 18),
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
                // RIGHT COLUMN - INPUT FIELDS
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (widget.floorlabel.isNotEmpty)  Expanded(child:    _blueBox(widget.floorlabel, _floorController),
    ),
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
                      // ✅ Length Field (UOM) - NOW USING _lengthController
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _blueBox("UOM", _lengthController, isUOM: true, focusNode: _lengthFocusNode),
                        ],
                      ),
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

  Widget _blueBox(String label, TextEditingController controller, {bool isUOM = false, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    _quantityController.dispose();
    _sizeController.dispose();
    _lengthController.dispose();
    _floorController.dispose();
    _mocController.dispose();
    _lengthFocusNode.dispose();
    super.dispose();
  }
}