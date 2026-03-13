  import 'dart:io';
  
  import 'package:flutter/material.dart';
  
  import '../../../../../../core/utlis/widgets/file_upload.dart';
  import '../../models/dprModel.dart';
  import '../../models/rate_file_models.dart';
  
  class testDynamicItemCard extends StatefulWidget {
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
    final bool isEditMode;
    final Function(MaterialEditResult)? onSave;
    final bool isDpr;
  
    final VoidCallback? onCancel;
  
    final String sizePlaceholder;
    final String lengthPlaceholder;
    final List<DynamicField> fields;
    final Function(String key, String value) onChanged;
  
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
  
    const testDynamicItemCard({
      required this.quantity,
      required this.size,
      this.isDpr = true,
      required this.fields,
      required this.onChanged,
      this.floorlabel = 'Floor',
      this.isEditMode = false,
      this.onSave,
      this.onCancel,
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
    State<testDynamicItemCard> createState() => _testDynamicItemCardState();
  }
  
  class _testDynamicItemCardState extends State<testDynamicItemCard>
      with AutomaticKeepAliveClientMixin {
    // Controllers to preserve
    late String draftName;
    File? draftImageFile;
    String? draftImageUrl;
  
    late String draftUom;
    late List<DynamicField> draftFields;
  
    late TextEditingController _quantityController;
    late TextEditingController _sizeController;
    late TextEditingController
        _lengthController; // ✅ Using lengthController for length/UOM
    late TextEditingController _floorController;
    late TextEditingController _mocController;
    bool _isEditingLength = false;
    final Map<String, TextEditingController> _controllers = {};
  
    late FocusNode _lengthFocusNode; // ✅ Renamed from _uomFocusNode
  
    @override
    bool get wantKeepAlive => true;
  
    @override
    void initState() {
      super.initState();
      draftName = widget.lengthLabel;
      draftImageUrl = widget.image;
      draftImageFile = null;
  
      draftUom = widget.lengthPlaceholder;
      draftFields = widget.fields.map((e) => e.copy()).toList();
  
      for (final f in widget.fields) {
        final key = f.key.toLowerCase();
  
        String text = '';
  
        if (key == 'qty') {
          text = f.displayText;
        } else if (key == 'size') {
          text = widget.size;
  
          // 🔥 ADD THIS LINE
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(f.key, text);
          });
        }
  
        _controllers[f.key] = TextEditingController(text: text);
      }
  
      // Initialize controllers with current values
      _quantityController = TextEditingController(text: widget.quantity);
      _sizeController = TextEditingController(text: widget.size);
      _lengthController =
          TextEditingController(text: widget.length); // ✅ Initialize with length
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
    void didUpdateWidget(covariant testDynamicItemCard oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.isEditMode && !oldWidget.isEditMode) {
        draftName = widget.lengthLabel;
        draftImageUrl = widget.image;
        draftImageFile = null;


        draftUom = widget.lengthPlaceholder;
        draftFields = widget.fields.map((e) => e.copy()).toList();
      }
      if (widget.image != oldWidget.image) {
        draftImageUrl = widget.image;
        draftImageFile = null;
      }



  
      if (widget.size != oldWidget.size) {
        final sizeController = _controllers.putIfAbsent(
          'size',
          () => TextEditingController(),
        );
  
        if (sizeController.text != widget.size) {
          sizeController.text = widget.size;
        }
      }
      if (widget.size != oldWidget.size) {
        final c = _controllers.putIfAbsent(
          'size',
          () => TextEditingController(),
        );
  
        if (c.text != widget.size) {
          c.text = widget.size;
        }
      }
  
      /// FLOOR
      if (widget.floor != oldWidget.floor) {
        final c = _controllers.putIfAbsent(
          'floor',
          () => TextEditingController(),
        );
  
        if (c.text != widget.floor) {
          c.text = widget.floor;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged('floor', widget.floor);
        });
      }
  
      /// MOC
      if (widget.moc != oldWidget.moc) {
        final c = _controllers.putIfAbsent(
          'moc',
          () => TextEditingController(),
        );
  
        if (c.text != widget.moc) {
          c.text = widget.moc;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged('moc', widget.moc);
        });
      }
  
      if (!_isEditingLength &&
          widget.length != oldWidget.length &&
          widget.length != _lengthController.text) {
        _lengthController.text = widget.length;
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
  
    Widget _buildDynamicFields() {
      final items = widget.isEditMode ? draftFields : widget.fields;
      if (items.isEmpty) return const SizedBox();
  
      final rows = <Widget>[];
  
      for (int i = 0; i < items.length; i += 2) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: widget.isEditMode
                    ? _editFieldTile(i)
                    : _viewFieldTile(items[i]),
              ),
              const SizedBox(width: 8),
              if (i + 1 < items.length)
                Expanded(
                  child: widget.isEditMode
                      ? _editFieldTile(i + 1)
                      : _viewFieldTile(items[i + 1]),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
  
        rows.add(const SizedBox(height: 8));
      }
  
      return Column(children: rows);
    }

    Widget _viewFieldTile(DynamicField field) {
      final isQty = field.key.toLowerCase() == 'qty';

      final controller = _controllers.putIfAbsent(
        field.key,
            () => TextEditingController(),
      );

      // 🔥 FORCE SYNC CONTROLLER WITH FIELD VALUE
      final newValue = widget.isDpr
          ? (field.value?.toString() ?? '')
          : (isQty ? field.displayText ?? '' : '');

      if (controller.text != newValue) {
        controller.text = newValue;
      }

      print("📦 ${field.key} -> '${controller.text}'");

      return _updatedblueBox(
        label: field.label,
        controller: controller,
        unit: field.unit,
        keyName: field.key,
      );
    }
    Widget _editFieldTile(int index) {
      final field = draftFields[index];
  
      final valueController = _controllers.putIfAbsent(
        field.key,
        () => TextEditingController(text: ""),
      );
  
      final labelController = TextEditingController(text: field.label);
      final unitController = TextEditingController(text: field.unit);
  
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LABEL EDIT
          SizedBox(
            height: 22,
            child: TextFormField(
              controller: labelController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Add Label",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                filled: true,
                fillColor: const Color(0xFFD0EAFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              onChanged: (v) {
                draftFields[index] = field.copyWith(label: v);
              },
            ),
          ),
  
          const SizedBox(height: 4),
  
          /// VALUE EDIT (original behavior)
          SizedBox(
            height: 23,
            child: TextFormField(
              controller: valueController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: "Add Value",
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                filled: true,
                fillColor: const Color(0xFFD0EAFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 8),
              onChanged: (v) {
                draftFields[index] = field.copyWith(unit: v);
              },
            ),
          ),
  
          const SizedBox(height: 4),
  
          const SizedBox(height: 4),
  
          /// DELETE
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => draftFields.removeAt(index)),
              child: const Icon(Icons.delete, size: 14, color: Colors.red),
            ),
          ),
        ],
      );
    }
    Widget buildSmartImage({
      String? imageUrl,
      File? imageFile,
      double height = 120,
      double width = double.infinity,
      BoxFit fit = BoxFit.contain,
    }) {
      if (imageFile != null) {
        return SizedBox(
          height: height,
          width: width,
          child: Image.file(
            imageFile,
            fit: fit,
            errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
          ),
        );
      }
  
      if (imageUrl == null || imageUrl.isEmpty) {
        return _imagePlaceholder(height, width);
      }
  
      final isNetwork =
          imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  
      return SizedBox(
        height: height,
        width: width,
        child: isNetwork
            ? Image.network(
          imageUrl,
          fit: fit,
          errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
        )
            : Image.asset(
          imageUrl,
          fit: fit,
          errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
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
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: 300 // Adjust this value as needed
                        ),
                    child: widget.isEditMode
                        ? TextFormField(
                            initialValue: draftName,
                            onChanged: (v) => draftName = v,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            widget.lengthLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0EAFD),
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.remark?.isNotEmpty == true
                                ? widget.remark!
                                : 'Remark',
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w600),
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
                          if (widget.isEditMode)
                            TextButton.icon(
                              onPressed: () async {
                                final helper = ImageUploadHelper(context);
  
                                final file = await helper.pickAndCropImage(
                                  enableCropping: true,
                                  cropTitle: "Crop Material Image",
                                );
  
                                if (file != null) {
                                  setState(() {
                                    draftImageFile = file;
                                    draftImageUrl = null; // override server image
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo),
                              label: const Text("Change"),
                            ),
                      buildSmartImage(
                            imageFile: widget.isEditMode ? draftImageFile : null,
                            imageUrl: widget.isEditMode
                                ? draftImageUrl
                                : widget.image,
                          ),
  
  
                          if (widget.isEditable &&
                              (widget.onAdd != null ||
                                  widget.onEdit != null ||
                                  widget.onDelete != null ||
                                  widget.onCopy != null))
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
                                          side: const BorderSide(
                                              color: Colors.blue, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                          side: const BorderSide(
                                              color: Colors.green, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                        icon: const Icon(Icons.delete, size: 18),
                                        color: Colors.red,
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(6),
                                          minimumSize: const Size(0, 32),
                                          side: const BorderSide(
                                              color: Colors.red, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                        _buildDynamicFields(),
                        if (widget.isEditMode)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                draftFields.add(
                                  DynamicField(
                                    key: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    label: "New Field",
                                    unit: "",
                                    displayText: "",
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Add Field"),
                          ),
  
                        const SizedBox(height: 12),
                        // ✅ Length Field (UOM) - NOW USING _lengthController
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.isEditMode
                                ? TextFormField(
                                    initialValue: draftUom,
                                    decoration:
                                        const InputDecoration(labelText: "UOM"),
                                    onChanged: (v) => draftUom = v,
                                  )
                                : _blueBox("UOM", _lengthController,
                                    isUOM: true, focusNode: _lengthFocusNode),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSave?.call(
                            MaterialEditResult(
                              name: draftName,
                              imageFile: draftImageFile,
                              imageUrl: draftImageUrl,
                              uom: draftUom,
                              fields: draftFields,
                            ),
                          );

  
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
  
    Widget _blueBox(String label, TextEditingController controller,
        {bool isUOM = false, FocusNode? focusNode}) {
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isUOM ? 14 : 8,
                fontWeight: isUOM ? FontWeight.w500 : FontWeight.normal,
                color: isUOM
                    ? Colors.black
                    : (widget.lengthPlaceholder == 'UOM'
                        ? Colors.grey[600]
                        : Colors.black),
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
                    : (widget.isEditable
                        ? const Color(0xFFD0EAFD)
                        : Colors.grey[300]),
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
  
    Widget _updatedblueBox({
      required String label,
      required TextEditingController controller,
      required String keyName,
      String unit = '',
    }) {
      final shouldShowHint = label.toLowerCase() == "qty";
      print("❤️❤️❤️❤️❤️ $shouldShowHint");
  
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              unit.isEmpty ? label : "$label ($unit)",
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 23,
            child: TextFormField(
              key: ValueKey(keyName),
              controller: controller,
              onChanged: (v) => widget.onChanged(keyName, v),
              textAlign: TextAlign.center,
              enabled: widget.isEditable,
              decoration: InputDecoration(
                /// ⭐ ONLY for Qty
                hintText: shouldShowHint ? "Enter quantity" : "",
  
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 2,
                ),
                filled: true,
                fillColor: widget.isEditable
                    ? const Color(0xFFD0EAFD)
                    : Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 8,
                color: Colors.black,
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
