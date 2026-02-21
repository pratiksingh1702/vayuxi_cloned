enum PipingFieldType {
  size,
  length,
  qty,
}


class PipingFieldConfig {
  final String label;
  final PipingFieldType type;
  final String? unit; // nullable

  const PipingFieldConfig({
    required this.label,
    required this.type,
    this.unit,
  });
}


final Map<String, List<PipingFieldConfig>> pipingFieldConfig = {
  'PIPE': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'ELBOW 90°': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'ELBOW 45°': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'TEE': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'REDUCER': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'CAP': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  // 🔥 FLANGE & VALVES (ALL FIXED/REMOVABLE)
  'INSULATED FLANGE': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  'INSULATED WELDED VALVE': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],

  // ✅ fallback
  'DEFAULT': [
    PipingFieldConfig(label: 'Size', type: PipingFieldType.size),
    PipingFieldConfig(label: 'Quantity', type: PipingFieldType.qty, unit: 'NOS'),
  ],
};

