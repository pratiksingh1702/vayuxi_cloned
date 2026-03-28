// lib/features/modules/all_Modules/dpr/dpr_insu/model/card_form_state.dart

/// A single field's value + unit within a card.
class FieldEntry {
  final dynamic value; // num | String | null
  final String? unit;

  const FieldEntry({this.value, this.unit});

  factory FieldEntry.fromJson(Map<String, dynamic> json) {
    return FieldEntry(
      value: json['value'],
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    if (unit != null) 'unit': unit,
  };

  FieldEntry copyWith({dynamic value, String? unit, bool clearValue = false}) {
    return FieldEntry(
      value: clearValue ? null : (value ?? this.value),
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() => 'FieldEntry(value: $value, unit: $unit)';
}

/// Per-card isolated form state.
///
/// Each [CardFormState] is owned by exactly ONE material card.
/// [geometryMode] is stored here, NOT globally — switching it in
/// one card has ZERO effect on any other card.
///
/// Structure stored as JSON in [LocalMaterial.cardFormStateJson]:
/// ```json
/// {
///   "geometryMode": "DIAMETER",
///   "fieldEntries": {
///     "length":        { "value": 100, "unit": "MM" },
///     "diameter":      { "value": 50,  "unit": "MM" },
///     "circumference": { "value": null, "unit": "MM" },
///     "quantity":      { "value": 1,   "unit": "NOS" }
///   },
///   "customLabels": { "length": "My Length" }
/// }
/// ```
class CardFormState {
  /// Per-card geometry mode. NOT shared between cards.
  final String? geometryMode;

  /// Map of fieldKey → FieldEntry (value + unit).
  final Map<String, FieldEntry> fieldEntries;

  /// User-customised labels for fields (allowRename).
  final Map<String, String> customLabels;

  const CardFormState({
    this.geometryMode,
    Map<String, FieldEntry>? fieldEntries,
    Map<String, String>? customLabels,
  })  : fieldEntries = fieldEntries ?? const {},
        customLabels = customLabels ?? const {};

  // ── Factory ──────────────────────────────────

  factory CardFormState.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['fieldEntries'] as Map<String, dynamic>? ?? {};
    final labelsRaw = json['customLabels'] as Map<String, dynamic>? ?? {};

    return CardFormState(
      geometryMode: json['geometryMode'] as String?,
      fieldEntries: entriesRaw.map(
            (k, v) => MapEntry(
          k,
          FieldEntry.fromJson(v as Map<String, dynamic>),
        ),
      ),
      customLabels: labelsRaw.map((k, v) => MapEntry(k, v as String)),
    );
  }

  Map<String, dynamic> toJson() => {
    if (geometryMode != null) 'geometryMode': geometryMode,
    'fieldEntries': fieldEntries.map((k, v) => MapEntry(k, v.toJson())),
    'customLabels': customLabels,
  };

  // ── Helpers ──────────────────────────────────

  /// Get the value for a field key, or null.
  dynamic getValue(String key) => fieldEntries[key]?.value;

  /// Get the unit for a field key, or null.
  String? getUnit(String key) => fieldEntries[key]?.unit;

  /// Get the label for a field key, or fall back to [defaultLabel].
  String getLabel(String key, String defaultLabel) =>
      customLabels[key] ?? defaultLabel;

  // ── CopyWith ─────────────────────────────────

  CardFormState copyWith({
    String? geometryMode,
    Map<String, FieldEntry>? fieldEntries,
    Map<String, String>? customLabels,
    bool clearGeometryMode = false,
  }) {
    return CardFormState(
      geometryMode:
      clearGeometryMode ? null : (geometryMode ?? this.geometryMode),
      fieldEntries: fieldEntries ?? this.fieldEntries,
      customLabels: customLabels ?? this.customLabels,
    );
  }

  /// Update a single field's value, preserving its unit.
  CardFormState updateValue(String key, dynamic value) {
    final existing = fieldEntries[key];
    final updated = Map<String, FieldEntry>.from(fieldEntries);
    updated[key] = FieldEntry(value: value, unit: existing?.unit);
    return copyWith(fieldEntries: updated);
  }

  /// Update a single field's unit, preserving its value.
  CardFormState updateUnit(String key, String unit) {
    final existing = fieldEntries[key];
    final updated = Map<String, FieldEntry>.from(fieldEntries);
    updated[key] = FieldEntry(value: existing?.value, unit: unit);
    return copyWith(fieldEntries: updated);
  }

  /// Update a field's label.
  CardFormState updateLabel(String key, String label) {
    final updated = Map<String, String>.from(customLabels);
    updated[key] = label;
    return copyWith(customLabels: updated);
  }

  /// Update geometry mode. Does NOT clear any field values.
  CardFormState updateGeometryMode(String mode) =>
      copyWith(geometryMode: mode);

  /// Build initial state from a [FieldConfig].
  /// Sets default units from [FieldDefaults] and default geometryMode.
  static CardFormState buildInitial({
    required dynamic fieldConfig, // FieldConfig
    CardFormState? existing,
  }) {
    if (existing != null) return existing;

    final defaults = fieldConfig.defaults;
    final defaultsMap = defaults.toJson() as Map<String, dynamic>;

    final entries = <String, FieldEntry>{};

    for (final field in fieldConfig.fields as List) {
      // Resolve default unit from dropdown key
      String? defaultUnit;
      if (field.dropdown != null) {
        defaultUnit = defaultsMap[field.dropdown] as String?;
        // Fallback: first option in the dropdown list
        if (defaultUnit == null) {
          final unitDropdowns =
          fieldConfig.unitDropdowns.toJson() as Map<String, dynamic>;
          final opts = unitDropdowns[field.dropdown] as List?;
          if (opts != null && opts.isNotEmpty) {
            defaultUnit = opts.first.toString();
          }
        }
      }
      entries[field.key] = FieldEntry(value: null, unit: defaultUnit);
    }

    final defaultGeometry = defaultsMap['geometryMode'] as String?;

    return CardFormState(
      geometryMode: defaultGeometry,
      fieldEntries: entries,
      customLabels: {},
    );
  }

  @override
  String toString() =>
      'CardFormState(geometryMode: $geometryMode, entries: $fieldEntries)';
}