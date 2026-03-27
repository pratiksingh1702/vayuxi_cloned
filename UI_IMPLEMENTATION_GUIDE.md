# Dynamic Insulation DPR - UI Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the dynamic field UI components and integrating them with the local Isar database.

---

## Table of Contents
1. [Files Created](#files-created)
2. [Database Migration](#database-migration)
3. [Sync Service Integration](#sync-service-integration)
4. [UI Component Integration](#ui-component-integration)
5. [Step-by-Step Implementation](#step-by-step-implementation)
6. [Testing Checklist](#testing-checklist)

---

## Files Created

### 1. Dynamic Field Builder Widget
**Path**: `lib/features/modules/all_Modules/dpr/dpr_insu/widgets/dynamic_field_builder.dart`

**Purpose**: Renders form fields dynamically based on `MaterialSetup.fieldConfig`

**Key Features**:
- ✅ Renders fields based on `FieldConfig`
- ✅ Handles conditional field visibility (`visibleWhen`)
- ✅ Geometry mode switching (diameter/circumference)
- ✅ Unit dropdowns with default values
- ✅ Custom label editing in edit mode
- ✅ Type-safe field value management

**Usage**:
```dart
DynamicFieldBuilder(
  materialSetup: materialSetup,
  fieldValues: fieldValues,
  onFieldValuesChanged: (newValues) {
    // Handle field value changes
  },
  isEditMode: false,
  customLabels: customLabels,
  onCustomLabelsChanged: (newLabels) {
    // Handle label changes
  },
)
```

### 2. Material Sync Service
**Path**: `lib/features/modules/all_Modules/dpr/offline/data/material_sync_service.dart`

**Purpose**: Sync MaterialSetup between server and local database

**Key Methods**:
- `syncFromServer()` - Sync all materials from server
- `syncDesignation()` - Sync specific designation (piping/equipment)
- `getMaterials()` - Get materials (offline-first)
- `updateFieldConfig()` - Update field configuration
- `addCustomField()` - Add custom field
- `removeCustomField()` - Remove custom field

**Usage**:
```dart
final syncService = MaterialSyncService();

// Sync from server
final result = await syncService.syncFromServer(siteId: 'site_123');

// Get materials (offline-first)
final materials = await syncService.getMaterials(
  siteId: 'site_123',
  designation: 'equipment',
  preferLocal: true,
);
```

### 3. Updated Local Material DAO
**Path**: `lib/features/modules/all_Modules/dpr/offline/data/local/local_material_dao.dart`

**New Methods**:
- `syncMaterialSetup()` - Store MaterialSetup in local DB
- `getMaterialSetups()` - Retrieve MaterialSetup from local DB
- `storeFieldValues()` - Store field values for a material
- `getFieldValues()` - Get field values for a material
- `updateCustomLabels()` - Update custom labels
- `toEquipmentMaterial()` - Convert LocalMaterial to EquipmentMaterial
- `toPipingMaterial()` - Convert LocalMaterial to PipingMaterial

### 4. Example Implementation
**Path**: `lib/features/modules/all_Modules/dpr/dpr_insu/widgets/dynamic_equipment_card_example.dart`

**Purpose**: Shows how to integrate dynamic fields with existing card UI

---

## Database Migration

### Step 1: Run Build Runner

After the `LocalMaterial` schema has been updated with new fields, regenerate the Isar database files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Verify Schema Changes

The updated `LocalMaterial` schema includes:

```dart
@collection
class LocalMaterial {
  // ... existing fields ...
  
  // NEW: Material Setup Data
  String? materialCode;
  String? calculationType;
  String? fieldConfigJson;
  String? calculationConfigJson;
  bool isDefault = false;
  int displayOrder = 0;
  
  // NEW: Dynamic Field Values
  String? fieldValuesJson;
}
```

### Step 3: Test Database Operations

```dart
final dao = LocalMaterialDao();

// Test sync
final materialSetups = [/* ... */];
await dao.syncMaterialSetup(
  siteId: 'site_123',
  materialSetups: materialSetups,
);

// Test retrieval
final retrieved = await dao.getMaterialSetups(siteId: 'site_123');
print('Retrieved ${retrieved.length} materials');
```

---

## Sync Service Integration

### Step 1: Initialize Sync Service

In your DPR screen or repository:

```dart
class DPRInsulationRepository {
  final MaterialSyncService _syncService = MaterialSyncService();
  
  Future<void> initialize(String siteId) async {
    // Sync materials on app start
    final result = await _syncService.syncFromServer(siteId: siteId);
    
    if (result.success) {
      print('✅ Synced ${result.syncedCount} materials');
    } else {
      print('❌ Sync failed: ${result.message}');
    }
  }
}
```

### Step 2: Implement Pull-to-Refresh

```dart
Future<void> _handleRefresh() async {
  final result = await _syncService.syncFromServer(
    siteId: widget.siteId,
    forceRefresh: true,
  );
  
  if (result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    _loadMaterials(); // Reload from local DB
  }
}

// In build method
RefreshIndicator(
  onRefresh: _handleRefresh,
  child: ListView(...),
)
```

### Step 3: Offline-First Data Loading

```dart
Future<void> _loadMaterials() async {
  setState(() => _isLoading = true);
  
  try {
    // Try local first, fallback to server
    final materials = await _syncService.getMaterials(
      siteId: widget.siteId,
      designation: 'equipment',
      preferLocal: true,
    );
    
    setState(() {
      _materialSetups = materials;
      _isLoading = false;
    });
  } catch (e) {
    print('Error: $e');
    setState(() => _isLoading = false);
  }
}
```

---

## UI Component Integration

### Option 1: Update Existing Cards

You can update your existing `equipment_card.dart` and `piping_card.dart` to support both legacy and dynamic modes:

```dart
class EquipmentMaterialCard extends StatefulWidget {
  final EquipmentMaterial material;
  final MaterialSetup? materialSetup; // NEW: Optional for dynamic mode
  // ... other parameters
}

class _EquipmentMaterialCardState extends State<EquipmentMaterialCard> {
  @override
  Widget build(BuildContext context) {
    // If MaterialSetup is provided, use dynamic rendering
    if (widget.materialSetup != null) {
      return _buildDynamicCard();
    }
    
    // Otherwise, use legacy rendering
    return _buildLegacyCard();
  }
  
  Widget _buildDynamicCard() {
    return Container(
      // ... card container
      child: Column(
        children: [
          _buildHeader(),
          
          // Use DynamicFieldBuilder
          DynamicFieldBuilder(
            materialSetup: widget.materialSetup!,
            fieldValues: _fieldValues,
            onFieldValuesChanged: _handleFieldValuesChanged,
            isEditMode: _isEditMode,
          ),
          
          _buildQuantityField(),
          _buildActionRow(),
        ],
      ),
    );
  }
}
```

### Option 2: Create New Dynamic Cards

Create separate card widgets for dynamic mode (see `dynamic_equipment_card_example.dart`):

```dart
// Use in your DPR screen
DynamicEquipmentCardExample(
  material: material,
  materialSetup: setup,
  onChanged: (updated) { /* ... */ },
  onAdd: () { /* ... */ },
  onDelete: () { /* ... */ },
  onRemark: () { /* ... */ },
)
```

---

## Step-by-Step Implementation

### Phase 1: Database Setup ✅

**Status**: COMPLETED

- [x] Update `LocalMaterial` schema
- [x] Run build_runner
- [x] Update `LocalMaterialDao` with new methods
- [x] Create `MaterialSyncService`

### Phase 2: Sync Integration

**Steps**:

1. **Add sync service to your repository/provider**:

```dart
// lib/features/modules/all_Modules/dpr/dpr_insu/repository/dpr_repository.dart
import '../../offline/data/material_sync_service.dart';

class DPRInsulationRepository {
  final MaterialSyncService _syncService = MaterialSyncService();
  
  Future<List<MaterialSetup>> loadMaterialSetups(String siteId) async {
    return await _syncService.getMaterials(
      siteId: siteId,
      preferLocal: true,
    );
  }
}
```

2. **Initialize sync on app start**:

```dart
// In your main DPR screen initState
@override
void initState() {
  super.initState();
  _initializeData();
}

Future<void> _initializeData() async {
  // Sync materials from server
  final syncResult = await _syncService.syncFromServer(
    siteId: widget.siteId,
  );
  
  if (syncResult.success) {
    _loadMaterials();
  }
}
```

3. **Load materials from local DB**:

```dart
Future<void> _loadMaterials() async {
  final materials = await _syncService.getMaterials(
    siteId: widget.siteId,
    designation: 'equipment',
  );
  
  setState(() {
    _materialSetups = materials;
  });
}
```

### Phase 3: UI Integration

**Steps**:

1. **Update material selection screen**:

```dart
// Show material selection dialog
void _showMaterialSelection() {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return FutureBuilder<List<MaterialSetup>>(
        future: _syncService.getMaterials(
          siteId: widget.siteId,
          designation: 'equipment',
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final setup = snapshot.data![index];
              return ListTile(
                leading: setup.image.isNotEmpty
                    ? Image.network(setup.image.first, width: 40, height: 40)
                    : const Icon(Icons.image),
                title: Text(setup.name),
                subtitle: Text(setup.materialCode),
                onTap: () {
                  _addMaterial(setup);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      );
    },
  );
}
```

2. **Create material from setup**:

```dart
void _addMaterial(MaterialSetup setup) {
  // Initialize field values with defaults
  final fieldValues = FieldValues({});
  
  // Apply default values from fieldConfig
  for (final field in setup.fieldConfig.fields) {
    if (field.unitType != null) {
      final defaultKey = field.dropdown;
      if (defaultKey != null) {
        final defaultValue = setup.fieldConfig.defaults.toJson()[defaultKey];
        if (defaultValue != null) {
          fieldValues['${field.key}Uom'] = defaultValue;
        }
      }
    }
  }
  
  // Apply geometry mode default if exists
  if (setup.fieldConfig.defaults.geometryMode != null) {
    fieldValues['geometryMode'] = setup.fieldConfig.defaults.geometryMode;
  }
  
  final newMaterial = EquipmentMaterial(
    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    name: setup.name,
    image: setup.image,
    uom: setup.uom,
    materialCode: setup.materialCode,
    fieldValues: fieldValues,
  );
  
  setState(() {
    _selectedMaterials.add(newMaterial);
  });
}
```

3. **Render materials with dynamic cards**:

```dart
ListView.builder(
  itemCount: _selectedMaterials.length,
  itemBuilder: (context, index) {
    final material = _selectedMaterials[index];
    
    // Find corresponding MaterialSetup
    final setup = _materialSetups.firstWhere(
      (s) => s.materialCode == material.materialCode,
      orElse: () => _materialSetups.first,
    );
    
    return EquipmentMaterialCard(
      material: material,
      materialSetup: setup, // Pass MaterialSetup for dynamic rendering
      onChanged: (updated) {
        setState(() {
          _selectedMaterials[index] = updated;
        });
      },
      // ... other callbacks
    );
  },
)
```

### Phase 4: DPR Submission

**Steps**:

1. **Prepare DPR data with field values**:

```dart
Future<void> _submitDPR() async {
  final equipmentMaterialsData = _selectedMaterials.map((material) {
    return {
      'name': material.name,
      'materialCode': material.materialCode,
      'fieldValues': material.fieldValues?.toJson() ?? {},
      'customLabels': material.customLabels ?? {},
    };
  }).toList();
  
  final dprData = {
    'designation': 'equipment',
    'layer': _selectedLayer,
    'legging_material_1': _leggingMaterial1,
    'legging_thickness_1': _leggingThickness1,
    'cladding_material': _claddingMaterial,
    'cladding_swg': _claddingSwg,
    'equipment_materials': equipmentMaterialsData,
  };
  
  // Submit to server
  await _dprService.createDPR(
    siteId: widget.siteId,
    teamId: widget.teamId,
    data: dprData,
  );
}
```

2. **Store in local database for offline support**:

```dart
// Store field values in local DB
for (final material in _selectedMaterials) {
  if (material.fieldValues != null) {
    await _localDao.storeFieldValues(
      materialId: material.id,
      fieldValues: material.fieldValues!.values,
    );
  }
  
  if (material.customLabels != null) {
    await _localDao.updateCustomLabels(
      materialId: material.id,
      customLabels: material.customLabels!,
    );
  }
}
```

---

## Testing Checklist

### Database Tests
- [ ] Run build_runner successfully
- [ ] Sync MaterialSetup from server to local DB
- [ ] Retrieve MaterialSetup from local DB
- [ ] Store field values in local DB
- [ ] Retrieve field values from local DB
- [ ] Update custom labels in local DB
- [ ] Convert LocalMaterial to EquipmentMaterial/PipingMaterial

### Sync Service Tests
- [ ] Sync all materials from server
- [ ] Sync specific designation (equipment/piping)
- [ ] Get materials with offline-first strategy
- [ ] Update field configuration
- [ ] Add custom field
- [ ] Remove custom field
- [ ] Check sync status

### UI Tests
- [ ] Render dynamic fields based on FieldConfig
- [ ] Handle conditional field visibility (geometryMode)
- [ ] Switch between diameter and circumference modes
- [ ] Edit custom labels in edit mode
- [ ] Select units from dropdowns
- [ ] Apply default values from FieldConfig
- [ ] Validate required fields
- [ ] Submit DPR with field values
- [ ] Display materials in offline mode

### Integration Tests
- [ ] Create material from MaterialSetup
- [ ] Edit material field values
- [ ] Save material to local DB
- [ ] Sync changes to server
- [ ] Handle offline mode gracefully
- [ ] Pull-to-refresh updates materials
- [ ] Custom field management works end-to-end

---

## Common Issues and Solutions

### Issue 1: Build Runner Fails
**Solution**: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue 2: Field Values Not Persisting
**Solution**: Ensure you're calling `storeFieldValues()` after changes
```dart
await _localDao.storeFieldValues(
  materialId: material.id,
  fieldValues: material.fieldValues!.values,
);
```

### Issue 3: Geometry Mode Not Switching
**Solution**: Check that `allowGeometrySwitch` is true in UiConfig
```dart
final hasGeometrySwitch = materialSetup.fieldConfig.ui.allowGeometrySwitch;
```

### Issue 4: Dropdowns Not Showing Options
**Solution**: Verify unitDropdowns are populated in FieldConfig
```dart
final options = materialSetup.fieldConfig.unitDropdowns.toJson()[field.dropdown];
```

### Issue 5: Custom Labels Not Saving
**Solution**: Call `updateCustomLabels()` when labels change
```dart
await _localDao.updateCustomLabels(
  materialId: material.id,
  customLabels: customLabels,
);
```

---

## Next Steps

1. **Implement in Equipment DPR Screen**
   - Update equipment material selection
   - Integrate DynamicFieldBuilder
   - Test with SHELL material (geometry mode)

2. **Implement in Piping DPR Screen**
   - Update piping material selection
   - Handle size field with constants
   - Test with PIPE and ELBOW materials

3. **Add Custom Field Management UI**
   - Create dialog for adding custom fields
   - Implement field renaming
   - Add field removal confirmation

4. **Implement Report Generation**
   - Update measurement sheet generation
   - Update abstract sheet generation
   - Update invoice sheet generation
   - Generate combined PDF

5. **Testing and Refinement**
   - Test all material types
   - Test offline mode
   - Test sync scenarios
   - Performance optimization

---

## Resources

- **Backend API Documentation**: `be.md`
- **Implementation Guide**: `DYNAMIC_INSULATION_DPR_IMPLEMENTATION.md`
- **Implementation Summary**: `IMPLEMENTATION_SUMMARY.md`
- **This Guide**: `UI_IMPLEMENTATION_GUIDE.md`

---

**Last Updated**: March 28, 2026  
**Version**: 1.0.0  
**Status**: Ready for Implementation
