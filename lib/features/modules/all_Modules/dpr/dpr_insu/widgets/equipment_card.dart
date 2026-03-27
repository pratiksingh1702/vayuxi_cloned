import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../core/utlis/widgets/image.dart';
import '../model/eqip_insu.dart';
import '../model/material_setup.dart';
import '../model/field_config.dart';
import '../service/material_service.dart';
import 'config/equipment_config.dart';

class EquipmentMaterialCard extends StatefulWidget {
  final EquipmentMaterial material;
  final MaterialSetup? materialSetup; // NEW: For dynamic field rendering
  final ValueChanged<EquipmentMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRemark;

  const EquipmentMaterialCard({
    super.key,
    required this.material,
    this.materialSetup, // Optional: enables dynamic mode
    required this.onChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<EquipmentMaterialCard> createState() => _EquipmentMaterialCardState();
}

class _EquipmentMaterialCardState extends State<EquipmentMaterialCard> {
  // Legacy field controllers
  final Map<EquipmentFieldType, FocusNode> _focusNodes = {
    EquipmentFieldType.qty: FocusNode(),
    EquipmentFieldType.length: FocusNode(),
    EquipmentFieldType.circumference: FocusNode(),
    EquipmentFieldType.circumference1: FocusNode(),
    EquipmentFieldType.circumference2: FocusNode(),
    EquipmentFieldType.circumference3: FocusNode(),
    EquipmentFieldType.zHeight: FocusNode(),
    EquipmentFieldType.gSlantHeight: FocusNode(),
  };
  late final TextEditingController _qtyController;

  late Map<EquipmentFieldType, TextEditingController> _valueControllers;
  late Map<EquipmentFieldType, TextEditingController> _labelControllers;
  late Map<EquipmentFieldType, TextEditingController> _uomControllers;

  // Dynamic field controllers
  final Map<String, TextEditingController> _dynamicValueControllers = {};
  final Map<String, TextEditingController> _dynamicLabelControllers = {};
  final Map<String, FocusNode> _dynamicFocusNodes = {};
  
  bool _isEditMode = false;
  late EquipmentMaterial _draftMaterial;
  late FieldValues _fieldValues;
  late Map<String, String> _customLabels;

  /// Per-field draft image files (index matches field.imageIndex)
  final Map<int, File?> _draftImageFiles = {};
  
  /// Check if using dynamic mode
  bool get _isDynamicMode => widget.materialSetup != null;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.material.qty.toString(),
    );
    _draftMaterial = widget.material.copyWith();
    _fieldValues = widget.material.fieldValues ?? FieldValues({});
    _customLabels = Map.from(widget.material.customLabels ?? {});
    
    if (_isDynamicMode) {
      _initDynamicControllers();
    } else {
      _initControllers(widget.material);
    }
  }

  void _initControllers(EquipmentMaterial m) {
    _valueControllers = {
      EquipmentFieldType.qty:
      TextEditingController(text: m.qty.toString()),

      EquipmentFieldType.length:
      TextEditingController(text: m.length == 0 ? "" : m.length.toString()),

      EquipmentFieldType.circumference:
      TextEditingController(text: m.circumference == 0 ? "" : m.circumference.toString()),

      EquipmentFieldType.circumference1:
      TextEditingController(text: m.circumference1 == 0 ? "" : m.circumference1.toString()),

      EquipmentFieldType.circumference2:
      TextEditingController(text: m.circumference2 == 0 ? "" : m.circumference2.toString()),

      EquipmentFieldType.circumference3:
      TextEditingController(text: m.circumference3 == 0 ? "" : m.circumference3.toString()),

      EquipmentFieldType.zHeight:
      TextEditingController(text: m.zHeight == 0 ? "" : m.zHeight.toString()),

      EquipmentFieldType.gSlantHeight:
      TextEditingController(text: m.gSlantHeight == 0 ? "" : m.gSlantHeight.toString()),
    };

    _labelControllers = {
      EquipmentFieldType.qty: TextEditingController(text: m.customLabels?['qty'] ?? 'Qty'),
      EquipmentFieldType.length: TextEditingController(text: m.customLabels?['length'] ?? 'Length'),
      EquipmentFieldType.circumference: TextEditingController(text: m.customLabels?['circumference'] ?? 'Circumference'),
      EquipmentFieldType.circumference1: TextEditingController(text: m.customLabels?['circumference1'] ?? 'Circumference 1'),
      EquipmentFieldType.circumference2: TextEditingController(text: m.customLabels?['circumference2'] ?? 'Circumference 2'),
      EquipmentFieldType.circumference3: TextEditingController(text: m.customLabels?['circumference3'] ?? 'Circumference 3'),
      EquipmentFieldType.zHeight: TextEditingController(text: m.customLabels?['zHeight'] ?? 'Z-Height'),
      EquipmentFieldType.gSlantHeight: TextEditingController(
          text: m.customLabels?['gSlantHeight'] ?? 'Slant Height'
      ),
    };

    _uomControllers = {
      EquipmentFieldType.qty: TextEditingController(text: m.customLabels?['qty_uom'] ?? 'NOS'),
      EquipmentFieldType.length: TextEditingController(text: m.customLabels?['length_uom'] ?? 'mm'),
      EquipmentFieldType.circumference: TextEditingController(text: m.customLabels?['circumference_uom'] ?? 'mm'),
      EquipmentFieldType.circumference1: TextEditingController(text: m.customLabels?['circumference1_uom'] ?? 'mm'),
      EquipmentFieldType.circumference2: TextEditingController(text: m.customLabels?['circumference2_uom'] ?? 'mm'),
      EquipmentFieldType.circumference3: TextEditingController(text: m.customLabels?['circumference3_uom'] ?? 'mm'),
      EquipmentFieldType.zHeight: TextEditingController(text: m.customLabels?['zHeight_uom'] ?? 'mm'),
      EquipmentFieldType.gSlantHeight: TextEditingController(
          text: m.customLabels?['gSlantHeight_uom'] ?? 'mm'
      ),
    };
  }

  void _initDynamicControllers() {
    if (widget.materialSetup == null) return;
    
    // Initialize controllers for each dynamic field
    for (final field in widget.materialSetup!.fieldConfig.fields) {
      // Value controller
      final value = _fieldValues[field.key];
      _dynamicValueControllers[field.key] = TextEditingController(
        text: value?.toString() ?? '',
      );
      
      // Label controller
      final label = _customLabels[field.key] ?? field.label;
      _dynamicLabelControllers[field.key] = TextEditingController(text: label);
      
      // Focus node
      _dynamicFocusNodes[field.key] = FocusNode();
    }
  }

  @override
  void didUpdateWidget(covariant EquipmentMaterialCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.material.id != widget.material.id && !_isEditMode) {
      _initControllers(widget.material);
    }

    if (oldWidget.material.qty != widget.material.qty) {
      _qtyController.text = widget.material.qty.toString();
    }

    if (!_isEditMode) {
      _draftMaterial = widget.material.copyWith();
      _draftImageFiles.clear();
    }
  }
  @override
  void dispose() {
    // Dispose legacy controllers
    for (final n in _focusNodes.values) n.dispose();
    if (!_isDynamicMode) {
      for (final c in _valueControllers.values) c.dispose();
      for (final c in _labelControllers.values) c.dispose();
      for (final c in _uomControllers.values) c.dispose();
    }
    
    // Dispose dynamic controllers
    for (final c in _dynamicValueControllers.values) c.dispose();
    for (final c in _dynamicLabelControllers.values) c.dispose();
    for (final n in _dynamicFocusNodes.values) n.dispose();
    
    _qtyController.dispose();
    super.dispose();
  }

  void _focusMainField(List<EquipmentFieldConfig> fields) {
    final order = [
      EquipmentFieldType.length,
      EquipmentFieldType.qty,
      EquipmentFieldType.zHeight,
      EquipmentFieldType.circumference,
      EquipmentFieldType.circumference1,
      EquipmentFieldType.circumference2,
      EquipmentFieldType.circumference3,
    ];
    for (final type in order) {
      if (fields.any((f) => f.type == type)) {
        _focusNodes[type]!.requestFocus();
        return;
      }
    }
  }

  // --------------------------------------------------
  // IMAGE HELPERS
  // --------------------------------------------------

  Widget _buildSmartImage({
    File? imageFile,
    String? imageUrl,
    double height = 80,
    double width = double.infinity,
    BoxFit fit = BoxFit.contain,
  }) {
    if (imageFile != null) {
      return Image.file(imageFile, height: height, width: width, fit: fit);
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      return _imagePlaceholder(height, width);
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(height: height, width: width, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        },
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
      );
    }
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final cleanPath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
      );
    }
    return Image.asset(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
    );
  }

  Widget _imagePlaceholder(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Use dynamic mode if MaterialSetup is provided
    if (_isDynamicMode) {
      return _buildDynamicCard();
    }
    
    // Legacy mode
    final key = _resolveConfigKey(widget.material.name);
    final fields = equipmentFieldConfig[key]!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusMainField(fields),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 8),

            Column(
              children: fields.map((field) {
                final imageUrl = widget.material.image.length > field.imageIndex
                    ? widget.material.image[field.imageIndex]
                    : null;
                return _fieldCard(field: field, imageUrl: imageUrl);
              }).toList(),
            ),


            const SizedBox(height: 6),
            const SizedBox(height: 10),

// QUANTITY FIELD (Bottom Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _actionRow(),
                Container(
                  width: 80,

                  // decoration: BoxDecoration(
                  //   color: Colors.white,
                  //   border: Border.all(color: Colors.grey.shade400),
                  //   borderRadius: BorderRadius.circular(8),
                  // ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Qty",
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                      ),

                  SizedBox(
                    height:40,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (val) {
                        final qty = int.tryParse(val) ?? 0;
                        widget.onChanged(widget.material.copyWith(qty: qty));
                      },

                      style: TextStyle(
                        fontSize: 16,
                        height: 15 // 🔥 important
                      ),

                      strutStyle: StrutStyle(
                        forceStrutHeight: true,
                        height: 1,
                      ),

                      decoration: InputDecoration(
                        isCollapsed: true, // 🔥 removes default vertical padding
                        contentPadding: EdgeInsets.symmetric(horizontal: 8,vertical: 8),

                        filled: true,
                        fillColor: Colors.white,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  )
                    ],
                  ),
                ),
              ],
            ),



            // Save / Cancel buttons in edit mode
            if (_isEditMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SAVE / CANCEL
  // --------------------------------------------------

  Future<void> _onSave() async {
    try {
      final hasImageChanges = _draftImageFiles.values.any((f) => f != null);
      final hasNameChange = _draftMaterial.name != widget.material.name;

      if (hasImageChanges || hasNameChange) {
        // Collect all changed images in order
        final List<File?> orderedImages = [];
        final key = _resolveConfigKey(widget.material.name);
        final fields = equipmentFieldConfig[key]!;
        for (final field in fields) {
          orderedImages.add(_draftImageFiles[field.imageIndex]);
        }

        await InsulationMaterialSetupService().updateMaterial(
          materialId: widget.material.id,
          name: _draftMaterial.name,
          images: hasImageChanges
              ? orderedImages.whereType<File>().toList()
              : null,
        );
      }

      widget.onChanged(_draftMaterial);
      setState(() {
        _isEditMode = false;
        _draftImageFiles.clear();
      });
    } catch (e) {
      print("Equipment update failed: $e");
    }
  }

  void _onCancel() {
    setState(() {
      _draftMaterial = widget.material.copyWith();
      _draftImageFiles.clear();
      _isEditMode = false;
    });
  }

  // --------------------------------------------------
  // ACTION ROW
  // --------------------------------------------------

  Widget _actionRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _actionBtn(Icons.edit, Colors.blue, () {
            setState(() {
              _isEditMode = !_isEditMode;
            });
          }),
          const SizedBox(width: 8),
          _actionBtn(Icons.copy, Colors.green, widget.onAdd),
          const SizedBox(width: 8),
          _actionBtn(Icons.delete_outline, Colors.red, widget.onDelete),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: color,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(32, 32),
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER (editable name in edit mode)
  // --------------------------------------------------

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: widget.material.name,
            waitDuration: const Duration(milliseconds: 300),
            showDuration: const Duration(seconds: 3),
            child: _isEditMode
                ? TextFormField(
              initialValue: _draftMaterial.name,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFD0EAFD),
                hintText: "Enter Name",
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _draftMaterial = _draftMaterial.copyWith(name: val);
                });
              },
            )
                : Text(
              widget.material.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onRemark,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD0EAFD),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Remark',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // FIELD CARD (image + input row)
  // --------------------------------------------------

  Widget _fieldCard({
    required EquipmentFieldConfig field,
    String? imageUrl,
  }) {
    final labelKey = field.type.name;
    final material = _isEditMode ? _draftMaterial : widget.material;
    final customLabel = material.customLabels?[labelKey] ?? field.label;
    final uomKey = '${labelKey}_uom';
    final customUom = material.customLabels?[uomKey] ?? _defaultUom(field.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNodes[field.type]?.requestFocus(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LEFT — image + label (+ edit controls in edit mode)
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Edit mode: show change image button
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: () async {
                        final helper = ImageUploadHelper(context);
                        final file = await helper.pickAndCropImage(
                          enableCropping: true,
                          cropTitle: "Crop Image",
                        );
                        if (file != null) {
                          setState(() {
                            _draftImageFiles[field.imageIndex] = file;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo, size: 14),
                      label: const Text("Change", style: TextStyle(fontSize: 12)),
                    ),

                  // Image display
                  _buildSmartImage(
                    imageFile: _isEditMode ? _draftImageFiles[field.imageIndex] : null,
                    imageUrl: _isEditMode
                        ? (_draftImageFiles[field.imageIndex] == null ? imageUrl : null)
                        : imageUrl,
                    height: 80,
                  ),

                  const SizedBox(height: 6),

                  // Label
                  _isEditMode
                      ? SizedBox(
                    height: 28,
                    child: TextFormField(
                      controller: _labelControllers[field.type],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFD0EAFD),
                        hintText: "Label",
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        final newLabels = Map<String, String>.from(_draftMaterial.customLabels ?? {});
                        newLabels[labelKey] = val;
                        _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
                      },
                    ),
                  )
                      : Text(
                    customLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // RIGHT — UOM (editable) + value input
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UOM row
                  _isEditMode
                      ? SizedBox(
                    height: 28,
                    child: TextFormField(
                      controller: _uomControllers[field.type],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,

                        filled: true,
                        fillColor: const Color(0xFFD0EAFD),
                        hintText: "UOM",
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        final newLabels = Map<String, String>.from(_draftMaterial.customLabels ?? {});
                        newLabels[uomKey] = val;
                        _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
                      },
                    ),
                  )
                      : Text(
                    customUom,
                    style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 6),

                  // Value input (only in view mode; hidden in edit mode)
                  if (!_isEditMode)
                    TextFormField(
                      controller: _valueControllers[field.type],
                      style: TextStyle(
                        fontSize: 10
                      ),

                      focusNode: _focusNodes[field.type],
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFD0EAFD),

                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                        onChanged: (val) {
                          final v = double.tryParse(val) ?? 0;
                          widget.onChanged(_updateMaterial(field, v));
                        }
                    ),

                  // In edit mode show a placeholder message
                  if (_isEditMode)
                    Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getValue(field).toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // VALUE & UPDATE LOGIC
  // --------------------------------------------------

  double _getValue(EquipmentFieldConfig config) {
    final m = _isEditMode ? _draftMaterial : widget.material;
    switch (config.type) {
      case EquipmentFieldType.qty:
        return m.qty.toDouble();
      case EquipmentFieldType.length:
        return m.length;
      case EquipmentFieldType.circumference:
        return m.circumference;
      case EquipmentFieldType.circumference1:
        return m.circumference1;
      case EquipmentFieldType.circumference2:
        return m.circumference2;
      case EquipmentFieldType.circumference3:
        return m.circumference3;
      case EquipmentFieldType.zHeight:
        return m.zHeight;
        case EquipmentFieldType.gSlantHeight:
        return m.gSlantHeight;

    }
  }

  EquipmentMaterial _updateMaterial(EquipmentFieldConfig config, double value) {
    switch (config.type) {
      case EquipmentFieldType.qty:
        return widget.material.copyWith(qty: value.toInt());
      case EquipmentFieldType.length:
        return widget.material.copyWith(length: value);
      case EquipmentFieldType.circumference:
        return widget.material.copyWith(circumference: value);
      case EquipmentFieldType.circumference1:
        return widget.material.copyWith(circumference1: value);
      case EquipmentFieldType.circumference2:
        return widget.material.copyWith(circumference2: value);
      case EquipmentFieldType.circumference3:
        return widget.material.copyWith(circumference3: value);
      case EquipmentFieldType.zHeight:
        return widget.material.copyWith(zHeight: value);
        case EquipmentFieldType.gSlantHeight:
        return widget.material.copyWith(gSlantHeight: value);

    }
  }

  String _resolveConfigKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');

    // 1️⃣ Exact match first
    if (equipmentFieldConfig.containsKey(upper)) {
      return upper;
    }

    // 2️⃣ Then fallback to prefix match
    for (final key in equipmentFieldConfig.keys) {
      if (upper.startsWith(key)) {
        return key;
      }
    }

    return 'DEFAULT';
  }

  String _defaultUom(EquipmentFieldType type) {
    return type == EquipmentFieldType.qty ? 'NOS' : 'mm';
  }

  // --------------------------------------------------
  // DYNAMIC FIELD RENDERING
  // --------------------------------------------------

  Widget _buildDynamicCard() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusFirstDynamicField(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 8),

            // Geometry mode switch (for SHELL material)
            if (widget.materialSetup!.fieldConfig.ui.allowGeometrySwitch)
              _buildGeometryModeSwitch(),

            // Dynamic fields
            ..._buildDynamicFields(),

            const SizedBox(height: 8),

            // Quantity field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _actionRow(),
                _buildQuantityField(),
              ],
            ),

            // Save/Cancel in edit mode
            if (_isEditMode) ...[
              const SizedBox(height: 8),
              _buildEditActions(),
            ],
          ],
        ),
      ),
    );
  }

  void _focusFirstDynamicField() {
    if (widget.materialSetup == null) return;
    
    // Focus first required field
    final firstRequired = widget.materialSetup!.fieldConfig.fields
        .firstWhere((f) => f.required, orElse: () => widget.materialSetup!.fieldConfig.fields.first);
    
    _dynamicFocusNodes[firstRequired.key]?.requestFocus();
  }

  Widget _buildGeometryModeSwitch() {
    final currentMode = _fieldValues['geometryMode']?.toString() ?? 'DIAMETER';
    final options = widget.materialSetup!.fieldConfig.unitDropdowns.geometryMode ?? [];

    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: options.map((mode) {
          final isSelected = currentMode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _isEditMode
                    ? null
                    : () {
                        setState(() {
                          _fieldValues['geometryMode'] = mode;
                        });
                        widget.onChanged(
                          widget.material.copyWith(fieldValues: _fieldValues),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  mode,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    if (widget.materialSetup == null) return [];

    return widget.materialSetup!.fieldConfig.fields
        .where((f) => f.key != 'geometryMode' && _isFieldVisible(f))
        .map((field) => _buildDynamicFieldCard(field))
        .toList();
  }

  bool _isFieldVisible(FieldDefinition field) {
    if (field.visibleWhen == null) return true;

    // Check geometry mode visibility
    if (field.visibleWhen!.geometryMode != null) {
      final currentMode = _fieldValues['geometryMode'];
      return currentMode == field.visibleWhen!.geometryMode;
    }

    return true;
  }

  Widget _buildDynamicFieldCard(FieldDefinition field) {
    final customLabel = _customLabels[field.key] ?? field.label;
    final imageIndex = _getImageIndexForField(field);
    final imageUrl = widget.material.image.length > imageIndex
        ? widget.material.image[imageIndex]
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _dynamicFocusNodes[field.key]?.requestFocus(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image section
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: () => _changeDynamicFieldImage(field, imageIndex),
                      icon: const Icon(Icons.photo, size: 14),
                      label: const Text("Change", style: TextStyle(fontSize: 12)),
                    ),
                  _buildSmartImage(
                    imageFile: _isEditMode ? _draftImageFiles[imageIndex] : null,
                    imageUrl: _isEditMode
                        ? (_draftImageFiles[imageIndex] == null ? imageUrl : null)
                        : imageUrl,
                    height: 80,
                  ),
                  const SizedBox(height: 6),
                  _buildDynamicFieldLabel(field, customLabel),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Value and unit section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDynamicFieldUnit(field),
                  const SizedBox(height: 6),
                  _buildDynamicFieldInput(field),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getImageIndexForField(FieldDefinition field) {
    // Map field roles to image indices
    final roleToIndex = {
      'LENGTH': 0,
      'CIRCUMFERENCE': 0,
      'DIAMETER': 0,
      'Z_HEIGHT': 1,
      'G_SLANT_HEIGHT': 1,
      'CIRCUMFERENCE_1': 1,
      'CIRCUMFERENCE_2': 2,
      'CIRCUMFERENCE_3': 3,
    };
    return roleToIndex[field.role] ?? 0;
  }

  Future<void> _changeDynamicFieldImage(FieldDefinition field, int imageIndex) async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: "Crop Image",
    );
    if (file != null) {
      setState(() {
        _draftImageFiles[imageIndex] = file;
      });
    }
  }

  Widget _buildDynamicFieldLabel(FieldDefinition field, String customLabel) {
    if (_isEditMode && widget.materialSetup!.fieldConfig.ui.allowRename) {
      return SizedBox(
        height: 28,
        child: TextFormField(
          controller: _dynamicLabelControllers[field.key],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFD0EAFD),
            hintText: "Label",
            hintStyle: const TextStyle(fontSize: 11, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            _customLabels[field.key] = val;
          },
        ),
      );
    }

    return Text(
      customLabel,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDynamicFieldUnit(FieldDefinition field) {
    if (field.dropdown == null) return const SizedBox.shrink();

    final unitKey = '${field.key}Uom';
    final dropdownKey = field.dropdown!;
    final unitDropdowns = widget.materialSetup!.fieldConfig.unitDropdowns.toJson();
    final options = unitDropdowns[dropdownKey] as List?;

    if (options == null || options.isEmpty) return const SizedBox.shrink();

    final currentUnit = _fieldValues[unitKey]?.toString() ??
        widget.materialSetup!.fieldConfig.defaults.toJson()[dropdownKey]?.toString() ??
        options.first.toString();

    if (_isEditMode) {
      return Text(
        currentUnit,
        style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Unit:',
            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentUnit,
              isDense: true,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt.toString(),
                  child: Text(opt.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _fieldValues[unitKey] = value;
                  });
                  widget.onChanged(
                    widget.material.copyWith(fieldValues: _fieldValues),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicFieldInput(FieldDefinition field) {
    if (_isEditMode) {
      final value = _fieldValues[field.key];
      return Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value?.toString() ?? '0',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black54),
        ),
      );
    }

    return TextFormField(
      controller: _dynamicValueControllers[field.key],
      focusNode: _dynamicFocusNodes[field.key],
      textAlign: TextAlign.center,
      keyboardType: field.type == 'NUMBER'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(fontSize: 10),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFD0EAFD),
        hintText: field.required ? 'Required' : '',
        hintStyle: const TextStyle(fontSize: 9, color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      validator: field.required
          ? (value) => (value?.isEmpty ?? true) ? 'Required' : null
          : null,
      onChanged: (val) {
        if (field.type == 'NUMBER') {
          final numValue = num.tryParse(val);
          if (numValue != null) {
            _fieldValues[field.key] = numValue;
            widget.onChanged(
              widget.material.copyWith(fieldValues: _fieldValues),
            );
          }
        } else {
          _fieldValues[field.key] = val;
          widget.onChanged(
            widget.material.copyWith(fieldValues: _fieldValues),
          );
        }
      },
    );
  }

  Widget _buildQuantityField() {
    return Container(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Qty",
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (val) {
                final qty = int.tryParse(val) ?? 0;
                widget.onChanged(widget.material.copyWith(qty: qty));
              },
              style: const TextStyle(fontSize: 16, height: 1.5),
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _onSave,
            child: const Text("Save"),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            onPressed: _onCancel,
            child: const Text("Cancel"),
          ),
        ),
      ],
    );
  }
}