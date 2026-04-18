// lib/features/modules/all_Modules/dpr/dpr_insu/widgets/piping_card.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../core/utlis/widgets/shimmer.dart';
import '../../offline/data/local/cache_image_dao.dart';
import '../../offline/data/local/local_material_dao.dart';
import '../../utils/image_track/material_image_upload_service.dart';
import '../model/piping_insu.dart';
import '../model/material_setup.dart';
import '../model/field_config.dart';
import '../model/card_form_State.dart';
import '../service/material_service.dart';
import 'config/piping_config.dart';
import 'edit_overlay.dart';

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

  late TextEditingController _qtyController;
  late FocusNode _qtyFocusNode;
  final ValueNotifier<int> _rebuildNotifier = ValueNotifier<int>(0);

  File? _draftImageFile;
  String? _draftImageUrl;

  late Map<PipingFieldType, TextEditingController> _legacyValueControllers;
  late Map<PipingFieldType, TextEditingController> _legacyLabelControllers;
  late Map<PipingFieldType, FocusNode> _legacyFocusNodes;
  late TextEditingController _sizeUomController;

  bool get _isDynamic => widget.materialSetup != null;
  FieldConfig? get _config => widget.materialSetup?.fieldConfig;
  ColorScheme get _cs => Theme.of(context).colorScheme;
  Color get _fieldFill => _cs.surfaceContainerHighest;

  bool get _isAnyInputFocused {
    if (_qtyFocusNode.hasFocus) return true;
    if (_isDynamic) {
      for (final node in _focusNodes.values) {
        if (node.hasFocus) return true;
      }
      return false;
    }

    for (final node in _legacyFocusNodes.values) {
      if (node.hasFocus) return true;
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _draftMaterial = widget.material;
    _draftImageUrl =
        widget.material.image.isNotEmpty ? widget.material.image.first : null;
    final initialQtyText =
        (widget.material.qty > 0) ? widget.material.qty.toString() : '';
    _qtyController = TextEditingController(text: initialQtyText);
    _qtyFocusNode = FocusNode();
    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) {
        widget.onChanged(getLatestMaterial());
      }
    });

    if (_isDynamic) {
      _initCardState();
      _initDynamicControllers();
    } else {
      _initLegacyControllers();
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
    _rebuildNotifier.value++;
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
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (!focusNode.hasFocus) {
          widget.onChanged(getLatestMaterial());
        }
      });
      _focusNodes[field.key] = focusNode;
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
      PipingFieldType.qty: TextEditingController(
          text:
              (widget.material.qty > 0) ? widget.material.qty.toString() : ''),
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
    final justBecameDynamic =
        oldWidget.materialSetup == null && widget.materialSetup != null;

    if (oldWidget.material.id != widget.material.id || justBecameDynamic) {
      _disposeControllers();
      _draftMaterial = widget.material;
      _draftImageUrl =
          widget.material.image.isNotEmpty ? widget.material.image.first : null;

      if (_isDynamic) {
        _initCardState();
        _initDynamicControllers();
      } else {
        _initLegacyControllers();
      }
    } else if (!_isEditMode) {
      if (_isAnyInputFocused) return;

      _draftMaterial = widget.material;
      _draftImageUrl =
          widget.material.image.isNotEmpty ? widget.material.image.first : null;

      // Only update QTY controller when QTY field is not focused.
      if (!_qtyFocusNode.hasFocus) {
        final qty = widget.material.qty;
        final newQtyText = (qty == 0 || qty == null) ? '' : qty.toString();

        if (_qtyController.text != newQtyText) {
          _qtyController.text = newQtyText;
        }
      }

      if (_isDynamic) {
        // ✅ Sync dynamic controllers when cardFormState changes (e.g., from updateAllSizes)
        final incomingState = widget.material.cardFormState;
        if (incomingState != null && _cardState != incomingState) {
          _cardState = incomingState;

          // Only update controllers for fields that have changed AND are not currently focused
          for (final field in _config!.fields) {
            if (field.role == 'QTY' || field.role == 'QUANTITY') continue;

            final controller = _valueControllers[field.key];
            final focusNode = _focusNodes[field.key];

            if (controller != null) {
              final newValue = _cardState.getValue(field.key)?.toString() ?? '';
              final currentValue = controller.text;

              // Only update if:
              // 1. The value has actually changed
              // 2. The field is NOT currently focused (to avoid interrupting user input)
              // 3. The controller text is different from the new value
              if (currentValue != newValue &&
                  (focusNode == null || !focusNode.hasFocus)) {
                debugPrint(
                    '✅ Updating controller for ${widget.material.name} - field ${field.key} from "$currentValue" to "$newValue"');
                controller.text = newValue;
              }
            }
          }
        }
      } else {
        // same guard for legacy controllers
        final sizeVal = widget.material.size ?? '';
        final sizeController = _legacyValueControllers[PipingFieldType.size];
        final sizeFocusNode = _legacyFocusNodes[PipingFieldType.size];
        if (sizeController != null &&
            sizeController.text != sizeVal &&
            (sizeFocusNode == null || !sizeFocusNode.hasFocus)) {
          sizeController.text = sizeVal;
        }

        final lengthVal = widget.material.length.toString();
        final lengthController =
            _legacyValueControllers[PipingFieldType.length];
        final lengthFocusNode = _legacyFocusNodes[PipingFieldType.length];
        if (lengthController != null &&
            lengthController.text != lengthVal &&
            (lengthFocusNode == null || !lengthFocusNode.hasFocus)) {
          lengthController.text = lengthVal;
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
    _qtyFocusNode.dispose();
    _rebuildNotifier.dispose();
    _disposeControllers();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STATE MUTATION
  // ─────────────────────────────────────────────
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
            // Clear focus first
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
            // Clear focus first
            FocusScope.of(ctx).unfocus();
            _onCancel();
            if (ctx.mounted) {
              // Ensure overlay state is cleared before popping
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

        // Wait multiple frames for the overlay to be completely removed from widget tree
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Recreate focus nodes to ensure they're fresh
                _recreateFocusNodes();

                // Add delay to ensure keyboard can be shown
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted && _qtyFocusNode.canRequestFocus) {
                    _qtyFocusNode.requestFocus();
                    // Force keyboard to show
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

// Helper method to recreate focus nodes
  void _recreateFocusNodes() {
    // Dispose old focus nodes
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();

    // Recreate dynamic focus nodes
    if (_isDynamic && _config != null) {
      for (final field in _config!.fields) {
        if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
        _focusNodes[field.key] = FocusNode();
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
      _legacyFocusNodes = {
        PipingFieldType.size: FocusNode(),
        PipingFieldType.length: FocusNode(),
        PipingFieldType.qty: FocusNode(),
      };
    }
  }

// Update _ensureFocusNodesValid method
  void _ensureFocusNodesValid() {
    if (_isDynamic) {
      // Recreate any disposed or invalid focus nodes
      for (final field in _config!.fields) {
        if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
        final node = _focusNodes[field.key];
        if (node == null || !node.canRequestFocus) {
          if (node != null) node.dispose();
          _focusNodes[field.key] = FocusNode();
        }
      }
    }

    // Ensure qty focus node is valid
    if (!_qtyFocusNode.canRequestFocus) {
      _qtyFocusNode.dispose();
      _qtyFocusNode = FocusNode();
    }
  }

  void _updateCardState(CardFormState newState) {
    setState(() => _cardState = newState);
    final updated = _draftMaterial.copyWith(cardFormState: newState);
    _draftMaterial = updated;
    widget.onChanged(updated);
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
    widget.onChanged(_draftMaterial);
  }

  // Add a public method to _PipingMaterialCardState:
  PipingMaterial getLatestMaterial() {
    // Sync qty from controller
    final qty = num.tryParse(_qtyController.text) ?? 0;
    _draftMaterial = _draftMaterial.copyWith(qty: qty);

    // Sync dynamic field values from controllers
    if (_isDynamic && _config != null) {
      CardFormState state = _cardState;
      for (final field in _config!.fields) {
        if (field.role == 'QTY' || field.role == 'QUANTITY') continue;
        final controller = _valueControllers[field.key];
        if (controller == null) continue;
        final text = controller.text;
        if (field.type == 'NUMBER') {
          final parsed = num.tryParse(text);
          if (parsed != null) state = state.updateValue(field.key, parsed);
        } else {
          state = state.updateValue(field.key, text);
        }
      }
      _draftMaterial = _draftMaterial.copyWith(cardFormState: state);
    }

    return _draftMaterial;
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
  // Matches testDynamicItemCard layout exactly:
  // - padding: EdgeInsets.all(2)
  // - No boxShadow
  // - Left col: Expanded + Container(padding: EdgeInsets.all(13))
  // - Right col: Flexible(fit: FlexFit.loose)
  // - Image height: 120
  // ─────────────────────────────────────────────

  Widget _buildDynamicCard() {
    final visibleFields = _config!.fields
        .where((f) => _isFieldVisible(f))
        .where((f) => f.role != 'QTY' && f.role != 'QUANTITY')
        .toList();

    final savedImageUrl =
        widget.material.image.isNotEmpty ? widget.material.image.first : null;

    return GestureDetector(
      behavior: HitTestBehavior
          .opaque, // Changed from translucent to prevent focus stealing from children
      onTap: () {
        print(
            '🖐️ Card tapped - requesting focus on QTY field for ${widget.material.name}');
        if (_qtyFocusNode.canRequestFocus) {
          _qtyFocusNode.requestFocus();
        }
        // Ensure focus works after overlay closes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _qtyFocusNode.canRequestFocus) {
            _qtyFocusNode.requestFocus();
          }
        });
      },
      child: Container(
        // ✅ MATCHES: testDynamicItemCard padding: const EdgeInsets.all(2)
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLow,
          // ✅ MATCHES: testDynamicItemCard has NO boxShadow
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            IntrinsicHeight(
              child: Row(
                children: [
                  // LEFT COLUMN — matches testDynamicItemCard: Expanded + Container(padding: all(13))
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          if (_isEditMode)
                            TextButton.icon(
                              onPressed: _pickImage,
                              // ✅ MATCHES: testDynamicItemCard icon: Icon(Icons.photo), label: Text("Change")
                              icon: const Icon(Icons.photo),
                              label: const Text('Change'),
                            ),
                          // ✅ MATCHES: testDynamicItemCard buildSmartImage height: 120 (default)
                          _buildSmartImage(
                            imageFile: _isEditMode ? _draftImageFile : null,
                            imageUrl: _isEditMode
                                ? (_draftImageFile == null
                                    ? _draftImageUrl
                                    : null)
                                : savedImageUrl,
                            height: 120,
                            width: double.infinity,
                          ),

                          Expanded(child: SizedBox()), // 🔥 force fill

                          // ✅ MATCHES: testDynamicItemCard action row inside left col, after image
                          _buildActionRow(),
                        ],
                      ),
                    ),
                  ),
                  // RIGHT COLUMN — matches testDynamicItemCard: Flexible(fit: FlexFit.loose)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...visibleFields.map(_buildDynamicFieldRow).toList(),

                          Expanded(child: SizedBox()), // 🔥 force fill

                          _buildQtyField(),
                        ],
                      ),
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

  // ─────────────────────────────────────────────
  // DYNAMIC FIELD ROW
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
    final isSizeField =
        field.role == 'SIZE' || field.key.toLowerCase().contains('size');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelWithUnit,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 23,
          width: isSizeField ? 50 : null,
          child: TextFormField(
            controller: _valueControllers[field.key],
            focusNode: _focusNodes[field.key],
            readOnly: false,
            keyboardType: field.type == 'NUMBER'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.normal,
              color: _cs.onSurface,
            ),
            onChanged: (v) {
              if (field.type == 'NUMBER') {
                final parsed = num.tryParse(v);
                if (parsed != null) {
                  _onFieldValueChanged(field.key, parsed);
                  // 🔥 Immediately notify parent to save the change
                }
              } else {
                _onFieldValueChanged(field.key, v);
                // 🔥 Immediately notify parent to save the change
              }
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _fieldFill,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: _cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: _cs.primary, width: 1.5),
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
    final isSizeField =
        field.role == 'SIZE' || field.key.toLowerCase().contains('size');

    final hasGeometrySiblings =
        _config!.unitDropdowns.geometryMode?.isNotEmpty ?? false;
    final isGeometryGated = field.visibleWhen?.geometryMode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _config!.ui.allowRename
            ? SizedBox(
                height: 22,
                child: TextFormField(
                  controller: _labelControllers[field.key],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Add Label',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: _cs.outlineVariant),
                    ),
                  ),
                  style:
                      const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  onChanged: (v) => _onLabelChanged(field.key, v),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
        const SizedBox(height: 4),
        if (hasGeometrySiblings && isGeometryGated) _buildGeometryPills(field),
        Row(
          children: [
            if (isSizeField)
              SizedBox(
                width: 50,
                height: 23,
                child: TextFormField(
                  controller: _valueControllers[field.key],
                  focusNode: _focusNodes[field.key],
                  textAlign: TextAlign.center,
                  keyboardType: field.type == 'NUMBER'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(
                      fontSize: 8, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: _fieldFill,
                    hintText: field.required ? '*' : '',
                    hintStyle:
                        TextStyle(fontSize: 10, color: _cs.onSurfaceVariant),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: _cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: _cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: _cs.primary, width: 2),
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
              )
            else
              Expanded(
                child: SizedBox(
                  height: 23,
                  child: TextFormField(
                    controller: _valueControllers[field.key],
                    focusNode: _focusNodes[field.key],
                    textAlign: TextAlign.center,
                    keyboardType: field.type == 'NUMBER'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.normal),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: _fieldFill,
                      hintText: field.required ? '*' : '',
                      hintStyle:
                          TextStyle(fontSize: 10, color: _cs.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: _cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: _cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: _cs.primary, width: 2),
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
            if (field.dropdown != null) ...[
              const SizedBox(width: 4),
              _buildInlineUnitDropdown(field, currentUnit),
            ],
          ],
        ),
      ],
    );
  }

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
                color: isSelected ? _cs.primary : _cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mode,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _cs.onPrimary : _cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
        color: _cs.surface,
        border: Border.all(color: _cs.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          style: TextStyle(fontSize: 11, color: _cs.onSurface),
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
  // Matches testDynamicItemCard _blueBox(..., isUOM: true):
  // - label fontSize: 14, fontWeight: w600
  // - field height: 60
  // - field fontSize: 14
  // - fillColor: Colors.transparent
  // - border with Colors.grey[300], width: 1, radius: 8
  // - contentPadding: vertical 12, horizontal 8
  // ─────────────────────────────────────────────

  Widget _buildQtyField() {
    final qtyUom = _resolveQtyUom();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            // ✅ MATCHES: testDynamicItemCard _blueBox label format "UOM ( ${widget.lengthPlaceholder} )"
            // For piping, "Qty" is the UOM equivalent label shown with same large style
            'Qty ($qtyUom)',
            style: TextStyle(
              // ✅ MATCHES: testDynamicItemCard isUOM fontSize: 14
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          // ✅ MATCHES: testDynamicItemCard isUOM height: 60
          height: 60,
          child: TextFormField(
            controller: _qtyController,
            focusNode: _qtyFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (v) {
              final newQty = num.tryParse(v) ?? 0;
              debugPrint(
                  '📝 Card Qty Changed: $newQty for ${widget.material.name}');
              setState(() {
                _draftMaterial = _draftMaterial.copyWith(qty: newQty);
              });
              widget.onChanged(_draftMaterial);
            },
            onEditingComplete: () {
              // Save to parent when editing is complete
              widget.onChanged(_draftMaterial);
            },
            style: TextStyle(
              // ✅ MATCHES: testDynamicItemCard isUOM fontSize: 14, fontWeight: w500
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                // ✅ MATCHES: testDynamicItemCard isUOM contentPadding vertical: 12, horizontal: 8
                vertical: 12,
                horizontal: 8,
              ),
              filled: true,
              fillColor: _fieldFill,
              enabledBorder: OutlineInputBorder(
                // ✅ MATCHES: testDynamicItemCard isUOM borderRadius: 8
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  // ✅ MATCHES: testDynamicItemCard isUOM Colors.grey[300], width: 1
                  color: _cs.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _cs.primary, width: 2),
              ),
            ),
          ),
        ),
        if (_isEditMode) ...[
          const SizedBox(height: 4),
          _buildQtyUomDropdown(qtyUom),
        ],
      ],
    );
  }

  FieldDefinition? get _qtyFieldConfig {
    if (_config == null) return null;
    for (final field in _config!.fields) {
      if (field.role == 'QUANTITY' || field.key.toLowerCase() == 'quantity') {
        return field;
      }
    }
    return null;
  }

  String _resolveQtyUom() {
    if (_isDynamic && _config != null) {
      final qtyFieldKey = _qtyFieldConfig?.key;
      if (qtyFieldKey != null) {
        final currentUnit = _cardState.getUnit(qtyFieldKey);
        if (currentUnit != null && currentUnit.isNotEmpty) {
          return currentUnit;
        }
      }

      final defaultQtyUom = _config!.defaults.qtyUom;
      if (defaultQtyUom != null && defaultQtyUom.isNotEmpty) {
        print('🔍 Using default QTY UOM from config: $defaultQtyUom');
        return defaultQtyUom;
      }

      final qtyOptions = _config!.unitDropdowns.qtyUom;
      if (qtyOptions != null && qtyOptions.isNotEmpty) {
        return qtyOptions.first;
      }
    }

    return widget.material.customLabels?['qty_uom'] ??
        widget.material.uom ??
        'NOS';
  }

  Widget _buildQtyUomDropdown(String? currentUnit) {
    final qtyFieldConfig = _qtyFieldConfig;
    if (qtyFieldConfig == null || qtyFieldConfig.dropdown == null) {
      return const SizedBox.shrink();
    }

    final options = _config!.unitDropdowns.optionsFor(qtyFieldConfig.dropdown!);
    if (options.isEmpty) return const SizedBox.shrink();

    final defaultUnit = _config!.defaults.defaultFor(qtyFieldConfig.dropdown!);
    final safeValue = (currentUnit != null && options.contains(currentUnit))
        ? currentUnit
        : (defaultUnit != null && options.contains(defaultUnit)
            ? defaultUnit
            : options.first);

    return Row(
      children: [
        const Text(
          'UOM',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 36,
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
                style: TextStyle(fontSize: 11, color: _cs.onSurface),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _onUnitChanged(qtyFieldConfig.key, v);
                },
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          // ✅ MATCHES: testDynamicItemCard header name container constraints maxWidth: 300
          constraints: const BoxConstraints(maxWidth: 300),
          child: _isEditMode
              ? TextFormField(
                  initialValue: _draftMaterial.name,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  onChanged: (v) => setState(
                      () => _draftMaterial = _draftMaterial.copyWith(name: v)),
                )
              : Text(
                  widget.material.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // ✅ MATCHES: testDynamicItemCard fontSize: 16, fontWeight: w600
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        // AFTER
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
  // Matches testDynamicItemCard: Row of Expanded IconButtons
  // padding: all(6), minimumSize: Size(0, 32)
  // ─────────────────────────────────────────────

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () => _openEditOverlay(context),
            icon: const Icon(Icons.edit, size: 18),
            color: _cs.primary,
            style: IconButton.styleFrom(
              // ✅ MATCHES: testDynamicItemCard padding: all(6), minimumSize: Size(0, 32)
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: _cs.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: IconButton(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.copy, size: 18),
            color: _cs.tertiary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: _cs.tertiary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: _cs.error,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: _cs.error, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // EDIT ACTIONS
  // ─────────────────────────────────────────────

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            // ✅ MATCHES: testDynamicItemCard Cancel is first (left)
            onPressed: _onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _onSave,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      List<String>? newImages;
      // Stage image for batch upload at submit time — no individual API call
      if (_draftImageFile != null) {
        MaterialImageUploadService().stageImage(
          materialId: widget.material.id,
          imageFile: _draftImageFile!,
        );
      }
      try {
        if (_draftImageFile != null ||
            _draftMaterial.name != widget.material.name) {
          newImages = await InsulationMaterialSetupService().updateMaterial(
            materialId: widget.material.id,
            name: _draftMaterial.name,
            images: _draftImageFile != null ? [_draftImageFile!] : null,
          );

          // ✅ Update local DB if images returned
          if (newImages.isNotEmpty) {
            await LocalMaterialDao().updateMaterialImage(
              serverId: widget.material.id,
              images: newImages,
            );
          }
        }
      } catch (e, stackTrace) {
        // 🔴 Log properly (don’t just print in production)
        debugPrint('❌ Error updating material: $e');
        debugPrint('📌 StackTrace: $stackTrace');

        // Optional: Show user feedback (don’t ignore UX)
      }

      // Build updated material with local file path as temporary image URL
      // The real AWS URL will be patched in before DPR submit
      final updatedMaterial = _draftMaterial.copyWith(
        cardFormState: _cardState,
        image: (newImages != null && newImages.isNotEmpty)
            ? newImages // ✅ use server images if available
            : (_draftImageFile != null
                ? [_draftImageFile!.path] // ⚡ fallback to local preview
                : _draftMaterial.image), // 📦 fallback to existing
      );

      widget.onChanged(updatedMaterial);
      print(updatedMaterial.name);
      print("😭😭😭");

      setState(() {
        _isEditMode = false;
        _draftImageFile = null;
        _isLoading = false;
        // _draftImageUrl stays as the file path for display until real URL arrives
        _draftImageUrl = updatedMaterial.image.isNotEmpty
            ? updatedMaterial.image.first
            : null;
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
    // Small delay to ensure any overlay is fully dismissed and focus nodes are ready
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        // Ensure focus node is still valid
        if (!_qtyFocusNode.canRequestFocus) {
          _qtyFocusNode.dispose();
          _qtyFocusNode = FocusNode();
        }
        _qtyFocusNode.requestFocus();
      }
    });
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
      // ✅ Stage for batch upload — no individual API call
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
    double height = 120,
    double width = double.infinity,
    BoxFit fit = BoxFit.contain,
  }) {
    // Priority 1: Use imageFile if provided
    if (imageFile != null) {
      return SizedBox(
        height: height,
        width: width,
        child: Image.file(imageFile, fit: fit),
      );
    }

    // Check if imageUrl is valid
    if (imageUrl == null || imageUrl.isEmpty) {
      return _imagePlaceholder(height, width);
    }

    print('Image URL: $imageUrl');

    // Priority 2: For HTTP/HTTPS URLs, check if we have a cached local version
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return FutureBuilder<String?>(
        future: CachedImageDao().getLocalPath(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerImage(
              height: height,
              width: width,
              borderRadius: 8,
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return SizedBox(
              height: height,
              width: width,
              child: Image.file(
                File(snapshot.data!),
                fit: fit,
                errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
              ),
            );
          }

          return SizedBox(
            height: height,
            width: width,
            child: Image.network(
              imageUrl,
              fit: fit,
              loadingBuilder: (_, child, prog) => prog == null
                  ? child
                  : ShimmerImage(
                      height: height,
                      width: width,
                      borderRadius: 8,
                    ),
              errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
            ),
          );
        },
      );
    }

    // Priority 3: Handle local file paths
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return SizedBox(
        height: height,
        width: width,
        child: Image.file(
          File(path),
          fit: fit,
          errorBuilder: (_, __, ___) => _imagePlaceholder(height, width),
        ),
      );
    }

    // Priority 4: Handle asset images
    return SizedBox(
      height: height,
      width: width,
      child: Image.asset(
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
        // ✅ MATCHES: testDynamicItemCard Colors.grey[200]
        color: _cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        // ✅ MATCHES: testDynamicItemCard Icons.image_not_supported (no _outlined suffix)
        Icons.image_not_supported,
        color: _cs.onSurfaceVariant,
        size: 32,
      ),
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
        // ✅ MATCHES: testDynamicItemCard padding: all(2)
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _cs.surfaceContainerLow,
          // ✅ MATCHES: testDynamicItemCard no boxShadow
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Row(
              children: [
                // LEFT COLUMN — matches testDynamicItemCard: Expanded + Container(padding: all(13))
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        if (_isEditMode)
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo),
                            label: const Text('Change'),
                          ),
                        // ✅ MATCHES: testDynamicItemCard buildSmartImage height: 120 (default)
                        _buildSmartImage(
                          imageFile: _isEditMode ? _draftImageFile : null,
                          imageUrl: _isEditMode
                              ? _draftImageUrl
                              : widget.material.image.isNotEmpty
                                  ? widget.material.image.first
                                  : null,
                          height: 120,
                          width: double.infinity,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: IconButton(
                                  onPressed: () => setState(
                                      () => _isEditMode = !_isEditMode),
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: _cs.primary,
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(
                                        color: _cs.primary, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: IconButton(
                                  onPressed: widget.onAdd,
                                  icon: const Icon(Icons.copy, size: 18),
                                  color: _cs.tertiary,
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(
                                        color: _cs.tertiary, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: IconButton(
                                  onPressed: widget.onDelete,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  color: _cs.error,
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(
                                        color: _cs.error, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
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
                // RIGHT COLUMN — matches testDynamicItemCard: Flexible(fit: FlexFit.loose)
                Flexible(
                  fit: FlexFit.loose,
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
            if (_isEditMode) ...[
              const SizedBox(height: 6),
              Row(
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSaveLegacy,
                      child: const Text('Save'),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              config.type == PipingFieldType.qty
                  ? '$customLabel ($qtyUom)'
                  : '$customLabel (${config.unit ?? ''})',
              style: TextStyle(
                // ✅ MATCHES: testDynamicItemCard _blueBox isUOM fontSize: 14
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cs.onSurface,
              ),
            ),
          ),
        if (_isEditMode) ...[
          SizedBox(
            height: 22,
            child: TextFormField(
              controller: _legacyLabelControllers[config.type],
              textAlign: TextAlign.center,
              decoration: _compactDecoration(
                  fillColor: const Color(0xFFD0EAFD), hint: 'Enter Label'),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
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
            _buildLegacyQtyUomDropdown(qtyUom),
          ],
        ],
        const SizedBox(height: 4),
        SizedBox(
          // ✅ MATCHES: testDynamicItemCard _blueBox isUOM height: 60
          height: 60,
          child: TextFormField(
            controller: _legacyValueControllers[config.type],
            focusNode: _legacyFocusNodes[config.type],
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              // ✅ MATCHES: testDynamicItemCard isUOM fontSize: 14, fontWeight: w500
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _fieldFill,
              border: OutlineInputBorder(
                // ✅ MATCHES: testDynamicItemCard isUOM borderRadius: 8
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _cs.outlineVariant,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                // ✅ MATCHES: testDynamicItemCard isUOM vertical: 12, horizontal: 8
                vertical: 12,
                horizontal: 8,
              ),
            ),
            onChanged: (val) {
              final parsed = isDecimal
                  ? double.tryParse(val) ?? 0
                  : int.tryParse(val) ?? 0;
              widget.onChanged(_legacyUpdateMaterial(config, parsed));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyQtyUomDropdown(String? currentUnit) {
    if (_config == null) {
      return SizedBox(
        height: 22,
        child: TextFormField(
          keyboardType: TextInputType.text,
          initialValue: currentUnit,
          textAlign: TextAlign.center,
          decoration: _compactDecoration(
              fillColor: const Color(0xFFD0EAFD), hint: 'Enter UOM'),
          style: const TextStyle(fontSize: 8),
          onChanged: (val) {
            final newLabels =
                Map<String, String>.from(_draftMaterial.customLabels ?? {});
            newLabels['qty_uom'] = val;
            _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
          },
        ),
      );
    }

    final options = _config!.unitDropdowns.qtyUom ?? [];
    if (options.isEmpty) {
      return SizedBox(
        height: 22,
        child: TextFormField(
          keyboardType: TextInputType.text,
          initialValue: currentUnit,
          textAlign: TextAlign.center,
          decoration: _compactDecoration(
              fillColor: const Color(0xFFD0EAFD), hint: 'Enter UOM'),
          style: const TextStyle(fontSize: 8),
          onChanged: (val) {
            final newLabels =
                Map<String, String>.from(_draftMaterial.customLabels ?? {});
            newLabels['qty_uom'] = val;
            _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
          },
        ),
      );
    }

    final defaultUnit = _config!.defaults.qtyUom;
    final safeValue = (currentUnit != null && options.contains(currentUnit))
        ? currentUnit
        : (defaultUnit != null && options.contains(defaultUnit)
            ? defaultUnit
            : options.first);

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
            if (v == null) return;
            final newLabels =
                Map<String, String>.from(_draftMaterial.customLabels ?? {});
            newLabels['qty_uom'] = v;
            setState(() {
              _draftMaterial = _draftMaterial.copyWith(customLabels: newLabels);
            });
          },
        ),
      ),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                config.type == PipingFieldType.size
                    ? '$customLabel (${material.sizeUom ?? 'inch'})'
                    : '$customLabel (${config.unit ?? ''})',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          if (_isEditMode) ...[
            SizedBox(
              height: 22,
              child: TextFormField(
                controller: _legacyLabelControllers[config.type],
                textAlign: TextAlign.center,
                decoration: _compactDecoration(
                    fillColor: const Color(0xFFD0EAFD), hint: 'Enter Label'),
                style:
                    const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
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
                  textAlign: TextAlign.center,
                  decoration: _compactDecoration(
                      fillColor: const Color(0xFFD0EAFD), hint: 'Enter UOM'),
                  style: const TextStyle(fontSize: 8),
                  onChanged: (val) {
                    _draftMaterial = _draftMaterial.copyWith(sizeUom: val);
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 4),
          SizedBox(
            height: 23,
            width: 50,
            child: TextFormField(
              controller: _legacyValueControllers[config.type],
              focusNode: _legacyFocusNodes[config.type],
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                filled: true,
                fillColor: const Color(0xFFD0EAFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
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
        return _draftMaterial.copyWith(size: value.toString());
      case PipingFieldType.length:
        return _draftMaterial.copyWith(length: value.toDouble());
      case PipingFieldType.qty:
        return _draftMaterial.copyWith(qty: value.toInt());
    }
  }

  void _focusLegacyMainField(List<PipingFieldConfig> fields) {
    _qtyFocusNode.requestFocus();
  }

  String _resolveLegacyKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');
    return pipingFieldConfig.keys.firstWhere(
      (k) => upper.startsWith(k),
      orElse: () => 'DEFAULT',
    );
  }
}
