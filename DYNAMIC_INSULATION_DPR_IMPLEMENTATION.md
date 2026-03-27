# Dynamic Insulation DPR System - Implementation Guide

## Overview
This document describes the implementation of the dynamic insulation DPR system in the Flutter application, based on the backend API changes that introduce dynamic field configurations for insulation materials.

**Implementation Date**: March 28, 2026  
**Backend API Version**: v1  
**Flutter Implementation**: FE-V2-Vayuxi

---

## Table of Contents
1. [Key Changes](#key-changes)
2. [New Models](#new-models)
3. [Updated Models](#updated-models)
4. [Database Schema Changes](#database-schema-changes)
5. [Service Layer Updates](#service-layer-updates)
6. [API Integration](#api-integration)
7. [Usage Examples](#usage-examples)
8. [Migration Guide](#migration-guide)

---

## Key Changes

### Backend API Changes
The backend now returns materials with dynamic field configurations instead of fixed schemas:

**Old Response Structure:**
```json
{
  "_id": "material_id",
  "name": "SHELL",
  "image": ["url"],
  "uom": "M2"
}
```

**New Response Structure:**
```json
{
  "_id": "material_id",
  "name": "SHELL",
  "materialCode": "SHELL",
  "image": ["url"],
  "uom": "M2",
  "designation": "equipment",
  "calculationType": "AREA",
  "fieldConfig": {
    "fields": [
      {
        "key": "length",
        "label": "Length",
        "role": "LENGTH",
        "type": "NUMBER",
        "unitType": "LENGTH",
        "required": true,
        "dropdown": "lengthUom",
        "isUserAdded": false
      }
    ],
    "unitDropdowns": {
      "lengthUom": ["MM", "MTR", "FT", "INCH"],
      "qtyUom": ["NOS", "SET", "PAIR"]
    },
    "defaults": {
      "lengthUom": "MM",
      "qtyUom": "NOS"
    },
    "ui": {
      "allowRename": true,
      "allowCustomUom": true,
      "allowUserFields": true,
      "allowGeometrySwitch": true
    }
  },
  "calculationConfig": {
    "formulaType": "SHELL"
  }
}
```

---

## New Models

### 1. FieldConfig Model
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/field_config.dart`

Represents the dynamic field configuration for a material.

```dart
class FieldConfig {
  final List<FieldDefinition> fields;
  final UnitDropdowns unitDropdowns;
  final FieldDefaults defaults;
  final UiConfig ui;
}
```

**Key Classes:**
- `FieldDefinition`: Defines a single field (key, label, role, type, etc.)
- `UnitDropdowns`: Available unit options for dropdowns
- `FieldDefaults`: Default values for fields
- `UiConfig`: UI permissions (allowRename, allowCustomUom, etc.)
- `VisibleWhen`: Conditional field visibility
- `CalculationConfig`: Formula configuration for calculations

### 2. MaterialSetup Model
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart`

Represents the complete material setup configuration from the backend.

```dart
class MaterialSetup {
  final String id;
  final String name;
  final String materialCode;
  final List<String> image;
  final String uom;
  final String designation;
  final String calculationType;
  final FieldConfig fieldConfig;
  final CalculationConfig? calculationConfig;
  final bool isDefault;
  final int displayOrder;
}
```

### 3. FieldValues Model
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart`

Stores dynamic field values as key-value pairs.

```dart
class FieldValues {
  final Map<String, dynamic> values;
  
  // Access methods
  dynamic operator [](String key);
  void operator []=(String key, dynamic value);
  T? get<T>(String key);
  T getOrDefault<T>(String key, T defaultValue);
}
```

---

## Updated Models

### 1. BaseMaterial
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/base_material.dart`

**Changes:**
- Added `materialCode`, `fieldValues`, and `customLabels` fields
- Made legacy fields optional with default values
- Updated constructor to support dynamic fields

**New Fields:**
```dart
final String? materialCode;
final FieldValues? fieldValues;
final Map<String, String>? customLabels;
```

### 2. EquipmentMaterial
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/eqip_insu.dart`

**Changes:**
- Updated constructor to use named parameters with defaults
- Added support for `materialCode` and `fieldValues`
- Updated `fromJson` to parse dynamic field values
- Updated `toJson` to serialize dynamic fields

### 3. PipingMaterial
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/model/piping_insu.dart`

**Changes:**
- Similar updates to EquipmentMaterial
- Retained `size` and `sizeUom` fields for piping-specific data
- Added support for dynamic field values

---

## Database Schema Changes

### LocalMaterial Schema
**Location**: `lib/features/modules/all_Modules/dpr/offline/data/local/local_material.dart`

**New Fields:**
```dart
@collection
class LocalMaterial {
  // Material Setup Data
  String? materialCode;
  String? calculationType;
  String? fieldConfigJson;  // Stores FieldConfig as JSON
  String? calculationConfigJson;  // Stores CalculationConfig as JSON
  bool isDefault = false;
  int displayOrder = 0;
  
  // Dynamic Field Values
  String? fieldValuesJson;  // Stores dynamic field values as JSON
  
  // Legacy fields remain for backward compatibility
  int qty = 0;
  double length = 0;
  String? size;
  String? sizeUom;
  // ... other legacy fields
}
```

**Migration Required:**
After updating the schema, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Service Layer Updates

### InsulationMaterialSetupService
**Location**: `lib/features/modules/all_Modules/dpr/dpr_insu/service/material_service.dart`

**New Methods:**

#### 1. Fetch Material Setup
```dart
Future<List<MaterialSetup>> fetchMaterialSetup({
  required String siteId,
  String? designation,
}) async {
  final response = await _dio.get(
    '/insulation-dpr-setup/materials',
    queryParameters: {
      'siteId': siteId,
      if (designation != null) 'designation': designation,
    },
  );
  
  final List list = response.data['data'] ?? [];
  return list.map((json) => MaterialSetup.fromJson(json)).toList();
}
```

#### 2. Update Field Configuration
```dart
Future<MaterialSetup> updateFieldConfig({
  required String materialId,
  required List<Map<String, dynamic>> fieldUpdates,
}) async {
  final response = await _dio.put(
    '/insulation-dpr-setup/materials/$materialId/field-config',
    data: {'fieldUpdates': fieldUpdates},
  );
  return MaterialSetup.fromJson(response.data['material']);
}
```

#### 3. Add Custom Field
```dart
Future<MaterialSetup> addCustomField({
  required String materialId,
  required Map<String, dynamic> fieldDef,
}) async {
  final response = await _dio.post(
    '/insulation-dpr-setup/materials/$materialId/custom-field',
    data: {'fieldDef': fieldDef},
  );
  return MaterialSetup.fromJson(response.data['material']);
}
```

#### 4. Remove Custom Field
```dart
Future<MaterialSetup> removeCustomField({
  required String materialId,
  required String fieldKey,
}) async {
  final response = await _dio.delete(
    '/insulation-dpr-setup/materials/$materialId/custom-field/$fieldKey',
  );
  return MaterialSetup.fromJson(response.data['material']);
}
```

---

## API Integration

### Endpoints

#### 1. Get Materials with Field Config
```
GET /api/v1/insulation-dpr-setup/materials?siteId={siteId}&designation={designation}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "material_id",
      "name": "SHELL",
      "materialCode": "SHELL",
      "fieldConfig": { /* ... */ },
      "calculationConfig": { /* ... */ }
    }
  ],
  "count": 22
}
```

#### 2. Update Field Configuration
```
PUT /api/v1/insulation-dpr-setup/materials/:materialId/field-config
```

**Request Body:**
```json
{
  "fieldUpdates": [
    {
      "fieldKey": "size",
      "newLabel": "Pipe Diameter"
    }
  ]
}
```

#### 3. Add Custom Field
```
POST /api/v1/insulation-dpr-setup/materials/:materialId/custom-field
```

**Request Body:**
```json
{
  "fieldDef": {
    "key": "insulation_thickness",
    "label": "Insulation Thickness",
    "type": "NUMBER",
    "unitType": "LENGTH",
    "required": false,
    "dropdown": "lengthUom"
  }
}
```

#### 4. Create DPR with Dynamic Fields
```
POST /api/v1/site/:siteId/team/:teamId/dpr-insulation
```

**Request Body (Equipment):**
```json
{
  "designation": "equipment",
  "layer": "single",
  "legging_material_1": "LRB",
  "legging_thickness_1": 50,
  "cladding_material": "Aluminium",
  "cladding_swg": 24,
  "equipment_materials": [
    {
      "name": "SHELL",
      "materialCode": "SHELL",
      "fieldValues": {
        "length": 5000,
        "lengthUom": "MM",
        "geometryMode": "DIAMETER",
        "diameter": 2000,
        "diameterUom": "MM",
        "quantity": 1,
        "qtyUom": "NOS"
      }
    }
  ]
}
```

---

## Usage Examples

### Example 1: Fetch and Display Materials

```dart
final service = InsulationMaterialSetupService();

// Fetch material setup configurations
final materials = await service.fetchMaterialSetup(
  siteId: 'site_123',
  designation: 'equipment',
);

// Access field configuration
for (final material in materials) {
  print('Material: ${material.name}');
  print('Material Code: ${material.materialCode}');
  
  // Access field definitions
  for (final field in material.fieldConfig.fields) {
    print('Field: ${field.label} (${field.key})');
    print('Type: ${field.type}');
    print('Required: ${field.required}');
    
    // Check if field has dropdown
    if (field.dropdown != null) {
      final options = material.fieldConfig.unitDropdowns.toJson()[field.dropdown];
      print('Options: $options');
    }
  }
}
```

### Example 2: Create DPR Entry with Dynamic Fields

```dart
// Create field values for a SHELL material
final fieldValues = FieldValues({
  'length': 5000,
  'lengthUom': 'MM',
  'geometryMode': 'DIAMETER',
  'diameter': 2000,
  'diameterUom': 'MM',
  'quantity': 1,
  'qtyUom': 'NOS',
});

// Create equipment material
final material = EquipmentMaterial(
  id: 'temp_id',
  name: 'SHELL',
  image: [],
  uom: 'M2',
  materialCode: 'SHELL',
  fieldValues: fieldValues,
);

// Access field values
final length = material.fieldValues?.get<int>('length'); // 5000
final lengthUom = material.fieldValues?.get<String>('lengthUom'); // 'MM'
```

### Example 3: Render Dynamic Form Fields

```dart
Widget buildDynamicForm(MaterialSetup setup) {
  return Column(
    children: setup.fieldConfig.fields.map((field) {
      // Check visibility condition
      if (field.visibleWhen != null) {
        // Implement visibility logic
      }
      
      // Render based on field type
      if (field.type == 'NUMBER') {
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
          ),
          keyboardType: TextInputType.number,
          validator: field.required 
            ? (value) => value?.isEmpty ?? true ? 'Required' : null
            : null,
        );
      }
      
      // Handle dropdown fields
      if (field.dropdown != null) {
        final options = setup.fieldConfig.unitDropdowns.toJson()[field.dropdown];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: field.label),
          items: (options as List).map((opt) {
            return DropdownMenuItem(
              value: opt.toString(),
              child: Text(opt.toString()),
            );
          }).toList(),
          onChanged: (value) {
            // Handle change
          },
        );
      }
      
      return SizedBox.shrink();
    }).toList(),
  );
}
```

### Example 4: Update Field Configuration

```dart
final service = InsulationMaterialSetupService();

// Rename a field
final updatedMaterial = await service.updateFieldConfig(
  materialId: 'material_123',
  fieldUpdates: [
    {
      'fieldKey': 'size',
      'newLabel': 'Pipe Diameter',
    },
    {
      'fieldKey': 'quantity',
      'newLabel': 'Length',
    },
  ],
);

print('Updated field config: ${updatedMaterial.fieldConfig}');
```

### Example 5: Add Custom Field

```dart
final service = InsulationMaterialSetupService();

// Add insulation thickness field
final updatedMaterial = await service.addCustomField(
  materialId: 'material_123',
  fieldDef: {
    'key': 'insulation_thickness',
    'label': 'Insulation Thickness',
    'type': 'NUMBER',
    'unitType': 'LENGTH',
    'required': false,
    'dropdown': 'lengthUom',
  },
);

print('Custom field added: ${updatedMaterial.fieldConfig.fields.last.label}');
```

---

## Migration Guide

### For Existing Code

#### 1. Update Material Fetching
**Before:**
```dart
final materials = await service.getMaterials(siteId: siteId);
final equipmentMaterials = materials['equipmentMaterials'];
```

**After:**
```dart
// Option 1: Use MaterialSetup for full configuration
final materialSetups = await service.fetchMaterialSetup(
  siteId: siteId,
  designation: 'equipment',
);

// Option 2: Continue using legacy method (still supported)
final materials = await service.getMaterials(siteId: siteId);
final equipmentMaterials = materials['equipmentMaterials'];
```

#### 2. Update Material Creation
**Before:**
```dart
final material = EquipmentMaterial(
  id: 'id',
  name: 'SHELL',
  image: [],
  qty: 1,
  length: 5000,
  circumference: 6280,
  // ... all required fields
);
```

**After:**
```dart
// All fields now have defaults
final material = EquipmentMaterial(
  id: 'id',
  name: 'SHELL',
  image: [],
  uom: 'M2',
  materialCode: 'SHELL',
  fieldValues: FieldValues({
    'length': 5000,
    'diameter': 2000,
    'quantity': 1,
  }),
);
```

#### 3. Update Local Database
After updating `LocalMaterial` schema:

```bash
# Regenerate Isar database files
flutter pub run build_runner build --delete-conflicting-outputs
```

Then update data access code:
```dart
// Store field config
localMaterial.fieldConfigJson = jsonEncode(materialSetup.fieldConfig.toJson());
localMaterial.fieldValuesJson = jsonEncode(fieldValues.toJson());

// Retrieve field config
final fieldConfig = FieldConfig.fromJson(
  jsonDecode(localMaterial.fieldConfigJson!)
);
final fieldValues = FieldValues.fromJson(
  jsonDecode(localMaterial.fieldValuesJson!)
);
```

---

## Material Types and Field Configurations

### Equipment Materials

#### SHELL
**Fields:**
- length (LENGTH) - with diameter/circumference mode switch
- diameter (DIAMETER) - visible when geometryMode = "DIAMETER"
- circumference (CIRCUMFERENCE) - visible when geometryMode = "CIRCUMFERENCE"
- quantity (QUANTITY)

**Calculation:** `AREA = π × diameter × length × quantity`

#### DOME
**Fields:**
- circumference (CIRCUMFERENCE)
- z_height (Z_HEIGHT)
- quantity (QUANTITY)

**Calculation:** `AREA = (circumference² / (4π)) × constant × quantity`
**Constant Rule:** `if z_height < (circumference/π)/3 then 1.27 else 1.75`

#### FLAT END
**Fields:**
- circumference (CIRCUMFERENCE)
- quantity (QUANTITY)

**Calculation:** `AREA = (circumference² / (4π)) × quantity`

#### CONE END
**Fields:**
- g_slant_height (G_SLANT_HEIGHT)
- quantity (QUANTITY)

**Constant Rule:** `if g_slant_height > 3000 then 1 else 1.5`

#### REDUCER
**Fields:**
- length (LENGTH)
- circumference (CIRCUMFERENCE)
- circumference_1 (CIRCUMFERENCE_1)
- quantity (QUANTITY)

**Constant Rule:** `if length > 3000 then 1 else 1.5`

#### FLANGE BOX (1-4)
**Fields:**
- circumference (CIRCUMFERENCE)
- length (LENGTH) - for types 3 & 4
- quantity (QUANTITY)

#### NOZZLE
**Fields:**
- circumference (CIRCUMFERENCE)
- length (LENGTH)
- quantity (QUANTITY)

#### PATCH
**Fields:**
- area (AREA)
- quantity (QUANTITY)

### Piping Materials

#### PIPE
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** MTR
**Constant:** 1

#### ELBOW 90°
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.5, large=1.5

#### ELBOW 45°
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.3424, large=0.9

#### TEE
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.6, large=1.8

#### REDUCER
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.3424, large=0.9

#### CAP
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.1712, large=0.45

#### FLANGE PAIR/VALVE (REMOVABLE/FIXED)
**Fields:**
- size (SIZE)
- quantity (QUANTITY)

**UOM:** NOS
**Constants:** small=0.5, large=1.5

---

## Testing Checklist

- [ ] Fetch materials with field configurations
- [ ] Parse FieldConfig correctly
- [ ] Display dynamic fields in UI
- [ ] Handle conditional field visibility
- [ ] Validate required fields
- [ ] Submit DPR with dynamic field values
- [ ] Update field labels
- [ ] Add custom fields
- [ ] Remove custom fields
- [ ] Store field config in local database
- [ ] Retrieve field config from local database
- [ ] Handle backward compatibility with legacy data
- [ ] Test offline mode with new schema

---

## Troubleshooting

### Issue: Field not visible
**Solution:** Check `visibleWhen` condition and ensure the dependent field value matches.

### Issue: Validation errors
**Solution:** Ensure all `required: true` fields have values in `fieldValues`.

### Issue: Database migration errors
**Solution:** Run `flutter pub run build_runner build --delete-conflicting-outputs` after schema changes.

### Issue: API returns 400 Bad Request
**Solution:** Verify that `fieldValues` structure matches the material's `fieldConfig`.

---

## Future Enhancements

1. **Dynamic Validation Rules**: Support for custom validation rules in field definitions
2. **Conditional Calculations**: Support for dynamic calculation formulas
3. **Field Dependencies**: Advanced field dependency management
4. **Bulk Field Updates**: Update multiple materials' field configs at once
5. **Field Templates**: Reusable field configuration templates
6. **Version Control**: Track field configuration changes over time

---

## Support

For questions or issues related to this implementation:
- Backend API Documentation: See `be.md` file
- Frontend Issues: Contact the Flutter development team
- Database Issues: Check Isar documentation

---

**Last Updated**: March 28, 2026  
**Version**: 1.0.0
