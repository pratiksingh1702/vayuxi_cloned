// ============================================================
// field_mapping_model.dart
// Models for Manpower Field Mapping feature
// ============================================================

/// Represents a single model field available for mapping
class ModelField {
  final String field;
  final String label;
  final bool required;
  final String type; // string | number | date | boolean | enum
  final List<String>? enumValues;

  const ModelField({
    required this.field,
    required this.label,
    required this.required,
    required this.type,
    this.enumValues,
  });

  factory ModelField.fromJson(Map<String, dynamic> json) {
    return ModelField(
      field: json['field']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      required: json['required'] == true,
      type: json['type']?.toString() ?? 'string',
      enumValues: (json['enumValues'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  @override
  String toString() => label;
}

/// AI-suggested mapping for a CSV column
class SuggestedMapping {
  final String csvColumn;
  final String? modelField;
  final double confidence; // 0.0 – 1.0

  const SuggestedMapping({
    required this.csvColumn,
    this.modelField,
    required this.confidence,
  });

  factory SuggestedMapping.fromJson(Map<String, dynamic> json) {
    return SuggestedMapping(
      csvColumn: json['csvColumn']?.toString() ?? '',
      modelField: json['modelField']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Full preview response from POST /field-mapping/preview
class FieldMappingPreview {
  final List<String> csvColumns;
  final List<ModelField> modelFields;
  final List<SuggestedMapping> suggestedMappings;
  final List<Map<String, dynamic>> preview; // first N rows as raw maps
  final List<String> unmappedColumns;
  final int? totalRows;
  final bool isStandardTemplate;

  const FieldMappingPreview({
    required this.csvColumns,
    required this.modelFields,
    required this.suggestedMappings,
    required this.preview,
    required this.unmappedColumns,
    this.totalRows,
    this.isStandardTemplate = false,
  });

  factory FieldMappingPreview.fromJson(Map<String, dynamic> json) {
    return FieldMappingPreview(
      csvColumns: (json['csvColumns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modelFields: (json['modelFields'] as List<dynamic>?)
              ?.map((e) => ModelField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedMappings: (json['suggestedMappings'] as List<dynamic>?)
              ?.map((e) => SuggestedMapping.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preview: (json['preview'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      unmappedColumns: (json['unmappedColumns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalRows: json['totalRows'] is int
          ? json['totalRows'] as int
          : int.tryParse('${json['totalRows']}'),
      isStandardTemplate: json['isStandardTemplate'] == true,
    );
  }
}

/// A single mapping pair (CSV column → model field)
class FieldMapping {
  final String csvColumn;
  final String modelField;

  const FieldMapping({required this.csvColumn, required this.modelField});

  Map<String, String> toJson() => {
        'csvColumn': csvColumn,
        'modelField': modelField,
      };

  factory FieldMapping.fromJson(Map<String, dynamic> json) {
    return FieldMapping(
      csvColumn: json['csvColumn']?.toString() ?? '',
      modelField: json['modelField']?.toString() ?? '',
    );
  }
}

/// A saved mapping configuration
class MappingConfiguration {
  final String id;
  final String configurationName;
  final String type;
  final List<FieldMapping> mappings;
  final bool isDefault;
  final String? createdAt;

  const MappingConfiguration({
    required this.id,
    required this.configurationName,
    required this.type,
    required this.mappings,
    required this.isDefault,
    this.createdAt,
  });

  factory MappingConfiguration.fromJson(Map<String, dynamic> json) {
    return MappingConfiguration(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      configurationName: json['configurationName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      mappings: (json['mappings'] as List<dynamic>?)
              ?.map((e) => FieldMapping.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isDefault: json['isDefault'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Result after import completes
class ImportResult {
  final int totalRows;
  final int successCount;
  final int duplicatesFound;
  final int errorCount;
  final List<ImportRowError> errors;

  const ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.duplicatesFound,
    required this.errorCount,
    required this.errors,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    // Support both { data: {...} } and flat response
    final d = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ImportResult(
      totalRows:
          (d['totalRows'] is int) ? d['totalRows'] as int : int.tryParse('${d['totalRows']}') ?? 0,
      successCount: (d['successCount'] is int)
          ? d['successCount'] as int
          : int.tryParse('${d['successCount']}') ?? 0,
      duplicatesFound: (d['duplicatesFound'] is int)
          ? d['duplicatesFound'] as int
          : int.tryParse('${d['duplicatesFound']}') ?? 0,
      errorCount:
          (d['errorCount'] is int) ? d['errorCount'] as int : int.tryParse('${d['errorCount']}') ?? 0,
      errors: (d['errors'] as List<dynamic>?)
              ?.map((e) => ImportRowError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A single row-level import error
class ImportRowError {
  final int? row;
  final String error;

  const ImportRowError({this.row, required this.error});

  factory ImportRowError.fromJson(Map<String, dynamic> json) {
    return ImportRowError(
      row: json['row'] is int ? json['row'] as int : int.tryParse('${json['row']}'),
      error: json['error']?.toString() ?? 'Unknown error',
    );
  }

  @override
  String toString() => row == null ? error : 'Row $row: $error';
}