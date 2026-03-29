// lib/features/modules/all_Modules/dpr/dpr_insu/widgets/piping_card.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../offline/data/local/local_material_dao.dart';
import '../model/piping_insu.dart';
import '../model/material_setup.dart';
import '../model/field_config.dart';
import '../model/card_form_State.dart';
import '../service/material_service.dart';
import 'config/piping_config.dart';

class PipingMaterialCard extends StatefulWidget {
  final PipingMaterial material;
  final MaterialSetup? materialSetup;
  final ValueChanged<PipingMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRemark;

  const PipingMaterialCard({
    super.key,
    required this.material,
    this.materialSetup,
    required this.onChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<PipingMaterialCard> createState() => _PipingMaterialCardState();
}

class _PipingMaterialCardState extends State<PipingMaterialCard> {
  bool _isEditMode = false;
  bool _isLoading = false;
  late PipingMaterial _draftMaterial;

  // Per-card isolated form state (nullable to avoid LateInitializationError)
  CardFormState? _cardStateField;

  CardFormState get _cardState {
    if (_cardStateField == null) {
      _cardStateField = CardFormState.buildInitial(
        fieldConfig: _config!,
        existing: widget.material.cardFormState,
      );
    }
    return _cardStateField!;
  }

  set _cardState(CardFormState s) => _cardStateField = s;

  final Map<String, TextEditingController> _valueControllers = {};
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  late TextEditingController _qtyController;

  File? _draftImageFile;
  String? _draftImageUrl;

  late Map<PipingFieldType, TextEditingController> _legacyValueControllers;
  late Map<PipingFieldType, TextEditingController> _legacyLabelControllers;
  late Map<PipingFieldType, FocusNode> _legacyFocusNodes;
  late TextEditingController _sizeUomController;

  bool get _isDynamic => widget.materialSetup != null;
  FieldConfig? get _config => widget.materialSetup?.fieldConfig;

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _draftMaterial = widget.material;
    _draftImageUrl =
        widget.material.image.isNotEmpty ? widget.material.image.first : null;
    _qtyController =
        TextEditingController();

    if (_isDynamic) {
      _initCardState();
      _initDynamicControllers();
    } else {
      _initLegacyControllers();
    }
  }

  void _initCardState() {
    _cardStateField = CardFormState.buildInitial(
      fieldConfig: _config!,
      existing: widget.material.cardFormState,
    );
  }

  void _initDynamicControllers() {
    if (_config == null) return;
    for (final field in _config!.fields) {
      if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
      final rawValue = _cardState.getValue(field.key);
      _valueControllers[field.key] = TextEditingController(
        text: rawValue != null ? rawValue.toString() : '',
      );
      _labelControllers[field.key] = TextEditingController(
        text: _cardState.getLabel(field.key, field.label),
      );
      _focusNodes[field.key] = FocusNode();
    }
  }

  void _initLegacyControllers() {
    _legacyFocusNodes = {
      PipingFieldType.size: FocusNode(),
      PipingFieldType.length: FocusNode(),
      PipingFieldType.qty: FocusNode(),
    };
    _legacyValueControllers = {
      PipingFieldType.size:
          TextEditingController(text: widget.material.size ?? ''),
      PipingFieldType.length:
          TextEditingController(text: widget.material.length.toString()),
      PipingFieldType.qty:
          TextEditingController(text: widget.material.qty.toString()),
    };
    _legacyLabelControllers = {
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
    final justBecameDynamic = oldWidget.materialSetup == null && widget.materialSetup != null;

    if (oldWidget.material.id != widget.material.id || justBecameDynamic) {
      _disposeControllers();
      _draftMaterial = widget.material;
      _draftImageUrl = widget.material.image.isNotEmpty ? widget.material.image.first : null;
      _qtyController.text = widget.material.qty.toString();
      if (_isDynamic) {
        _initCardState();
        _initDynamicControllers();
      } else {
        _initLegacyControllers();
      }
    } else if (!_isEditMode) {
      _draftMaterial = widget.material;
      _draftImageUrl = widget.material.image.isNotEmpty ? widget.material.image.first : null;

      // Only update QTY controller if it's not currently focused
      if (!_qtyController.value.selection.isValid ||
          _qtyController.value.selection.start == _qtyController.value.selection.end) {
        final newQtyText = widget.material.qty.toString();
        if (_qtyController.text != newQtyText) {
          _qtyController.text = newQtyText;
        }
      }

      if (_isDynamic) {
        // ✅ Sync dynamic controllers when cardFormState changes (e.g., from updateAllSizes)
        final incomingState = widget.material.cardFormState;
        if (incomingState != null) {
          _cardState = incomingState;
          for (final field in _config!.fields) {
            if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
            final controller = _valueControllers[field.key];
            final focusNode = _focusNodes[field.key];
            if (controller != null) {
              final newValue = _cardState.getValue(field.key)?.toString() ?? '';
              // Force update if not focused
              if (controller.text != newValue && (focusNode == null || !focusNode.hasFocus)) {
                debugPrint('✅ Updating controller for ${widget.material.name} - field ${field.key} to $newValue');
                controller.text = newValue;
              }
            }
          }
        }
      } else {
        // same guard for legacy controllers
        final sizeVal = widget.material.size ?? '';
        if (_legacyValueControllers[PipingFieldType.size]?.text != sizeVal &&
            !(_legacyValueControllers[PipingFieldType.size]?.value.selection.isValid ?? false)) {
          _legacyValueControllers[PipingFieldType.size]?.text = sizeVal;
        }
        final lengthVal = widget.material.length.toString();
        if (_legacyValueControllers[PipingFieldType.length]?.text != lengthVal &&
            !(_legacyValueControllers[PipingFieldType.length]?.value.selection.isValid ?? false)) {
          _legacyValueControllers[PipingFieldType.length]?.text = lengthVal;
        }
        _sizeUomController.text = widget.material.sizeUom ?? 'inch';
      }
    }
  }
  void _disposeControllers() {
    for (final c in _valueControllers.values) c.dispose();
    for (final c in _labelControllers.values) c.dispose();
    for (final n in _focusNodes.values) n.dispose();
    _valueControllers.clear();
    _labelControllers.clear();
    _focusNodes.clear();
    if (!_isDynamic) {
      for (final c in _legacyValueControllers.values) c.dispose();
      for (final c in _legacyLabelControllers.values) c.dispose();
      for (final n in _legacyFocusNodes.values) n.dispose();
      _sizeUomController.dispose();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _disposeControllers();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STATE MUTATION
  // ─────────────────────────────────────────────

  void _updateCardState(CardFormState newState) {
    setState(() => _cardState = newState);
    final updated = _draftMaterial.copyWith(cardFormState: newState);
    _draftMaterial = updated;
  }

  void _onFieldValueChanged(String key, dynamic value) =>
      _updateCardState(_cardState.updateValue(key, value));

  void _onUnitChanged(String key, String unit) =>
      _updateCardState(_cardState.updateUnit(key, unit));

  void _onLabelChanged(String key, String label) {
    setState(() {
      _cardState = _cardState.updateLabel(key, label);
      _draftMaterial = _draftMaterial.copyWith(cardFormState: _cardState);
    });
  }

  /// Geometry mode is controlled by field selection, NOT a standalone dropdown.
  /// Switching does NOT clear any field values.
  void _selectGeometryMode(String mode) {
    if (_cardState.geometryMode == mode) return;
    _updateCardState(_cardState.updateGeometryMode(mode));
  }

  // ─────────────────────────────────────────────
  // VISIBILITY
  // ─────────────────────────────────────────────

  bool _isFieldVisible(FieldDefinition field) {
    final vw = field.visibleWhen;
    if (vw == null) return true;
    if (vw.geometryMode != null) {
      return _cardState.geometryMode == vw.geometryMode;
    }
    return true;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: _isLoading ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: _isLoading,
            child: _isDynamic ? _buildDynamicCard() : _buildLegacyCard(),
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // DYNAMIC CARD
  // ─────────────────────────────────────────────

  Widget _buildDynamicCard() {
    final visibleFields = _config!.fields
        .where((f) => _isFieldVisible(f))
        .where((f) => f.role != 'QTY' && f.role != 'QUANTITY')
        .toList();

    final savedImageUrl =
        widget.material.image.isNotEmpty ? widget.material.image.first : null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _focusFirstDynamicField,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: image + action row
                  SizedBox(
                    width: 110,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isEditMode)
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo, size: 13),
                            label: const Text('Change',
                                style: TextStyle(fontSize: 11)),
                          ),
                        _buildSmartImage(
                          imageFile: _isEditMode ? _draftImageFile : null,
                          imageUrl: _isEditMode
                              ? (_draftImageFile == null
                                  ? _draftImageUrl
                                  : null)
                              : savedImageUrl,
                          height: 90,
                          width: 110,
                        ),
                        const Spacer(),
                        const SizedBox(height: 6),
                        _buildActionRow(),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // RIGHT: fields + qty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...visibleFields.map(_buildDynamicFieldRow).toList(),
                        const Spacer(),
                        _buildQtyField(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 8),
              _buildEditActions(),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DYNAMIC FIELD ROW
  //
  // VIEW MODE:
  //   "Size (inch)"   ← plain text label+unit
  //   "12"            ← plain text value
  //
  // EDIT MODE:
  //   "Size"          ← label (editable if allowRename)
  //   [ 12   | inch▼ ]  ← TextField + inline unit dropdown
  // ─────────────────────────────────────────────

  Widget _buildDynamicFieldRow(FieldDefinition field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          _isEditMode ? _buildFieldEditMode(field) : _buildFieldViewMode(field),
    );
  }

  // ── VIEW MODE ─────────────────────────────────

  Widget _buildFieldViewMode(FieldDefinition field) {
    final label = _cardState.getLabel(field.key, field.label);
    final unit = _cardState.getUnit(field.key) ?? _resolveDefaultUnit(field);
    final labelWithUnit =
        (unit != null && unit.isNotEmpty) ? '$label ($unit)' : label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelWithUnit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextFormField(
            controller: _valueControllers[field.key],
            focusNode: _focusNodes[field.key], // Attached focusNode
            readOnly: false, // 🔥 MUST allow typing
            keyboardType: field.type == 'NUMBER'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            onChanged: (v) {
              if (field.type == 'NUMBER') {
                final parsed = num.tryParse(v);
                if (parsed != null) {
                  _onFieldValueChanged(field.key, parsed);
                }
              } else {
                _onFieldValueChanged(field.key, v);
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFD0EAFD), // 🔥 SAME BLUE FIELD
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── EDIT MODE ─────────────────────────────────

  Widget _buildFieldEditMode(FieldDefinition field) {
    final label = _cardState.getLabel(field.key, field.label);
    final currentUnit =
        _cardState.getUnit(field.key) ?? _resolveDefaultUnit(field);

    // Geometry-gated fields show an inline mode selector pill row
    final hasGeometrySiblings =
        _config!.unitDropdowns.geometryMode?.isNotEmpty ?? false;
    final isGeometryGated = field.visibleWhen?.geometryMode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (editable if allowed)
        _config!.ui.allowRename
            ? SizedBox(
                height: 24,
                child: TextFormField(
                  controller: _labelControllers[field.key],
                  decoration: _compactDecoration(
                    fillColor: const Color(0xFFEEF4FF),
                    hint: 'Label',
                  ),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  onChanged: (v) => _onLabelChanged(field.key, v),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),

        const SizedBox(height: 4),

        // Geometry mode pills — inline, attached to this field only
        if (hasGeometrySiblings && isGeometryGated) _buildGeometryPills(field),

        // TextField + unit dropdown in one row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextFormField(
                  controller: _valueControllers[field.key],
                  focusNode: _focusNodes[field.key],
                  textAlign: TextAlign.center,
                  keyboardType: field.type == 'NUMBER'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFD0EAFD),
                    hintText: field.required ? '*' : '',
                    hintStyle:
                        const TextStyle(fontSize: 10, color: Colors.black38),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: Color(0xFF5B8FFF), width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (field.type == 'NUMBER') {
                      final parsed = num.tryParse(v);
                      if (parsed != null)
                        _onFieldValueChanged(field.key, parsed);
                    } else {
                      _onFieldValueChanged(field.key, v);
                    }
                  },
                ),
              ),
            ),

            // Unit dropdown — ONLY in edit mode, ONLY if field.dropdown exists
            if (field.dropdown != null) ...[
              const SizedBox(width: 4),
              _buildInlineUnitDropdown(field, currentUnit),
            ],
          ],
        ),
      ],
    );
  }

  /// Geometry mode pills — inline inside the field, not a standalone widget.
  /// Tapping a pill sets geometry mode WITHOUT clearing any field values.
  Widget _buildGeometryPills(FieldDefinition field) {
    final options = _config!.unitDropdowns.geometryMode ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: options.map((mode) {
          final isSelected = _cardState.geometryMode == mode;
          return GestureDetector(
            onTap: () => _selectGeometryMode(mode),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF5B8FFF) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mode,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Inline unit dropdown — sits next to TextField, only in edit mode.
  Widget _buildInlineUnitDropdown(FieldDefinition field, String? currentUnit) {
    final unitDropdowns = _config!.unitDropdowns.toJson();
    final optionsRaw = unitDropdowns[field.dropdown!];
    if (optionsRaw == null) return const SizedBox.shrink();
    final options = (optionsRaw as List).map((e) => e.toString()).toList();
    if (options.isEmpty) return const SizedBox.shrink();

    final safeValue = (currentUnit != null && options.contains(currentUnit))
        ? currentUnit
        : options.first;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) _onUnitChanged(field.key, v);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // QTY FIELD
  // ─────────────────────────────────────────────

  Widget _buildQtyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qty',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
        SizedBox(
          height: 40,
          child: TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),

              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (v) {
                // Only update draft material locally, don't call widget.onChanged
                setState(() {
                  _draftMaterial = _draftMaterial.copyWith(qty: int.tryParse(v) ?? 0);
                });
              },
              onEditingComplete: () {
                // Save to parent when editing is complete
                widget.onChanged(_draftMaterial);
              },
              style: const TextStyle(fontSize: 25, height: 2),
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
      );
  }
  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: _isEditMode
              ? TextFormField(
                  initialValue: _draftMaterial.name,
                  decoration: _compactDecoration(
                    fillColor: const Color(0xFFD0EAFD),
                    hint: 'Enter Name',
                  ),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  onChanged: (v) => setState(
                      () => _draftMaterial = _draftMaterial.copyWith(name: v)),
                )
              : Tooltip(
                  message: widget.material.name,
                  waitDuration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.material.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onRemark,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD0EAFD),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Remark',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ACTION ROW
  // ─────────────────────────────────────────────

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _actionBtn(Icons.edit, Colors.blue,
              () => setState(() => _isEditMode = !_isEditMode)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _actionBtn(Icons.copy, Colors.green, widget.onAdd),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _actionBtn(Icons.delete_outline, Colors.red, widget.onDelete),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: color,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(4), // Slightly tighter padding to fit well
        minimumSize: const Size(0, 32), // Height fixed, width flexible for Expanded
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EDIT ACTIONS
  // ─────────────────────────────────────────────

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _onSave,
            child: const Text('Save'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            onPressed: _onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      List<String>? newImages;

      if (_draftImageFile != null || _draftMaterial.name != widget.material.name) {
        newImages = await InsulationMaterialSetupService().updateMaterial(
          materialId: widget.material.id,
          name: _draftMaterial.name,
          images: _draftImageFile != null ? [_draftImageFile!] : null,
        );

        // ✅ Write new image URL back to local DB so the card reflects it
        if (newImages.isNotEmpty) {
          await LocalMaterialDao().updateMaterialImage(
            serverId: widget.material.id,
            images: newImages,
          );
        }
      }

      // Propagate updated image list to the draft before notifying parent
      final updatedMaterial = _draftMaterial.copyWith(
        cardFormState: _cardState,
        image: newImages ?? _draftMaterial.image,
      );

      widget.onChanged(updatedMaterial);

      setState(() {
        _isEditMode = false;
        _draftImageFile = null;
        _isLoading = false;
        // ✅ Also update the local draft URL so the card repaints immediately
        // without waiting for the Isar stream to fire
        _draftImageUrl = newImages?.isNotEmpty == true
            ? newImages!.first
            : _draftImageUrl;
      });
    } catch (e) {
      debugPrint('Piping save error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onCancel() {
    setState(() {
      _draftMaterial = widget.material;
      _draftImageFile = null;
      _draftImageUrl =
          widget.material.image.isNotEmpty ? widget.material.image.first : null;
      _isEditMode = false;
      _cardState = widget.material.cardFormState ??
          CardFormState.buildInitial(fieldConfig: _config!);
      for (final field in _config!.fields) {
        if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
        final raw = _cardState.getValue(field.key);
        _valueControllers[field.key]?.text = raw != null ? raw.toString() : '';
        _labelControllers[field.key]?.text =
            _cardState.getLabel(field.key, field.label);
      }
    });
  }

  // ─────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────

  void _focusFirstDynamicField() {
    if (_config == null || _config!.fields.isEmpty) return;

    final visibleFields = _config!.fields
        .where((f) =>
            _isFieldVisible(f) && f.role != 'QTY' && f.role != 'QUANTITY')
        .toList();

    if (visibleFields.isEmpty) return;

    // Prioritize focusing the SIZE field
    final sizeField = visibleFields.firstWhere(
      (f) => f.role == 'SIZE' || f.key.toLowerCase().contains('size'),
      orElse: () => visibleFields.first,
    );

    _focusNodes[sizeField.key]?.requestFocus();
  }

  String? _resolveDefaultUnit(FieldDefinition field) {
    if (field.dropdown == null) return null;
    final defaults = _config!.defaults.toJson();
    final fromDefaults = defaults[field.dropdown!];
    if (fromDefaults != null) return fromDefaults.toString();
    final unitDropdowns = _config!.unitDropdowns.toJson();
    final opts = unitDropdowns[field.dropdown!] as List?;
    if (opts != null && opts.isNotEmpty) return opts.first.toString();
    return null;
  }

  Future<void> _pickImage() async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop Material Image',
    );
    if (file != null) {
      setState(() {
        _draftImageFile = file;
        _draftImageUrl = null;
      });
    }
  }

  InputDecoration _compactDecoration(
      {required Color fillColor, String hint = ''}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fillColor,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // IMAGE HELPERS
  // ─────────────────────────────────────────────

  Widget _buildSmartImage({
    File? imageFile,
    String? imageUrl,
    double height = 100,
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
        loadingBuilder: (_, child, prog) => prog == null
            ? child
            : SizedBox(
                height: height,
                width: width,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
      );
    }
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return Image.file(File(path),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => _imagePlaceholder(height, width));
    }
    return Image.asset(imageUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height, width));
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

  // ─────────────────────────────────────────────
  // LEGACY CARD
  // ─────────────────────────────────────────────

  Widget _buildLegacyCard() {
    final key = _resolveLegacyKey(widget.material.name);
    final fields = pipingFieldConfig[key]!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusLegacyMainField(fields),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 2),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        if (_isEditMode)
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo),
                            label: const Text('Change'),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _legacyActionBtn(
                                Icons.edit,
                                Colors.blue,
                                () =>
                                    setState(() => _isEditMode = !_isEditMode)),
                            const SizedBox(width: 6),
                            _legacyActionBtn(
                                Icons.copy, Colors.green, widget.onAdd),
                            const SizedBox(width: 6),
                            _legacyActionBtn(Icons.delete_outline, Colors.red,
                                widget.onDelete),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                        final hasMain = fields.any((f) =>
                            f.type == PipingFieldType.length ||
                            f.type == PipingFieldType.qty);
                        final otherFields =
                            fields.where((f) => f != mainField).toList();
                        return [
                          ...otherFields.map(_legacyBlueField),
                          if (hasMain) _legacyMainField(mainField),
                        ];
                      }(),
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSaveLegacy,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _draftMaterial = widget.material;
                        _draftImageFile = null;
                        _isEditMode = false;
                      }),
                      child: const Text('Cancel'),
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

  Future<void> _onSaveLegacy() async {
    setState(() => _isLoading = true);
    try {
      if (_draftImageFile != null ||
          _draftMaterial.name != widget.material.name) {
        await InsulationMaterialSetupService().updateMaterial(
          materialId: widget.material.id,
          name: _draftMaterial.name,
          images: _draftImageFile != null ? [_draftImageFile!] : null,
        );
      }
      widget.onChanged(_draftMaterial);
      setState(() {
        _isEditMode = false;
        _draftImageFile = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Piping legacy save error: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _legacyMainField(PipingFieldConfig config) {
    final isDecimal = config.type == PipingFieldType.length;
    final material = _isEditMode ? _draftMaterial : widget.material;
    final labelKey = config.type.name;
    final customLabel = material.customLabels?[labelKey] ?? config.label;
    final qtyUom = material.customLabels?['qty_uom'] ?? config.unit ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isEditMode)
          Text(
            config.type == PipingFieldType.qty
                ? '$customLabel ($qtyUom)'
                : '$customLabel (${config.unit ?? ''})',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        if (_isEditMode) ...[
          SizedBox(
            height: 24,
            child: TextFormField(
              controller: _legacyLabelControllers[config.type],
              decoration: _compactDecoration(
                  fillColor: const Color(0xFFD0EAFD), hint: 'Enter Label'),
              onChanged: (val) {
                final newLabels =
                    Map<String, String>.from(_draftMaterial.customLabels ?? {});
                newLabels[labelKey] = val;
                _draftMaterial =
                    _draftMaterial.copyWith(customLabels: newLabels);
              },
            ),
          ),
          if (config.type == PipingFieldType.qty) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 24,
              child: TextFormField(
                keyboardType: TextInputType.text,
                initialValue: qtyUom,
                decoration: _compactDecoration(
                    fillColor: const Color(0xFFD0EAFD), hint: 'Enter UOM'),
                onChanged: (val) {
                  final newLabels = Map<String, String>.from(
                      _draftMaterial.customLabels ?? {});
                  newLabels['qty_uom'] = val;
                  _draftMaterial =
                      _draftMaterial.copyWith(customLabels: newLabels);
                },
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: _legacyValueControllers[config.type],
          focusNode: _legacyFocusNodes[config.type],
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          onChanged: (val) {
            final parsed =
                isDecimal ? double.tryParse(val) ?? 0 : int.tryParse(val) ?? 0;
            widget.onChanged(_legacyUpdateMaterial(config, parsed));
          },
        ),
      ],
    );
  }

  Widget _legacyBlueField(PipingFieldConfig config) {
    final material = _isEditMode ? _draftMaterial : widget.material;
    final labelKey = config.type.name;
    final customLabel = material.customLabels?[labelKey] ?? config.label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditMode)
            Text(
              config.type == PipingFieldType.size
                  ? '$customLabel (${material.sizeUom ?? 'inch'})'
                  : '$customLabel (${config.unit ?? ''})',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          if (_isEditMode) ...[
            SizedBox(
              height: 22,
              child: TextFormField(
                controller: _legacyLabelControllers[config.type],
                decoration: _compactDecoration(
                    fillColor: const Color(0xFFD0EAFD), hint: 'Enter Label'),
                onChanged: (val) {
                  final newLabels = Map<String, String>.from(
                      _draftMaterial.customLabels ?? {});
                  newLabels[labelKey] = val;
                  _draftMaterial =
                      _draftMaterial.copyWith(customLabels: newLabels);
                },
              ),
            ),
            if (config.type == PipingFieldType.size) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 22,
                child: TextFormField(
                  controller: _sizeUomController,
                  decoration: _compactDecoration(
                      fillColor: const Color(0xFFD0EAFD), hint: 'Enter UOM'),
                  onChanged: (val) {
                    _draftMaterial = _draftMaterial.copyWith(sizeUom: val);
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 4),
          SizedBox(
            height: 24,
            width: 70,
            child: TextFormField(
              controller: _legacyValueControllers[config.type],
              focusNode: _legacyFocusNodes[config.type],
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 11, height: 1),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                filled: true,
                fillColor: Color(0xFFD0EAFD),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                final parsed = config.type == PipingFieldType.length
                    ? double.tryParse(val) ?? 0
                    : int.tryParse(val) ?? 0;
                widget.onChanged(_legacyUpdateMaterial(config, parsed));
              },
            ),
          ),
        ],
      ),
    );
  }

  PipingMaterial _legacyUpdateMaterial(PipingFieldConfig config, num value) {
    switch (config.type) {
      case PipingFieldType.size:
        return widget.material.copyWith(size: value.toString());
      case PipingFieldType.length:
        return widget.material.copyWith(length: value.toDouble());
      case PipingFieldType.qty:
        return widget.material.copyWith(qty: value.toInt());
    }
  }

  Widget _legacyActionBtn(IconData icon, Color color, VoidCallback onTap) {
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

  void _focusLegacyMainField(List<PipingFieldConfig> fields) {
    // Prioritize focusing the SIZE field in legacy mode
    if (fields.any((f) => f.type == PipingFieldType.size)) {
      _legacyFocusNodes[PipingFieldType.size]?.requestFocus();
      return;
    }
    if (fields.any((f) => f.type == PipingFieldType.length)) {
      _legacyFocusNodes[PipingFieldType.length]?.requestFocus();
      return;
    }
    if (fields.any((f) => f.type == PipingFieldType.qty)) {
      _legacyFocusNodes[PipingFieldType.qty]?.requestFocus();
      return;
    }
  }

  String _resolveLegacyKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');
    return pipingFieldConfig.keys.firstWhere(
      (k) => upper.startsWith(k),
      orElse: () => 'DEFAULT',
    );
  }
}
