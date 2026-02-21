import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../core/utlis/widgets/image.dart';
import '../model/piping_insu.dart';
import '../service/material_service.dart';
import 'config/piping_config.dart';

class PipingMaterialCard extends StatefulWidget {
  final PipingMaterial material;
  final ValueChanged<PipingMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRemark;
  final Map<String, String>? customLabels;
  const PipingMaterialCard({
    super.key,
    required this.material,
    required this.onChanged,
    this.customLabels,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<PipingMaterialCard> createState() => _PipingMaterialCardState();
}

class _PipingMaterialCardState extends State<PipingMaterialCard> {
  File? _draftImageFile;
  String? _draftImageUrl;
  final Map<PipingFieldType, FocusNode> _focusNodes = {
    PipingFieldType.size: FocusNode(),
    PipingFieldType.length: FocusNode(),
    PipingFieldType.qty: FocusNode(),
  };
  late Map<PipingFieldType, TextEditingController> _valueControllers;
  late Map<PipingFieldType, TextEditingController> _labelControllers;
  late TextEditingController _sizeUomController;
  bool _isEditMode = false;
  late PipingMaterial _draftMaterial;
  @override
  void initState() {
    super.initState();

    _draftMaterial = widget.material.copyWith();

    _draftImageUrl = widget.material.image.isNotEmpty
        ? widget.material.image.first
        : null;

    _valueControllers = {
      PipingFieldType.size: TextEditingController(text: widget.material.size ?? ''),
      PipingFieldType.length: TextEditingController(text: widget.material.length.toString()),
      PipingFieldType.qty: TextEditingController(text: ""),
    };

    _labelControllers = {
      PipingFieldType.size: TextEditingController(
          text: widget.material.customLabels?['size'] ?? 'Size'),
      PipingFieldType.length: TextEditingController(
          text: widget.material.customLabels?['length'] ?? 'Length'),
      PipingFieldType.qty: TextEditingController(
          text: widget.material.customLabels?['qty'] ?? 'Qty'),
    };

    _sizeUomController =
        TextEditingController(text: widget.material.sizeUom ?? 'inch');
  }
  @override
  void didUpdateWidget(covariant PipingMaterialCard oldWidget) {
    super.didUpdateWidget(oldWidget);


    if (!_isEditMode) {
      _draftMaterial = widget.material.copyWith();
      _draftImageFile = null;
      _draftImageUrl = widget.material.image.isNotEmpty
          ? widget.material.image.first
          : null;
      _valueControllers[PipingFieldType.size]!.text =
          widget.material.size ?? '';
      _valueControllers[PipingFieldType.length]!.text =
          widget.material.length.toString();
      _valueControllers[PipingFieldType.qty]!.text =
          widget.material.qty.toString();

      _sizeUomController.text =
          widget.material.sizeUom ?? 'inch';
    }
  }
  @override
  void dispose() {
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    _sizeUomController.dispose();
    super.dispose();
  }
  Widget _buildSmartImage({
    String? imageUrl,
    File? imageFile,
    double height = 100,
    double width = double.infinity,
    BoxFit fit = BoxFit.contain,
  }) {
    // 1️⃣ FILE OBJECT
    if (imageFile != null) {
      return Image.file(imageFile, height: height, width: width, fit: fit);
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return _imagePlaceholder(height, width);
    }

    // 2️⃣ NETWORK
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
      );
    }

    // 3️⃣ LOCAL FILE PATH (string like /data/user/0/.../image.jpg)
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final cleanPath = imageUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
      );
    }

    // 4️⃣ ASSET
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
      child: const Icon(Icons.image_not_supported_outlined,
          color: Colors.grey, size: 32),
    );
  }


  void _focusMainField(List<PipingFieldConfig> fields) {
    // Priority: length > qty > size
    if (fields.any((f) => f.type == PipingFieldType.length)) {
      _focusNodes[PipingFieldType.length]!.requestFocus();
      return;
    }
    if (fields.any((f) => f.type == PipingFieldType.qty)) {
      _focusNodes[PipingFieldType.qty]!.requestFocus();
      return;
    }
    _focusNodes[PipingFieldType.size]!.requestFocus();
  }


  @override
  Widget build(BuildContext context) {/**/
    final key = _resolveConfigKey(widget.material.name);
    final fields = pipingFieldConfig[key]!;


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
          children: [
            _header(),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN – IMAGE + ACTIONS (FIXED WIDTH)
                SizedBox(
                  width: 140, // 🔑 controls image + action width
                  child: Column(
                    children: [
                      Column(
                        children: [
                          if (_isEditMode)
                            TextButton.icon(
                              onPressed: () async {
                                final helper = ImageUploadHelper(context);

                                final file = await helper.pickAndCropImage(
                                  enableCropping: true,
                                  cropTitle: "Crop Material Image",
                                );

                                if (file != null) {
                                  setState(() {
                                    _draftImageFile = file;
                                    _draftImageUrl = null; // override server image
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo),
                              label: const Text("Change"),
                            ),

                          _buildSmartImage(
                            imageFile: _isEditMode ? _draftImageFile : null,
                            imageUrl: _isEditMode
                                ? _draftImageUrl
                                : widget.material.image.isNotEmpty
                                ? widget.material.image.first
                                : null,
                            height: 100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _actionBtn(Icons.edit, Colors.blue, () {
                            setState(() {
                              _isEditMode = !_isEditMode;
                            });
                          }),
                          const SizedBox(width: 6),
                          _actionBtn(Icons.copy, Colors.green, widget.onAdd),
                          const SizedBox(width: 6),
                          _actionBtn(Icons.delete, Colors.red, widget.onDelete),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // RIGHT COLUMN – FIELDS
                Expanded(
                  child: Container(


                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: () {
                        final mainField = fields.firstWhere(
                              (f) =>
                          f.type == PipingFieldType.length ||
                              f.type == PipingFieldType.qty,
                          orElse: () => fields.first,
                        );

                        final hasMain = fields.any(
                              (f) =>
                          f.type == PipingFieldType.length ||
                              f.type == PipingFieldType.qty,
                        );

                        final otherFields = fields.where((f) => f != mainField).toList();

                        return [

                          ...otherFields.map(_blueField),
                         // ✅ pushes main field DOWN
                          if (hasMain) _mainWhiteField(mainField),
                        ];
                      }(),
                    ),
                  ),
                ),

              ],
            ),
            Row(
              children: [
                if (_isEditMode) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (_draftImageFile != null ||
                              _draftMaterial.name != widget.material.name) {

                            await InsulationMaterialSetupService().updateMaterial(
                              materialId: widget.material.id,
                              name: _draftMaterial.name,
                              images: _draftImageFile != null
                                  ? [_draftImageFile!]
                                  : null,
                            );
                          }

                          widget.onChanged(_draftMaterial);

                          setState(() {
                            _isEditMode = false;
                            _draftImageFile = null;
                          });

                        } catch (e) {
                          print("Update failed: $e");
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _draftMaterial = widget.material.copyWith();
                          _isEditMode = false;
                        });
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
  String _resolveDisplayValue(
      PipingFieldConfig config,
      PipingMaterial material,
      ) {
    switch (config.type) {
      case PipingFieldType.qty:
        final qty = material.qty;
        if (qty == null || qty == 0) return '';
        return qty.toString();

      case PipingFieldType.length:
        final len = material.length;
        if (len == 0) return '';
        return len.toString();

      case PipingFieldType.size:
        return material.size ?? '';
    }
  }
  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------
  Widget _mainWhiteField(PipingFieldConfig config) {
    final isDecimal = config.type == PipingFieldType.length;
    final material = _isEditMode ? _draftMaterial : widget.material;
    final labelKey = config.type.name;

    final customLabel =
        material.customLabels?[labelKey] ?? config.label;

    // 🔥 UOM now tied to QTY and stored in customLabels
    final qtyUom =
        material.customLabels?['qty_uom'] ?? config.unit ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // -------- LABEL + UOM --------
        _isEditMode
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              child: TextFormField(
                controller: _labelControllers[config.type],
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFD0EAFD),
                  hintText:"Enter Label",
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final newLabels =
                  Map<String, String>.from(
                      _draftMaterial.customLabels ?? {});
                  newLabels[labelKey] = val;

                  _draftMaterial =
                      _draftMaterial.copyWith(
                          customLabels: newLabels);
                },
              ),
            ),

            // 🔥 ONLY FOR QTY — Editable UOM
            if (config.type == PipingFieldType.qty)
              const SizedBox(height: 6),

            if (config.type == PipingFieldType.qty)
              SizedBox(
                height: 24,
                child: TextFormField(
                  initialValue: qtyUom,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFD0EAFD),
                    hintText:"Enter UOM",
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    final newLabels =
                    Map<String, String>.from(
                        _draftMaterial.customLabels ?? {});
                    newLabels['qty_uom'] = val;

                    _draftMaterial =
                        _draftMaterial.copyWith(
                            customLabels: newLabels);
                  },
                ),
              ),
          ],
        )
            : Text(
          config.type == PipingFieldType.qty
              ? "$customLabel ($qtyUom)"
              : "$customLabel (${config.unit ?? ''})",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        // -------- VALUE --------
        if(!_isEditMode)TextFormField(
          controller: _valueControllers[config.type]
            ?..text = _resolveDisplayValue(config, material),
          focusNode: _focusNodes[config.type],
          textAlign: TextAlign.center,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            final parsed = isDecimal
                ? double.tryParse(val) ?? 0
                : int.tryParse(val) ?? 0;

            if (_isEditMode) {
              setState(() {
                _draftMaterial = _updateDraftMaterial(config, parsed);
              });
            } else {
              widget.onChanged(_updateMaterial(config, parsed));
            }
          },
        ),
      ],
    );
  }
  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: widget.material.name, // full text
            waitDuration: const Duration(milliseconds: 300),
            showDuration: const Duration(seconds: 3),
            child:_isEditMode
                ? TextFormField(
              initialValue: _draftMaterial.name,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFD0EAFD),
                hintText:"Enter Name",
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: color,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(6),
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FIELD (BLUE STYLE)
  // --------------------------------------------------
  Widget _blueField(PipingFieldConfig config) {
    final isDecimal = config.type == PipingFieldType.length;
    final material = _isEditMode ? _draftMaterial : widget.material;
    final labelKey = config.type.name;

    final customLabel =
        material.customLabels?[labelKey] ?? config.label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // -------- LABEL --------
          _isEditMode
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 22,
                child: TextFormField(
                  controller: _labelControllers[config.type],
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFD0EAFD),
                    hintText:"Enter Label",
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    final newLabels =
                    Map<String, String>.from(
                        _draftMaterial.customLabels ?? {});
                    newLabels[labelKey] = val;

                    _draftMaterial =
                        _draftMaterial.copyWith(
                            customLabels: newLabels);
                  },
                ),
              ),

              if (config.type == PipingFieldType.size)
                const SizedBox(height: 4),

              if (config.type == PipingFieldType.size)
                SizedBox(
                  height: 22,
                  child: TextFormField(
                    controller: _sizeUomController,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFD0EAFD),
                      hintText:"Enter UOM",
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      _draftMaterial =
                          _draftMaterial.copyWith(sizeUom: val);
                    },
                  ),
                ),
            ],
          )
              : Text(
            config.type == PipingFieldType.size
                ? "$customLabel (${material.sizeUom ?? 'inch'})"
                : "$customLabel (${config.unit ?? ''})",
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // -------- VALUE --------
          if(!_isEditMode) SizedBox(
            height: 26,
            width: 110,
            child: TextFormField(
              controller: _valueControllers[config.type],
              focusNode: _focusNodes[config.type],
              textAlign: TextAlign.center,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Color(0xFFD0EAFD),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              onChanged: (val) {
                final parsed = isDecimal
                    ? double.tryParse(val) ?? 0
                    : int.tryParse(val) ?? 0;

                if (_isEditMode) {
                  setState(() {
                    _draftMaterial = _updateDraftMaterial(config, parsed);
                  });
                } else {
                  widget.onChanged(_updateMaterial(config, parsed));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  PipingMaterial _updateDraftMaterial(
      PipingFieldConfig config,
      num value,
      ) {
    switch (config.type) {
      case PipingFieldType.size:
        return _draftMaterial.copyWith(
          size: value.toString(),
        );
      case PipingFieldType.length:
        return _draftMaterial.copyWith(
          length: value.toDouble(),
        );
      case PipingFieldType.qty:
        return _draftMaterial.copyWith(
          qty: value.toInt(),
        );
    }
  }
  Object? _getValueFrom(PipingMaterial material, PipingFieldConfig config) {
    switch (config.type) {
      case PipingFieldType.size:
        return material.size;
      case PipingFieldType.length:
        return material.length;
      case PipingFieldType.qty:
        return material.qty;
    }
  }
  // --------------------------------------------------
  // VALUE RESOLUTION (UNCHANGED)
  // --------------------------------------------------

  Object? _getValue(PipingFieldConfig config) {
    switch (config.type) {
      case PipingFieldType.size:
        return widget.material.size; // String
      case PipingFieldType.length:
        return widget.material.length; // double
      case PipingFieldType.qty:
        return widget.material.qty; // int
    }
  }

  PipingMaterial _updateMaterial(PipingFieldConfig config, num value) {
    switch (config.type) {
      case PipingFieldType.size:
        return widget.material.copyWith(size: value.toString());
      case PipingFieldType.length:
        return widget.material.copyWith(length: value.toDouble());
      case PipingFieldType.qty:
        return widget.material.copyWith(qty: value.toInt());
    }
  }

  String _resolveConfigKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');
    return pipingFieldConfig.keys.firstWhere(
      (k) => upper.startsWith(k),
      orElse: () => 'DEFAULT',
    );
  }
}
