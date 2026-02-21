import 'package:flutter/material.dart';

import '../../../models/equipmentModel.dart';
import '../../../models/pipingModel.dart';
import '../../../screens/widgets/dynamic_item_card.dart';
import '../../../screens/widgets/dynamic_item_card2.dart';
import '../../model/eqip_insu.dart';
import '../../model/piping_insu.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/piping_card.dart';
import '../../widgets/selection_check.dart';

abstract class MaterialCardStrategy<T> {
  Widget build({
    required BuildContext context,
    required T material,
    required bool isSelectionMode,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onRemark,
  });
}
class DprPipingCardStrategy
    implements MaterialCardStrategy<PipingItem> {
  @override
  Widget build({
    required BuildContext context,
    required PipingItem material,
    required bool isSelectionMode,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onRemark,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: isSelectionMode && !isSelected ? 0.5 : 1,
          child: DynamicItemCard(
            quantity: material.qty.toString(),
            size: material.size,
            length: material.length.toString(),
            floor: '',
            moc: material.moc,
            image: material.image,
            sizeLabel: "Size",
            lengthLabel: material.materialName,
            sizePlaceholder: material.uom,
            lengthPlaceholder: material.uom,
            isEditable: !isSelectionMode,
            onEdit: isSelectionMode ? null : onEdit,
            onDelete: isSelectionMode ? null : onDelete,
            onCopy: isSelectionMode ? null : onCopy,
            onRemark: isSelectionMode ? () {} : onRemark, onQtyChanged: (String p1) {  }, onSizeChanged: (String p1) {  }, onLengthChanged: (String p1) {  }, onFloorChanged: (String p1) {  }, onMocChanged: (String p1) {  },
          ),
        ),
        if (isSelectionMode)
          SelectionCheck(
            selected: isSelected,
            onTap: onSelect,
          ),
      ],
    );
  }
}
class DprEquipmentCardStrategy
    implements MaterialCardStrategy<EquipmentItem> {
  @override
  Widget build({
    required BuildContext context,
    required EquipmentItem material,
    required bool isSelectionMode,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onRemark,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: isSelectionMode && !isSelected ? 0.5 : 1,
          child: DynamicItemCard2(
            title: material.materialName,
            quantity: material.qty.toString(),
            image: material.image,
            isEditable: !isSelectionMode,
            onEdit: isSelectionMode ? null : onEdit,
            onDelete: isSelectionMode ? null : onDelete,
            onCopy: isSelectionMode ? null : onCopy,
            onRemark: isSelectionMode ? () {} : onRemark, ton: '', meter: '', floor: '', moc: '', onMeterChanged: (String p1) {  }, onQtyChanged: (String p1) {  }, onTonChanged: (String p1) {  }, onFloorChanged: (String p1) {  }, onMocChanged: (String p1) {  }, fields: [], onChanged: (String key, String value) {  },
          ),
        ),
        if (isSelectionMode)
          SelectionCheck(
            selected: isSelected,
            onTap: onSelect,
          ),
      ],
    );
  }
}
class InsulationPipingCardStrategy
    implements MaterialCardStrategy<PipingMaterial> {
  @override
  Widget build({
    required BuildContext context,
    required PipingMaterial material,
    required bool isSelectionMode,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onRemark,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: isSelectionMode && !isSelected ? 0.4 : 1,
          child: PipingMaterialCard(
            material: material,
            // editable: !isSelectionMode,
            onEdit: onEdit,
            onDelete: onDelete, onChanged: (PipingMaterial value) {  }, onAdd: () {  }, onRemark: () {  },
          ),
        ),
        if (isSelectionMode)
          SelectionCheck(
            selected: isSelected,
            onTap: onSelect,
          ),
      ],
    );
  }
}
class InsulationEquipmentCardStrategy
    implements MaterialCardStrategy<EquipmentMaterial> {
  @override
  Widget build({
    required BuildContext context,
    required EquipmentMaterial material,
    required bool isSelectionMode,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onRemark,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: isSelectionMode && !isSelected ? 0.4 : 1,
          child:  EquipmentMaterialCard (
            material: material,
            // editable: !isSelectionMode,
            onEdit: onEdit,
            onDelete: onDelete, onChanged: (EquipmentMaterial value) {  }, onAdd: () {  }, onRemark: () {  },
          ),
        ),
        if (isSelectionMode)
          SelectionCheck(
            selected: isSelected,
            onTap: onSelect,
          ),
      ],
    );
  }
}



