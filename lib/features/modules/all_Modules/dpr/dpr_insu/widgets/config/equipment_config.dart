enum EquipmentFieldType {
  qty,
  length,
  circumference,
  circumference1,
  circumference2,
  circumference3,
  zHeight,
  SlantHeight,
}

/// Enhanced config matching FieldConfig structure
class EquipmentFieldConfig {
  final String label;
  final EquipmentFieldType type;
  final int imageIndex;
  final String? unitType; // 'LENGTH', 'AREA', 'QUANTITY'
  final String? dropdown; // 'lengthUom', 'areaUom', 'qtyUom'
  final bool required;
  final bool editable; // Can be edited in edit mode
  final String role; // Field role from backend

  const EquipmentFieldConfig({
    required this.label,
    required this.type,
    required this.imageIndex,
    this.unitType,
    this.dropdown,
    this.required = false,
    this.editable = true,
    this.role = '',
  });
}

/// Equipment field configurations matching backend FieldConfig structure
final Map<String, List<EquipmentFieldConfig>> equipmentFieldConfig = {
  'SHELL': [
    EquipmentFieldConfig(
      label: 'Length',
      type: EquipmentFieldType.length,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'LENGTH',
    ),
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 1,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],

  'DOME': [
    EquipmentFieldConfig(
      label: 'Height',
      type: EquipmentFieldType.zHeight,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'Z_HEIGHT',
    ),
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 1,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],

  'FLAT END': [
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],

  'CONE END': [
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
    EquipmentFieldConfig(
      label: 'Slant Height',
      type: EquipmentFieldType.SlantHeight,
      imageIndex: 1,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'slant_height',
    ),
  ],

  'REDUCER': [
    EquipmentFieldConfig(
      label: 'Length',
      type: EquipmentFieldType.length,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'LENGTH',
    ),
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 1,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
    EquipmentFieldConfig(
      label: 'Circumference 1',
      type: EquipmentFieldType.circumference1,
      imageIndex: 2,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE_1',
    ),
  ],

  'NOZZLE': [
    EquipmentFieldConfig(
      label: 'Length',
      type: EquipmentFieldType.length,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'LENGTH',
    ),
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 1,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],

  'PATCH': [
    EquipmentFieldConfig(
      label: 'Patch',
      type: EquipmentFieldType.qty,
      imageIndex: 0,
      unitType: 'COUNT',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'FLANGE BOX-4': [
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
    EquipmentFieldConfig(
      label: 'Length',
      type: EquipmentFieldType.length,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'LENGTH',
    ),
  ],

  'FLANGE BOX': [
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],

  'DEFAULT': [
    EquipmentFieldConfig(
      label: 'Circumference',
      type: EquipmentFieldType.circumference,
      imageIndex: 0,
      unitType: 'LENGTH',
      dropdown: 'lengthUom',
      required: true,
      editable: true,
      role: 'CIRCUMFERENCE',
    ),
  ],
};

/// Default unit dropdown options (matching backend)
const Map<String, List<String>> equipmentUnitDropdowns = {
  'lengthUom': ['MM', 'MTR', 'FT', 'INCH'],
  'areaUom': ['SQM', 'SQFT'],
  'qtyUom': ['NOS'],
};

/// Default unit values
const Map<String, String> equipmentDefaultUnits = {
  'lengthUom': 'MM',
  'areaUom': 'SQM',
  'qtyUom': 'NOS',
};

