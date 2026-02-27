enum EquipmentFieldType {
  qty,
  length,
  circumference,
  circumference1,
  circumference2,
  circumference3,
  zHeight,
  gSlantHeight,
}


class EquipmentFieldConfig {
  final String label;
  final EquipmentFieldType type;
  final int imageIndex; // which image to show

  const EquipmentFieldConfig({
    required this.label,
    required this.type,
    required this.imageIndex,
  });
}

final Map<String, List<EquipmentFieldConfig>> equipmentFieldConfig = {
  'SHELL': [
    EquipmentFieldConfig(label: 'Length', type: EquipmentFieldType.length, imageIndex: 0),
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 1),
  ],

  'DOME': [
    EquipmentFieldConfig(label: 'Height', type: EquipmentFieldType.zHeight, imageIndex: 0),
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 1),
  ],

  'FLAT END': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
  ],

  'CONE END': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
    EquipmentFieldConfig(label: 'Slant Height', type: EquipmentFieldType.gSlantHeight, imageIndex: 1),
  ],

  'REDUCER': [
    EquipmentFieldConfig(label: 'Length', type: EquipmentFieldType.length, imageIndex: 0),
    EquipmentFieldConfig(label: 'Circumference 1', type: EquipmentFieldType.circumference1, imageIndex: 1),
    EquipmentFieldConfig(label: 'Circumference 2', type: EquipmentFieldType.circumference2, imageIndex: 2),
  ],

  'NOZZLE': [
    EquipmentFieldConfig(label: 'Length', type: EquipmentFieldType.length, imageIndex: 0),
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 1),
  ],

  'PATCH': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
  ],

  // 🔥 ALL FLANGE BOX VARIANTS
  'FLANGE BOX-4': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
    EquipmentFieldConfig(label: 'Lenght', type: EquipmentFieldType.length, imageIndex: 0),
  ],
'FLANGE BOX': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
  ],

  // ✅ fallback
  'DEFAULT': [
    EquipmentFieldConfig(label: 'Circumference', type: EquipmentFieldType.circumference, imageIndex: 0),
  ],
};

