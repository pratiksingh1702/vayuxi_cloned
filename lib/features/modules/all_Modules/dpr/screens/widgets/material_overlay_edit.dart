import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/test_dynamic.dart';

import '../../models/dprModel.dart';
import '../../models/equipmentModel.dart';
import '../../models/pipingModel.dart';

import 'calculation/cat_wrapper.dart';
import 'dynamic_item_card2.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point helpers — call these instead of setting editingMaterialId inline
// ─────────────────────────────────────────────────────────────────────────────

Future<MaterialEditResult?> showPipingEditOverlay({
  required BuildContext context,
  required PipingItem material,
  required String? rateUploadId,
  required String siteId,
}) {
  return showGeneralDialog<MaterialEditResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent, // we paint our own
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => _MaterialEditOverlay.piping(
      material: material,
      rateUploadId: rateUploadId,
      siteId: siteId,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<MaterialEditResult?> showEquipmentEditOverlay({
  required BuildContext context,
  required EquipmentItem material,
  required String? rateUploadId,
  required String siteId,
}) {
  return showGeneralDialog<MaterialEditResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => _MaterialEditOverlay.equipment(
      material: material,
      rateUploadId: rateUploadId,
      siteId: siteId,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal overlay widget
// ─────────────────────────────────────────────────────────────────────────────

enum _MaterialType { piping, equipment }

class _MaterialEditOverlay extends StatefulWidget {
  final _MaterialType type;
  final PipingItem? pipingMaterial;
  final EquipmentItem? equipmentMaterial;
  final String? rateUploadId;
  final String siteId;

  const _MaterialEditOverlay._({
    required this.type,
    this.pipingMaterial,
    this.equipmentMaterial,
    required this.rateUploadId,
    required this.siteId,
  });

  factory _MaterialEditOverlay.piping({
    required PipingItem material,
    required String? rateUploadId,
    required String siteId,
  }) =>
      _MaterialEditOverlay._(
        type: _MaterialType.piping,
        pipingMaterial: material,
        rateUploadId: rateUploadId,
        siteId: siteId,
      );

  factory _MaterialEditOverlay.equipment({
    required EquipmentItem material,
    required String? rateUploadId,
    required String siteId,
  }) =>
      _MaterialEditOverlay._(
        type: _MaterialType.equipment,
        equipmentMaterial: material,
        rateUploadId: rateUploadId,
        siteId: siteId,
      );

  @override
  State<_MaterialEditOverlay> createState() => _MaterialEditOverlayState();
}

class _MaterialEditOverlayState extends State<_MaterialEditOverlay> {
  // Draft category — mirrors draftCategoryId in AllMaterialsScreen
  String? _draftCategoryId;

  // Captured result from the inner card's onSave
  MaterialEditResult? _pendingResult;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draftCategoryId = widget.type == _MaterialType.piping
        ? widget.pipingMaterial!.calculationCategory
        : widget.equipmentMaterial!.calculationCategory;
  }

  void _cancel() => Navigator.of(context).pop(null);

  void _save() {
    if (_pendingResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap "Save" inside the card first to confirm changes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      MaterialEditResult(
        name: _pendingResult!.name,
        imageFile: _pendingResult!.imageFile,
        imageUrl: _pendingResult!.imageUrl,
        uom: _pendingResult!.uom,
        fields: _pendingResult!.fields,
        categoryId: _draftCategoryId,  // ← carries selected category back
      ),
    );
  }
  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Blurred + dimmed background ──────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: _cancel, // tap outside to cancel
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
            ),
          ),

          // ── Scrollable content + fixed bottom bar ────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top handle + label ──────────────────────────────────────

                // ── Scrollable card + category ────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card in edit mode
                        _buildEditableCard(),

                        const SizedBox(height: 20),

                        // ── Calculation category section ──────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calculate_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Calculation Category",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              MaterialCategoryWrapper(
                                categoryId: _draftCategoryId,
                                isEditMode: true,
                                onChanged: (id) =>
                                    setState(() => _draftCategoryId = id),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // breathing room above FAB
                      ],
                    ),
                  ),
                ),

                // ── Fixed bottom action bar ───────────────────────────────
                _BottomActionBar(
                  isSaving: _isSaving,
                  hasChanges: _pendingResult != null,
                  onCancel: _cancel,
                  onSave: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard() {
    if (widget.type == _MaterialType.piping) {
      final m = widget.pipingMaterial!;
      return testDynamicItemCard(
        key: ValueKey('overlay_piping_${m.id}'),
        isDpr: false,
        image: m.image,
        lengthLabel: m.materialName,
        lengthPlaceholder: m.uom,
        fields: m.dynamicFields,
        isEditable: true,
        isEditMode: true,
        onCancel: _cancel,
        onSave: (result) {
          // Capture result but don't close — user must tap the bottom Save
          setState(() => _pendingResult = result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes staged — tap Save to apply'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onChanged: (_, __) {},
        quantity: '',
        size: '',
        length: '',
        floor: '',
        moc: '',
        sizeLabel: '',
        sizePlaceholder: '',
        onQtyChanged: (_) {},
        onSizeChanged: (_) {},
        onLengthChanged: (_) {},
        onFloorChanged: (_) {},
        onMocChanged: (_) {},
        onRemark: () {},
      );
    } else {
      final m = widget.equipmentMaterial!;
      return DynamicItemCard2(
        key: ValueKey('overlay_equipment_${m.id}'),
        isDpr: false,
        image: m.image ?? '',
        title: m.materialName,
        quantity: m.qty.toString(),
        moc: m.moc,
        fields: m.dynamicFields,
        isEditMode: true,
        isEditable: true,
        onCancel: _cancel,
        onSave: (result) {
          setState(() => _pendingResult = result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes staged — tap Save to apply'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onChanged: (_, __) {},
        floor: '',
        ton: m.weight.toString(),
        meter: m.length.toString(),
        onQtyChanged: (_) {},
        onTonChanged: (_) {},
        onFloorChanged: (_) {},
        onMocChanged: (_) {},
        onMeterChanged: (_) {},
        onRemark: () {},
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixed bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _BottomActionBar({
    required this.isSaving,
    required this.hasChanges,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Save
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasChanges
                    ? const Color(0xFF218AE6)
                    : Colors.grey.shade300,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasChanges
                        ? Icons.check_circle_rounded
                        : Icons.edit_outlined,
                    size: 16,
                    color: hasChanges ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasChanges ? "Save Changes" : "Make Changes First",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                      hasChanges ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}