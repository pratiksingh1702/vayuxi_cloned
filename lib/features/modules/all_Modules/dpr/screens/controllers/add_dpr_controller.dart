
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/dprModel.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dpr.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../../team/provider/teamProvider.dart';
import '../../providers/floorProvider.dart';
import '../../providers/mocProvider.dart';
import '../../providers/selectedSize_provider.dart';

class AddDescriptionController {
  final Ref ref;
  String? _mechanicalId;



  final TeamModel team;

  List<DprModel> _availableMaterials = [];
  List<Map<String, dynamic>> _selectedPipingMaterials = [];
  List<Map<String, dynamic>> _selectedEquipmentMaterials = [];
  Set<String> _pendingUpdates = {};
  List<Map<String, dynamic>> _cardInputs = [];

  // Cache for optimization
  List<Map<String, dynamic>>? _cachedPipingMaterials;
  List<Map<String, dynamic>>? _cachedEquipmentMaterials;

  // State variables
  bool isSubmitting = false;
  bool isLoadingMaterials = false;
  bool isEditingName = true;


  // Form values
  String dprName = 'New DPR Entry';
  String moc = '';
  String floor = '';
  String size = '';
  String plant = '';
  bool pipeFittingOn = false;
  bool equipmentOn = false;

  AddDescriptionController({
    required this.ref,

    required this.team,
  });


  // Getters
  List<Map<String, dynamic>> get selectedPipingMaterials => _selectedPipingMaterials;
  List<Map<String, dynamic>> get selectedEquipmentMaterials => _selectedEquipmentMaterials;
  List<Map<String, dynamic>> get cardInputs => _cardInputs;
  Set<String> get pendingUpdates => _pendingUpdates;

  // Initialize data from providers
  void initializeFromProviders() {
    moc = ref.read(selectedMOCProvider)!.name;
    floor = ref.read(selectedFloorProvider)!.name;
    size = ref.read(selectedSizeProvider)!;
    plant = '';
    pipeFittingOn = false;
    equipmentOn = false;

  }
  void setMechanicalIdFromResponse(List<DprModel> dprList) {
    if (dprList.isNotEmpty) {
      _mechanicalId = dprList.first.id;
      print('✅ Set mechanical ID from DPR response: $_mechanicalId');
    } else {
      print('⚠️ No DPR data found to extract mechanical ID');
    }
  }

  // Or extract from a single DPR
  void setMechanicalId(String id) {
    _mechanicalId = id;
    print('✅ Set mechanical ID: $_mechanicalId');
  }
  void debugIds() {
    print('🔍 ID DEBUG:');
    final siteId=ref.read(selectedSiteIdProvider)!;
    final teamId=ref.read(selectedTeamIdProvider)!;
    print('   Site ID: $siteId');
    print('   Team ID: $teamId');
    print('   Mechanical ID: $_mechanicalId');

    if (_selectedPipingMaterials.isNotEmpty) {
      print('   First piping material ID: ${_selectedPipingMaterials.first['id']}');
    }
    if (_selectedEquipmentMaterials.isNotEmpty) {
      print('   First equipment material ID: ${_selectedEquipmentMaterials.first['id']}');
    }
  }



  // Fetch available materials
  Future<void> fetchAvailableMaterials() async {
    if (isLoadingMaterials || _availableMaterials.isNotEmpty) return;

    isLoadingMaterials = true;
    final siteId=ref.read(selectedSiteIdProvider)!;
    final teamId=ref.read(selectedTeamIdProvider)!;


    try {
      await ref.read(dprProvider.notifier).fetchDprWork(
        siteId: siteId,
        teamId: teamId,
      );

      final dprState = ref.read(dprProvider);
      if (dprState.data != null && dprState.data is List<DprModel>) {
        _availableMaterials = dprState.data as List<DprModel>;
        if (_availableMaterials.isNotEmpty) {
          setMechanicalIdFromResponse(_availableMaterials);
          debugIds(); // Debug print
        }

        // Clear cache when new data arrives
        _cachedPipingMaterials = null;
        _cachedEquipmentMaterials = null;
      }
    } catch (e) {
      throw Exception('Failed to load materials: $e');
    } finally {
      isLoadingMaterials = false;
    }
  }

  // Get piping materials from API with caching
  List<Map<String, dynamic>> getPipingMaterialsFromAPI() {
    if (_cachedPipingMaterials != null) {
      return _cachedPipingMaterials!;
    }

    final List<Map<String, dynamic>> pipingMaterials = [];
    for (final dpr in _availableMaterials) {
      for (final piping in dpr.piping) {
        pipingMaterials.add({
          'id': piping.id,
          'materialName': piping.materialName,
          'uom': piping.uom,
          'image': _cleanImageUrl(piping.image),
          'category': 'piping',
          'originalData': piping,
        });
      }
    }

    _cachedPipingMaterials = pipingMaterials;
    return pipingMaterials;
  }

  // Get equipment materials from API with caching
  List<Map<String, dynamic>> getEquipmentMaterialsFromAPI() {
    if (_cachedEquipmentMaterials != null) {
      return _cachedEquipmentMaterials!;
    }

    final List<Map<String, dynamic>> equipmentMaterials = [];
    for (final dpr in _availableMaterials) {
      for (final equipment in dpr.equipment) {
        equipmentMaterials.add({
          'id': equipment.id,
          'materialName': equipment.materialName,
          'uom': equipment.uom,
          'image': _cleanImageUrl(equipment.image),
          'category': 'equipment',
          'originalData': equipment,
        });
      }
    }

    _cachedEquipmentMaterials = equipmentMaterials;
    return equipmentMaterials;
  }

  // Clean image URLs
  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  // Toggle pipe fitting
  void togglePipeFitting(bool value) {
    pipeFittingOn = value;
    if (value && _selectedPipingMaterials.isEmpty) {
      _addDefaultPipingMaterials();
    } else if (!value) {
      _selectedPipingMaterials.clear();
      _removePipingCardInputs();
    }
  }

  // Toggle equipment
  void toggleEquipment(bool value) {
    equipmentOn = value;
    if (value && _selectedEquipmentMaterials.isEmpty) {
      _addDefaultEquipmentMaterials();
    } else if (!value) {
      _selectedEquipmentMaterials.clear();
      _removeEquipmentCardInputs();
    }
  }

  // Add default piping materials when toggled on
  void _addDefaultPipingMaterials() {
    final materials = getPipingMaterialsFromAPI();
    if (materials.isNotEmpty) {
      for (final material in materials) { // Add first 2 as default
        if (!_selectedPipingMaterials.any((item) => item['id'] == material['id'])) {
          _selectedPipingMaterials.add(material);
          _cardInputs.add(_createCardInput(material));
        }
      }
    }
  }

  // Add default equipment materials when toggled on
  void _addDefaultEquipmentMaterials() {
    final materials = getEquipmentMaterialsFromAPI();
    if (materials.isNotEmpty) {
      for (final material in materials) { // Add first 2 as default
        if (!_selectedEquipmentMaterials.any((item) => item['id'] == material['id'])) {
          _selectedEquipmentMaterials.add(material);
          _cardInputs.add(_createCardInput(material));
        }
      }
    }
  }

  Map<String, dynamic> _createCardInput(Map<String, dynamic> material) {
    final isEquipment = material['category'] == 'equipment';

    return {
      'id': material['id'],
      'floor': floor,
      'moc': moc,
      'quantity': '0',
      'size': size,
      'length': '0',
      if (isEquipment) 'ton': '0',
      'materialName': material['materialName'],
      'uom': material['uom'],
      'image': material['image'],
      'category': material['category'],
    };
  }

  // Remove piping card inputs
  void _removePipingCardInputs() {
    _cardInputs.removeWhere((input) => input['category'] == 'piping');
  }

  // Remove equipment card inputs
  void _removeEquipmentCardInputs() {
    _cardInputs.removeWhere((input) => input['category'] == 'equipment');
  }

  // Update card input values
  void updateCardInput(String id, String field, String value) {
    final index = _cardInputs.indexWhere((input) => input['id'] == id);
    if (index != -1) {
      _cardInputs[index][field] = value;
    }
    _pendingUpdates.add(id);

    // Debounced update
    Timer(const Duration(milliseconds: 500), () {
      if (_pendingUpdates.contains(id)) {
        _performMaterialUpdate(id);
      }
    });
  }

  // Perform material update to API
  void _performMaterialUpdate(String materialId) {
    final input = _cardInputs.firstWhere(
          (input) => input['id'] == materialId,
      orElse: () => {},
    );

    if (input.isEmpty) return;

    final formData = {
      '_id': materialId,
      'moc': input['moc'] ?? '',
      'qty': input['quantity'] ?? '0',
      'size': input['size'] ?? '',
      'location': input['floor'] ?? '',
      'length': input['length'] ?? '0',
      if (input.containsKey('ton')) 'weight': input['ton'] ?? '0',
    };

    ref.read(dprProvider.notifier).updateMaterialQty(
      data: formData,
      mechanicalID: _mechanicalId!,
      materialId: materialId,
    );

    _pendingUpdates.remove(materialId);
  }

  // Add new material (for manual addition)
  void addMaterial(Map<String, dynamic> material) {
    final isPiping = material['category'] == 'piping';

    if (isPiping) {
      if (!_selectedPipingMaterials.any((item) => item['id'] == material['id'])) {
        _selectedPipingMaterials.add(material);
      }
    } else {
      if (!_selectedEquipmentMaterials.any((item) => item['id'] == material['id'])) {
        _selectedEquipmentMaterials.add(material);
      }
    }

    if (!_cardInputs.any((input) => input['id'] == material['id'])) {
      _cardInputs.add(_createCardInput(material));
    }
  }

  // Copy material
  void copyMaterial(String materialId) {
    final originalMaterial = _cardInputs.firstWhere(
          (input) => input['id'] == materialId,
      orElse: () => {},
    );

    if (originalMaterial.isNotEmpty) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final copiedMaterial = Map<String, dynamic>.from(originalMaterial)..['id'] = newId;

      _cardInputs.add(copiedMaterial);

      final isPiping = _selectedPipingMaterials.any((item) => item['id'] == materialId);
      if (isPiping) {
        final copiedPiping = Map<String, dynamic>.from(
            _selectedPipingMaterials.firstWhere((item) => item['id'] == materialId)
        )..['id'] = newId;
        _selectedPipingMaterials.add(copiedPiping);
      } else {
        final copiedEquipment = Map<String, dynamic>.from(
            _selectedEquipmentMaterials.firstWhere((item) => item['id'] == materialId)
        )..['id'] = newId;
        _selectedEquipmentMaterials.add(copiedEquipment);
      }
    }
  }

  // Delete material
  void deleteMaterial(String materialId) {
    _cardInputs.removeWhere((input) => input['id'] == materialId);
    _selectedPipingMaterials.removeWhere((item) => item['id'] == materialId);
    _selectedEquipmentMaterials.removeWhere((item) => item['id'] == materialId);
  }

  // Validate form
  String? validateForm() {
    if (dprName.isEmpty) return 'Please enter DPR name';
    if (moc.isEmpty) return 'Please select MOC';
    if (floor.isEmpty) return 'Please select location';
    if (plant.isEmpty) return 'Please enter plant';
    if (!pipeFittingOn && !equipmentOn) {
      return 'Please select at least one type (Pipe Fitting or Equipment)';
    }
    return null;
  }

  // Get designation string
  String getDesignation() {
    final designations = <String>[];
    if (pipeFittingOn) designations.add('piping');
    if (equipmentOn) designations.add('equipment');
    return designations.join(',');
  }

  // Submit DPR
  Future<void> submitDpr() async {
    final validationError = validateForm();
    if (validationError != null) {
      throw Exception(validationError);
    }

    if (isSubmitting) return;
    isSubmitting = true;

    try {
      final newDprData = {
        'dprName': dprName,
        'moc': moc,
        'size': size,
        'location': floor,
        'plant': plant,
        'piping': _selectedPipingMaterials,
        'equipment': _selectedEquipmentMaterials,
        'designation': getDesignation(),
      };
      final siteId=ref.read(selectedSiteIdProvider)!;
      final teamId=ref.read(selectedTeamIdProvider)!;

      await ref.read(dprProvider.notifier).postDprWork(
        data: newDprData,
        siteId: siteId,
        teamId: teamId,
      );
    } finally {
      isSubmitting = false;
    }
  }

  // Clear all data
  void clear() {
    _availableMaterials.clear();
    _selectedPipingMaterials.clear();
    _selectedEquipmentMaterials.clear();
    _cardInputs.clear();
    _pendingUpdates.clear();
    _cachedPipingMaterials = null;
    _cachedEquipmentMaterials = null;

    dprName = 'New DPR Entry';
    moc = '';
    floor = '';
    size = '';
    plant = '';
    pipeFittingOn = false;
    equipmentOn = false;
    isSubmitting = false;
    isLoadingMaterials = false;
    isEditingName = true;
  }
}