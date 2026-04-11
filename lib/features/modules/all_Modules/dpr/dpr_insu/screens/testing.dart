import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/local/local_material.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import '../../../../../../core/utlis/common_functions.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../offline/data/local/cache_image_dao.dart';
import '../../offline/data/local/local_material_dao.dart';
import '../../offline/data/material_sync_service.dart';
import '../../offline/data/repo/material_repo_provider.dart';
import '../../providers/selectedSize_provider.dart';
import '../../screens/add_description.dart';
import '../../utils/image_track/material_image_upload_service.dart';
import '../model/card_form_State.dart';
import '../model/dpr_model_insu.dart';
import '../model/eqip_insu.dart';
import '../model/field_config.dart' hide FieldEntry;
import '../model/insu_step_date.dart';
import '../model/material_setup.dart';
import '../model/piping_insu.dart';
import '../providers/draft_insu.dart';
import '../providers/insu_equipment.dart';
import '../providers/insu_piping.dart';
import '../providers/material_load.dart';
import '../providers/material_util.dart';
import '../service/insulation_dpr_service.dart';
import '../service/material_service.dart';
import '../widgets/equipment_card.dart';
import '../widgets/piping_card.dart';
import '../../../../../../core/utlis/widgets/shimmer.dart';
import '../model/field_config.dart' as fc;

class AddInsulationDescriptionScreen extends ConsumerStatefulWidget {
  final InsulationDprModel? work;

  const AddInsulationDescriptionScreen({super.key, this.work});

  @override
  ConsumerState<AddInsulationDescriptionScreen> createState() =>
      _AddInsulationDescriptionScreenState();
}

class _AddInsulationDescriptionScreenState
    extends ConsumerState<AddInsulationDescriptionScreen> {
  late final TextEditingController _dprNameController;
  late final TextEditingController _mocController;
  late final TextEditingController _sizeController;
  late final TextEditingController _plantController;
  late final TextEditingController _floorController;

  // Insulation-specific controllers
  late final TextEditingController _layerNameController;
  late final TextEditingController _thicknessController;
  late final TextEditingController _claddingNameController;
  late final TextEditingController _claddingThicknessController;
  late TextEditingController _claddingController;

  late String siteId;
  late String teamId;
  late TeamModel team;

  InsulationDprApi service = InsulationDprApi();

  String? _insulationId;
  String? _selectedDprId;

  bool _pipeInsulationOn = true;
  bool _equipmentInsulationOn = true;
  bool _editMode = true;
  bool _globalEditMode = false;
  bool _showPipingMaterials = true;
  bool _showEquipmentMaterials = true;

  DateTime _selectedDate = DateTime.now();

  // Material setup state
  final MaterialSyncService _syncService = MaterialSyncService();
  List<MaterialSetup> _pipingSetups = [];
  List<MaterialSetup> _equipmentSetups = [];
  bool _setupsLoaded = false;

  bool _isLoadingMaterials = false;
  bool _isSubmitting = false;
  bool _isCreatingWork = false;
  bool _isDisposed = false;
  bool _initialDataLoaded = false;
  bool _autoCreateAttempted = false;
  bool _removeLagging = false;
  bool _removeCladding = false;
  bool _materialListenerAttached = false;
  bool _isEditingExistingWork = false;

  List<InsulationDprModel> _dprListForSelectedDate = [];
  bool _isLoadingDprList = false;
  bool _isDateOverrideMode = false;

  // Insulation layer state
  LayerType _selectedLayerType = LayerType.single;
  final List<LayerData> _layers = [];
  LayerData _cladding = LayerData.empty();

  final Map<String, GlobalKey<State<EquipmentMaterialCard>>> _equipmentKeys =
      {};
  final Map<String, GlobalKey<State<PipingMaterialCard>>> _pipingKeys = {};

  bool get isCreatingDpr => _insulationId == null;
  bool get isEditingDpr => _insulationId != null;
  bool get isEditing => _insulationId != null;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
    _isEditingExistingWork = widget.work != null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(insulationPipingMaterialsProvider.notifier).clear();
      ref.read(insulationEquipmentMaterialsProvider.notifier).clear();

      if (!mounted) return;

      if (widget.work != null) {
        // ✅ Step 1: immediately set materials from work (no waiting)
        //    Cards render with correct qty/size from day 1
        // Set materials FIRST so cards show immediately with correct data
        _initializeFromWorkImmediate(widget.work!);

        // THEN load setups in background for field config
        // When setups load, setState triggers rebuild with proper materialSetup
        await _loadMaterialSetupsOnly(siteId);

        // Re-hydrate equipment cardFormState now that setups are available
        if (mounted) _rehydrateEquipmentWithSetups();
      } else {
        setState(() => _isLoadingMaterials = true);
        _loadMaterialSetups(siteId);
        setState(() => _loadLayersFromProvider());
      }
    });
  }

// ✅ Sets all UI state and providers immediately — no setup dependency
  void _initializeFromWorkImmediate(InsulationDprModel work) {
    setState(() {
      _insulationId = work.id;
      _selectedDprId = work.id;
      _selectedDate = work.date;
      _dprNameController.text = work.workDescription;
      _plantController.text = work.plant ?? '';
      _floorController.text = work.location;
      ref.read(dprSizeProvider.notifier).state = work.size.toString();
      _sizeController.text = work.size.toString();
      _pipeInsulationOn = work.pipingMaterials.isNotEmpty;
      _equipmentInsulationOn = work.equipmentMaterials.isNotEmpty;
      _showPipingMaterials = _pipeInsulationOn;
      _showEquipmentMaterials = _equipmentInsulationOn;
      _loadLayersFromModel(work);
    });

    // Set piping directly — all data is on the flat model, no setup needed
    ref
        .read(insulationPipingMaterialsProvider.notifier)
        .setMaterials(work.pipingMaterials);

    // Set equipment with cardFormState built from fieldValues (API data)
    final equipmentWithState = work.equipmentMaterials.map((e) {
      // Build cardFormState purely from API fieldValues — no setup needed
      final cardState = _buildCardStateFromFieldValues(e);
      return e.copyWith(cardFormState: cardState);
    }).toList();

    ref
        .read(insulationEquipmentMaterialsProvider.notifier)
        .setMaterials(equipmentWithState);
  }

// ✅ Build CardFormState purely from the API's fieldValues map
//    No setup/schema needed — just read what the server sent
// ✅ Fix 1 & 2: Remove field_config.dart import conflict
// In your imports, use a prefix for field_config to avoid FieldEntry clash:

// Now FieldEntry from card_form_State.dart is the default one used everywhere
// and fc.FieldEntry refers to the one in field_config.dart (which you won't need)

// ✅ Fix 3 & 4: Corrected _buildCardStateFromFieldValues
  CardFormState _buildCardStateFromFieldValues(EquipmentMaterial e) {
    if (e.cardFormState != null && e.cardFormState!.fieldEntries.isNotEmpty) {
      return e.cardFormState!;
    }

    final fieldValuesMap = e.fieldValues?.values;

    if (fieldValuesMap == null || fieldValuesMap.isEmpty) {
      return const CardFormState(
        fieldEntries: {},
        geometryMode: null,
        customLabels: {},
      );
    }

    final geometryMode = fieldValuesMap['geometryMode']?.toString();

    // ✅ Explicitly typed as card_form_State.dart's FieldEntry
    final entries =
        <String, FieldEntry>{}; // FieldEntry from card_form_State.dart

    fieldValuesMap.forEach((key, value) {
      if (key.endsWith('Uom') || key == 'geometryMode') return;
      final unit = fieldValuesMap['${key}Uom']?.toString();
      entries[key] = FieldEntry(value: value, unit: unit ?? '');
    });

    return CardFormState(
      fieldEntries: entries,
      geometryMode: geometryMode,
      customLabels: const {},
    );
  }

// ✅ Fix 4: Corrected _rehydrateEquipmentWithSetups
// FieldDefinition has no defaultUnit — resolve unit from fieldConfig.defaults
  void _rehydrateEquipmentWithSetups() {
    final existing = ref.read(insulationEquipmentMaterialsProvider);

    final rehydrated = existing.map((e) {
      final setup = _equipmentSetups.firstWhere(
        (s) => s.materialCode == e.materialCode,
        orElse: () => _emptySetup(e, siteId),
      );

      if (e.cardFormState != null && e.cardFormState!.fieldEntries.isNotEmpty) {
        var state = e.cardFormState!;

        // Add missing fields from setup schema without overwriting existing values
        for (final field in setup.fieldConfig.fields) {
          if (!state.fieldEntries.containsKey(field.key)) {
            // Resolve default unit from fieldConfig.defaults (not field.defaultUnit)
            String? defaultUnit;
            if (field.dropdown != null) {
              defaultUnit =
                  setup.fieldConfig.defaults.defaultFor(field.dropdown!);
              // Fallback: first option in the dropdown list
              if (defaultUnit == null) {
                final opts =
                    setup.fieldConfig.unitDropdowns.optionsFor(field.dropdown!);
                defaultUnit = opts.isNotEmpty ? opts.first : null;
              }
            }
            state = state.updateValue(field.key, null);
            if (defaultUnit != null) {
              state = state.updateUnit(field.key, defaultUnit);
            }
          }
        }

        // Set geometryMode from setup defaults if missing in state
        if ((state.geometryMode == null || state.geometryMode!.isEmpty) &&
            setup.fieldConfig.defaults.geometryMode != null) {
          state = state.copyWith(
            geometryMode: setup.fieldConfig.defaults.geometryMode,
          );
        }

        return e.copyWith(cardFormState: state);
      }

      // No cardFormState — build fresh from setup schema
      return e.copyWith(
        cardFormState:
            CardFormState.buildInitial(fieldConfig: setup.fieldConfig),
      );
    }).toList();

    ref
        .read(insulationEquipmentMaterialsProvider.notifier)
        .setMaterials(rehydrated);
  }

// Keep _initializeFromWork for the dropdown DPR selection case
  void _initializeFromWork(InsulationDprModel work) {
    ref.read(insulationPipingMaterialsProvider.notifier).clear();
    ref.read(insulationEquipmentMaterialsProvider.notifier).clear();
    _initializeFromWorkImmediate(work);
  }

  Future<void> _loadMaterialSetupsOnly(String siteId) async {
    try {
      var piping = await _syncService.getMaterials(
        siteId: siteId,
        designation: 'piping',
        preferLocal: true,
      );
      var equipment = await _syncService.getMaterials(
        siteId: siteId,
        designation: 'equipment',
        preferLocal: true,
      );

      // Resolve cached images
      piping = await _resolveSetupImages(piping);
      equipment = await _resolveSetupImages(equipment);

      if (mounted) {
        setState(() {
          _pipingSetups = piping;
          _equipmentSetups = equipment;
          _setupsLoaded = true;
        });
      }
      // ✅ No _attachMaterialListeners() call — work model owns the state
    } catch (e) {
      if (mounted) setState(() => _setupsLoaded = true);
    } finally {
      if (mounted) setState(() => _isLoadingMaterials = false);
    }
  }

  Future<void> _loadMaterials() async {
    final repo = ref.read(materialRepositoryProvider);
    print("77777777777777777777");

    if (!mounted) return;

    // setState(() {
    //   _isLoadingMaterials = true;
    // });
    await Future.delayed(const Duration(milliseconds: 16));

    try {
      await repo.syncInBackground(
        siteId: siteId,
        domain: 'insulation',
        designation: '',
      );

      _attachMaterialListeners();
    } catch (e, stack) {
      debugPrint("❌ Material sync failed: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingMaterials = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // MATERIAL SETUP LOADING
  // ─────────────────────────────────────────────

  Future<void> _loadMaterialSetups(String siteId) async {
    try {
      final piping = await _syncService.getMaterials(
        siteId: siteId,
        designation: 'piping',
        preferLocal: true,
      );
      final equipment = await _syncService.getMaterials(
        siteId: siteId,
        designation: 'equipment',
        preferLocal: true,
      );

      if (mounted) {
        setState(() {
          _pipingSetups = piping;
          _equipmentSetups = equipment;
          _setupsLoaded = true;
        });
        debugPrint('✅ Loaded ${piping.length} piping / '
            '${equipment.length} equipment setups');
      }

      // ✅ CRITICAL FIX: Initialize equipment materials with cardFormState
      final equipmentWithState = equipment.map((setup) {
        return EquipmentMaterial(
          id: setup.id,
          name: setup.name,
          materialCode: setup.materialCode,
          image: setup.image,
          uom: setup.uom,
          remarks: '',
          // 🔥 Initialize cardFormState from the setup's fieldConfig
          cardFormState: CardFormState.buildInitial(
            fieldConfig: setup.fieldConfig,
          ),
          qty: 0,
          customLabels: {},
        );
      }).toList();

      // Update the equipment provider with initialized materials
      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .updateSetups(equipment);

      ref.read(insulationPipingMaterialsProvider.notifier).updateSetups(piping);

      final size = ref.read(selectedSizeProvider);
      final unit = ref.read(selectedUnitProvider);
      debugPrint('🚀 Triggering updateAllSizes with: $size ($unit)');
      ref.read(insulationPipingMaterialsProvider.notifier).updateAllSizes(
            size: size ?? '',
            unit: unit ?? '',
          );

      _attachMaterialListeners();
    } catch (e, s) {
      debugPrint('❌ Failed to load material setups: $e');
      if (mounted) setState(() => _setupsLoaded = true);
    } finally {
      if (mounted) setState(() => _isLoadingMaterials = false);
    }
  }

  // ─────────────────────────────────────────────
  // IMAGE CACHE RESOLUTION
  // ─────────────────────────────────────────────

  Future<List<MaterialSetup>> _resolveSetupImages(
      List<MaterialSetup> setups) async {
    final dao = CachedImageDao();
    final List<MaterialSetup> resolved = [];
    for (var setup in setups) {
      final List<String> updatedImages = [];
      bool changed = false;
      for (var url in setup.image) {
        if (url.startsWith('http')) {
          final local = await dao.getLocalPath(url);
          if (local != null && File(local).existsSync()) {
            updatedImages.add(local);
            changed = true;
            continue;
          }
        }
        updatedImages.add(url);
      }
      resolved.add(changed ? setup.copyWith(image: updatedImages) : setup);
    }
    return resolved;
  }

  Future<List<PipingMaterial>> _resolvePipingImages(
      List<PipingMaterial> materials) async {
    final dao = CachedImageDao();
    final List<PipingMaterial> resolved = [];
    for (var m in materials) {
      final List<String> updatedImages = [];
      bool changed = false;
      for (var url in m.image) {
        if (url.startsWith('http')) {
          final local = await dao.getLocalPath(url);
          if (local != null && File(local).existsSync()) {
            updatedImages.add(local);
            changed = true;
            continue;
          }
        }
        updatedImages.add(url);
      }
      resolved.add(changed ? m.copyWith(image: updatedImages) : m);
    }
    return resolved;
  }

  Future<List<EquipmentMaterial>> _resolveEquipmentImages(
      List<EquipmentMaterial> materials) async {
    final dao = CachedImageDao();
    final List<EquipmentMaterial> resolved = [];
    for (var m in materials) {
      final List<String> updatedImages = [];
      bool changed = false;
      for (var url in m.image) {
        if (url.startsWith('http')) {
          final local = await dao.getLocalPath(url);
          if (local != null && File(local).existsSync()) {
            updatedImages.add(local);
            changed = true;
            continue;
          }
        }
        updatedImages.add(url);
      }
      resolved.add(changed ? m.copyWith(image: updatedImages) : m);
    }
    return resolved;
  }

  MaterialSetup? _findMaterialSetup(String? code, String designation) {
    if (!_setupsLoaded) {
      print("⏳ Setups not loaded yet → returning null");
      // ✅ FIX: Trigger a reload if setups aren't loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_setupsLoaded && mounted) {
          final siteId = ref.read(selectedSiteIdProvider);
          if (siteId != null) {
            if (_isEditingExistingWork) {
              _loadMaterialSetupsOnly(siteId);
            } else {
              _loadMaterialSetups(siteId);
            }
          }
        }
      });
      return null;
    }

    final pool = designation == 'piping' ? _pipingSetups : _equipmentSetups;

    if (pool.isEmpty) {
      print("❌ No setups available → returning null");
      return null;
    }

    if (code == null || code.isEmpty) {
      print("❌ INVALID materialCode (null or empty)");
      return null;
    }

    // 🔍 Try exact match
    final matches = pool.where((s) => s.materialCode == code).toList();

    if (matches.isNotEmpty) {
      return matches.first;
    }

    print("❌ NO MATCH FOUND FOR: $code");
    return null;
  }

  void _attachMaterialListeners() {
    if (_materialListenerAttached) return;
    _materialListenerAttached = true;
    if (_isEditingExistingWork) return;

    final size = ref.read(selectedSizeProvider) ?? '';
    final unit = ref.read(selectedUnitProvider);

    ref.listenManual(
      materialsStreamProvider((
        siteId: siteId,
        domain: 'insulation',
        designation: 'piping',
      )),
      (previous, next) {
        next.whenData((localMaterials) {
          if (!mounted) return;

          // ✅ DEBUG: Check what's coming from the database
          for (var m in localMaterials) {
            print(
                "🔍 LocalMaterial: id=${m.serverId}, name=${m.name}, materialCode=${m.materialCode}");
          }

          final incoming = localMaterials.where((m) => !m.isDeleted).map((m) {
            final piping = m.toPiping();
            // ✅ CRITICAL FIX: Always preserve the server ID from LocalMaterial
            return piping.copyWith(
              id: m.serverId, // ← Use serverId from LocalMaterial
              materialCode: m.materialCode ?? piping.materialCode,
            );
          }).toList();

          Future.microtask(() async {
            if (!mounted) return;

            final notifier =
                ref.read(insulationPipingMaterialsProvider.notifier);
            final existing = ref.read(insulationPipingMaterialsProvider);

            final merged = incoming.map((newMat) {
              final old = existing.firstWhere(
                (e) => e.id == newMat.id,
                orElse: () => newMat,
              );

              return newMat.copyWith(
                cardFormState: old.cardFormState ?? newMat.cardFormState,
                // ✅ Also preserve materialCode if it was set in old
                materialCode: newMat.materialCode!.isNotEmpty
                    ? newMat.materialCode
                    : old.materialCode,
              );
            }).toList();

            final resolved = await _resolvePipingImages(merged);
            notifier.setMaterials(resolved);
            notifier.updateAllSizes(size: size, unit: unit);
          });
        });
      },
      fireImmediately: true,
    );

    // Equipment listener already works, but we need to ensure materialCode is preserved
    ref.listenManual(
      materialsStreamProvider((
        siteId: siteId,
        domain: 'insulation',
        designation: 'equipment',
      )),
      (previous, next) {
        next.whenData((localMaterials) {
          if (!mounted) return;

          // ✅ FIX: Initialize each equipment material with proper cardFormState
          final incoming = localMaterials.where((m) => !m.isDeleted).map((m) {
            final equipment = m.toEquipment();

            // 🔥 Find the corresponding MaterialSetup to get fieldConfig
            final setup = _equipmentSetups.firstWhere(
              (s) => s.id == equipment.id,
              orElse: () => MaterialSetup(
                id: equipment.id,
                name: equipment.name,
                materialCode: equipment.materialCode ?? '',
                image: equipment.image,
                uom: equipment.uom ?? '',
                designation: 'equipment',
                calculationType: '',
                fieldConfig: FieldConfig(
                  fields: [],
                  unitDropdowns: UnitDropdowns.fromJson({}),
                  defaults: FieldDefaults.fromJson({}),
                  ui: UiConfig.fromJson({}),
                ),
                siteId: siteId,
                companyId: '',
              ),
            );

            // ✅ Initialize cardFormState if it's null or empty
            if (equipment.cardFormState == null ||
                equipment.cardFormState!.fieldEntries.isEmpty) {
              return equipment.copyWith(
                cardFormState: CardFormState.buildInitial(
                  fieldConfig: setup.fieldConfig,
                ),
              );
            }

            return equipment;
          }).toList();

          Future.microtask(() async {
            if (!mounted) return;

            final notifier =
                ref.read(insulationEquipmentMaterialsProvider.notifier);
            final existing = ref.read(insulationEquipmentMaterialsProvider);

            final merged = incoming.map((newMat) {
              final old = existing.firstWhere(
                (e) => e.id == newMat.id,
                orElse: () => newMat,
              );

              // ✅ Preserve existing values while ensuring cardFormState is initialized
              final updatedCardState =
                  old.cardFormState ?? newMat.cardFormState;

              return newMat.copyWith(
                cardFormState: updatedCardState,
                materialCode: newMat.materialCode!.isNotEmpty
                    ? newMat.materialCode
                    : old.materialCode,
              );
            }).toList();

            final resolved = await _resolveEquipmentImages(merged);
            notifier.setMaterials(resolved);
          });
        });
      },
      fireImmediately: true,
    );
  }

  // Future<void> _hydrateFromMaterialStream() async {
  //   final siteId = ref.read(selectedSiteIdProvider)!;
  //   ref.read(insulationPipingMaterialsProvider).clear();
  //
  //   /// STEP 1 — Force sync before listening
  //   await ref.read(materialRepositoryProvider).sync(
  //     siteId: siteId,
  //     domain: 'insulation',
  //     designation: '',
  //   );
  //
  //   /// STEP 2 — Listen to DB stream
  //   ref.listenManual(
  //     materialsStreamProvider((
  //     siteId: siteId,
  //     domain: 'insulation',
  //     designation: '',
  //     )),
  //         (previous, next) {
  //       next.whenData((localMaterials) {
  //         if (localMaterials.isEmpty) return;
  //
  //         final pipingIncoming = <PipingMaterial>[];
  //         final equipmentIncoming = <EquipmentMaterial>[];
  //
  //         for (final local in localMaterials) {
  //           if (local.isDeleted) continue;
  //
  //           if (local.designation == 'piping') {
  //             pipingIncoming.add(local.toPiping());
  //           } else if (local.designation == 'equipment') {
  //             equipmentIncoming.add(local.toEquipment());
  //           }
  //         }
  //
  //         /// Existing provider materials
  //         final existingPiping =
  //         ref.read(insulationPipingMaterialsProvider);
  //
  //         final existingEquipment =
  //         ref.read(insulationEquipmentMaterialsProvider);
  //
  //         final pipingIds =
  //         existingPiping.map((e) => e.id).toSet();
  //
  //         final equipmentIds =
  //         existingEquipment.map((e) => e.id).toSet();
  //
  //         /// Add only missing materials
  //         final newPiping = pipingIncoming
  //             .where((m) => !pipingIds.contains(m.id))
  //             .toList();
  //
  //         final newEquipment = equipmentIncoming
  //             .where((m) => !equipmentIds.contains(m.id))
  //             .toList();
  //
  //         if (newPiping.isNotEmpty) {
  //           ref
  //               .read(insulationPipingMaterialsProvider.notifier)
  //               .addMaterials(newPiping);
  //         }
  //
  //         if (newEquipment.isNotEmpty) {
  //           ref
  //               .read(insulationEquipmentMaterialsProvider.notifier)
  //               .addMaterials(newEquipment);
  //         }
  //
  //         /// propagate global size + unit
  //         final size = ref.read(selectedSizeProvider) ?? '';
  //         final unit = ref.read(selectedUnitProvider);
  //
  //         ref
  //             .read(insulationPipingMaterialsProvider.notifier)
  //             .updateAllSizes(
  //           size: size,
  //           unit: unit,
  //         );
  //       });
  //     },
  //   );
  // }
  void _initializeControllers() {
    _dprNameController = TextEditingController();
    _dprNameController.addListener(() => setState(() {}));
    _mocController = TextEditingController();
    _sizeController = TextEditingController();
    _plantController = TextEditingController();
    _floorController = TextEditingController();

    // Insulation-specific controllers
    _layerNameController = TextEditingController();
    _thicknessController = TextEditingController();
    _claddingNameController = TextEditingController();
    _claddingThicknessController = TextEditingController();
    _claddingController = TextEditingController();
  }
  // void _initializeFromWork(InsulationDprModel work) {
  //   ref.read(insulationPipingMaterialsProvider.notifier).clear();
  //   ref.read(insulationEquipmentMaterialsProvider.notifier).clear();
  //
  //   setState(() {
  //     _insulationId = work.id;
  //     _selectedDprId = work.id;
  //     _dprNameController.text = work.workDescription;
  //     _plantController.text = work.plant ?? '';
  //     _floorController.text = work.location;
  //     ref.read(dprSizeProvider.notifier).state = work.size.toString();
  //     _sizeController.text = work.size.toString();
  //     _pipeInsulationOn = work.pipingMaterials.isNotEmpty;
  //     _equipmentInsulationOn = work.equipmentMaterials.isNotEmpty;
  //     _showPipingMaterials = _pipeInsulationOn;
  //     _showEquipmentMaterials = _equipmentInsulationOn;
  //     _loadLayersFromModel(work);
  //   });
  //
  //   // ✅ Hydrate cardFormState from setup fieldConfig IF missing,
  //   //    but preserve any existing values from the work model
  //   final hydratedPiping = work.pipingMaterials; // piping cards don't use cardFormState
  //
  //   final hydratedEquipment = work.equipmentMaterials.map((e) {
  //     if (e.cardFormState != null && e.cardFormState!.fieldEntries.isNotEmpty) {
  //       return e; // ✅ Already has values from API — use as-is
  //     }
  //     // cardFormState missing — build from setup schema
  //     final setup = _equipmentSetups.firstWhere(
  //           (s) => s.materialCode == e.materialCode,
  //       orElse: () => _equipmentSetups.firstWhere(
  //             (s) => s.id == e.id,
  //         orElse: () => _emptySetup(e, siteId),
  //       ),
  //     );
  //     return e.copyWith(
  //       cardFormState: CardFormState.buildInitial(fieldConfig: setup.fieldConfig),
  //     );
  //   }).toList();
  //
  //   ref.read(insulationPipingMaterialsProvider.notifier).setMaterials(hydratedPiping);
  //   ref.read(insulationEquipmentMaterialsProvider.notifier).setMaterials(hydratedEquipment);
  // }

// Helper to avoid null setup crashes
  MaterialSetup _emptySetup(EquipmentMaterial e, String siteId) =>
      MaterialSetup(
        id: e.id,
        name: e.name,
        materialCode: e.materialCode ?? '',
        image: e.image,
        uom: e.uom ?? '',
        designation: 'equipment',
        calculationType: '',
        siteId: siteId,
        companyId: '',
        fieldConfig: FieldConfig(
          fields: [],
          unitDropdowns: UnitDropdowns.fromJson({}),
          defaults: FieldDefaults.fromJson({}),
          ui: UiConfig.fromJson({}),
        ),
      );

  void _loadLayersFromModel(InsulationDprModel work) {
    _selectedLayerType = _mapLayerStringToEnum(work.layer);

    _layers.clear();

    if (work.leggingMaterial1 != null) {
      _layers.add(LayerData(
        name: work.leggingMaterial1!,
        thickness: work.leggingThickness1?.toDouble() ?? 0,
      ));
    }

    if (work.leggingMaterial2 != null) {
      _layers.add(LayerData(
        name: work.leggingMaterial2!,
        thickness: work.leggingThickness2?.toDouble() ?? 0,
      ));
    }

    if (work.leggingMaterial3 != null) {
      _layers.add(LayerData(
        name: work.leggingMaterial3!,
        thickness: work.leggingThickness3?.toDouble() ?? 0,
      ));
    }

    _cladding = LayerData(
      name: work.claddingMaterial ?? '',
      thickness: work.claddingSwg?.toDouble() ?? 0,
    );
  }

  void _loadLayersFromProvider() {
    final state = ref.read(insulationStateProvider);

    debugPrint("========== LOAD LAYERS ==========");
    debugPrint("LayerType: ${state.layerType}");
    debugPrint("Layers Count: ${state.layers.length}");

    for (int i = 0; i < state.layers.length; i++) {
      final layer = state.layers[i];
      debugPrint("Layer[$i] → thickness: ${layer.thickness}, "
          "density: ${layer.name}, "
          "material: ${layer.thickness}");
    }

    debugPrint("Cladding: ${state.cladding.thickness}");
    debugPrint("=================================");

    _selectedLayerType = state.layerType ?? LayerType.single;

    _layers
      ..clear()
      ..addAll(state.layers);

    _cladding = state.cladding;
    _claddingController.text =
        _cladding.thickness == 0 ? '' : _cladding.thickness.toString();
    debugPrint("Cladding: ${_cladding.thickness}");
  }

  void _initializeData() {
    siteId = ref.read(selectedSiteIdProvider)!;
    teamId = ref.read(selectedTeamIdProvider) ?? "";

    // ONLY read, never watch
    final insulationState = ref.read(insulationStateProvider);
    _floorController.text = insulationState.floor;

    _mocController.text = "";
    _sizeController.text = ref.read(selectedSizeProvider) ?? '';
  }

  Future<void> loadScreenState() async {
    setState(() => _isLoadingMaterials = true);
    try {
      ref.read(insulationPipingMaterialsProvider.notifier).clear();
      ref.read(insulationEquipmentMaterialsProvider.notifier).clear();

      if (_insulationId != null) {
        // 🔵 EDITING INSULATION DPR
        await _loadInsulationDprMaterials();
      } else {
        // 🟢 CREATING NEW INSULATION DPR
        await _loadDefaultInsulationMaterials();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMaterials = false);
      }
    }
  }

  Future<void> _loadSelectedDpr(String dprId) async {
    try {
      setState(() {
        _isLoadingDprList = true;
        _isLoadingMaterials = true;
      });

      final dpr = await InsulationDprApi.fetchInsulationDprById(
        insulationId: dprId,
      );

      if (dpr == null) return;

      if (!mounted) return;

      setState(() {
        _selectedDprId = dpr.id;
        _insulationId = dpr.id;

        // ✅ IMPORTANT: editing mode
        _globalEditMode = true; // optional
      });

      // ✅ Use ONE single initializer
      _initializeFromWork(dpr);
    } catch (e) {
      _showSnackBar(
        "Failed to load DPR: ${extractBackendError(e)}",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDprList = false;
          _isLoadingMaterials = false;
        });
      }
    }
  }

  //
  // Future<void> _loadSelectedDpr(String dprId) async {
  //   try {
  //     setState(() {
  //       _isLoadingDprList = true;
  //       _isLoadingMaterials = true;
  //     });
  //
  //     final dpr = await InsulationDprApi.fetchInsulationDprById(
  //       insulationId: dprId,
  //     );
  //
  //     if (dpr == null) return;
  //
  //     // ✅ store ids
  //     _insulationId = dpr.id;
  //     _selectedDprId = dpr.id;
  //
  //     // ✅ controllers
  //     _dprNameController.text = dpr.workDescription;
  //     _plantController.text = dpr.plant ?? '';
  //     _floorController.text = dpr.location;
  //     _sizeController.text = dpr.size.toString();
  //     ref.read(dprSizeProvider.notifier).state = dpr.size;
  //
  //     // ✅ toggles
  //     setState(() {
  //       _pipeInsulationOn = dpr.pipingMaterials.isNotEmpty;
  //       _equipmentInsulationOn = dpr.equipmentMaterials.isNotEmpty;
  //       _showPipingMaterials = _pipeInsulationOn;
  //       _showEquipmentMaterials = _equipmentInsulationOn;
  //
  //       // ✅ backend fields (ONLY if backend supports)
  //       // _removeLagging = dpr.laggingRemoval ?? false;
  //       // _removeCladding = dpr.claddingRemoval ?? false;
  //     });
  //
  //     // ✅ rebuild layers list from DPR
  //     final layerType = _mapLayerStringToEnum(dpr.layer);
  //
  //     final layers = <LayerData>[];
  //     if (dpr.leggingMaterial1 != null) {
  //       layers.add(LayerData(
  //         name: dpr.leggingMaterial1!,
  //         thickness: dpr.leggingThickness1?.toDouble() ?? 0,
  //       ));
  //     }
  //     if (dpr.leggingMaterial2 != null) {
  //       layers.add(LayerData(
  //         name: dpr.leggingMaterial2!,
  //         thickness: dpr.leggingThickness2?.toDouble() ?? 0,
  //       ));
  //     }
  //     if (dpr.leggingMaterial3 != null) {
  //       layers.add(LayerData(
  //         name: dpr.leggingMaterial3!,
  //         thickness: dpr.leggingThickness3?.toDouble() ?? 0,
  //       ));
  //     }
  //
  //     final cladding = LayerData(
  //       name: dpr.claddingMaterial ?? '',
  //       thickness: dpr.claddingSwg?.toDouble() ?? 0,
  //     );
  //
  //     // ✅ provider hydrate (this updates UI)
  //     ref.read(insulationStateProvider.notifier).hydrate(
  //       layerType: layerType,
  //       layers: layers,
  //       cladding: cladding,
  //       floor: dpr.location,
  //     );
  //
  //     // ✅ set materials providers
  //     ref.read(insulationPipingMaterialsProvider.notifier)
  //         .setMaterials(dpr.pipingMaterials);
  //
  //     ref.read(insulationEquipmentMaterialsProvider.notifier)
  //         .setMaterials(dpr.equipmentMaterials);
  //
  //
  //
  //   } catch (e) {
  //     _showSnackBar(
  //       "Failed to load DPR: ${extractBackendError(e)}",
  //       isError: true,
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingDprList = false;
  //         _isLoadingMaterials = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _loadDefaultInsulationMaterials() async {
    final service = InsulationMaterialSetupService();
    final apiNotifier = ref.read(insulationMaterialsApiProvider.notifier);
    try {
      final siteID = ref.read(selectedSiteIdProvider)!;
      await apiNotifier.fetchAndSetMaterials(siteId: siteID);
      final size = ref.read(selectedSizeProvider);
      final unit = ref.read(selectedUnitProvider);
      ref.read(insulationPipingMaterialsProvider.notifier).updateAllSizes(
            size: size!,
            unit: unit,
          );
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load materials: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMaterials = false);
    }
  }

  Future<void> _loadInsulationDprMaterials() async {
    try {
      final dpr = await InsulationDprApi.fetchInsulationDprById(
        insulationId: _insulationId!,
      );

      if (dpr == null) return;

      // Layer type
      _selectedLayerType = _mapLayerStringToEnum(dpr.layer);

      // Rebuild insulation layers
      _layers.clear();

      if (dpr.leggingMaterial1 != null && dpr.leggingThickness1 != null) {
        _layers.add(
          LayerData(
            name: dpr.leggingMaterial1!,
            thickness: dpr.leggingThickness1!.toDouble(),
          ),
        );
      }

      if (_selectedLayerType != LayerType.single &&
          dpr.leggingMaterial2 != null &&
          dpr.leggingThickness2 != null) {
        _layers.add(
          LayerData(
            name: dpr.leggingMaterial2!,
            thickness: dpr.leggingThickness2!.toDouble(),
          ),
        );
      }

      if (_selectedLayerType == LayerType.triple &&
          dpr.leggingMaterial3 != null &&
          dpr.leggingThickness3 != null) {
        _layers.add(
          LayerData(
            name: dpr.leggingMaterial3!,
            thickness: dpr.leggingThickness3!.toDouble(),
          ),
        );
      }

      // Cladding (mapped correctly)
      _cladding = (dpr.claddingMaterial != null && dpr.claddingSwg != null)
          ? LayerData(
              name: dpr.claddingMaterial!,
              thickness: dpr.claddingSwg!.toDouble(), // SWG stored as numeric
            )
          : LayerData.empty();

      // Materials resolved from cache
      final resolvedPiping = await _resolvePipingImages(dpr.pipingMaterials);
      final resolvedEquipment =
          await _resolveEquipmentImages(dpr.equipmentMaterials);

      ref
          .read(insulationPipingMaterialsProvider.notifier)
          .setMaterials(resolvedPiping);

      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .setMaterials(resolvedEquipment);

      // Controllers
      _dprNameController.text = dpr.workDescription;
      _sizeController.text = dpr.size.toString();
      _floorController.text = dpr.location;
    } catch (e, s) {
      debugPrint('Error loading insulation DPR: $e');
      debugPrintStack(stackTrace: s);
      _showSnackBar('Failed to load DPR', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingMaterials = false);
    }
  }

  LayerType _mapLayerStringToEnum(String layer) {
    switch (layer.toLowerCase()) {
      case 'double':
        return LayerType.double;
      case 'triple':
        return LayerType.triple;
      default:
        return LayerType.single;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Clear any pending updates
    }
  }

  Future<void> _fetchDprListForDate(DateTime date) async {
    if (_isDisposed) return;

    setState(() => _isLoadingDprList = true);

    try {
      final List<InsulationDprModel> allDprs =
          await InsulationDprApi.fetchInsulationDprList(
        siteId: siteId,
        teamId: teamId,
      );

      _dprListForSelectedDate = allDprs.where((dpr) {
        final dprDate = dpr.updatedAt;
        return dprDate.year == date.year &&
            dprDate.month == date.month &&
            dprDate.day == date.day;
      }).toList();

      _showSnackBar(
        _dprListForSelectedDate.isNotEmpty
            ? 'Found ${_dprListForSelectedDate.length} Insulation DPR(s) for ${_formatDate(date)}'
            : 'No Insulation DPR found for ${_formatDate(date)}. Create a new DPR.',
      );
    } catch (e) {
      final message = extractBackendError(e);
      _showSnackBar('Error fetching DPR list: $message', isError: true);
      _dprListForSelectedDate = [];
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingDprList = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditable) {
      // Show toast message
      AppToast.error("Edit mode is off");
      return;
    }

    if (_isSubmitting) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _selectedDate) return;

    setState(() {
      _selectedDate = picked;
    });

    await _fetchDprListForDate(picked);

    if (_dprListForSelectedDate.isNotEmpty) {
      _insulationId = _dprListForSelectedDate.first.id;
      _selectedDprId = _insulationId;
    } else {
      _insulationId = null;
      _selectedDprId = null;
      _dprNameController.text = '';
    }

    await loadScreenState();
  }

  Future<void> _handleDateOverride(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _selectedDate) return;

    setState(() {
      _selectedDate = picked;
      _isDateOverrideMode = true;
    });
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  void _handleToggleChange(bool isPiping, bool newValue) {
    if (_isDisposed) return;

    setState(() {
      if (isPiping) {
        _pipeInsulationOn = newValue;
        if (!newValue) {
          _showPipingMaterials = false;
        } else {
          final materials = ref.read(insulationPipingMaterialsProvider);
          if (materials.isNotEmpty) {
            _showPipingMaterials = true;
          }
        }
      } else {
        _equipmentInsulationOn = newValue;
        if (!newValue) {
          _showEquipmentMaterials = false;
        } else {
          final materials = ref.read(insulationEquipmentMaterialsProvider);
          if (materials.isNotEmpty) {
            _showEquipmentMaterials = true;
          }
        }
      }
    });
  }

  void _toggleMaterialVisibility(bool isPiping) {
    if (isPiping) {
      setState(() {
        _showPipingMaterials = !_showPipingMaterials;
      });
    } else {
      setState(() {
        _showEquipmentMaterials = !_showEquipmentMaterials;
      });
    }
  }

  // _________INSULATION MATERIAL FUNCTIONS_______ //
  void deleteInsulationMaterial({
    required dynamic material,
    required bool isPiping,
  }) {
    if (isPiping) {
      final notifier = ref.read(insulationPipingMaterialsProvider.notifier);
      final materials = ref.read(insulationPipingMaterialsProvider);

      if (material is! PipingMaterial) return;

      final updated = materials.where((m) => m.id != material.id).toList();

      notifier.setMaterials(updated);
    } else {
      final notifier = ref.read(insulationEquipmentMaterialsProvider.notifier);
      final materials = ref.read(insulationEquipmentMaterialsProvider);
      print("😂😂😂😂😂😂😂");

      if (material is! EquipmentMaterial) return;
      print("😂😂😂😂😂😂😂");
      final updated = materials.where((m) => m.id != material.id).toList();

      notifier.setMaterials(updated);
      print("😂😂😂😂😂😂😂");
    }

    _showSnackBar('Material deleted');
  }

  //
  // Future<void> _copyInsulationMaterial(String materialId) async {
  //   try {
  //     await InsulationDprApi.copyInsulationMaterial(
  //       dprId: _insulationId!,
  //       matId: materialId,
  //     );
  //
  //     await _loadInsulationDprMaterials();
  //     _showSnackBar('Material copied');
  //   } catch (e) {
  //     final message = extractBackendError(e);
  //     _showSnackBar('Copy failed: $message', isError: true);
  //   }
  // }

  String generateObjectId() {
    final seconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toRadixString(16)
        .padLeft(8, '0');

    final random = Random.secure();
    final randomPart = List.generate(10, (_) => random.nextInt(16))
        .map((e) => e.toRadixString(16))
        .join();

    final counter = random.nextInt(0xffffff).toRadixString(16).padLeft(6, '0');

    return seconds + randomPart + counter;
  }

  void copyInsulationMaterial({
    required dynamic material,
    required bool isPiping,
  }) {
    final newId = generateObjectId();

    if (isPiping) {
      if (material is! PipingMaterial) return;

      // Pre-register GlobalKey so submit sync works for the copy too
      _pipingKeys.putIfAbsent(
          newId, () => GlobalKey<State<PipingMaterialCard>>());

      final copied = material.copyWith(
        id: newId,
        name: material.name,
      );

      ref
          .read(insulationPipingMaterialsProvider.notifier)
          .addPipingMaterialAfter(copied, material.id);
    } else {
      if (material is! EquipmentMaterial) return;

      _equipmentKeys.putIfAbsent(
          newId, () => GlobalKey<State<EquipmentMaterialCard>>());

      final copied = material.copyWith(
        id: newId,
        name: material.name,
      );

      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .addEquipmentMaterialAfter(copied, material.id);
    }
  }

  void _editInsulationMaterial(dynamic material) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    if (material is PipingMaterial) {
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (_) => AddInsulationMaterialScreen(
      //       editMaterialId: material.id,
      //       designation: 'piping',
      //       pipingMaterial: material,
      //       isDpr: true,
      //       dprId: _insulationId!,
      //       siteId: siteId,
      //       teamId: teamId,
      //     ),
      //   ),
      // ).then((_) async {
      //   await _loadInsulationDprMaterials();
      // });
      // } else if (material is EquipmentMaterial) {
      //   Navigator.of(context).push(
      //     MaterialPageRoute(
      //       builder: (_) => AddInsulationMaterialScreen(
      //         editMaterialId: material.id,
      //         designation: 'equipment',
      //         equipmentMaterial: material,
      //         isDpr: true,
      //         dprId: _insulationId!,
      //         siteId: siteId,
      //         teamId: teamId,
      //       ),
      //     ),
      //   ).then((_) async {
      //     await _loadInsulationDprMaterials();
      //   });
      // }
    }
  }

  void _showEditRequiredMessage() {
    if (_isToday(_selectedDate)) {
      _showSnackBar("You can edit today's DPR directly", isError: true);
    } else {
      _showSnackBar("Please enable edit mode to make changes", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get _isEditable =>
      _isToday(_selectedDate) || _globalEditMode || widget.work != null;
  static const List<String> insulationMaterials = [
    'Nitrile Rubber',
    'PUF',
    'LRB',
  ];
  static const List<String> claddingMaterials = [
    'SS Sheet',
    'Aluminium Sheet',
  ];
  List<String> get layerTypeOptions =>
      LayerType.values.map((e) => e.name.toUpperCase()).toList();
  Widget _buildLayerTypeSection() {
    print("cladding in the buildlayer section ${_cladding.thickness}");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Layer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildInlineCompactDropdown(
                  value: _selectedLayerType.name.toUpperCase(),
                  items: layerTypeOptions,
                  onChanged: (v) {
                    final selected = LayerType.values.firstWhere(
                      (e) => e.name.toUpperCase() == v,
                    );

                    setState(() {
                      _selectedLayerType = selected;

                      if (_selectedLayerType == LayerType.single) {
                        if (_layers.length > 1)
                          _layers.removeRange(1, _layers.length);
                      } else if (_selectedLayerType == LayerType.double) {
                        while (_layers.length < 2)
                          _layers.add(LayerData.empty());
                        if (_layers.length > 2)
                          _layers.removeRange(2, _layers.length);
                      } else if (_selectedLayerType == LayerType.triple) {
                        while (_layers.length < 3)
                          _layers.add(LayerData.empty());
                        if (_layers.length > 3)
                          _layers.removeRange(3, _layers.length);
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ..._layers.asMap().entries.map((entry) {
            final index = entry.key;
            final layer = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCompactDropdown(
                      label: 'Lagging Material ${index + 1}',
                      value: layer.name.isNotEmpty ? layer.name : null,
                      items: insulationMaterials,
                      onChanged: (v) {
                        setState(() {
                          _layers[index] = _layers[index].copyWith(name: v);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Thickness (mm)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 34,
                          child: TextFormField(
                            initialValue: layer.thickness == 0
                                ? ''
                                : layer.thickness.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFE3F2FD),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _layers[index] = _layers[index].copyWith(
                                  thickness: double.tryParse(v) ?? 0,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 12),

          /// CLADDING
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildCompactDropdown(
                  label: 'Cladding Material',
                  value: _cladding.name.isNotEmpty ? _cladding.name : null,
                  items: claddingMaterials,
                  onChanged: (v) {
                    setState(() {
                      _cladding = _cladding.copyWith(name: v);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Thickness (SWG)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      child: TextFormField(
                        controller: _claddingController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _cladding = _cladding.copyWith(
                              thickness: double.tryParse(v) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

//
//   Widget _buildLayerTypeSection() {
//     final state = ref.watch(insulationStateProvider);
//     final notifier = ref.read(insulationStateProvider.notifier);
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Layer',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(width: 12),
//
//               _buildInlineCompactDropdown(
//                 value: state.layerType?.name.toUpperCase(),
//                 items: layerTypeOptions,
//                 onChanged: (v) {
//                   final selected = LayerType.values.firstWhere(
//                         (e) => e.name.toUpperCase() == v,
//                   );
//                   notifier.setLayerType(selected);
//                 },
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 10),
//
//
//
//
//
//
//           /// Layers
//         ...state.layers.asMap().entries.map((entry) {
//       final index = entry.key;
//       final layer = entry.value;
//
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 12),
//         child: Row(
//           children: [
//             /// MATERIAL DROPDOWN (COMPACT)
//             Expanded(
//               flex: 3,
//               child: _buildCompactDropdown(
//                 label: 'Lagging  Material ${index + 1}',
//                 value: layer.name.isNotEmpty ? layer.name : null,
//                 items: insulationMaterials,
//                 onChanged: (v) {
//                   notifier.updateLayer(
//                     index: index,
//                     name: v,
//                   );
//                 },
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             /// THICKNESS (COMPACT)
//             Expanded(
//               flex: 2,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.only(bottom: 6),
//                     child: Text(
//                       'Thickness (mm)',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     height: 34,
//                     child: TextFormField(
//                       initialValue: layer.thickness == 0
//                           ? ''
//                           : layer.thickness.toString(),
//                       keyboardType: TextInputType.number,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                       decoration: InputDecoration(
//                         isDense: true,
//                         filled: true,
//                         fillColor: const Color(0xFFE3F2FD)
// ,
//                         contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide.none,
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: const BorderSide(color: Colors.blue, width: 2),
//                         ),
//                       ),
//                       onChanged: (v) {
//                         notifier.updateLayer(
//                           index: index,
//                           thickness: double.tryParse(v) ?? 0,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           ],
//         ),
//       );
//     })
//     ,
//
//           const Divider(height: 12),
//
//           /// Cladding
//           const Text(
//             'Cladding',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 2),
//           Row(
//             children: [
//               /// CLADDING MATERIAL (DROPDOWN)
//               Expanded(
//                 flex: 3,
//                 child: _buildCompactDropdown(
//                   label: 'Cladding Material',
//                   value: state.cladding.name.isNotEmpty
//                       ? state.cladding.name
//                       : null,
//                   items: claddingMaterials,
//                   onChanged: (v) {
//                     notifier.setCladding(name: v);
//                   },
//                 ),
//               ),
//
//               const SizedBox(width: 12),
//
//               /// CLADDING THICKNESS (COMPACT NUMERIC)
//               Expanded(
//                 flex: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Padding(
//                       padding: EdgeInsets.only(bottom: 6),
//                       child: Text(
//                         'Thickness (SWG)',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                     SizedBox(
//                       height: 34,
//                       child: TextFormField(
//                         initialValue: state.cladding.thickness == 0
//                             ? ''
//                             : state.cladding.thickness.toString(),
//                         keyboardType: TextInputType.number,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                         decoration: InputDecoration(
//                           isDense: true,
//                           filled: true,
//                           fillColor: const Color(0xFFE3F2FD)
// ,
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 6,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide.none,
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide:
//                             const BorderSide(color: Colors.blue, width: 2),
//                           ),
//                         ),
//                         onChanged: (v) {
//                           notifier.setCladding(
//                             thickness: double.tryParse(v) ?? 0,
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 16),
//
//           Row(
//             children: [
//               _buildRemovalCheckbox(
//                 label: 'Lagging Removal ',
//                 value: _removeLagging,
//                 onChanged: (v) {
//                   setState(() => _removeLagging = v);
//                 },
//               ),
//               const SizedBox(width: 16),
//               _buildRemovalCheckbox(
//                 label: 'Cladding Removal',
//                 value: _removeCladding,
//                 onChanged: (v) {
//                   setState(() => _removeCladding = v);
//                 },
//               ),
//             ],
//           ),
//
//
//
//
//         ],
//       ),
//     );
//   }
  Widget _buildRemovalCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          activeColor: Colors.blue,
          checkColor: Colors.white,
          side: BorderSide(
            color: Colors.blue.shade600,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineCompactDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFE3F2FD),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("againnnnnnnnnnnnn");

    // ✅ ref.listen only fires on VALUE CHANGE, not every rebuild
    // No infinite loop!
    // if (_insulationId == null && widget.work == null) {
    //   print("00000000000000000000000000000000000000000000000000000000");
    //   ref.listen(
    //     materialsStreamProvider((
    //     siteId: siteId,
    //     domain: 'insulation',
    //     designation: 'piping',
    //     )),
    //         (previous, next) {
    //       next.whenData((localMaterials) {
    //         if (!mounted) return;
    //         final incoming = localMaterials
    //             .where((m) => !m.isDeleted)
    //             .map((m) => m.toPiping())
    //             .toList();
    //
    //         print("STREAM DATA: ${localMaterials.length}");
    //
    //
    //         ref.read(insulationPipingMaterialsProvider.notifier).clear();
    //         if (incoming.isNotEmpty) {
    //           ref.read(insulationPipingMaterialsProvider.notifier).addMaterials(incoming);
    //         }
    //       });
    //     },
    //   );
    //
    //   ref.listen(
    //     materialsStreamProvider((
    //     siteId: siteId,
    //     domain: 'insulation',
    //     designation: 'equipment',
    //     )),
    //         (previous, next) {
    //       next.whenData((localMaterials) {
    //         if (!mounted) return;
    //         final incoming = localMaterials
    //             .where((m) => !m.isDeleted)
    //             .map((m) => m.toEquipment())
    //             .toList();
    //
    //         ref.read(insulationEquipmentMaterialsProvider.notifier).clear();
    //         if (incoming.isNotEmpty) {
    //           ref.read(insulationEquipmentMaterialsProvider.notifier).addMaterials(incoming);
    //         }
    //       });
    //     },
    //   );
    // }
    final pipingMaterials = ref.watch(insulationPipingMaterialsProvider);
    final equipmentMaterials = ref.watch(insulationEquipmentMaterialsProvider);
    final insulationState = ref.watch(insulationStateProvider);
    final insulationNotifier = ref.read(insulationStateProvider.notifier);

    final hasPipingMaterials = pipingMaterials.isNotEmpty;
    final hasEquipmentMaterials = equipmentMaterials.isNotEmpty;
    final shouldShowPiping =
        _pipeInsulationOn && _showPipingMaterials && hasPipingMaterials;
    final shouldShowEquipment = _equipmentInsulationOn &&
        _showEquipmentMaterials &&
        hasEquipmentMaterials;

    final shouldShowDropdown =
        _globalEditMode && _dprListForSelectedDate.isNotEmpty;
    final team = ref.read(currentTeamProvider);
    final site = ref.read(currentSiteProvider);
    final teamid = ref.read(selectedTeamIdProvider)!;
    final siteid = ref.read(selectedSiteIdProvider)!;

    debugPrint("Team -> $team");
    debugPrint("Site -> $site");
    debugPrint("Teamid -> $teamid");
    debugPrint("Siteid -> $siteid");

    final appBarTitle = team?.isDefaultTeam == true
        ? (site?.siteName ?? "DPR")
        : (team?.teamName ?? "DPR");

    debugPrint("AppBar Title -> $appBarTitle");

    return WillPopScope(
      onWillPop: () async {
        await _autoSaveDraft();
        return true;
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: Colors.grey[50],
        body: NestedScrollView(
          // AFTER
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            final appBarTitle = (team == null || team.isDefaultTeam)
                ? (site?.siteName ?? "DPR")
                : (team.teamName ?? "DPR");
            return [CustomSliverAppBar(title: appBarTitle)];
          },
          body: BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: RoundedButton(
                  text: _isSubmitting ? 'Saving..' : 'Save',
                  color: _isEditable ? const Color(0xFF1B6DCE) : Colors.grey,
                  textColor: Colors.white,
                  onPressed: _isSubmitting ? () {} : _handleSubmitFields,
                  isOutlined: false,
                ),
              ),
            ],
            child: Column(
              children: [
                if (_isLoadingMaterials || _isCreatingWork)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1B6DCE)),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(6),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildEditModeButton(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDateSection(),
                        const SizedBox(height: 16),
                        _buildDprInfoCard(shouldShowDropdown),
                        const SizedBox(height: 16),

                        // Insulation Layer Section
                        _buildLayerTypeSection(),
                        const SizedBox(height: 16),

                        _buildToggleSection(),
                        const SizedBox(height: 16),

                        Column(
                          children: [
                            if (_pipeInsulationOn && hasPipingMaterials)
                              _buildMaterialToggleCard(
                                'Pipe Insulation Materials',
                                pipingMaterials.length,
                                _showPipingMaterials,
                                () => _toggleMaterialVisibility(true),
                              ),

                            if (shouldShowPiping)
                              ..._buildPipingMaterials(pipingMaterials),

                            if (_equipmentInsulationOn && hasEquipmentMaterials)
                              _buildMaterialToggleCard(
                                'Equipment Insulation Materials',
                                equipmentMaterials.length,
                                _showEquipmentMaterials,
                                () => _toggleMaterialVisibility(false),
                              ),

                            if (shouldShowEquipment)
                              ..._buildEquipmentMaterials(equipmentMaterials),

                            if (_pipeInsulationOn && !hasPipingMaterials ||
                                (_equipmentInsulationOn &&
                                    !hasEquipmentMaterials))
                              _buildSetupState(siteId)

                            // if (!_pipeInsulationOn && !_equipmentInsulationOn && _initialDataLoaded)
                            //   _buildEmptyState('Materials will appear here once loaded', Icons.downloading),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupState(String siteId) {
    return const ShimmerList(
      itemCount: 3,
      type: ShimmerListType.card,
      scrollable: false,
      padding: EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildLaggingSection() {
    final laggings = ref.watch(laggingMaterialProvider);
    final notifier = ref.read(laggingMaterialProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lagging',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  notifier.add(
                    LaggingMaterial(
                      id: DateTime.now().toIso8601String(),
                      name: '',
                      thickness: 0,
                      uom: 'mm',
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Lagging Items
          if (laggings.isEmpty)
            Text(
              'No lagging added',
              style: TextStyle(color: Colors.grey[600]),
            ),

          ...laggings.asMap().entries.map((entry) {
            final index = entry.key;
            final lagging = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  /// Lagging Name
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: lagging.name,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        notifier.update(
                          id: lagging.id,
                          name: v,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Thickness
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: lagging.thickness == 0
                          ? ''
                          : lagging.thickness.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thickness',
                        suffixText: 'mm',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        notifier.update(
                          id: lagging.id,
                          thickness: double.tryParse(v) ?? 0,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => notifier.delete(lagging.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyMaterialsCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialToggleCard(
    String title,
    int count,
    bool isExpanded,
    VoidCallback onToggle,
  ) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            _buildAddInsulationMaterialButton(),
            Text(
              isExpanded ? 'Hide' : 'Show',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddInsulationMaterialButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        // if (_insulationId == null) {
        //   _showSnackBar('DPR not created yet', isError: true);
        //   return;
        // }
        //
        // final result = await Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (_) => AddInsulationMaterialScreen(
        //       isDpr: true,
        //       dprId: _insulationId!,
        //       siteId: siteId,
        //       teamId: teamId,
        //     ),
        //   ),
        // );
        //
        // if (result == true) {
        //   await _loadInsulationDprMaterials();
        // }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    final bool canChangeDateNormal = _globalEditMode;
    final bool showPencil = isEditingDpr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.description, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Report',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap:
                        canChangeDateNormal ? () => _selectDate(context) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _globalEditMode
                            ? Colors.blue.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _globalEditMode
                              ? Colors.blue.shade200
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  _globalEditMode ? Colors.blue : Colors.black,
                            ),
                          ),
                          if (canChangeDateNormal) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showPencil) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _handleDateOverride(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_isDateOverrideMode)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Date modified",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditModeButton() {
    return GestureDetector(
      onTap: _toggleGlobalEditMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _globalEditMode ? "Editing" : "Edit",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDprInfoCard(bool shouldShowDropdown) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _buildDprNameSection(shouldShowDropdown),
            const SizedBox(height: 16),
            _buildInputFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildDprNameSection(bool shouldShowDropdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowDropdown) _buildDprDropdown(),
        const SizedBox(height: 8),
        _buildRegularDprNameField(),
      ],
    );
  }

  Widget _buildDprDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Insulation DPR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isLoadingDprList
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDprId,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    elevation: 16,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    hint: const Text('Select DPR'),
                    onChanged: (String? newValue) async {
                      if (newValue == null) return;
                      await _loadSelectedDpr(newValue);
                    },
                    items: _dprListForSelectedDate
                        .map<DropdownMenuItem<String>>(
                            (InsulationDprModel dpr) {
                      return DropdownMenuItem<String>(
                        value: dpr.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            dpr.workDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_dprListForSelectedDate.length} Insulation DPR(s) found for ${_formatDate(_selectedDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_isEditable)
              TextButton.icon(
                onPressed: () async {
                  await _autoCreateDprWork();
                  await _fetchDprListForDate(_selectedDate);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New DPR'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegularDprNameField() {
    return Row(
      children: [
        Expanded(
          child: _editMode
              ? TextField(
                  controller: _dprNameController,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    hintText: 'Enter Insulation DPR Name',
                    prefixIcon: const Icon(Icons.insights, size: 20),
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dprNameController.text,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: 12),
        if (_editMode)
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {
                if (_editMode && _dprNameController.text.trim().isEmpty) {
                  _showSnackBar('Please enter DPR name', isError: true);
                  return;
                }
                setState(() => _editMode = !_editMode);
              },
              icon: Icon(
                _editMode ? Icons.check_circle : Icons.edit_rounded,
                color: _editMode ? Colors.blue[700] : Colors.blue[700],
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFields() {
    final selectedUnit = ref.watch(selectedUnitProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// Plant
        Expanded(
          child: _buildCompactInputField(
            'Plant',
            _plantController,
            Icons.factory,
          ),
        ),

        const SizedBox(width: 12),

        /// Location
        Expanded(
          child: _buildCompactInputField(
            'Location',
            _floorController,
            Icons.location_on,
          ),
        ),

        const SizedBox(width: 12),

        /// Size (NOW SAME STYLE)
        Expanded(
          child: _buildCompactInputField(
            'Size',
            _sizeController,
            Icons.straighten,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              ref.read(dprSizeProvider.notifier).state = value;

              /// propagate with unit
              final unit = ref.read(selectedUnitProvider);
              ref
                  .read(insulationPipingMaterialsProvider.notifier)
                  .updateAllSizes(
                    size: value,
                    unit: unit,
                  );
            },
          ),
        ),

        const SizedBox(width: 12),

        /// Unit (MATCH HEIGHT + PADDING)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: DropdownButtonFormField<String>(
                  value: selectedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    filled: true,
                    fillColor: const Color(0xFFE3F2FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const ['mm', 'inch']
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedUnitProvider.notifier).state = value;
                      final size =
                          (ref.read(dprSizeProvider)?.trim().isNotEmpty ??
                                  false)
                              ? ref.read(dprSizeProvider)!
                              : (ref
                                          .read(selectedSizeProvider)
                                          ?.trim()
                                          .isNotEmpty ??
                                      false)
                                  ? ref.read(selectedSizeProvider)!
                                  : '';

                      ref
                          .read(insulationPipingMaterialsProvider.notifier)
                          .updateAllSizes(
                            size: size,
                            unit: value,
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              filled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 34,
          child: DropdownButtonFormField<String>(
            value: validValue, // ✅ Use validated value
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFE3F2FD),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text(
              'Select',
              style: TextStyle(fontSize: 13),
            ),
            items: items
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                'Pipe Insulation',
                Icons.insights,
                _pipeInsulationOn,
                false,
                (value) => _handleToggleChange(true, value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                'Equipment Insulation',
                Icons.thermostat,
                _equipmentInsulationOn,
                false,
                (value) => _handleToggleChange(false, value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleCard(
    String title,
    IconData ico,
    bool value,
    bool isLoading,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [Colors.blue, Colors.blue],
                )
              : null,
          color: value ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? Colors.blue : Colors.grey[300]!,
            width: value ? 2 : 1.5,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: value ? Colors.white : Colors.blue,
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _persistMaterialUpdate(dynamic updated) async {
    try {
      final dao = LocalMaterialDao();
      final repo = ref.read(materialRepositoryProvider);

      final serverId = updated is PipingMaterial
          ? updated.id
          : (updated as EquipmentMaterial).id;

      final local = await dao.findByServerId(serverId);
      if (local == null) return;

      local
        ..name = updated.name
        ..images = updated.image // ← this is the key line for images
        ..uom = updated.uom ?? ''
        ..materialDataJson = jsonEncode(updated.toJson())
        ..isDirty = false
        ..updatedAt = DateTime.now();

      await repo.update(local);

      if (updated.cardFormState != null) {
        await dao.saveCardFormState(
          isarId: local.id,
          state: updated.cardFormState!,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to persist material update: $e');
    }
  }

  List<Widget> _buildPipingMaterials(List<PipingMaterial> materials) {
    return materials.map((material) {
      final materialSetup = _findMaterialSetup(material.materialCode, 'piping');
      print("materialid ${material.id}");
      print("materialname ${material.name}");

      final key = _pipingKeys.putIfAbsent(
        material.id,
        () => GlobalKey<State<PipingMaterialCard>>(),
      );

      return Padding(
          key: ValueKey(
            material.id.isNotEmpty
                ? 'piping_${material.id}'
                : 'piping_${material.name}',
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: PipingMaterialCard(
            material: material,
            key: key,
            materialSetup: materialSetup,
            onChanged: (updated) {
              ref
                  .read(insulationPipingMaterialsProvider.notifier)
                  .editPipingMaterial(material.id, updated);
            },
            onAdd: () {
              copyInsulationMaterial(material: material, isPiping: true);
            },
            onEdit: () {},
            onDelete: () {
              deleteInsulationMaterial(
                material: material,
                isPiping: true,
              );
            },
            onRemark: () {
              _showRemarkDialog(material.id, material.remarks ?? '');
            },
          ));
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials(List<EquipmentMaterial> materials) {
    return materials.map((material) {
      final materialSetup =
          _findMaterialSetup(material.materialCode, 'equipment');

      // 🔥 Assign/Retrieve GlobalKey for state sync
      final key = _equipmentKeys.putIfAbsent(
          material.id, () => GlobalKey<State<EquipmentMaterialCard>>());

      return Padding(
          key: ValueKey(
            material.id.isNotEmpty
                ? 'equipment_${material.id}'
                : 'equipment_${material.name}',
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: EquipmentMaterialCard(
            key: key,
            material: material,
            materialSetup: materialSetup,
            onChanged: (updated) {
              ref
                  .read(insulationEquipmentMaterialsProvider.notifier)
                  .editEquipmentMaterial(material.id, updated);
            },
            onAdd: () {
              copyInsulationMaterial(material: material, isPiping: false);
            },
            onEdit: () {},
            onDelete: () {
              deleteInsulationMaterial(
                material: material,
                isPiping: false,
              );
            },
            onRemark: () {
              _showRemarkDialog(material.id, material.remarks ?? '');
            },
          ));
    }).toList();
  }

  void _showRemarkDialog(String materialId, String currentRemark,
      {bool isPiping = true}) {
    final remarkController = TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Remark'),
        content: TextField(
          controller: remarkController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter remark...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateMaterialRemark(materialId, remarkController.text,
                  isPiping: isPiping);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateMaterialRemark(String materialId, String remark,
      {bool isPiping = true}) {
    if (isPiping) {
      final materials = ref.read(insulationPipingMaterialsProvider);
      final updatedMaterials = materials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref
          .read(insulationPipingMaterialsProvider.notifier)
          .setMaterials(updatedMaterials);
    } else {
      final materials = ref.read(insulationEquipmentMaterialsProvider);
      final updatedMaterials = materials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .setMaterials(updatedMaterials);
    }

    _showSnackBar('Remark saved for material');
  }

  void _toggleGlobalEditMode() {
    setState(() {
      _globalEditMode = !_globalEditMode;
      _isDateOverrideMode = false;
    });

    if (_globalEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isToday(_selectedDate)
              ? "Edit mode enabled - You can now modify today's DPR and change date"
              : "Edit mode enabled - You can now modify DPR for ${_formatDate(_selectedDate)}"),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchDprListForDate(_selectedDate);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Edit mode disabled"),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _autoCreateDprWork() async {
    // Implementation for auto-creating insulation DPR
    // Similar to the DPR version but with insulation-specific data
  }

  Map<String, dynamic> buildInsulationDprPayload({
    required List<PipingMaterial> pipingMaterials,
    required List<EquipmentMaterial> equipmentMaterials,
  }) {
    // ✅ Use local _layers and _cladding, NOT insulationStateProvider
    final validLayers = _layers.where((l) => l.name.trim().isNotEmpty).toList();

    String? lm1, lm2, lm3;
    int lt1 = 0, lt2 = 0, lt3 = 0;

    if (validLayers.length >= 1) {
      lm1 = validLayers[0].name.trim();
      lt1 = validLayers[0].thickness.toInt();
    }
    if (validLayers.length >= 2) {
      lm2 = validLayers[1].name.trim();
      lt2 = validLayers[1].thickness.toInt();
    }
    if (validLayers.length >= 3) {
      lm3 = validLayers[2].name.trim();
      lt3 = validLayers[2].thickness.toInt();
    }

    final designation = <String>[];
    if (pipingMaterials.isNotEmpty) designation.add('piping');
    if (equipmentMaterials.isNotEmpty) designation.add('equipment');

    final size = [
      ref.read(dprSizeProvider),
      ref.read(selectedSizeProvider),
      _sizeController.text
    ].firstWhere(
      (v) =>
          v != null &&
          v.trim().isNotEmpty &&
          (num.tryParse(v.trim()) ?? 0) != 0,
      orElse: () => '',
    );

    // ✅ Get location, default to 'Ground' if empty
    final location = _floorController.text.trim().isNotEmpty
        ? _floorController.text.trim()
        : 'Ground';

    return {
      'designation': designation,
      'plant': _plantController.text.trim(),
      'location': location, // ✅ Updated: default to 'Ground' if empty
      'layer': _selectedLayerType.name,
      'work_description': _dprNameController.text,
      'size': size,
      'sizeUom': ref.read(selectedUnitProvider),
      'legging_material_1': lm1,
      'legging_thickness_1': lt1,
      'legging_material_2': lm2,
      'legging_thickness_2': lt2,
      'legging_material_3': lm3,
      'legging_thickness_3': lt3,
      'cladding_material': _cladding.name.isNotEmpty ? _cladding.name : null,
      'cladding_swg': _cladding.thickness.toInt(),
      'lagging_removal': _removeLagging,
      'cladding_removal': _removeCladding,

      if (equipmentMaterials.isNotEmpty)
        'equipment_materials': equipmentMaterials.map((e) {
          final fieldValues = <String, dynamic>{};
          final state = e.cardFormState;

          if (state != null) {
            print("images ${e.image}");
            // Log what's in the state
            debugPrint(
                "📦 Equipment [${e.name}] - FieldEntries: ${state.fieldEntries.keys} with values: ${state.fieldEntries.values}");
            debugPrint(
                "📦 Equipment [${e.name}] - GeometryMode: ${state.geometryMode}");

            // Map ALL dynamic fields from cardFormState
            state.fieldEntries.forEach((key, entry) {
              final val = entry.value;

              // Always include the field, even if null
              fieldValues[key] = val;

              // Always include unit if it exists
              if (entry.unit != null && entry.unit!.isNotEmpty) {
                fieldValues["${key}Uom"] = entry.unit;
              }
            });

            // Include geometryMode
            if (state.geometryMode != null && state.geometryMode!.isNotEmpty) {
              fieldValues["geometryMode"] = state.geometryMode;
            }

            // With this:
            final qtyEntry =
                state.fieldEntries['quantity'] ?? state.fieldEntries['qty'];
            final hasOtherFields = state.fieldEntries.entries.any((entry) {
              final key = entry.key.toLowerCase();
              if (key == 'quantity' || key == 'qty') return false;
              return _hasMeaningfulValue(entry.value.value);
            });
            final qtyEntryNum = num.tryParse('${qtyEntry?.value ?? ''}');
            final baseQtyNum = num.tryParse('${e.qty ?? 0}') ?? 0;
            final hasExplicitQty = qtyEntryNum != null && qtyEntryNum > 0;
            final hasMaterialInputs = hasOtherFields;
            final resolvedQty = (qtyEntry != null &&
                    qtyEntry.value != null &&
                    qtyEntry.value != 0)
                ? qtyEntry.value
              : hasExplicitQty
                ? qtyEntryNum
                : (baseQtyNum > 0 && (hasMaterialInputs || baseQtyNum != 1)
                  ? baseQtyNum
                  : (hasMaterialInputs ? 1 : 0));
            fieldValues["quantity"] = resolvedQty;
            fieldValues["qtyUom"] =
                qtyEntry?.unit != null && qtyEntry!.unit!.isNotEmpty
                    ? qtyEntry.unit
                    : "NOS";

            fieldValues["qtyUom"] =
                qtyEntry?.unit != null && qtyEntry!.unit!.isNotEmpty
                    ? qtyEntry.unit
                    : "NOS";
            debugPrint(
                "📦 Equipment [${e.name}] - Final fieldValues: $fieldValues");
          } else {
            final baseQty = num.tryParse('${e.qty ?? 0}') ?? 0;
            // No field state means no meaningful inputs; avoid synthetic default qty=1.
            fieldValues["quantity"] = baseQty == 1 ? 0 : baseQty;
            fieldValues["qtyUom"] = "NOS";
            debugPrint(
                "📦 Equipment [${e.name}] - No state, using default: $fieldValues");
          }

          return {
            "name": e.name,
            "materialCode": e.materialCode,
            "fieldValues": fieldValues,
            "image": e.image,
          };
        }).toList(),
      if (pipingMaterials.isNotEmpty)
        'piping_materials': pipingMaterials.map((p) {
          // ✅ Ensure quantity is treated as an integer and defaults to 0 if null
          // ✅ Override size/sizeUom from card field entry when present
          final sizeEntry = p.cardFormState?.fieldEntries['size'];
          final qtyEntry = p.cardFormState?.fieldEntries['quantity'];
          final sizeValue = sizeEntry?.value;
          final resolvedSize =
            (sizeValue != null && sizeValue.toString().trim().isNotEmpty)
              ? sizeValue.toString()
              : p.size;
          final resolvedSizeUom =
            (sizeEntry?.unit != null && sizeEntry!.unit!.isNotEmpty)
              ? sizeEntry.unit
              : p.sizeUom;

          final hasFieldValues = _hasMeaningfulMapValues(
            p.fieldValues?.values,
            ignoreKeys: const {
              'quantity',
              'qty',
              'qtyUom',
              'size',
              'sizeUom',
              'geometryMode',
            },
          );
          final qty =
              (p.qty != null && p.qty != 0) ? p.qty : (hasFieldValues ? 1 : 0);
          final updatedPiping = p.copyWith(qty: qty);
          final json = updatedPiping.toJson();
          final cardFormState = json['cardFormState'] as Map<String, dynamic>?;
          final fieldEntries = cardFormState?['fieldEntries'] as Map<String, dynamic>?;
          final quantityField = fieldEntries?['quantity'] as Map<String, dynamic>?;

          if (quantityField != null) {
            final qtyEntryValue = qtyEntry?.value;
            final hasQtyEntryValue = qtyEntryValue != null &&
                qtyEntryValue.toString().trim().isNotEmpty;
            quantityField['value'] = hasQtyEntryValue ? qtyEntryValue : qty;
          }

          json['images'] = p.image;
          debugPrint(
            '📦 Piping Material Payload [${p.name}]: Qty=$qty, Size=${json['size']}, SizeUom=${json['sizeUom']}');
          return json;
        }).toList(),
    };
  }

  InsulationDprModel _buildDraftModel() {
    final pipingMaterials = ref.read(insulationPipingMaterialsProvider);

    final equipmentMaterials = ref.read(insulationEquipmentMaterialsProvider);

    final state = ref.read(insulationStateProvider);

    final validLayers =
        state.layers.where((l) => l.name.trim().isNotEmpty).toList();

    return InsulationDprModel(
      id: _insulationId ?? generateObjectId(),
      workDescription: _dprNameController.text.trim(),
      designation: [
        if (pipingMaterials.isNotEmpty) 'piping',
        if (equipmentMaterials.isNotEmpty) 'equipment',
      ],
      plant: _plantController.text.trim(),
      location: _floorController.text.trim(),
      size: int.tryParse(_sizeController.text.trim()) ?? 0,
      layer: state.layerType?.name ?? 'single',
      leggingMaterial1: validLayers.length > 0 ? validLayers[0].name : null,
      leggingThickness1:
          validLayers.length > 0 ? validLayers[0].thickness.toInt() : null,
      leggingMaterial2: validLayers.length > 1 ? validLayers[1].name : null,
      leggingThickness2:
          validLayers.length > 1 ? validLayers[1].thickness.toInt() : null,
      leggingMaterial3: validLayers.length > 2 ? validLayers[2].name : null,
      leggingThickness3:
          validLayers.length > 2 ? validLayers[2].thickness.toInt() : null,
      claddingMaterial:
          state.cladding.name.isNotEmpty ? state.cladding.name : null,
      claddingSwg: state.cladding.thickness.toInt(),
      pipingMaterials: pipingMaterials,
      equipmentMaterials: equipmentMaterials,
      layer1Rate: 0,
      layer2Rate: 0,
      layer3Rate: 0,
      totalMaterialCost: 0,
      totalPipingArea: 0,
      totalEquipmentArea: 0,
      grandTotalArea: 0,
      totalAmount: 0,
      status: 'draft',
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _autoSaveDraft() async {
    final draft = _buildDraftModel();
    debugPrint(
        "PIPING COUNT: ${ref.read(insulationPipingMaterialsProvider).length}");
    debugPrint(
        "EQUIPMENT COUNT: ${ref.read(insulationEquipmentMaterialsProvider).length}");

    ref.read(insulationDraftProvider.notifier).saveDraft(draft);

    debugPrint("💾 Draft Auto Saved");
  }

  Future<void> _handleSubmitFields() async {
    if (!_isEditable && !_isDateOverrideMode) {
      AppToast.error("Edit mode is off");
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Sync latest state from cards
      _syncPipingBeforeSubmit();
      _syncEquipmentBeforeSubmit();

      final imageService = MaterialImageUploadService();
      final cacheDao = CachedImageDao();

      var equipmentMaterials = ref.read(insulationEquipmentMaterialsProvider);
      final pipingMaterials = ref.read(insulationPipingMaterialsProvider);

      // ✅ STEP 1: Check cache for existing server URLs
      debugPrint('🔍 Step 1: Checking cache for existing server URLs...');
      for (final material in equipmentMaterials) {
        for (final imagePath in material.image) {
          // Skip if already a remote URL
          if (!imagePath.startsWith('http://') &&
              !imagePath.startsWith('https://')) {
            final serverUrl = await cacheDao.getServerUrl(imagePath);
            if (serverUrl != null && serverUrl.isNotEmpty) {
              debugPrint('✅ Found cached URL: $imagePath -> $serverUrl');
            }
          }
        }
      }

      // ✅ STEP 2: Process all equipment images - check cache and stage new ones
      debugPrint(
          '📷 Step 2: Processing equipment images (check cache + stage new)...');
      final processedUrls =
          await imageService.processMaterialImages(equipmentMaterials);

      // Update materials with processed URLs (mixing cached server URLs + placeholders for pending)
      equipmentMaterials = equipmentMaterials.map((material) {
        final urls = processedUrls[material.id];
        if (urls != null && urls.isNotEmpty) {
          return material.copyWith(image: urls);
        }
        return material;
      }).toList();

      debugPrint('📤 Materials after processing:');
      for (final m in equipmentMaterials) {
        debugPrint('   ${m.name}: ${m.image}');
      }

      // ✅ STEP 3: Upload all staged (new) images to AWS in batch
      debugPrint('☁️ Step 3: Uploading staged images to AWS...');
      final uploadedUrls = await imageService.uploadAllStagedImages();

      if (uploadedUrls.isNotEmpty) {
        debugPrint('✅ AWS upload successful. URLs received:');
        uploadedUrls.forEach((id, urls) {
          debugPrint('   [$id]: $urls');
        });

        // ✅ STEP 4: Replace placeholders with actual AWS URLs
        debugPrint('🔄 Step 4: Replacing placeholders with AWS URLs...');
        equipmentMaterials = imageService.replacePlaceholdersWithUrls(
          equipmentMaterials,
          uploadedUrls,
        );
      } else {
        debugPrint('ℹ️ No new images to upload (all cached)');
      }

      // Update provider with final equipment materials
      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .setMaterials(equipmentMaterials);

      // ✅ STEP 5: Build final payload with all resolved image URLs
      debugPrint('📦 Step 5: Building final DPR payload...');
      final finalEquipment = ref.read(insulationEquipmentMaterialsProvider);
      final finalPiping = ref.read(insulationPipingMaterialsProvider);

      final payload = buildInsulationDprPayload(
        pipingMaterials: finalPiping,
        equipmentMaterials: finalEquipment,
      );

      if (_isDateOverrideMode) {
        payload['date'] = _selectedDate.toIso8601String();
      }

      debugPrint("📋 Final DPR Payload - Equipment Images:");
      for (final eq in finalEquipment) {
        debugPrint("   ${eq.name}:");
        for (final img in eq.image) {
          debugPrint("      - $img");
        }
      }
      debugPrint("📤 INSULATION DPR PAYLOAD:");
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));


      // ✅ STEP 6: Send the payload to server
      debugPrint('📤 Step 6: Sending DPR payload to server...');
      if (_insulationId == null) {
        await InsulationDprApi.createInsulationDpr(
          data: payload,
          siteId: siteId,
          teamId: teamId,
        );
        debugPrint('✅ Insulation DPR created successfully');
      } else {
        await InsulationDprApi.updateInsulationDpr(
          dprId: _insulationId!,
          data: payload,
        );
        debugPrint('✅ Insulation DPR updated successfully');
      }

      // Clean up staged images
      imageService.clearAll();

      _showSnackBar("Insulation DPR Saved Successfully");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          int count = 0;
            if (widget.work == null) {
            Navigator.of(context).popUntil((_) => count++ >= 5);
          } else {
            context.pop(true);
          }
          _showSnackBar("Successfully Saved");
        }
      });
    } catch (e, s) {
      await _autoSaveDraft();
      debugPrint("❌ Submit error: $e");
      debugPrint("❌ Stack trace: $s");
      _showSnackBar(
        'Failed to save Insulation DPR: ${extractBackendError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _patchPipingImages(Map<String, List<String>> urlMap) {
    final notifier = ref.read(insulationPipingMaterialsProvider.notifier);
    final materials = ref.read(insulationPipingMaterialsProvider);
    final patched = materials.map((m) {
      final urls = urlMap[m.id];
      if (urls == null) return m;
      return m.copyWith(image: urls);
    }).toList();
    notifier.setMaterials(patched);
  }

  /// Patches AWS image URLs into equipment materials after batch upload
  void _patchEquipmentImages(Map<String, List<String>> urlMap) {
    final notifier = ref.read(insulationEquipmentMaterialsProvider.notifier);
    final materials = ref.read(insulationEquipmentMaterialsProvider);
    final patched = materials.map((m) {
      final urls = urlMap[m.id];
      if (urls == null) return m;
      return m.copyWith(image: urls);
    }).toList();
    notifier.setMaterials(patched);
  }

  bool _hasMeaningfulValue(dynamic value) {
    if (value == null) return false;
    final text = value.toString().trim();
    return text.isNotEmpty && text.toLowerCase() != 'null';
  }

  bool _hasMeaningfulMapValues(
    Map<String, dynamic>? values, {
    Set<String> ignoreKeys = const {},
  }) {
    if (values == null || values.isEmpty) return false;
    for (final entry in values.entries) {
      if (ignoreKeys.contains(entry.key)) continue;
      if (_hasMeaningfulValue(entry.value)) return true;
    }
    return false;
  }

  /// NEW: Synchronizes all equipment cards by calling getLatestMaterial() on each.
  void _syncEquipmentBeforeSubmit() {
    final notifier = ref.read(insulationEquipmentMaterialsProvider.notifier);
    final materials = ref.read(insulationEquipmentMaterialsProvider);
    final List<EquipmentMaterial> updatedList = [];

    for (final m in materials) {
      final key = _equipmentKeys[m.id];
      final dynamic cardState = key?.currentState;

      if (cardState != null && cardState.mounted) {
        try {
          // Check if the method exists
          if (cardState.getLatestMaterial != null) {
            final updated = cardState.getLatestMaterial();
            updatedList.add(updated);
          } else {
            updatedList.add(m);
          }
        } catch (e) {
          debugPrint("Failed to sync equipment material ${m.id}: $e");
          updatedList.add(m);
        }
      } else {
        updatedList.add(m);
      }
    }

    notifier.setMaterials(updatedList);
  }

  void _syncPipingBeforeSubmit() {
    final notifier = ref.read(insulationPipingMaterialsProvider.notifier);
    final materials = ref.read(insulationPipingMaterialsProvider);
    final List<PipingMaterial> updatedList = [];

    for (final m in materials) {
      final key = _pipingKeys[m.id];
      final dynamic cardState = key?.currentState;

      if (cardState != null && cardState.mounted) {
        try {
          final updated = cardState.getLatestMaterial();
          updatedList.add(updated);
        } catch (e) {
          debugPrint("Failed to sync piping material ${m.id}: $e");
          updatedList.add(m);
        }
      } else {
        updatedList.add(m);
      }
    }

    notifier.setMaterials(updatedList);
  }

  @override
  void dispose() {
    _isDisposed = true;

    _dprNameController.dispose();
    _mocController.dispose();
    _sizeController.dispose();
    _plantController.dispose();
    _floorController.dispose();
    _layerNameController.dispose();
    _thicknessController.dispose();
    _claddingNameController.dispose();
    _claddingThicknessController.dispose();
    super.dispose();
  }
}
