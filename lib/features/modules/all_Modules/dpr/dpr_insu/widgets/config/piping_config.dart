enum PipingFieldType {
  size,
  length,
  qty,
}

/// Enhanced config matching FieldConfig structure
class PipingFieldConfig {
  final String label;
  final PipingFieldType type;
  final String? unit;
  final String? unitType; // 'LENGTH', 'QUANTITY', 'SIZE'
  final String? dropdown; // 'lengthUom', 'qtyUom', 'sizeUom'
  final bool required;
  final bool editable; // Can be edited in edit mode
  final String role; // Field role from backend

  const PipingFieldConfig({
    required this.label,
    required this.type,
    this.unit,
    this.unitType,
    this.dropdown,
    this.required = false,
    this.editable = true,
    this.role = '',
  });
}


/// Piping field configurations matching backend FieldConfig structure
final Map<String, List<PipingFieldConfig>> pipingFieldConfig = {
  'PIPE': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'ELBOW 90°': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'ELBOW 45°': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'TEE': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'REDUCER': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'CAP': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'INSULATED FLANGE': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'INSULATED WELDED VALVE': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],

  'DEFAULT': [
    PipingFieldConfig(
      label: 'Size',
      type: PipingFieldType.size,
      unitType: 'SIZE',
      dropdown: 'sizeUom',
      required: true,
      editable: true,
      role: 'SIZE',
    ),
    PipingFieldConfig(
      label: 'Quantity',
      type: PipingFieldType.qty,
      unit: 'NOS',
      unitType: 'QUANTITY',
      dropdown: 'qtyUom',
      required: true,
      editable: true,
      role: 'QUANTITY',
    ),
  ],
};

/// Default unit dropdown options (matching backend)
const Map<String, List<String>> pipingUnitDropdowns = {
  'lengthUom': ['MM', 'MTR', 'FT', 'INCH'],
  'sizeUom': ['INCH', 'MM'],
  'qtyUom': ['NOS', 'MTR'],
};

/// Default unit values
const Map<String, String> pipingDefaultUnits = {
  'lengthUom': 'MTR',
  'sizeUom': 'INCH',
  'qtyUom': 'NOS',
};

