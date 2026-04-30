// lib/features/modules/all_Modules/dpr/dpr_insu/widgets/equipment_card.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../core/utlis/widgets/shimmer.dart';
import '../../offline/data/local/local_material_dao.dart';
import '../../utils/image_track/material_image_upload_service.dart';
import '../model/eqip_insu.dart';
import '../model/material_setup.dart';
import '../model/field_config.dart';
import '../model/card_form_State.dart';
import '../service/material_service.dart';
import 'config/equipment_config.dart';
import 'edit_overlay.dart';

class EquipmentMaterialCard extends StatefulWidget {
  final EquipmentMaterial material;
  final MaterialSetup? materialSetup;
  final ValueChanged<EquipmentMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRemark;

  const EquipmentMaterialCard({
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
  State<EquipmentMaterialCard> createState() => _EquipmentMaterialCardState();
}

class _EquipmentMaterialCardState extends State<EquipmentMaterialCard> {
  bool _isEditMode = false;
  bool _isLoading = false;
  late EquipmentMaterial _draftMaterial;

  CardFormState? _cardStateField;
  final _imageService = MaterialImageUploadService();

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

  final Map<int, File?> _draftImageFiles = {};

  late TextEditingController _qtyController;
  late FocusNode _qtyFocusNode;
  final ValueNotifier<int> _rebuildNotifier = ValueNotifier<int>(0);

  // Legacy
  late Map<EquipmentFieldType, TextEditingController> _legacyValueControllers;
  late Map<EquipmentFieldType, TextEditingController> _legacyLabelControllers;
  late Map<EquipmentFieldType, TextEditingController> _legacyUomControllers;
  late Map<EquipmentFieldType, FocusNode> _legacyFocusNodes;
  late TextEditingController _legacyQtyController;

  bool get _isDynamic => widget.materialSetup != null;
  FieldConfig? get _config => widget.materialSetup?.fieldConfig;
  ColorScheme get _cs => Theme.of(context).colorScheme;
  Color get _fieldFill => _cs.surfaceContainerHighest;

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _draftMaterial = widget.material;
    final initialQty = (widget.material.qty == null || widget.material.qty == 0)
        ? 1
        : widget.material.qty;
    _qtyController = TextEditingController(text: initialQty.toString());
    _qtyFocusNode = FocusNode();

    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) _flushQtyToParent();
    });

    if (_isDynamic) {
      _initCardState();
      _initDynamicControllers();
    } else {
      _initLegacyControllers(widget.material);
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return; // ← guard against disposed state
    super.setState(fn);
    _rebuildNotifier.value++; // ← mirror to overlay if open
  }

  void _initCardState() {
    _cardStateField = CardFormState.buildInitial(
      fieldConfig: _config!,
      existing: widget.material.cardFormState,
    );
  }

  void _initDynamicControllers() {
    if (_config == null) return;
    final isPatch = widget.material.name.trim().toLowerCase() == 'patch';
    debugPrint(
        '🔍 [${widget.material.name}] Initializing dynamic controllers (isPatch: $isPatch)');
    for (final field in _config!.fields) {
      if (!isPatch && (field.role == 'QUANTITY' || field.role == 'QTY')) {
        continue;
      }
      final raw = _cardState.getValue(field.key);
      debugPrint(
          '   -> Field: ${field.key} (Role: ${field.role}), Value: $raw');
      _valueControllers[field.key] =
          TextEditingController(text: raw != null ? raw.toString() : '');
      _labelControllers[field.key] = TextEditingController(
          text: _cardState.getLabel(field.key, field.label));
      final fn = FocusNode();
      fn.addListener(() {
        if (!fn.hasFocus) {
          widget.onChanged(_draftMaterial.copyWith(cardFormState: _cardState));
        }
      });
      _focusNodes[field.key] = fn;
    }
  }

  void _initLegacyControllers(EquipmentMaterial m) {
    _legacyFocusNodes = {
      for (final t in EquipmentFieldType.values) t: FocusNode(),
    };
    for (final entry in _legacyFocusNodes.entries) {
      final type = entry.key;
      final fn = entry.value;
      fn.addListener(() {
        if (!fn.hasFocus) _flushLegacyFieldToParent(type);
      });
    }

    String tv(double v) => v == 0 ? '' : v.toString();
    _legacyValueControllers = {
      EquipmentFieldType.qty: TextEditingController(text: m.qty.toString()),
      EquipmentFieldType.length: TextEditingController(text: tv(m.length)),
      EquipmentFieldType.circumference:
          TextEditingController(text: tv(m.circumference)),
      EquipmentFieldType.circumference1:
          TextEditingController(text: tv(m.circumference1)),
      EquipmentFieldType.circumference2:
          TextEditingController(text: tv(m.circumference2)),
      EquipmentFieldType.circumference3:
          TextEditingController(text: tv(m.circumference3)),
      EquipmentFieldType.zHeight: TextEditingController(text: tv(m.zHeight)),
      EquipmentFieldType.SlantHeight:
          TextEditingController(text: tv(m.SlantHeight)),
    };
    _legacyLabelControllers = {
      EquipmentFieldType.qty:
          TextEditingController(text: m.customLabels?['qty'] ?? 'Qty'),
      EquipmentFieldType.length:
          TextEditingController(text: m.customLabels?['length'] ?? 'Length'),
      EquipmentFieldType.circumference: TextEditingController(
          text: m.customLabels?['circumference'] ?? 'Circumference'),
      EquipmentFieldType.circumference1: TextEditingController(
          text: m.customLabels?['circumference1'] ?? 'Circumference 1'),
      EquipmentFieldType.circumference2: TextEditingController(
          text: m.customLabels?['circumference2'] ?? 'Circumference 2'),
      EquipmentFieldType.circumference3: TextEditingController(
          text: m.customLabels?['circumference3'] ?? 'Circumference 3'),
      EquipmentFieldType.zHeight:
          TextEditingController(text: m.customLabels?['zHeight'] ?? 'Height'),
      EquipmentFieldType.SlantHeight: TextEditingController(
          text: m.customLabels?['SlantHeight'] ?? 'Slant Height'),
    };
    _legacyUomControllers = {
      EquipmentFieldType.qty:
          TextEditingController(text: m.customLabels?['qty_uom'] ?? 'NOS'),
      EquipmentFieldType.length:
          TextEditingController(text: m.customLabels?['length_uom'] ?? 'mm'),
      EquipmentFieldType.circumference: TextEditingController(
          text: m.customLabels?['circumference_uom'] ?? 'mm'),
      EquipmentFieldType.circumference1: TextEditingController(
          text: m.customLabels?['circumference1_uom'] ?? 'mm'),
      EquipmentFieldType.circumference2: TextEditingController(
          text: m.customLabels?['circumference2_uom'] ?? 'mm'),
      EquipmentFieldType.circumference3: TextEditingController(
          text: m.customLabels?['circumference3_uom'] ?? 'mm'),
      EquipmentFieldType.zHeight:
          TextEditingController(text: m.customLabels?['zHeight_uom'] ?? 'mm'),
      EquipmentFieldType.SlantHeight: TextEditingController(
          text: m.customLabels?['SlantHeight_uom'] ?? 'mm'),
    };
    _legacyQtyController = TextEditingController(text: m.qty.toString());
  }

  // ─────────────────────────────────────────────
  // FLUSH HELPERS
  // ─────────────────────────────────────────────

  void _flushQtyToParent() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    _draftMaterial = _draftMaterial.copyWith(qty: qty);
    widget.onChanged(_draftMaterial);
  }

  void _flushLegacyFieldToParent(EquipmentFieldType type) {
    final text = _legacyValueControllers[type]?.text ?? '';
    final value = double.tryParse(text) ?? 0.0;
    _draftMaterial = _legacyBuildMaterial(type, value);
    widget.onChanged(_draftMaterial);
  }

  /// Reads EVERY controller and syncs into _draftMaterial + _cardState.
  /// Must be called at the top of _onSave so values typed in the last
  /// focused field (whose focus-loss listener hasn't fired yet) are captured.
  void _flushAllControllersToDraft() {
    // 1. qty
    final qty = int.tryParse(_qtyController.text) ?? 0;
    _draftMaterial = _draftMaterial.copyWith(qty: qty);

    if (_isDynamic && _config != null) {
      final isPatch = widget.material.name.trim().toLowerCase() == 'patch';
      // 2. dynamic field values
      var state = _cardState;
      for (final field in _config!.fields) {
        if (!isPatch && (field.role == 'QUANTITY' || field.role == 'QTY')) {
          continue;
        }
        final text = _valueControllers[field.key]?.text ?? '';
        final parsed = num.tryParse(text);

        // IMPORTANT: Update the state even if the value is empty/null
        if (text.isEmpty) {
          state = state.updateValue(field.key, null);
        } else {
          state = state.updateValue(field.key, parsed ?? text);
        }
      }

      // 3. dynamic labels
      for (final field in _config!.fields) {
        if (!isPatch && (field.role == 'QUANTITY' || field.role == 'QTY')) {
          continue;
        }
        final labelText = _labelControllers[field.key]?.text ?? '';
        if (labelText.isNotEmpty) {
          state = state.updateLabel(field.key, labelText);
        }
      }

      _cardStateField = state;
      _draftMaterial = _draftMaterial.copyWith(cardFormState: state);
    } else if (!_isDynamic) {
      // 4. legacy numeric fields
      _draftMaterial = _draftMaterial.copyWith(
        length: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.length]?.text ??
                    '') ??
            _draftMaterial.length,
        circumference: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.circumference]
                        ?.text ??
                    '') ??
            _draftMaterial.circumference,
        circumference1: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.circumference1]
                        ?.text ??
                    '') ??
            _draftMaterial.circumference1,
        circumference2: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.circumference2]
                        ?.text ??
                    '') ??
            _draftMaterial.circumference2,
        circumference3: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.circumference3]
                        ?.text ??
                    '') ??
            _draftMaterial.circumference3,
        zHeight: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.zHeight]?.text ??
                    '') ??
            _draftMaterial.zHeight,
        SlantHeight: double.tryParse(
                _legacyValueControllers[EquipmentFieldType.SlantHeight]?.text ??
                    '') ??
            _draftMaterial.SlantHeight,
        qty: num.tryParse(
                _legacyValueControllers[EquipmentFieldType.qty]?.text ?? '') ??
            _draftMaterial.qty,
      );
      // 5. legacy UOM + label text
      final newLabels =
          Map<String, String>.from(_draftMaterial.customLabels ?? {});
      for (final entry in _legacyUomControllers.entries) {
        final val = entry.value.text;
        if (val.isNotEmpty) newLabels['${entry.key.name}_uom'] = val;
      }
      for (final entry in _legacyLabelControllers.entries) {
        final val = entry.value.text;
        if (val.isNotEmpty) newLabels[entry.key.name] = val;
      }
      _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
    }
  }

  EquipmentMaterial _legacyBuildMaterial(
      EquipmentFieldType type, double value) {
    switch (type) {
      case EquipmentFieldType.qty:
        return _draftMaterial.copyWith(qty: value.toInt());
      case EquipmentFieldType.length:
        return _draftMaterial.copyWith(length: value);
      case EquipmentFieldType.circumference:
        return _draftMaterial.copyWith(circumference: value);
      case EquipmentFieldType.circumference1:
        return _draftMaterial.copyWith(circumference1: value);
      case EquipmentFieldType.circumference2:
        return _draftMaterial.copyWith(circumference2: value);
      case EquipmentFieldType.circumference3:
        return _draftMaterial.copyWith(circumference3: value);
      case EquipmentFieldType.zHeight:
        return _draftMaterial.copyWith(zHeight: value);
      case EquipmentFieldType.SlantHeight:
        return _draftMaterial.copyWith(SlantHeight: value);
    }
  }

  @override
  void didUpdateWidget(covariant EquipmentMaterialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justBecameDynamic =
        oldWidget.materialSetup == null && widget.materialSetup != null;

    if (oldWidget.material.id != widget.material.id || justBecameDynamic) {
      _disposeControllers();
      _draftMaterial = widget.material;
      final updatedQty =
          (widget.material.qty == null || widget.material.qty == 0)
              ? 1
              : widget.material.qty;
      _qtyController.text = updatedQty.toString();
      if (_isDynamic) {
        _initCardState();
        _initDynamicControllers();
      } else {
        _initLegacyControllers(widget.material);
      }
    }
    // NO else-branch — _draftMaterial is the truth while typing.

    // Keep remark in sync when provider updates it, without resetting edits.
    if (oldWidget.material.remarks != widget.material.remarks && !_isEditMode) {
      _draftMaterial =
          _draftMaterial.copyWith(remarks: widget.material.remarks);
    }

    if (_isDynamic && _config != null) {
      final oldMode = oldWidget.material.cardFormState?.geometryMode;
      final newMode = widget.material.cardFormState?.geometryMode;
      if (oldMode != newMode && newMode != null && newMode.isNotEmpty) {
        _cardStateField = CardFormState.buildInitial(
          fieldConfig: _config!,
          existing: widget.material.cardFormState,
        );
        for (final field in _config!.fields) {
          final controller = _valueControllers[field.key];
          if (controller == null) continue;
          final val = _cardState.getValue(field.key);
          controller.text = val?.toString() ?? '';
        }
        setState(() {});
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
      for (final c in _legacyUomControllers.values) c.dispose();
      for (final n in _legacyFocusNodes.values) n.dispose();
      _legacyQtyController.dispose();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    _rebuildNotifier.dispose();
    _disposeControllers();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STATE MUTATION
  // ─────────────────────────────────────────────

  void _updateCardState(CardFormState newState) {
    setState(() => _cardState = newState);
    _draftMaterial = _draftMaterial.copyWith(cardFormState: newState);
    // Do NOT call widget.onChanged here — wait for focus loss or Save
  }

  String? _fieldKeyByRole(String role) {
    if (_config == null) return null;
    for (final field in _config!.fields) {
      if (field.role.toUpperCase() == role.toUpperCase()) return field.key;
    }
    return null;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  void _mirrorDiameterAndCircumferenceValue(
    String changedKey,
    dynamic value,
  ) {
    final diameterKey = _fieldKeyByRole('DIAMETER');
    final circumferenceKey = _fieldKeyByRole('CIRCUMFERENCE');
    if (diameterKey == null || circumferenceKey == null) return;
    if (!_hasValue(value)) return;

    if (changedKey == diameterKey) {
      _cardState = _cardState.updateValue(circumferenceKey, value);
      if (_valueControllers.containsKey(circumferenceKey)) {
        _valueControllers[circumferenceKey]!.text = value.toString();
      }
    } else if (changedKey == circumferenceKey) {
      _cardState = _cardState.updateValue(diameterKey, value);
      if (_valueControllers.containsKey(diameterKey)) {
        _valueControllers[diameterKey]!.text = value.toString();
      }
    }
  }

  void _onFieldValueChanged(String key, dynamic value) {
    final updated = _cardState.updateValue(key, value);
    _updateCardState(updated);
    _mirrorDiameterAndCircumferenceValue(key, value);
  }

  void _onUnitChanged(String key, String unit) {
    // Preserve any in-progress keyboard input before notifying parent.
    _flushAllControllersToDraft();
    _updateCardState(_cardState.updateUnit(key, unit));
    widget.onChanged(_draftMaterial.copyWith(cardFormState: _cardState));
  }

  void _onLabelChanged(String key, String label) {
    setState(() {
      _cardState = _cardState.updateLabel(key, label);
      _draftMaterial = _draftMaterial.copyWith(cardFormState: _cardState);
    });
  }

  void _selectGeometryMode(String mode) {
    if (_cardState.geometryMode == mode) return;
    // Preserve typed values while geometry mode changes visible fields.
    _flushAllControllersToDraft();

    final diameterKey = _fieldKeyByRole('DIAMETER');
    final circumferenceKey = _fieldKeyByRole('CIRCUMFERENCE');
    if (diameterKey != null && circumferenceKey != null) {
      final diameterValue = _cardState.getValue(diameterKey);
      final circumferenceValue = _cardState.getValue(circumferenceKey);

      if (mode.toUpperCase() == 'CIRCUMFERENCE' &&
          !_hasValue(circumferenceValue) &&
          _hasValue(diameterValue)) {
        _cardState = _cardState.updateValue(circumferenceKey, diameterValue);
        _valueControllers[circumferenceKey]?.text = diameterValue.toString();
      }

      if (mode.toUpperCase() == 'DIAMETER' &&
          !_hasValue(diameterValue) &&
          _hasValue(circumferenceValue)) {
        _cardState = _cardState.updateValue(diameterKey, circumferenceValue);
        _valueControllers[diameterKey]?.text = circumferenceValue.toString();
      }
    }

    setState(() {
      _cardState = _cardState.updateGeometryMode(mode);
      _draftMaterial = _draftMaterial.copyWith(cardFormState: _cardState);
    });
    widget.onChanged(_draftMaterial);
  }

  void _openEditOverlay(BuildContext context) {
    if (_isEditMode) return;

    setState(() {
      _isEditMode = true;
      _isLoading = false;
    });

    // CLEAR FOCUS before pushing
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => EditOverlayPage(
          listenable: _rebuildNotifier,
          onSave: () async {
            FocusScope.of(ctx).unfocus();
            await _onSave();
            if (ctx.mounted) {
              // Ensure overlay state is cleared before popping
              await Future.delayed(const Duration(milliseconds: 50));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            }
          },
          onCancel: () {
            FocusScope.of(ctx).unfocus();
            _onCancel();
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
          cardBuilder: (ctx) {
            return _isDynamic ? _buildDynamicCard() : _buildLegacyCard();
          },
        ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    )
        .then((_) {
      if (mounted) {
        // CRITICAL: Set state to mark overlay as closed
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });

        // Force a rebuild to ensure all overlay-related state is cleared
        _rebuildNotifier.value++;

        // Wait multiple frames for the overlay to be completely removed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Recreate focus nodes
                _recreateFocusNodes();

                // Add delay to ensure keyboard can be shown
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted && _qtyFocusNode.canRequestFocus) {
                    _qtyFocusNode.requestFocus();
                    FocusScope.of(context).requestFocus(_qtyFocusNode);
                  }
                });
              }
            });
          });
        });
      }
    });
  }

// Add this helper method to recreate focus nodes
  void _recreateFocusNodes() {
    // Dispose old focus nodes
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();

    // Recreate dynamic focus nodes
    if (_isDynamic && _config != null) {
      final isPatch = widget.material.name.trim().toLowerCase() == 'patch';
      for (final field in _config!.fields) {
        if (!isPatch && (field.role == 'QUANTITY' || field.role == 'QTY')) {
          continue;
        }
        final fn = FocusNode();
        fn.addListener(() {
          if (!fn.hasFocus) {
            widget
                .onChanged(_draftMaterial.copyWith(cardFormState: _cardState));
          }
        });
        _focusNodes[field.key] = fn;
      }
    }

    // Recreate qty focus node
    _qtyFocusNode.dispose();
    _qtyFocusNode = FocusNode();

    // Recreate legacy focus nodes if needed
    if (!_isDynamic) {
      for (final node in _legacyFocusNodes.values) {
        node.dispose();
      }
      _legacyFocusNodes.clear();
      for (final type in EquipmentFieldType.values) {
        final fn = FocusNode();
        fn.addListener(() {
          if (!fn.hasFocus) _flushLegacyFieldToParent(type);
        });
        _legacyFocusNodes[type] = fn;
      }
    }
  }

// Add this helper to ensure focus nodes are valid
  void _ensureFocusNodesValid() {
    if (_isDynamic) {
      final isPatch = widget.material.name.trim().toLowerCase() == 'patch';
      // Recreate any disposed or invalid focus nodes
      for (final field in _config!.fields) {
        if (!isPatch && (field.role == 'QUANTITY' || field.role == 'QTY')) {
          continue;
        }
        final node = _focusNodes[field.key];
        if (node == null || !node.canRequestFocus) {
          if (node != null) node.dispose();
          final fn = FocusNode();
          fn.addListener(() {
            if (!fn.hasFocus) {
              widget.onChanged(
                  _draftMaterial.copyWith(cardFormState: _cardState));
            }
          });
          _focusNodes[field.key] = fn;
        }
      }
    }

    // Ensure qty focus node is valid
    if (!_qtyFocusNode.canRequestFocus) {
      _qtyFocusNode.dispose();
      _qtyFocusNode = FocusNode();
    }
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

  // Add this method to _EquipmentMaterialCardState class
  EquipmentMaterial getLatestMaterial() {
    _flushAllControllersToDraft();
    return _draftMaterial;
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
            child: ShimmerList(
              type: ShimmerListType.card,
              itemCount: 1,
              scrollable: false,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // DYNAMIC CARD
  // ─────────────────────────────────────────────

  // Widget _buildDynamicCard() {
  //   final fields = _config!.fields
  //       .where((f) => _isFieldVisible(f))
  //       .where((f) => f.role != 'QUANTITY' && f.role != 'QTY')
  //       .toList();
  //
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 8),
  //     padding: const EdgeInsets.all(10),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(14),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildHeader(),
  //         const SizedBox(height: 8),
  //         ...fields.map(_buildDynamicFieldCard),
  //         const SizedBox(height: 8),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           crossAxisAlignment: CrossAxisAlignment.end,
  //           children: [
  //             _buildActionRow(),
  //             _buildQtyField(),
  //           ],
  //         ),
  //         if (_isEditMode) ...[
  //           const SizedBox(height: 8),
  //           _buildEditActions(),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDynamicCard() {
    // First get ALL fields (including invisible ones to maintain indices)
    final allFields = _config!.fields;

    final isPatch = widget.material.name.trim().toLowerCase() == 'patch';

    final visibleFields = allFields.where((f) {
      if (!_isFieldVisible(f)) return false;

      // Only remove quantity if NOT patch
      if (!isPatch && (f.role == 'QUANTITY' || f.role == 'QTY')) {
        return false;
      }

      return true;
    }).toList();
    // Create a mapping from original index to visible index
    final Map<int, int> originalToVisibleIndex = {};
    for (int i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final visibleIndex = visibleFields.indexWhere((f) => f.key == field.key);
      if (visibleIndex != -1) {
        originalToVisibleIndex[i] = visibleIndex;
      }
    }

    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("🏗️ Building card for: ${widget.material.name}");
    debugPrint("📸 Total images in material: ${widget.material.image.length}");
    for (int i = 0; i < widget.material.image.length; i++) {
      debugPrint("   Image[$i]: ${widget.material.image[i]}");
    }
    debugPrint(
        "📋 Total fields: ${allFields.length}, Visible fields: ${visibleFields.length}");
    for (int i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final visibleIndex = originalToVisibleIndex[i];
      debugPrint(
          "   Field[$i]: ${field.label} (${field.role}) - Visible: ${visibleIndex != null ? "Yes (visible index $visibleIndex)" : "No"}");
    }
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Changed from translucent
      onTap: () {
        _qtyFocusNode.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: _cs.shadow.withOpacity(0.08),
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
            ...visibleFields
                .map((field) => _buildDynamicFieldCard(field, allFields)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActionRow(),
                if (!isPatch) _buildQtyField(),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Update _buildDynamicFieldCard to accept allFields parameter
  Widget _buildDynamicFieldCard(
      FieldDefinition field, List<FieldDefinition> allFields) {
    // Get the original index in the full fields list
    final originalIndex = allFields.indexWhere((f) => f.key == field.key);
    final isPatch = widget.material.name.trim().toLowerCase() ==
        'patch'; // or however you identify it

    final visibleFields = _config!.fields.where((f) {
      if (!_isFieldVisible(f)) return false;

      // Only exclude quantity if NOT patch
      if (!isPatch && (f.role == 'QUANTITY' || f.role == 'QTY')) {
        return false;
      }

      return true;
    }).toList();

    // Get the visible index (position in visible fields list)
    final visibleIndex = visibleFields.indexWhere((f) => f.key == field.key);

    // Use visible index for image URL
    final imageUrl =
        visibleIndex >= 0 && visibleIndex < widget.material.image.length
            ? widget.material.image[visibleIndex]
            : null;

    debugPrint(
        "🔍 [${widget.material.name}] Field: ${field.label} (${field.role}) - Original Index: $originalIndex, Visible Index: $visibleIndex - Image URL: ${imageUrl ?? 'null'}");

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNodes[field.key]?.requestFocus(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLowest,
          border: Border.all(color: _cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: () =>
                          _pickImageForField(visibleIndex), // Use visible index
                      icon: const Icon(Icons.photo, size: 13),
                      label:
                          const Text('Change', style: TextStyle(fontSize: 11)),
                    ),
                  _buildSmartImage(
                    imageFile: _isEditMode
                        ? _draftImageFiles[visibleIndex]
                        : null, // Use visible index
                    imageUrl: _isEditMode
                        ? (_draftImageFiles[visibleIndex] == null
                            ? imageUrl
                            : null)
                        : imageUrl,
                    height: 80,
                  ),
                  const SizedBox(height: 6),
                  _buildFieldLabel(field),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _isEditMode
                  ? _buildFieldEditRight(field)
                  : _buildFieldViewRight(field),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldViewRight(FieldDefinition field) {
    final hasUnitDropdown =
        field.dropdown != null && field.dropdown != 'geometryMode';
    final unit = hasUnitDropdown
        ? (_cardState.getUnit(field.key) ?? _resolveDefaultUnit(field))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unit != null) ...[
          Text(unit,
              style: TextStyle(
                  fontSize: 10,
                  color: _cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: _valueControllers[field.key],
            focusNode: _focusNodes[field.key],
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: field.type == 'NUMBER'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldFill,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.primary, width: 1.5),
              ),
            ),
            onChanged: (v) {
              final parsed = num.tryParse(v);
              _onFieldValueChanged(field.key, parsed ?? v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldEditRight(FieldDefinition field) {
    final currentUnit =
        _cardState.getUnit(field.key) ?? _resolveDefaultUnit(field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentUnit != null) ...[
          Text(currentUnit,
              style: TextStyle(
                  fontSize: 10,
                  color: _cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextFormField(
                  controller: _valueControllers[field.key],
                  focusNode: _focusNodes[field.key],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: field.type == 'NUMBER'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _fieldFill,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: _cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: _cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: _cs.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    _onFieldValueChanged(field.key, parsed ?? v);
                  },
                ),
              ),
            ),
            if (field.dropdown != null && field.dropdown != 'geometryMode') ...[
              const SizedBox(width: 4),
              _buildInlineUnitDropdown(field, currentUnit),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(FieldDefinition field) {
    final isPatch = widget.material.name.trim().toLowerCase() == 'patch';
    final label = _cardState.getLabel(field.key, field.label);
    final isGeometry = field.visibleWhen?.geometryMode != null;
    return Column(
      children: [
        if (_isEditMode && _config!.ui.allowRename && !isGeometry)
          SizedBox(
            height: 28,
            child: TextFormField(
              controller: _labelControllers[field.key],
              textAlign: TextAlign.center,
              decoration:
                  _compactDecoration(fillColor: _fieldFill, hint: 'Label'),
              onChanged: (v) => _onLabelChanged(field.key, v),
            ),
          )
        else
          Text(
            isPatch ? 'Patch' : label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        if (isGeometry) ...[
          const SizedBox(height: 4),
          if (_isEditMode)
            _buildInlineUnitDropdown(field, _cardState.geometryMode,
                forceGeometry: true),
        ],
      ],
    );
  }

  Widget _buildInlineUnitDropdown(
    FieldDefinition field,
    String? currentUnit, {
    bool forceGeometry = false,
  }) {
    final unitDropdowns = _config!.unitDropdowns.toJson();
    final dropdownKey = forceGeometry ? 'geometryMode' : field.dropdown;
    if (dropdownKey == null) return const SizedBox.shrink();

    final optionsRaw = unitDropdowns[dropdownKey];
    if (optionsRaw == null) return const SizedBox.shrink();

    final options = (optionsRaw as List).map((e) => e.toString()).toList();
    if (options.isEmpty) return const SizedBox.shrink();

    final safeValue = (currentUnit != null && options.contains(currentUnit))
        ? currentUnit
        : options.first;
    debugPrint(
        '🔧 Dropdown for ${field.key}: dropdownKey=${field.dropdown}, optionsRaw=$optionsRaw');

    return Container(
      height: 36,
      width:
          110, // Added fixed width to prevent overflow and ensure space for arrow
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _cs.surface,
        border: Border.all(color: _cs.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          isExpanded: true, // Allow content to use available space
          style: TextStyle(fontSize: 11, color: _cs.onSurface),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            if (forceGeometry) {
              _selectGeometryMode(v);
            } else {
              _onUnitChanged(field.key, v);
            }
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // QTY FIELD
  // ─────────────────────────────────────────────

  Widget _buildQtyField() {
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qty',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: _qtyController,
              focusNode: _qtyFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (v) {
                final qty = int.tryParse(v) ?? 0;
                _draftMaterial = _draftMaterial.copyWith(qty: qty);
              },
              onEditingComplete: () {
                _flushQtyToParent();
                FocusScope.of(context).unfocus();
              },
              style: const TextStyle(fontSize: 16, height: 1.5),
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: _cs.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _cs.primary, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
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
                    fillColor: _fieldFill,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: widget.onRemark,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  border: Border.all(
                    color: _cs.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      (widget.material.remarks != null &&
                              widget.material.remarks!.isNotEmpty)
                          ? widget.material.remarks
                          : "remarks",
                      style: TextStyle(
                        fontSize: 8,
                        color: _cs.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ACTION ROW
  // ─────────────────────────────────────────────

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _actionBtn(Icons.edit, _cs.primary, () => _openEditOverlay(context)),
        const SizedBox(width: 6),
        _actionBtn(Icons.copy, _cs.tertiary, widget.onAdd),
        const SizedBox(width: 6),
        _actionBtn(Icons.delete_outline, _cs.error, widget.onDelete),
      ],
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

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      _flushAllControllersToDraft();

      final hasImageChange = _draftImageFiles.values.any((f) => f != null);
      final hasNameChange = _draftMaterial.name != widget.material.name;

      // Stage all draft images for batch upload at DPR submit time
      if (hasImageChange) {
        for (final file in _draftImageFiles.values.whereType<File>()) {
          _imageService.stageImage(
            materialId: widget.material.id,
            imageFile: file,
          );
        }
      }

      List<String>? newImages;

      try {
        if (hasImageChange || hasNameChange) {
          newImages = await InsulationMaterialSetupService().updateMaterial(
            materialId: widget.material.id,
            name: _draftMaterial.name,
            images: hasImageChange
                ? _draftImageFiles.values.whereType<File>().toList()
                : null,
          );

          if (newImages.isNotEmpty) {
            await LocalMaterialDao().updateMaterialImage(
              serverId: widget.material.id,
              images: newImages,
            );
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error updating equipment material: $e');
        debugPrint('📌 StackTrace: $stackTrace');
      }

      // Build local image previews for fields that have draft files
      final previewImages = List<String>.from(
        _draftMaterial.image.isNotEmpty
            ? _draftMaterial.image
            : List.filled(widget.material.image.length, ''),
      );
      if (hasImageChange) {
        _draftImageFiles.forEach((index, file) {
          if (file != null) {
            if (index < previewImages.length) {
              previewImages[index] = file.path;
            } else {
              // Pad if needed
              while (previewImages.length <= index) {
                previewImages.add('');
              }
              previewImages[index] = file.path;
            }
          }
        });
      }

      final updatedMaterial = _draftMaterial.copyWith(
        image: (newImages != null && newImages.isNotEmpty)
            ? newImages // ✅ server URLs if upload succeeded
            : hasImageChange
                ? previewImages // ⚡ local file paths as preview
                : _draftMaterial.image, // 📦 unchanged
      );

      widget.onChanged(updatedMaterial);

      setState(() {
        _isEditMode = false;
        _draftImageFiles.clear();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Equipment save error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onCancel() {
    setState(() {
      _draftMaterial = widget.material;
      _draftImageFiles.clear();
      _isEditMode = false;
      final cancelQty =
          (widget.material.qty == null || widget.material.qty == 0)
              ? 1
              : widget.material.qty;
      _qtyController.text = cancelQty.toString();
      if (_isDynamic) {
        _cardState = widget.material.cardFormState ??
            CardFormState.buildInitial(fieldConfig: _config!);
        for (final field in _config!.fields) {
          if (field.role == 'QUANTITY' || field.role == 'QTY') continue;
          final raw = _cardState.getValue(field.key);
          _valueControllers[field.key]?.text =
              raw != null ? raw.toString() : '';
          _labelControllers[field.key]?.text =
              _cardState.getLabel(field.key, field.label);
        }
      } else {
        _legacyValueControllers[EquipmentFieldType.length]?.text =
            widget.material.length == 0
                ? ''
                : widget.material.length.toString();
        _legacyValueControllers[EquipmentFieldType.circumference]?.text =
            widget.material.circumference == 0
                ? ''
                : widget.material.circumference.toString();
        _legacyValueControllers[EquipmentFieldType.circumference1]?.text =
            widget.material.circumference1 == 0
                ? ''
                : widget.material.circumference1.toString();
        _legacyValueControllers[EquipmentFieldType.circumference2]?.text =
            widget.material.circumference2 == 0
                ? ''
                : widget.material.circumference2.toString();
        _legacyValueControllers[EquipmentFieldType.circumference3]?.text =
            widget.material.circumference3 == 0
                ? ''
                : widget.material.circumference3.toString();
        _legacyValueControllers[EquipmentFieldType.zHeight]?.text =
            widget.material.zHeight == 0
                ? ''
                : widget.material.zHeight.toString();
        _legacyValueControllers[EquipmentFieldType.SlantHeight]?.text =
            widget.material.SlantHeight == 0
                ? ''
                : widget.material.SlantHeight.toString();
        _legacyValueControllers[EquipmentFieldType.qty]?.text =
            widget.material.qty.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────

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

  int _imageIndexForRole(String role) {
    const roleMap = {
      'LENGTH': 0,
      'CIRCUMFERENCE': 0,
      'DIAMETER': 0,
      'AREA': 0,
      'Z_HEIGHT': 1,
      'slant_height': 1,
      'CIRCUMFERENCE_1': 1,
      'CIRCUMFERENCE_2': 2,
      'CIRCUMFERENCE_3': 3,
    };
    return roleMap[role] ?? 0;
  }

  Future<void> _pickImageForField(int fieldIndex) async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop Image',
    );
    if (file != null) {
      setState(() => _draftImageFiles[fieldIndex] = file);
      _imageService.stageImage(
        materialId: widget.material.id,
        imageFile: file,
      );
    }
  }

  InputDecoration _compactDecoration(
      {required Color fillColor, String hint = ''}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fillColor,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: _cs.onSurfaceVariant),
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

    // ✅ Add debug print to see what's being passed
    debugPrint("🖼️ Displaying image: $imageUrl");

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (_, child, prog) => prog == null
            ? child
            : ShimmerImage(
                height: height,
                width: width,
                borderRadius: 8,
              ),
        errorBuilder: (_, __, ___) {
          debugPrint("❌ Failed to load network image: $imageUrl");
          return _imagePlaceholder(height, width);
        },
      );
    }

    // Handle local file paths
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      debugPrint("📁 Loading local file: $path");
      return Image.file(
        File(path),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) {
          debugPrint("❌ Failed to load local file: $path");
          return _imagePlaceholder(height, width);
        },
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
        color: _cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported_outlined,
          color: _cs.onSurfaceVariant, size: 32),
    );
  }

  // ─────────────────────────────────────────────
  // LEGACY CARD
  // ─────────────────────────────────────────────

  Widget _buildLegacyCard() {
    final configKey = _resolveLegacyKey(widget.material.name);
    final fields = equipmentFieldConfig[configKey]!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Changed from translucent
      onTap: () {
        _legacyFocusNodes[EquipmentFieldType.qty]?.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            ...fields.map((f) => _legacyFieldCard(
                  field: f,
                  fields: fields, // Pass the fields list
                )),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActionRow(),
                _buildQtyField(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legacyFieldCard({
    required EquipmentFieldConfig field,
    required List<EquipmentFieldConfig> fields, // Add this parameter
  }) {
    // Get the actual index of this field in the fields list
    final fieldIndex = fields.indexOf(field);
    final imageUrl =
        fieldIndex >= 0 && fieldIndex < widget.material.image.length
            ? widget.material.image[fieldIndex]
            : null;

    final labelKey = field.type.name;
    final material = _isEditMode ? _draftMaterial : widget.material;
    final customLabel = material.customLabels?[labelKey] ?? field.label;
    final uomKey = '${labelKey}_uom';
    final customUom = material.customLabels?[uomKey] ??
        (field.type == EquipmentFieldType.qty ? 'NOS' : 'mm');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _legacyFocusNodes[field.type]?.requestFocus(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLowest,
          border: Border.all(color: _cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSmartImage(imageUrl: imageUrl, height: 80),
                  const SizedBox(height: 6),
                  Text(
                    customLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _isEditMode
                  ? _buildLegacyFieldEdit(field, customUom)
                  : _buildLegacyFieldView(field, customUom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyFieldView(EquipmentFieldConfig field, String uom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(uom,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: _legacyValueControllers[field.type],
            focusNode: _legacyFocusNodes[field.type],
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldFill,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _cs.primary, width: 1.5),
              ),
            ),
            onChanged: (v) {
              final val = double.tryParse(v) ?? 0;
              _draftMaterial = _legacyBuildMaterial(field.type, val);
            },
          ),
        ),
      ],
    );
  }

  String _legacyDisplayValue(EquipmentFieldConfig field) {
    final m = widget.material;
    double v;
    switch (field.type) {
      case EquipmentFieldType.qty:
        return m.qty.toString();
      case EquipmentFieldType.length:
        v = m.length;
        break;
      case EquipmentFieldType.circumference:
        v = m.circumference;
        break;
      case EquipmentFieldType.circumference1:
        v = m.circumference1;
        break;
      case EquipmentFieldType.circumference2:
        v = m.circumference2;
        break;
      case EquipmentFieldType.circumference3:
        v = m.circumference3;
        break;
      case EquipmentFieldType.zHeight:
        v = m.zHeight;
        break;
      case EquipmentFieldType.SlantHeight:
        v = m.SlantHeight;
        break;
    }
    return v == 0 ? '—' : v.toString();
  }

  Widget _buildLegacyFieldEdit(EquipmentFieldConfig field, String currentUom) {
    final labelKey = field.type.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: TextFormField(
            controller: _legacyUomControllers[field.type],
            decoration: _compactDecoration(fillColor: _fieldFill, hint: 'Unit'),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final newLabels =
                  Map<String, String>.from(_draftMaterial.customLabels ?? {});
              newLabels['${labelKey}_uom'] = val;
              _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
            },
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _legacyValueControllers[field.type],
          focusNode: _legacyFocusNodes[field.type],
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _cs.primary, width: 1.5),
            ),
          ),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0;
            _draftMaterial = _legacyBuildMaterial(field.type, val);
          },
        ),
      ],
    );
  }

  EquipmentMaterial _legacyUpdateMaterial(
          EquipmentFieldConfig config, double value) =>
      _legacyBuildMaterial(config.type, value);

  void _focusLegacyMainField(List<EquipmentFieldConfig> fields) {
    if (!_isEditMode) return;
    const order = [
      EquipmentFieldType.length,
      EquipmentFieldType.qty,
      EquipmentFieldType.zHeight,
      EquipmentFieldType.circumference,
    ];
    for (final t in order) {
      if (fields.any((f) => f.type == t)) {
        _legacyFocusNodes[t]?.requestFocus();
        return;
      }
    }
  }

  String _resolveLegacyKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');
    if (equipmentFieldConfig.containsKey(upper)) return upper;
    for (final key in equipmentFieldConfig.keys) {
      if (upper.startsWith(key)) return key;
    }
    return 'DEFAULT';
  }
}
