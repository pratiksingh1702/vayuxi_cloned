// lib/features/modules/all_Modules/dpr/dpr_insu/model/field_config.dart

class FieldConfig {
  final List<FieldDefinition> fields;
  final UnitDropdowns unitDropdowns;
  final FieldDefaults defaults;
  final UiConfig ui;

  const FieldConfig({
    required this.fields,
    required this.unitDropdowns,
    required this.defaults,
    required this.ui,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      fields: (json['fields'] as List?)
          ?.map((e) => FieldDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      unitDropdowns: UnitDropdowns.fromJson(
          json['unitDropdowns'] as Map<String, dynamic>? ?? {}),
      defaults: FieldDefaults.fromJson(
          json['defaults'] as Map<String, dynamic>? ?? {}),
      ui: UiConfig.fromJson(json['ui'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fields': fields.map((e) => e.toJson()).toList(),
      'unitDropdowns': unitDropdowns.toJson(),
      'defaults': defaults.toJson(),
      'ui': ui.toJson(),
    };
  }

  FieldConfig copyWith({
    List<FieldDefinition>? fields,
    UnitDropdowns? unitDropdowns,
    FieldDefaults? defaults,
    UiConfig? ui,
  }) {
    return FieldConfig(
      fields: fields ?? this.fields,
      unitDropdowns: unitDropdowns ?? this.unitDropdowns,
      defaults: defaults ?? this.defaults,
      ui: ui ?? this.ui,
    );
  }
}

class FieldDefinition {
  final String key;
  final String label;
  final String role;
  final String type; // 'NUMBER' | 'TEXT'
  final String? unitType; // 'LENGTH' | 'AREA' | 'COUNT'
  final bool required;
  final String? dropdown; // 'lengthUom' | 'areaUom' | 'qtyUom'
  final bool isUserAdded;
  final VisibleWhen? visibleWhen;

  const FieldDefinition({
    required this.key,
    required this.label,
    required this.role,
    required this.type,
    this.unitType,
    required this.required,
    this.dropdown,
    this.isUserAdded = false,
    this.visibleWhen,
  });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    return FieldDefinition(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      role: json['role'] as String? ?? '',
      type: json['type'] as String? ?? 'NUMBER',
      unitType: json['unitType'] as String?,
      required: json['required'] as bool? ?? false,
      dropdown: json['dropdown'] as String?,
      isUserAdded: json['isUserAdded'] as bool? ?? false,
      visibleWhen: json['visibleWhen'] != null
          ? VisibleWhen.fromJson(json['visibleWhen'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'role': role,
      'type': type,
      if (unitType != null) 'unitType': unitType,
      'required': required,
      if (dropdown != null) 'dropdown': dropdown,
      'isUserAdded': isUserAdded,
      if (visibleWhen != null) 'visibleWhen': visibleWhen!.toJson(),
    };
  }

  FieldDefinition copyWith({
    String? key,
    String? label,
    String? role,
    String? type,
    String? unitType,
    bool? required,
    String? dropdown,
    bool? isUserAdded,
    VisibleWhen? visibleWhen,
  }) {
    return FieldDefinition(
      key: key ?? this.key,
      label: label ?? this.label,
      role: role ?? this.role,
      type: type ?? this.type,
      unitType: unitType ?? this.unitType,
      required: required ?? this.required,
      dropdown: dropdown ?? this.dropdown,
      isUserAdded: isUserAdded ?? this.isUserAdded,
      visibleWhen: visibleWhen ?? this.visibleWhen,
    );
  }
}

/// Generic visibility condition — evaluated against card-local state
class VisibleWhen {
  final String? geometryMode;

  const VisibleWhen({this.geometryMode});

  factory VisibleWhen.fromJson(Map<String, dynamic> json) {
    return VisibleWhen(
      geometryMode: json['geometryMode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (geometryMode != null) 'geometryMode': geometryMode,
    };
  }

  /// Generic evaluator: checks this condition against [cardState]
  bool evaluate(Map<String, dynamic> cardState) {
    if (geometryMode != null) {
      return cardState['geometryMode'] == geometryMode;
    }
    return true;
  }
}

class UnitDropdowns {
  final List<String>? geometryMode;
  final List<String>? lengthUom;
  final List<String>? areaUom;
  final List<String>? qtyUom;
  final List<String>? sizeUom;

  const UnitDropdowns({
    this.geometryMode,
    this.lengthUom,
    this.areaUom,
    this.qtyUom,
    this.sizeUom,
  });

  factory UnitDropdowns.fromJson(Map<String, dynamic> json) {
    return UnitDropdowns(
      geometryMode: (json['geometryMode'] as List?)?.cast<String>(),
      lengthUom: (json['lengthUom'] as List?)?.cast<String>(),
      areaUom: (json['areaUom'] as List?)?.cast<String>(),
      qtyUom: (json['qtyUom'] as List?)?.cast<String>(),
      sizeUom: (json['sizeUom'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (geometryMode != null) 'geometryMode': geometryMode,
      if (lengthUom != null) 'lengthUom': lengthUom,
      if (areaUom != null) 'areaUom': areaUom,
      if (qtyUom != null) 'qtyUom': qtyUom,
      if (sizeUom != null) 'sizeUom': sizeUom,
    };
  }

  /// Get options for a given dropdown key
  List<String> optionsFor(String dropdownKey) {
    final map = toJson();
    final val = map[dropdownKey];
    if (val is List) return val.cast<String>();
    return [];
  }
}

class FieldDefaults {
  final String? geometryMode;
  final String? lengthUom;
  final String? areaUom;
  final String? qtyUom;
  final String? sizeUom;

  const FieldDefaults({
    this.geometryMode,
    this.lengthUom,
    this.areaUom,
    this.qtyUom,
    this.sizeUom,
  });

  factory FieldDefaults.fromJson(Map<String, dynamic> json) {
    return FieldDefaults(
      geometryMode: json['geometryMode'] as String?,
      lengthUom: json['lengthUom'] as String?,
      areaUom: json['areaUom'] as String?,
      qtyUom: json['qtyUom'] as String?,
      sizeUom: json['sizeUom'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (geometryMode != null) 'geometryMode': geometryMode,
      if (lengthUom != null) 'lengthUom': lengthUom,
      if (areaUom != null) 'areaUom': areaUom,
      if (qtyUom != null) 'qtyUom': qtyUom,
      if (sizeUom != null) 'sizeUom': sizeUom,
    };
  }

  /// Get default for a given dropdown key
  String? defaultFor(String dropdownKey) {
    return toJson()[dropdownKey] as String?;
  }
}

class UiConfig {
  final bool allowRename;
  final bool allowCustomUom;
  final bool allowUserFields;
  final bool allowGeometrySwitch;

  const UiConfig({
    this.allowRename = false,
    this.allowCustomUom = false,
    this.allowUserFields = false,
    this.allowGeometrySwitch = false,
  });

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      allowRename: json['allowRename'] as bool? ?? false,
      allowCustomUom: json['allowCustomUom'] as bool? ?? false,
      allowUserFields: json['allowUserFields'] as bool? ?? false,
      allowGeometrySwitch: json['allowGeometrySwitch'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowRename': allowRename,
      'allowCustomUom': allowCustomUom,
      'allowUserFields': allowUserFields,
      'allowGeometrySwitch': allowGeometrySwitch,
    };
  }
}

class CalculationConfig {
  final String formulaType;
  final String? constantRules;

  const CalculationConfig({
    required this.formulaType,
    this.constantRules,
  });

  factory CalculationConfig.fromJson(Map<String, dynamic> json) {
    return CalculationConfig(
      formulaType: json['formulaType'] as String? ?? '',
      constantRules: json['constantRules'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formulaType': formulaType,
      if (constantRules != null) 'constantRules': constantRules,
    };
  }
}

/// Per-field value entry: holds numeric/text value AND selected unit
class FieldEntry {
  final dynamic value; // num or String
  final String? unit;  // selected unit string

  const FieldEntry({this.value, this.unit});

  factory FieldEntry.fromJson(Map<String, dynamic> json) {
    return FieldEntry(
      value: json['value'],
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (value != null) 'value': value,
    if (unit != null) 'unit': unit,
  };

  FieldEntry copyWith({dynamic value, String? unit}) {
    return FieldEntry(
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}

/// Card-level state: isolated per material card instance
///
/// Structure:
/// {
///   "geometryMode": "DIAMETER",      ← geometry selection (card-local)
///   "length":       { value: 100, unit: "MM" },
///   "diameter":     { value: 50,  unit: "MM" },
///   "circumference":{ value: 0,   unit: "MM" },
///   "quantity":     { value: 1,   unit: "NOS" },
///   "customLabels": { "length": "My Length" }
/// }
// class CardFormState {
//   final Map<String, FieldEntry> fieldEntries;
//   final String? geometryMode;
//   final Map<String, String> customLabels; // field.key → custom label text
//
//   const CardFormState({
//     required this.fieldEntries,
//     this.geometryMode,
//     this.customLabels = const {},
//   });
//
//   factory CardFormState.initial({
//     required FieldConfig config,
//   }) {
//     final entries = <String, FieldEntry>{};
//
//     for (final field in config.fields) {
//       // Resolve default unit for this field
//       String? defaultUnit;
//       if (field.dropdown != null) {
//         defaultUnit = config.defaults.defaultFor(field.dropdown!);
//         if (defaultUnit == null) {
//           final options = config.unitDropdowns.optionsFor(field.dropdown!);
//           defaultUnit = options.isNotEmpty ? options.first : null;
//         }
//       }
//       entries[field.key] = FieldEntry(value: null, unit: defaultUnit);
//     }
//
//     return CardFormState(
//       fieldEntries: entries,
//       geometryMode: config.defaults.geometryMode,
//       customLabels: {},
//     );
//   }
//
//   factory CardFormState.fromJson(Map<String, dynamic> json) {
//     final entries = <String, FieldEntry>{};
//     final rawEntries = json['fieldEntries'] as Map<String, dynamic>? ?? {};
//     for (final kv in rawEntries.entries) {
//       entries[kv.key] = FieldEntry.fromJson(kv.value as Map<String, dynamic>);
//     }
//     return CardFormState(
//       fieldEntries: entries,
//       geometryMode: json['geometryMode'] as String?,
//       customLabels: (json['customLabels'] as Map<String, dynamic>? ?? {})
//           .cast<String, String>(),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'fieldEntries': {
//       for (final kv in fieldEntries.entries) kv.key: kv.value.toJson(),
//     },
//     if (geometryMode != null) 'geometryMode': geometryMode,
//     'customLabels': customLabels,
//   };
//
//   CardFormState copyWith({
//     Map<String, FieldEntry>? fieldEntries,
//     String? geometryMode,
//     Map<String, String>? customLabels,
//     bool clearGeometryMode = false,
//   }) {
//     return CardFormState(
//       fieldEntries: fieldEntries ?? Map.from(this.fieldEntries),
//       geometryMode: clearGeometryMode ? null : (geometryMode ?? this.geometryMode),
//       customLabels: customLabels ?? Map.from(this.customLabels),
//     );
//   }
//
//   /// Update a single field's value
//   CardFormState setFieldValue(String key, dynamic value) {
//     final updated = Map<String, FieldEntry>.from(fieldEntries);
//     updated[key] = (updated[key] ?? const FieldEntry()).copyWith(value: value);
//     return copyWith(fieldEntries: updated);
//   }
//
//   /// Update a single field's unit
//   CardFormState setFieldUnit(String key, String unit) {
//     final updated = Map<String, FieldEntry>.from(fieldEntries);
//     updated[key] = (updated[key] ?? const FieldEntry()).copyWith(unit: unit);
//     return copyWith(fieldEntries: updated);
//   }
//
//   /// Update geometry mode (card-local)
//   CardFormState setGeometryMode(String mode) {
//     return copyWith(geometryMode: mode);
//   }
//
//   /// Update a custom label
//   CardFormState setCustomLabel(String fieldKey, String label) {
//     final updated = Map<String, String>.from(customLabels);
//     updated[fieldKey] = label;
//     return copyWith(customLabels: updated);
//   }
//
//   /// Generic visibility evaluator — evaluates visibleWhen against THIS card's state
//   bool isFieldVisible(FieldDefinition field) {
//     if (field.visibleWhen == null) return true;
//     return field.visibleWhen!.evaluate({
//       'geometryMode': geometryMode,
//       ...{for (final e in fieldEntries.entries) e.key: e.value.value},
//     });
//   }
//
//   /// Validate: returns map of fieldKey → error message for visible required fields
//   Map<String, String> validate(List<FieldDefinition> fields) {
//     final errors = <String, String>{};
//     for (final field in fields) {
//       if (!isFieldVisible(field)) continue;
//       if (field.key == 'quantity') continue; // quantity always optional for visibility
//       if (field.required) {
//         final entry = fieldEntries[field.key];
//         final val = entry?.value;
//         if (val == null || val.toString().trim().isEmpty) {
//           errors[field.key] = '${field.label} is required';
//         }
//       }
//     }
//     return errors;
//   }
// }

/// Holds dynamic field values as a map (kept for backward compat)
class FieldValues {
  final Map<String, dynamic> values;

  FieldValues(this.values);

  factory FieldValues.fromJson(Map<String, dynamic> json) {
    return FieldValues(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  dynamic operator [](String key) => values[key];
  void operator []=(String key, dynamic value) => values[key] = value;
  bool containsKey(String key) => values.containsKey(key);

  T? get<T>(String key) => values[key] as T?;
  T getOrDefault<T>(String key, T defaultValue) =>
      values[key] as T? ?? defaultValue;
}