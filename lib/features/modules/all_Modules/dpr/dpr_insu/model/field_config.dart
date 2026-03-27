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
  final String type;
  final String? unitType;
  final bool required;
  final String? dropdown;
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
