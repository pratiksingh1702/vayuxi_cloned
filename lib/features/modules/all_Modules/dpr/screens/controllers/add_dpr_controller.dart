// lib/features/modules/all_Modules/dpr/controllers/add_dpr_controller.dart
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


import 'new_state.dart';

final addDescriptionControllerProvider =
StateNotifierProvider.family<AddDescriptionController, AddDprState, TeamModel>(
      (ref, team) => AddDescriptionController(ref: ref, team: team),
);

class AddDescriptionController extends StateNotifier<AddDprState> {
  final Ref ref;
  final TeamModel team;

  // Debouncer map per material id
  final Map<String, Timer> _debouncers = {};

  AddDescriptionController({
    required this.ref,
    required this.team,
  }) : super(const AddDprState()) {
    initializeFromProviders();
  }

  // Initialize form values from other providers
  void initializeFromProviders() {
    try {
      final mocObj = ref.read(selectedMOCProvider);
      final floorObj = ref.read(selectedFloorProvider);
      final sSize = ref.read(selectedSizeProvider);
      state = state.copyWith(
        moc: mocObj?.name ?? '',
        floor: floorObj?.name ?? '',
        size: sSize ?? '',
      );
    } catch (_) {}
  }

  // PUBLIC getters for convenience
  bool get isFormValid =>
      state.dprName.isNotEmpty &&
          state.moc.isNotEmpty &&
          state.floor.isNotEmpty &&
          state.plant.isNotEmpty &&
          (state.pipeFittingOn || state.equipmentOn);

  // Fetch materials once and cache them; sets mechanical id when possible
  Future<void> fetchAvailableMaterials() async {
    if (state.isLoadingMaterials || state.availableMaterials.isNotEmpty) return;
    state = state.copyWith(isLoadingMaterials: true);
    final siteId = ref.read(selectedSiteIdProvider)!;
    final teamId = ref.read(selectedTeamIdProvider)!;

    try {
      await ref.read(dprProvider.notifier).fetchDprWork(
        siteId: siteId,
        teamId: teamId,
      );

      final dprState = ref.read(dprProvider);
      if (dprState.data != null && dprState.data is List<DprModel>) {
        final List<DprModel> list = dprState.data as List<DprModel>;
        final materials = <Map<String, dynamic>>[];
        for (final dpr in list) {
          for (final piping in dpr.piping) {
            materials.add({
              'id': piping.id,
              'materialName': piping.materialName,
              'uom': piping.uom,
              'image': _cleanImageUrl(piping.image),
              'category': 'piping',
              'originalData': piping,
            });
          }
          for (final equipment in dpr.equipment) {
            materials.add({
              'id': equipment.id,
              'materialName': equipment.materialName,
              'uom': equipment.uom,
              'image': _cleanImageUrl(equipment.image),
              'category': 'equipment',
              'originalData': equipment,
            });
          }
        }

        state = state.copyWith(
          availableMaterials: materials,
          mechanicalId: list.isNotEmpty ? list.first.id : null,
        );
      }
    } catch (e) {
      // swallow but mark not loading
    } finally {
      state = state.copyWith(isLoadingMaterials: false);
    }
  }

  // Helpers to get piping/equipment lists (cached)
  List<Map<String, dynamic>> getPipingMaterialsFromAPI() {
    return state.availableMaterials.where((m) => m['category'] == 'piping').toList();
  }

  List<Map<String, dynamic>> getEquipmentMaterialsFromAPI() {
    return state.availableMaterials.where((m) => m['category'] == 'equipment').toList();
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }
  Future<void> fetchMaterials() async {
    if (state.availableMaterials.isNotEmpty) return;

    state = state.copyWith(isLoadingMaterials: true);
    try {
      final siteId = ref.read(selectedSiteIdProvider)!;
      final teamId = ref.read(selectedTeamIdProvider)!;
      await ref.read(dprProvider.notifier).fetchDprWork(siteId: siteId, teamId: teamId);
      final dprState = ref.read(dprProvider);
      final list = (dprState.data as List<DprModel>?) ?? [];

      final materials = <Map<String, dynamic>>[];
      for (final dpr in list) {
        for (final piping in dpr.piping) {
          materials.add({
            'id': piping.id,
            'materialName': piping.materialName,
            'uom': piping.uom,
            'image': piping.image,
            'category': 'piping',
            'originalData': piping,
          });
        }
        for (final equipment in dpr.equipment) {
          materials.add({
            'id': equipment.id,
            'materialName': equipment.materialName,
            'uom': equipment.uom,
            'image': equipment.image,
            'category': 'equipment',
            'originalData': equipment,
          });
        }
      }

      state = state.copyWith(
        availableMaterials: materials,
        mechanicalId: list.isNotEmpty ? list.first.id : null,
      );
    } catch (_) {
      // ignore errors silently
    } finally {
      state = state.copyWith(isLoadingMaterials: false);
    }
  }

  // ✅ Toggle functions: update UI instantly, load materials separately
  void togglePipeFitting(bool value) {
    // 1️⃣ Immediately update UI
    state = state.copyWith(pipeFittingOn: value);

    // 2️⃣ Clear old selections if turning off
    if (!value) {
      state = state.copyWith(
        selectedPipingMaterials: [],
        cardInputs: state.cardInputs.where((c) => c['category'] != 'piping').toList(),
      );
    }

    // 3️⃣ Trigger async loading if turning on
    if (value && state.selectedPipingMaterials.isEmpty) {
      // fire-and-forget; UI won't wait
      _loadPipingAsync();
    }
  }

// Private async loader
  Future<void> _loadPipingAsync() async {
    state = state.copyWith(pipingLoadState: MaterialLoadState.loading);

    try {
      await fetchMaterials(); // loads all materials if not already
      final piping = state.availableMaterials.where((m) => m['category'] == 'piping').toList();
      final cards = piping.map(_createCardInput).toList();

      state = state.copyWith(
        selectedPipingMaterials: piping,
        cardInputs: [...state.cardInputs, ...cards],
        pipingLoadState: MaterialLoadState.loaded,
      );
    } catch (_) {
      state = state.copyWith(pipingLoadState: MaterialLoadState.error);
    }
  }

  void toggleEquipment(bool value) {
    state = state.copyWith(equipmentOn: value);
    if (value && state.selectedEquipmentMaterials.isEmpty) loadEquipmentMaterials();
    if (!value) {
      state = state.copyWith(
        selectedEquipmentMaterials: [],
        cardInputs: state.cardInputs.where((c) => c['category'] != 'equipment').toList(),
      );
    }
  }

  Future<void> loadPipingMaterials() async {
    state = state.copyWith(pipingLoadState: MaterialLoadState.loading);
    await fetchMaterials();
    final piping = state.availableMaterials.where((m) => m['category'] == 'piping').toList();
    final cards = piping.map(_createCardInput).toList();
    state = state.copyWith(
      selectedPipingMaterials: piping,
      cardInputs: [...state.cardInputs, ...cards],
      pipingLoadState: MaterialLoadState.loaded,
    );
  }

  Future<void> loadEquipmentMaterials() async {
    state = state.copyWith(equipmentLoadState: MaterialLoadState.loading);
    await fetchMaterials();
    final equipment = state.availableMaterials.where((m) => m['category'] == 'equipment').toList();
    final cards = equipment.map(_createCardInput).toList();
    state = state.copyWith(
      selectedEquipmentMaterials: equipment,
      cardInputs: [...state.cardInputs, ...cards],
      equipmentLoadState: MaterialLoadState.loaded,
    );
  }

  Map<String, dynamic> _createCardInput(Map<String, dynamic> material) => {
    'id': material['id'],
    'floor': state.floor,
    'moc': state.moc,
    'quantity': '0',
    'size': state.size,
    'length': '0',
    if (material['category'] == 'equipment') 'ton': '0',
    'materialName': material['materialName'],
    'uom': material['uom'],
    'image': material['image'],
    'category': material['category'],
  };

  // Load piping materials on demand (shows section loader)
  Future<void> loadPipingFromAPI() async {
    if (state.pipingLoadState != MaterialLoadState.idle) return;

    state = state.copyWith(pipingLoadState: MaterialLoadState.loading);

    try {
      if (state.availableMaterials.isEmpty) {
        await fetchAvailableMaterials();
      }

      final piping = getPipingMaterialsFromAPI();

      final selected = <Map<String, dynamic>>[];
      final cards = <Map<String, dynamic>>[];

      for (final m in piping) {
        selected.add(m);
        cards.add(_createCardInput(m));
      }

      state = state.copyWith(
        selectedPipingMaterials: selected,
        cardInputs: [...state.cardInputs, ...cards],
        pipingLoadState: MaterialLoadState.loaded,
      );
    } catch (_) {
      state = state.copyWith(pipingLoadState: MaterialLoadState.error);
    }
  }

  Future<void> loadEquipmentFromAPI() async {
    if (state.equipmentLoadState != MaterialLoadState.idle) return;

    state = state.copyWith(equipmentLoadState: MaterialLoadState.loading);

    try {
      if (state.availableMaterials.isEmpty) {
        await fetchAvailableMaterials();
      }

      final equipment = getEquipmentMaterialsFromAPI();

      final selected = <Map<String, dynamic>>[];
      final cards = <Map<String, dynamic>>[];

      for (final m in equipment) {
        selected.add(m);
        cards.add(_createCardInput(m));
      }

      state = state.copyWith(
        selectedEquipmentMaterials: selected,
        cardInputs: [...state.cardInputs, ...cards],
        equipmentLoadState: MaterialLoadState.loaded,
      );
    } catch (_) {
      state = state.copyWith(equipmentLoadState: MaterialLoadState.error);
    }
  }

  // Add selected materials from modal
  void addMaterials(List<Map<String, dynamic>> selectedMaterials) {
    final piping = List<Map<String, dynamic>>.from(state.selectedPipingMaterials);
    final equipment = List<Map<String, dynamic>>.from(state.selectedEquipmentMaterials);
    final cards = List<Map<String, dynamic>>.from(state.cardInputs);

    for (final material in selectedMaterials) {
      final id = material['id'] as String;
      final alreadyInCards = cards.any((c) => c['id'] == id);
      if (!alreadyInCards) {
        cards.add(_createCardInput(material));
      }
      if (material['category'] == 'piping') {
        if (!piping.any((p) => p['id'] == id)) piping.add(material);
      } else {
        if (!equipment.any((e) => e['id'] == id)) equipment.add(material);
      }
    }

    state = state.copyWith(
      cardInputs: cards,
      selectedPipingMaterials: piping,
      selectedEquipmentMaterials: equipment,
    );
  }

  // Map<String, dynamic> _createCardInput(Map<String, dynamic> material) {
  //   final isEquipment = material['category'] == 'equipment';
  //   return {
  //     'id': material['id'],
  //     'floor': state.floor,
  //     'moc': state.moc,
  //     'quantity': '0',
  //     'size': state.size,
  //     'length': '0',
  //     if (isEquipment) 'ton': '0',
  //     'materialName': material['materialName'],
  //     'uom': material['uom'],
  //     'image': material['image'],
  //     'category': material['category'],
  //   };
  // }

  // Copy material (create cloned entry with unique client id)
  void copyMaterial(String materialId) {
    final original = state.cardInputs.firstWhere((c) => c['id'] == materialId, orElse: () => {});
    if (original.isEmpty) return;
    final newId = '${materialId}_clone_${DateTime.now().millisecondsSinceEpoch}';
    final cloned = Map<String, dynamic>.from(original)..['id'] = newId;

    final cards = List<Map<String, dynamic>>.from(state.cardInputs)..add(cloned);

    // also clone in the selected lists depending on category
    if (original['category'] == 'piping') {
      final existing = List<Map<String, dynamic>>.from(state.selectedPipingMaterials)
        ..add(Map<String, dynamic>.from(state.selectedPipingMaterials.firstWhere((e) => e['id'] == materialId))..['id'] = newId);
      state = state.copyWith(cardInputs: cards, selectedPipingMaterials: existing);
    } else {
      final existing = List<Map<String, dynamic>>.from(state.selectedEquipmentMaterials)
        ..add(Map<String, dynamic>.from(state.selectedEquipmentMaterials.firstWhere((e) => e['id'] == materialId))..['id'] = newId);
      state = state.copyWith(cardInputs: cards, selectedEquipmentMaterials: existing);
    }
  }

  // Delete material
  void deleteMaterial(String materialId) {
    final cards = List<Map<String, dynamic>>.from(state.cardInputs)
      ..removeWhere((c) => c['id'] == materialId);
    final piping = List<Map<String, dynamic>>.from(state.selectedPipingMaterials)
      ..removeWhere((p) => p['id'] == materialId);
    final equipment = List<Map<String, dynamic>>.from(state.selectedEquipmentMaterials)
      ..removeWhere((e) => e['id'] == materialId);

    state = state.copyWith(cardInputs: cards, selectedPipingMaterials: piping, selectedEquipmentMaterials: equipment);
  }

  // Update card input with real debouncing per id
  void updateCardInput(String id, String field, String value) {
    final cards = List<Map<String, dynamic>>.from(state.cardInputs);
    final idx = cards.indexWhere((c) => c['id'] == id);
    if (idx != -1) {
      cards[idx][field] = value;
      state = state.copyWith(cardInputs: cards);
    }

    // debounce per-id
    _debouncers[id]?.cancel();
    _debouncers[id] = Timer(const Duration(milliseconds: 600), () {
      _performMaterialUpdate(id);
      _debouncers.remove(id);
    });
  }

  void _performMaterialUpdate(String materialId) {
    final input = state.cardInputs.firstWhere((c) => c['id'] == materialId, orElse: () => {});
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

    final mechanicalId = state.mechanicalId;
    if (mechanicalId == null) return;

    // Fire-and-forget update through dprProvider
    ref.read(dprProvider.notifier).updateMaterialQty(
      data: formData,
      mechanicalID: mechanicalId,
      materialId: materialId,
    );
  }

  // Submit DPR
  Future<void> submitDpr() async {
    final validation = _validateForm();
    if (validation != null) {
      // attach validation error
      state = state.copyWith(validationErrors: {'form': validation});
      throw Exception(validation);
    }
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final newDprData = {
        'dprName': state.dprName,
        'moc': state.moc,
        'size': state.size,
        'location': state.floor,
        'plant': state.plant,
        'piping': state.selectedPipingMaterials,
        'equipment': state.selectedEquipmentMaterials,
        'designation': _getDesignation(),
      };

      final siteId = ref.read(selectedSiteIdProvider)!;
      final teamId = ref.read(selectedTeamIdProvider)!;

      await ref.read(dprProvider.notifier).postDprWork(
        data: newDprData,
        siteId: siteId,
        teamId: teamId,
      );

      // after successful post you may want to clear or navigate
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  String? _validateForm() {
    if (state.dprName.isEmpty) return 'Please enter DPR name';
    if (state.moc.isEmpty) return 'Please select MOC';
    if (state.floor.isEmpty) return 'Please select location';
    if (state.plant.isEmpty) return 'Please enter plant';
    if (!state.pipeFittingOn && !state.equipmentOn) {
      return 'Please select at least one type (Pipe Fitting or Equipment)';
    }
    return null;
  }

  String _getDesignation() {
    final designations = <String>[];
    if (state.pipeFittingOn) designations.add('piping');
    if (state.equipmentOn) designations.add('equipment');
    return designations.join(',');
  }

  // Update simple fields
  void updateDprName(String value) => state = state.copyWith(dprName: value);
  void updateMoc(String value) => state = state.copyWith(moc: value);
  void updateFloor(String value) => state = state.copyWith(floor: value);
  void updateSize(String value) => state = state.copyWith(size: value);
  void updatePlant(String value) => state = state.copyWith(plant: value);

  // Clean all
  void clear() {
    state = const AddDprState();
  }
}
