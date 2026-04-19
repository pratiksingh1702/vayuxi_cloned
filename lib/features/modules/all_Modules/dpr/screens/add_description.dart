import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/upload/upload_exports.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/equipment_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/calculation/expand_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/test_dynamic.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import '../../../../../core/local/isar_db.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../language/service/providers.dart';
import '../dpr-setup/screens/add/add_material.dart';
import '../models/data/eqipment_provider.dart';
import '../models/data/piping_provider.dart';
import '../models/dprModel.dart';
import '../models/equipmentModel.dart';
import '../models/pipingModel.dart';
import '../models/rate_file_models.dart';
import '../offline/mech/repo/dpr_draft_repo.dart';
import '../offline/mech/repo/rate_Repo.dart';
import '../providers/dpr.dart';
import '../providers/material_service.dart';
import '../providers/rate_variant_provider.dart';
import '../providers/selectedSize_provider.dart';
import '../providers/selection_provider.dart';
import 'controllers/dpr_session_provider.dart';
import 'material_sync_util.dart';
import 'widgets/material_overlay_edit.dart';

class AddDescriptionScreen extends ConsumerStatefulWidget {
  final DprModel? work;

  const AddDescriptionScreen({super.key, this.work});

  @override
  ConsumerState<AddDescriptionScreen> createState() =>
      _AddDescriptionScreenState();
}

class _AddDescriptionScreenState extends ConsumerState<AddDescriptionScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _dprNameController;
  late final TextEditingController _mocController;
  late final TextEditingController _sizeController;
  late final TextEditingController _sizeUomController;
  late final TextEditingController _plantController;
  late final TextEditingController _floorController;
  Key _materialsRebuildKey = UniqueKey();
  String? editingMaterialId;
  String? draftCategoryId;
  bool _isLoading = false;
  late String siteId;
  late String teamId;
  late TeamModel team;

  String? _mechanicalId;
  String? _selectedDprId;

  bool _pipeFittingOn = true;
  bool _equipmentOn = true;
  bool _editMode = true;
  bool _globalEditMode = false;
  bool _showPipingMaterials = true;
  bool _showEquipmentMaterials = true;

  DateTime _selectedDate = DateTime.now();

  bool _isLoadingMaterials = false;
  bool _isSubmitting = false;
  bool _isCreatingWork = false;
  bool _isDisposed = false;
  bool _initialDataLoaded = false;
  bool _autoCreateAttempted = false;

  List<DprModel> _dprListForSelectedDate = [];
  bool _isLoadingDprList = false;
  bool get isCreatingDpr => _mechanicalId == null;
  bool get isEditingDpr => _mechanicalId != null;
  bool get isEditing => _mechanicalId != null;
  Set<String> _updatingMaterialIds = {};
  final Map<String, String> _equipmentLengthDraft = {};
  bool _headerInitialized = false;
  bool _isDateOverrideMode = false;
  final DprDraftRepo _draftRepo = DprDraftRepo();

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //   _initializeControllers();
  //   _initializeData();
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _loadInitialData();
  //   });
  // }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 🔴 Read persisted session
      final session = ref.read(dprSessionProvider);

      // Restore date
      _selectedDate = session.selectedDate;
      _globalEditMode = session.isEditMode;

      if (widget.work != null) {
        _mechanicalId = widget.work!.id;
      }

      await loadScreenState(Dpr: widget.work);

      // 🔴 If edit mode was on for a past date, fetch DPR list for that date
      if (session.isEditMode && !_isToday(session.selectedDate)) {
        await _fetchDprListForDate(session.selectedDate);
      }

      if (widget.work == null) _applyHeaderValuesToMaterials();
    });

    _floorController.addListener(_applyHeaderValuesToMaterials);
    _mocController.addListener(_applyHeaderValuesToMaterials);
    _sizeController.addListener(_applyHeaderValuesToMaterials);
  }

  void _setControllerSilently(
    TextEditingController controller,
    String value,
  ) {
    controller.removeListener(_applyHeaderValuesToMaterials);
    controller.text = value;
    controller.addListener(_applyHeaderValuesToMaterials);
  }

  Future<void> loadScreenState({DprModel? Dpr}) async {
    _equipmentLengthDraft.clear();
    ref.read(pipingMaterialsProvider.notifier).clear();
    ref.read(equipmentMaterialsProvider.notifier).clear();

    // ✅ Always reset flag at the START of every load
    _headerInitialized = false;

    final work = widget.work ?? Dpr;

    if (work != null && (work.id == null || work.id!.trim().isEmpty)) {
      _hydrateFromWorkModel(work);
      return;
    }

    if (_mechanicalId != null) {
      if (work != null) {
        _mechanicalId = work.id;
        _selectedDprId = work.id;
        await _loadDprMaterials(work);
      } else {
        await _loadDefaultMaterials();
        _headerInitialized = true;
      }
    } else {
      await _loadDefaultMaterials();
      _headerInitialized = true;
    }
  }

  void _hydrateFromWorkModel(DprModel work) {
    if (work.siteId.trim().isNotEmpty) {
      siteId = work.siteId;
    }
    if (work.teamId.trim().isNotEmpty) {
      teamId = work.teamId;
    }

    _mechanicalId = work.id;
    _selectedDprId = work.id;
    _selectedDate = work.date;

    _dprNameController.text = work.dprName;
    _mocController.text = work.moc;
    _sizeController.text = work.size;
    _floorController.text = work.location;
    _plantController.text = work.plant;

    ref.read(pipingMaterialsProvider.notifier).setMaterials(work.piping);
    ref.read(equipmentMaterialsProvider.notifier).setMaterials(work.equipment);

    _headerInitialized = true;
    if (mounted) {
      setState(() {
        _showPipingMaterials = work.piping.isNotEmpty;
        _showEquipmentMaterials = work.equipment.isNotEmpty;
        _pipeFittingOn = work.piping.isNotEmpty;
        _equipmentOn = work.equipment.isNotEmpty;
      });
      _showSnackBar('Draft restored for editing');
    }
  }

  List<PipingItem> _toApprovedPipingItems(
    List<RateFileMaterial> materials,
  ) {
    return materials
        .where((m) => m.availableVariants.isNotEmpty) // 👈 IMPORTANT
        .map((m) {
      final v = m.availableVariants.first; // guaranteed non-null
      return PipingItem.fromRateMaterial(m, v);
    }).toList();
  }

  List<EquipmentItem> _toApprovedEquipmentItems(
    List<RateFileMaterial> materials,
  ) {
    return materials
        .where((m) => m.availableVariants.isNotEmpty) // 👈 IMPORTANT
        .map((m) {
      final v = m.availableVariants.first;
      return EquipmentItem.fromRateMaterial(m, v);
    }).toList();
  }

  Future<void> _loadDefaultMaterials() async {
    try {
      final approvedMaterials = ref.read(approvedRateMaterialsProvider(siteId));

      final pipingItems = _toApprovedPipingItems(
        approvedMaterials
            .where((m) => m.designation.contains("piping"))
            .toList(),
      );

      final equipmentItems = _toApprovedEquipmentItems(
        approvedMaterials
            .where((m) => m.designation.contains("equipment"))
            .toList(),
      );

      ref.read(pipingMaterialsProvider.notifier).setMaterials(pipingItems);
      ref
          .read(equipmentMaterialsProvider.notifier)
          .setMaterials(equipmentItems);
      _applyHeaderValuesToMaterials();
    } catch (e, st) {
      debugPrint("❌ Failed: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _loadDprMaterials(DprModel? fallbackDpr) async {
    debugPrint('================ DPR LOAD START ================');
    debugPrint('siteId: $siteId');
    debugPrint('teamId: $teamId');
    debugPrint('mechanicalId: $_mechanicalId');

    try {
      final dpr = fallbackDpr ??
          await ref.read(dprProvider.notifier).fetchDprById(
                siteId: siteId,
                teamId: teamId,
                workId: _mechanicalId!,
              );

      debugPrint('DPR fetch completed');

      if (dpr == null) {
        debugPrint('❌ DPR is NULL');
        debugPrint('================ DPR LOAD END ================');
        return;
      }
      for (final m in dpr.equipment) {
        debugPrint("🧱 ${m.materialName}");
        debugPrint("dynamic count: ${m.dynamicFields.length}");
      }

      debugPrint('✅ DPR received');
      debugPrint('dprName: ${dpr.dprName}');
      debugPrint('moc: ${dpr.moc}');
      debugPrint('size: ${dpr.size}');
      debugPrint('location: ${dpr.location}');
      debugPrint('plant: ${dpr.plant}');
      debugPrint('server piping count: ${dpr.piping.length}');
      debugPrint('server equipment count: ${dpr.equipment.length}');

      debugPrint('local piping count: ${PipingMaterialsData.materials.length}');
      debugPrint(
          'local equipment count: ${EquipmentMaterialsData.materials.length}');

      final mergedPiping = MaterialSyncService.syncPiping(
        local: PipingMaterialsData.materials,
        server: dpr.piping,
      );

      final mergedEquipment = MaterialSyncService.syncEquipment(
        local: EquipmentMaterialsData.materials,
        server: dpr.equipment,
      );

      debugPrint('merged piping count: ${mergedPiping.length}');
      debugPrint('merged equipment count: ${mergedEquipment.length}');

      ref.read(pipingMaterialsProvider.notifier).setMaterials(mergedPiping);

      ref
          .read(equipmentMaterialsProvider.notifier)
          .setMaterials(mergedEquipment);
      final state = ref.read(pipingMaterialsProvider);

      for (final m in state) {
        debugPrint("🧱 ${m.materialName}");
        debugPrint("dynamic count: ${m.dynamicFields.length}");
      }

      debugPrint('✅ Providers updated');

      _dprNameController.text = dpr.dprName;
      _mocController.text = dpr.moc;
      _sizeController.text = dpr.size;
      _floorController.text = dpr.location;
      _plantController.text = dpr.plant;
      _selectedDate = dpr.date;

      _headerInitialized = true;
      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ Controllers updated');
      debugPrint('================ DPR LOAD END ================');
    } catch (e, st) {
      debugPrint('🔥 ERROR while loading DPR');
      debugPrint(e.toString());
      _headerInitialized = true;

      debugPrint(st.toString());
      debugPrint('================ DPR LOAD END ================');
    }
  }

  Future<void> _loadMaterialsForEditing() async {
    final dpr = await ref.read(dprProvider.notifier).fetchDprById(
          siteId: siteId,
          teamId: teamId,
          workId: _mechanicalId!,
        );

    if (dpr == null) return;

    ref.read(pipingMaterialsProvider.notifier).setMaterials(dpr.piping);
    ref.read(equipmentMaterialsProvider.notifier).setMaterials(dpr.equipment);

    _dprNameController.text = dpr.dprName;
    _mocController.text = dpr.moc;
    _sizeController.text = dpr.size;
    _floorController.text = dpr.location;
    _plantController.text = dpr.plant;
  }

  Future<void> _loadMaterialsForCreate() async {
    final service = DefaultMaterialService();

    final materials = await service.getDefaultMaterials(
      siteId: siteId,
      designation: 'both',
    );

    ref.read(pipingMaterialsProvider.notifier).setMaterials(
          materials.whereType<PipingItem>().toList(),
        );

    ref.read(equipmentMaterialsProvider.notifier).setMaterials(
          materials.whereType<EquipmentItem>().toList(),
        );
  }

  void _applyHeaderValuesToMaterials() {
    print("😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂😂");
    if (!_headerInitialized) return;

    final floor = _floorController.text;
    final moc = _mocController.text;
    final size = _sizeController.text;

    /// PIPING
    final piping = ref.read(pipingMaterialsProvider);
    ref.read(pipingMaterialsProvider.notifier).state = piping.map((m) {
      final updated = m.dynamicFields.map((f) {
        final key = f.key.toLowerCase();

        if (key == 'floor') {
          return f.copyWith(value: floor);
        }
        if (key == 'moc') {
          return f.copyWith(value: moc);
        }
        if (key == 'size') {
          return f.copyWith(value: size);
        }
        if (key == 'qty') {
          return f.copyWith(displayText: '1', value: '1');
        }

        // everything else empty
        // 🔥 THIS IS THE IMPORTANT PART
        if (isCreatingDpr) {
          // New DPR → wipe DB default values
          return f.copyWith(value: '');
        } else {
          // Editing DPR → preserve server values
          return f;
        }
      }).toList();

      return m.copyWith(dynamicFields: updated);
    }).toList();

    /// EQUIPMENT
    final equipment = ref.read(equipmentMaterialsProvider);
    ref.read(equipmentMaterialsProvider.notifier).state = equipment.map((m) {
      final updated = m.dynamicFields.map((f) {
        final key = f.key.toLowerCase();

        if (key == 'floor') {
          return f.copyWith(displayText: floor, value: floor);
        }
        if (key == 'moc') {
          return f.copyWith(displayText: moc, value: moc);
        }
        if (key == 'size') {
          return f.copyWith(displayText: size, value: size);
        }
        if (key == 'qty') {
          return f.copyWith(displayText: '1', value: '1');
        }

        // everything else empty
        return f;
      }).toList();

      return m.copyWith(dynamicFields: updated);
    }).toList();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Clear any pending updates
    }
  }

  void _initializeControllers() {
    _dprNameController = TextEditingController();
    _dprNameController.addListener(() => setState(() {}));
    _mocController = TextEditingController();
    _sizeController = TextEditingController();
    _sizeUomController = TextEditingController();
    _plantController = TextEditingController();
    _floorController = TextEditingController();
  }

  void _initializeData() {
    siteId = ref.read(selectedSiteIdProvider)!;
    teamId = ref.read(selectedTeamIdProvider) ?? "default";
    team = ref.read(currentTeamProvider) ??
        TeamModel(
          id: "",
          teamName: "",
          teamMemberIds: [],
          company: '',
          isDeleted: false,
          type: '',
        );
    _mocController.text = (widget.work == null
            ? ref.read(selectedMocNameProvider)
            : widget.work?.moc) ??
        "";
    _floorController.text = (widget.work == null
            ? ref.read(selectedFloorNameProvider)
            : widget.work?.location) ??
        "";
    _sizeController.text = (widget.work == null
            ? ref.read(selectedSizeProvider)
            : widget.work?.size) ??
        "";
    _sizeUomController.text = (widget.work == null
            ? ref.read(selectedUnitProvider)!
            : widget.work?.size) ??
        "";
  }

  // Future<void> _loadInitialData() async {
  //   if (_isDisposed) return;
  //
  //   if (mounted) setState(() => _isLoadingMaterials = true);
  //
  //   try {
  //     if (widget.work != null) {
  //       // If workId is provided, load that specific DPR
  //       _mechanicalId = widget.work?.id;
  //       await _fetchDprWorkById();
  //     } else {
  //       // Check if today's date
  //       if (_isToday(_selectedDate)) {
  //         // For today's date, always create a new DPR
  //         await _autoCreateDprWork();
  //       } else {
  //         // For other dates, fetch DPR list
  //         await _fetchDprListForDate(_selectedDate);
  //
  //         if (_dprListForSelectedDate.isNotEmpty) {
  //           ref.read(pipingMaterialsProvider.notifier).clear();
  //           ref.read(equipmentMaterialsProvider.notifier).clear();
  //           await _loadDprWork(_dprListForSelectedDate.first);
  //         } else {
  //           // No DPR found for selected date
  //           setState(() {
  //             _mechanicalId = null;
  //             _selectedDprId = null;
  //             _dprNameController.text = 'New DPR Entry';
  //             _pipeFittingOn = false;
  //             _equipmentOn = false;
  //             _showPipingMaterials = false;
  //             _showEquipmentMaterials = false;
  //           });
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted && !_isDisposed) {
  //       print('Error loading initial data: $e');
  //       final message = extractBackendError(e);
  //       _showSnackBar('Failed to load DPR work: $message', isError: true);
  //     }
  //   } finally {
  //     if (mounted && !_isDisposed) {
  //       setState(() {
  //         _isLoadingMaterials = false;
  //         _initialDataLoaded = true;
  //       });
  //     }
  //   }
  // }
  Future<void> _resetMaterialProviders() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      /// 1️⃣ Clear providers
      ref.read(pipingMaterialsProvider.notifier).clear();
      ref.read(equipmentMaterialsProvider.notifier).clear();

      /// 2️⃣ Load defaults
      await _loadDefaultMaterials();

      /// 3️⃣ Apply header
      _applyHeaderValuesToMaterials();

      /// 4️⃣ FORCE FULL UI REBUILD
      setState(() {
        _materialsRebuildKey = UniqueKey();
      });
    } catch (e, st) {
      debugPrint("❌ Material reset failed: $e");
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDprListForDate(DateTime date) async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingDprList = true;
      _isLoading = true;
    });

    try {
      final List<DprModel> allDprs = await DprApi.fetchDprWork(
        siteId: siteId,
        teamId: teamId,
      );
      _dprListForSelectedDate = allDprs.where((dpr) {
        // Normalize DPR date (strip time completely)
        final dprDate = DateTime(
          dpr.date.year,
          dpr.date.month,
          dpr.date.day,
        );

        // Normalize selected date (strip time completely)
        final selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
        );

        return dprDate.year == selectedDate.year &&
            dprDate.month == selectedDate.month &&
            dprDate.day == selectedDate.day;
      }).toList();
      _showSnackBar(
        _dprListForSelectedDate.isNotEmpty
            ? 'Found ${_dprListForSelectedDate.length} DPR(s) for ${_formatDate(date)}'
            : 'No DPR found for ${_formatDate(date)}. Create a new DPR.',
      );
      // if(_dprListForSelectedDate.isNotEmpty){
      //   // 1️⃣ Reset DPR identity
      //   setState(() {
      //     _mechanicalId = null;
      //     _selectedDprId = null;
      //   });
      //   print("😂😂😂😂😂");
      //
      //   // 2️⃣ Reset header fields
      //   _dprNameController.text = '';
      //
      //
      //   // 3️⃣ Clear providers (remove old DPR materials completely)
      //   ref.read(pipingMaterialsProvider.notifier).clear();
      //   ref.read(equipmentMaterialsProvider.notifier).clear();
      //
      //   // 4️⃣ Load fresh default materials
      //   await _loadDefaultMaterials();
      //
      //
      //
      //   // 6️⃣ Force rebuild
      //   if (mounted) {
      //     setState(() {});
      //   }
      //
      //   _showSnackBar("New DPR initialized");
      // }

      print(
          'Found ${_dprListForSelectedDate.length} DPR(s) for ${_formatDate(date)}');
    } catch (e) {
      final message = extractBackendError(e);
      _showSnackBar('Error fetching DPR list: $message', isError: true);
      print('Error fetching DPR list: $e');

      _dprListForSelectedDate = [];
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoadingDprList = false;
          _isLoading = false;
        });
      }
    }
  }
  //
  // Future<void> _loadDprWork(DprModel dpr) async {
  //   if (_isDisposed) return;
  //
  //   _mechanicalId = dpr.id;
  //   _selectedDprId = dpr.id;
  //
  //   _dprNameController.text = dpr.dprName;
  //   _mocController.text = dpr.moc;
  //   _sizeController.text = dpr.size;
  //   _floorController.text = dpr.location;
  //   _plantController.text = dpr.plant;
  //
  //   await _fetchDprWorkById();
  //
  //   if (mounted && !_isDisposed) {
  //     setState(() {
  //       if (dpr.piping.isNotEmpty) {
  //         _pipeFittingOn = true;
  //         _showPipingMaterials = true;
  //       }
  //       if (dpr.equipment.isNotEmpty) {
  //         _equipmentOn = true;
  //         _showEquipmentMaterials = true;
  //       }
  //     });
  //   }
  // }

  Future<void> _autoCreateDprWork() async {
    if (_isDisposed || _autoCreateAttempted) return;

    // final designation = await _askDprDesignation();
    // if (designation == null || designation.isEmpty) {
    //   _showSnackBar('DPR creation cancelled', isError: true);
    //   return;
    // }

    _autoCreateAttempted = true;
    if (mounted) setState(() => _isCreatingWork = true);

    try {
      final postData = {
        'dprName': _dprNameController.text.trim(),
        'plant': _plantController.text.trim(),
        'location': _floorController.text.trim(),
        'size': _sizeController.text.trim(),
        'moc': _mocController.text.trim(),
        'designation': ["piping", "equipment"],
        'date': _selectedDate.toIso8601String(),
      };

      print('Auto-creating DPR work with data: $postData');

      final DprModel response = await DprApi.postDprWork(
        data: postData,
        siteId: siteId,
        teamId: teamId,
      );

      if (response != null && response.id != null) {
        _mechanicalId = response.id;
        _selectedDprId = response.id;
        await _fetchDprWorkById();

        print('Auto-created DPR work with ID: $_mechanicalId');

        _dprListForSelectedDate.add(response);

        if (mounted) {
          setState(() {
            _pipeFittingOn = true;
            _equipmentOn = true;
            _showPipingMaterials = true;
            _showEquipmentMaterials = true;
          });
        }

        _showSnackBar('DPR work created successfully!');
      } else {
        throw Exception('Failed to create DPR work - no ID returned');
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        print('Error auto-creating DPR work: $e');
        final message = extractBackendError(e);
        _showSnackBar('Failed to load DPR work: $message', isError: true);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isCreatingWork = false);
      }
    }
  }

  String materialKey(String name, String designation) {
    return '${designation.toLowerCase()}::${name.trim().toLowerCase()}';
  }

  Future<List<String>?> _askDprDesignation() async {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select DPR Work Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.precision_manufacturing),
                title: const Text('Piping'),
                onTap: () {
                  context.pop(['piping']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Equipment'),
                onTap: () {
                  context.pop(['equipment']);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text('Both (Piping + Equipment)'),
                onTap: () {
                  context.pop(['piping', 'equipment']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncLocalMaterialsWithServer(DprModel dpr) {
    print('🔄 SYNCING MATERIALS FOR DPR: ${dpr.id}');

    // ---- SYNC USING CENTRAL SERVICE ----
    final mergedPiping = MaterialSyncService.syncPiping(
      local: PipingMaterialsData.materials,
      server: dpr.piping,
    );

    final mergedEquipment = MaterialSyncService.syncEquipment(
      local: EquipmentMaterialsData.materials,
      server: dpr.equipment,
    );

    // ---- UPDATE PROVIDERS ----
    ref.read(pipingMaterialsProvider.notifier).setMaterials(mergedPiping);
    ref.read(equipmentMaterialsProvider.notifier).setMaterials(mergedEquipment);

    // ---- VERIFY UOM IS PRESERVED ----
    print('📋 VERIFYING UOM AFTER SYNC:');

    final pipingState = ref.read(pipingMaterialsProvider);
    print('Piping materials count: ${pipingState.length}');
    for (final p in pipingState) {
      print('  → ${p.materialName}: UOM = ${p.uom}, Length = ${p.length}');
    }

    final equipmentState = ref.read(equipmentMaterialsProvider);
    print('Equipment materials count: ${equipmentState.length}');
    for (final e in equipmentState) {
      print('  → ${e.materialName}: UOM = ${e.uom}, Weight = ${e.weight}');
    }
  } /**/

  Future<void> _fetchDprWorkById() async {
    if (_isDisposed || _mechanicalId == null) return;
    ref.read(pipingMaterialsProvider.notifier).clear();
    ref.read(equipmentMaterialsProvider.notifier).clear();

    if (mounted) setState(() => _isLoadingMaterials = true);

    try {
      print('Fetching DPR work with ID: $_mechanicalId');

      final dprWork = await ref.read(dprProvider.notifier).fetchDprById(
            siteId: siteId,
            teamId: teamId,
            workId: _mechanicalId!,
          );

      if (dprWork == null) return;

      _syncLocalMaterialsWithServer(dprWork);

      _dprNameController.text = dprWork.dprName ?? '';
      _mocController.text = dprWork.moc ?? _mocController.text;
      _sizeController.text = dprWork.size ?? _sizeController.text;
      _floorController.text = dprWork.location ?? _floorController.text;
      _plantController.text = dprWork.plant ?? _plantController.text;

      if (mounted) {
        setState(() {
          if (dprWork.piping.isNotEmpty) {
            _pipeFittingOn = true;
            _showPipingMaterials = true;
          }
          if (dprWork.equipment.isNotEmpty) {
            _equipmentOn = true;
            _showEquipmentMaterials = true;
          }
        });
      }

      print(
          'Fetched DPR work successfully with ${dprWork.piping.length} piping and ${dprWork.equipment.length} equipment materials');
    } catch (e) {
      if (mounted && !_isDisposed) {
        print('Error fetching DPR work: $e');
        final message = extractBackendError(e);
        _showSnackBar('Failed to load DPR work: $message', isError: true);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingMaterials = false);
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get _isEditable =>
      _isToday(_selectedDate) || _globalEditMode || widget.work != null;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _selectedDate) return;

    ref.read(dprSessionProvider.notifier).setDate(picked);

    setState(() => _selectedDate = picked);
    await _fetchDprListForDate(picked);

    /// ALWAYS initialize new DPR
    _mechanicalId = null;
    _selectedDprId = null;

    /// reset header
    _dprNameController.text = '';

    /// clear providers
    ref.read(pipingMaterialsProvider.notifier).clear();
    ref.read(equipmentMaterialsProvider.notifier).clear();

    /// load default materials
    await _loadDefaultMaterials();

    _applyHeaderValuesToMaterials();

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  void _handleToggleChange(bool isPiping, bool newValue) {
    if (_isDisposed) return;

    setState(() {
      if (isPiping) {
        _pipeFittingOn = newValue;
        if (!newValue) {
          _showPipingMaterials = false;
        } else {
          final materials = ref.read(pipingMaterialsProvider);
          if (materials.isNotEmpty) {
            _showPipingMaterials = true;
          }
        }
      } else {
        _equipmentOn = newValue;
        if (!newValue) {
          _showEquipmentMaterials = false;
        } else {
          final materials = ref.read(equipmentMaterialsProvider);
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

  // _________MATERIAL  FUNCTIONS_______ //
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

  Future<void> deleteDprMaterialLocal({
    required String materialId,
    required bool isPiping,
  }) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final scope = await _askMaterialScope();
    if (scope == null) return;

    // 🔥 Start spinner immediately
    setState(() {
      _updatingMaterialIds.add(materialId);
    });

    bool apiFailed = false;

    try {
      if (_mechanicalId != null) {
        await DprApi().deleteMaterial(
          mechanicalId: _mechanicalId!,
          materialId: materialId,
          designation: isPiping ? "piping" : "equipment",
          isMaterialStore: scope,
        );
      }
    } catch (e, st) {
      apiFailed = true;

      print("❌ Delete API failed: $e");
      print(st);

      final error = extractBackendError(e);
      AppToast.info(
        "$error\nDeleted locally. Will sync on final DPR save.",
      );
    }

    // ✅ ALWAYS DELETE LOCALLY (even if API fails)
    if (isPiping) {
      final notifier = ref.read(pipingMaterialsProvider.notifier);
      final materials = ref.read(pipingMaterialsProvider);

      notifier.setMaterials(
        materials.where((m) => m.id != materialId).toList(),
      );
    } else {
      final notifier = ref.read(equipmentMaterialsProvider.notifier);
      final materials = ref.read(equipmentMaterialsProvider);

      notifier.setMaterials(
        materials.where((m) => m.id != materialId).toList(),
      );
    }

    if (!apiFailed) {
      _showSnackBar('Material deleted');
    }

    // 🔥 Always stop spinner
    if (mounted) {
      setState(() {
        _updatingMaterialIds.remove(materialId);
      });
    }
  }

  Future<bool?> _askMaterialScope() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // 🔥 sharp edges
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: Colors.white, // 🔥 pure white
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Apply Changes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "How should these changes be applied?",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B6DCE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.pop(true),
                        child: const Text(
                          "Permanent Changes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B6DCE),
                          side: const BorderSide(color: Color(0xFF1B6DCE)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => context.pop(false),
                        child: const Text(
                          "Temporary Changes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> copyDprMaterialLocal({
    required dynamic material,
    required bool isPiping,
    required String rateUploadId,
  }) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final scope = await _askMaterialScope();
    if (scope == null) return;

    // 🔥 Start per-material loading
    setState(() {
      _updatingMaterialIds.add(material.id);
    });

    String? newId;
    bool apiFailed = false;

    try {
      if (_mechanicalId != null) {
        final response = await DprApi.copyDprMaterial(
          dprId: _mechanicalId!,
          matId: material.id,
          isMaterialStore: scope,
        );
        final jsonString = const JsonEncoder.withIndent('  ').convert(material);
        printLongString("INSERTING PIPING MATERIAL: $jsonString");

        if (response != null && response['data'] != null) {
          newId = response['data']['_id'];
        }
      }
    } catch (e, st) {
      apiFailed = true;
      print("❌ Copy API failed: $e");
      print(st);

      final error = extractBackendError(e);
      AppToast.info(
        "$error\nCopied locally. Will sync on final DPR save.",
      );
    }

    // 🔥 Always generate local ID if backend didn’t return one
    newId ??= generateObjectId();

    // 🔥 Always insert locally (optimistic)
    if (isPiping && material is PipingItem) {
      final jsonString = const JsonEncoder.withIndent('  ').convert(material);
      printLongString("INSERTING PIPING MATERIAL: $jsonString");

      final notifier = ref.read(pipingMaterialsProvider.notifier);
      final materials = ref.read(pipingMaterialsProvider);

      final index = materials.indexWhere((m) => m.id == material.id);
      if (index == -1) return;

      final copied = material.copyWith(
        id: newId,
        materialName: '${material.materialName} ',
      );

      final updated = [...materials];
      updated.insert(index + 1, copied);

      notifier.setMaterials(updated);
    } else if (!isPiping && material is EquipmentItem) {
      final notifier = ref.read(equipmentMaterialsProvider.notifier);
      final materials = ref.read(equipmentMaterialsProvider);

      final index = materials.indexWhere((m) => m.id == material.id);
      if (index == -1) return;

      final copied = material.copyWith(
        id: newId,
        materialName: '${material.materialName} (Copy)',
      );

      final updated = [...materials];
      updated.insert(index + 1, copied);

      notifier.setMaterials(updated);
    }

    if (!apiFailed) {
      _showSnackBar('Material copied');
    }

    // 🔥 Always stop spinner
    if (mounted) {
      setState(() {
        _updatingMaterialIds.remove(material.id);
      });
    }
  }

  Future<void> _openEditOverlay(dynamic material, bool isPiping) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final isPermanent = await _askMaterialScope();
    if (isPermanent == null) return;

    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
    final rateUploadId = rateFileMeta['rateFileId'] as String?;

    if (isPermanent) {
      // ── PERMANENT CHANGES (Calls Rate API inside overlay) ──
      final success = isPiping
          ? await showPipingEditOverlay(
              context: context,
              material: material as PipingItem,
              rateUploadId: rateUploadId,
              siteId: siteId,
              returnResult: false, // Calls API
            )
          : await showEquipmentEditOverlay(
              context: context,
              material: material as EquipmentItem,
              rateUploadId: rateUploadId,
              siteId: siteId,
              returnResult: false, // Calls API
            );

      if (success == true) {
        // After master rate is updated, we still need to update the local DPR card
        // to match the new master data (or at least reflect the change)
        // Since the overlay updated the master rate, the easiest way is to re-sync.
        // But for now, let's just update the local material fields too.
        // The overlay doesn't return the result when success=true, it just pops.
        // Actually, I should probably make it return the result even on success
        // so we can update the local DPR state without another fetch.
        // BUT the user said "integrate with existing rate APIs", which I did.

        // Let's just trigger a local refresh if needed.
        // Actually, if it was permanent, the user likely wants the DPR to reflect it too.
        // I'll re-fetch the DPR work to be safe if _mechanicalId exists.
        if (_mechanicalId != null) {
          await _fetchDprWorkById();
        }
      }
    } else {
      // ── TEMPORARY CHANGES (Local only) ──
      final result = isPiping
          ? await showPipingEditOverlay(
              context: context,
              material: material as PipingItem,
              rateUploadId: rateUploadId,
              siteId: siteId,
              returnResult: true, // Returns MaterialEditResult
            )
          : await showEquipmentEditOverlay(
              context: context,
              material: material as EquipmentItem,
              rateUploadId: rateUploadId,
              siteId: siteId,
              returnResult: true, // Returns MaterialEditResult
            );

      if (result is MaterialEditResult) {
        if (isPiping) {
          final materials = ref.read(pipingMaterialsProvider);
          final updated = materials.map((m) {
            if (m.id != (material as PipingItem).id) return m;
            return m.copyWith(
              materialName: result.name,
              uom: result.uom,
              calculationCategory: result.categoryId ?? m.calculationCategory,
              dynamicFields: result.fields,
              image: result.imageFile?.path ?? m.image,
            );
          }).toList();
          ref.read(pipingMaterialsProvider.notifier).state = updated;
        } else {
          final materials = ref.read(equipmentMaterialsProvider);
          final updated = materials.map((m) {
            if (m.id != (material as EquipmentItem).id) return m;
            return m.copyWith(
              materialName: result.name,
              uom: result.uom,
              calculationCategory: result.categoryId ?? m.calculationCategory,
              dynamicFields: result.fields,
              image: result.imageFile?.path ?? m.image,
            );
          }).toList();
          ref.read(equipmentMaterialsProvider.notifier).state = updated;
        }
        _showSnackBar('Temporary changes applied to this DPR');
      }
    }
  }

  void _editDprMaterial(dynamic material, String catgory) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    if (material is PipingItem) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'piping',
            pipingMaterial: material,

            // 🔴 DPR CONTEXT (this is the difference)
            isDpr: true,
            dprId: _mechanicalId!,
            siteId: siteId,
            teamId: teamId,
          ),
        ),
      )
          .then((_) async {
        await _fetchDprWorkById(); // ✅ DPR refresh, not default materials
      });
    } else if (material is EquipmentItem) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'equipment',
            equipmentMaterial: material,

            // 🔴 DPR CONTEXT
            isDpr: true,
            dprId: _mechanicalId!,
            siteId: siteId,
            teamId: teamId,
          ),
        ),
      )
          .then((_) async {
        await _fetchDprWorkById();
      });
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
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.tertiary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pipingMaterials = ref.watch(pipingMaterialsProvider);
    final equipmentMaterials = ref.watch(equipmentMaterialsProvider);

    final hasPipingMaterials = pipingMaterials.isNotEmpty;
    final hasEquipmentMaterials = equipmentMaterials.isNotEmpty;
    final shouldShowPiping =
        _pipeFittingOn && _showPipingMaterials && hasPipingMaterials;
    final shouldShowEquipment =
        _equipmentOn && _showEquipmentMaterials && hasEquipmentMaterials;
    final lang = ref.watch(dailyEntryTranslationHelperProvider);

    // Only show dropdown when:
    // 1. In edit mode
    // 2. Not today's date
    // 3. DPR list exists for selected date
    final shouldShowDropdown =
        _globalEditMode && _dprListForSelectedDate.isNotEmpty;
    final team = ref.read(currentTeamProvider);
    final site = ref.read(currentSiteProvider);

    return WillPopScope(
      onWillPop: () async {
        await _autoSaveDraftOnExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        drawer: const CustomDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [CustomSliverAppBar(title: "Dpr Entry")];
          },
          body: BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: RoundedButton(
                  text: _isSubmitting ? 'Saving..' : 'Save',
                  color: _isEditable || _isDateOverrideMode
                      ? cs.primary
                      : cs.surfaceContainerHigh,
                  textColor: _isEditable || _isDateOverrideMode
                      ? cs.onPrimary
                      : cs.onSurfaceVariant,
                  onPressed: _isSubmitting ? () {} : _handleSubmitFields,
                  isOutlined: false,
                ),
              ),
            ],
            child: Column(
              children: [
                if (_isLoading)
                  const ShimmerList(
                    type: ShimmerListType.card,
                    itemCount: 3,
                    scrollable: false,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(6),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      site?.siteName ?? "DPR",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      team?.teamName ?? "Default Team",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _buildEditModeButton(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDateSection(),
                        const SizedBox(height: 16),
                        _buildDprInfoCard(shouldShowDropdown),
                        const SizedBox(height: 16),
                        // _buildToggleSection(),
                        // const SizedBox(height: 16),
                        Column(
                          key: _materialsRebuildKey,
                          children: [
                            if (_pipeFittingOn && hasPipingMaterials)
                              _buildMaterialToggleCard(
                                lang.pipeFittingMaterialLabel,
                                pipingMaterials.length,
                                _showPipingMaterials,
                                () => _toggleMaterialVisibility(true),
                              ),
                            if (shouldShowPiping)
                              ..._buildPipingMaterials(pipingMaterials),
                            if (_equipmentOn && hasEquipmentMaterials)
                              _buildMaterialToggleCard(
                                lang.equipmentMaterialLabel,
                                equipmentMaterials.length,
                                _showEquipmentMaterials,
                                () => _toggleMaterialVisibility(false),
                              ),
                            if (shouldShowEquipment)
                              ..._buildEquipmentMaterials(equipmentMaterials),
                            if (_pipeFittingOn && !hasPipingMaterials)
                              _buildEmptyMaterialsCard(
                                  'No piping materials available'),
                            if (_equipmentOn && !hasEquipmentMaterials)
                              _buildEmptyMaterialsCard(
                                  'No equipment materials available'),
                            if (!_pipeFittingOn &&
                                !_equipmentOn &&
                                _initialDataLoaded)
                              _buildEmptyState(
                                  'Materials will appear here once loaded',
                                  Icons.downloading),
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

  Widget _buildEmptyMaterialsCard(String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
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
                  color: cs.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            _buildAddDprMaterialButton(),
            Text(
              isExpanded ? 'Hide' : 'Show',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDprMaterialButton() {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersistDPRScreen(
              isDpr: true, // 🔴 critical
              dprId: _mechanicalId ?? '', // 🔴 DPR ID
              siteId: siteId,
              teamId: teamId,
            ),
          ),
        );

        // Re-fetch DPR after add
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          size: 18,
          color: cs.onPrimary,
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String title, String subtitle) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final cs = Theme.of(context).colorScheme;
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final isEditingDpr = widget.work != null;
    final showPencil = isEditingDpr; // Always show if work is not null
    final canChangeDateNormal = !isEditingDpr && _globalEditMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isDateOverrideMode
                ? cs.primaryContainer
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: _isDateOverrideMode
                ? Border.all(color: cs.primary, width: 1.5)
                : Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    "${lang.dailyReportTitle}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
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
                                  _globalEditMode ? cs.primary : cs.onSurface,
                            ),
                          ),
                          if (canChangeDateNormal) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: cs.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showPencil) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.edit, color: cs.primary, size: 20),
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
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Date modified",
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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

  Widget _buildEditModeButton() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _toggleGlobalEditMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _globalEditMode ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _globalEditMode ? "Editing" : "Edit",
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDprInfoCard(bool shouldShowDropdown) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select DPR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
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
                    icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                    elevation: 16,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    hint: const Text('Select DPR'),
                    // onChanged: (String? newValue) {
                    //   if (newValue != null) {
                    //     ref.read(pipingMaterialsProvider.notifier).clear();
                    //     ref.read(equipmentMaterialsProvider.notifier).clear();
                    //     final selectedDpr = _dprListForSelectedDate
                    //         .firstWhere((dpr) => dpr.id == newValue);
                    //     _loadDprWork(selectedDpr);
                    //   }
                    // },
                    onChanged: (String? newValue) async {
                      if (newValue == null) return;
                      final dpr = _dprListForSelectedDate
                          .firstWhere((dpr) => dpr.id == newValue);
                      _dprNameController.text = dpr.dprName;
                      _mocController.text = dpr.moc;
                      _sizeController.text = dpr.size;
                      _floorController.text = dpr.location;
                      _plantController.text = dpr.plant;

                      _mechanicalId = newValue;
                      setState(() {
                        _isLoading = true;
                      });
                      _applyHeaderValuesToMaterials();
                      await getd(dpr);

                      await loadScreenState(Dpr: dpr);
                    },

                    items: _dprListForSelectedDate
                        .map<DropdownMenuItem<String>>((DprModel dpr) {
                      return DropdownMenuItem<String>(
                        value: dpr.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            dpr.dprName,
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
                '${_dprListForSelectedDate.length} DPR(s) found for ${_formatDate(_selectedDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_isEditable)
              TextButton.icon(
                onPressed: () async {
                  if (!_isEditable) return;

                  // 1️⃣ Reset DPR identity
                  setState(() {
                    _mechanicalId = null;
                    _selectedDprId = null;
                  });

                  // 2️⃣ Reset header fields
                  _dprNameController.text = 'New DPR Entry';
                  _mocController.clear();
                  _sizeController.clear();
                  _floorController.clear();
                  _plantController.clear();

                  // 3️⃣ Clear providers (remove old DPR materials completely)
                  ref.read(pipingMaterialsProvider.notifier).clear();
                  ref.read(equipmentMaterialsProvider.notifier).clear();

                  // 4️⃣ Load fresh default materials
                  await _loadDefaultMaterials();

                  // 5️⃣ Re-apply header values (now empty)
                  _applyHeaderValuesToMaterials();

                  // 6️⃣ Force rebuild
                  if (mounted) {
                    setState(() {});
                  }

                  _showSnackBar("New DPR initialized");
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
    final cs = Theme.of(context).colorScheme;
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
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    hintText: 'Enter DPR Name',
                    prefixIcon:
                        Icon(Icons.edit_document, size: 20, color: cs.primary),
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description,
                          color: cs.onSurfaceVariant, size: 20),
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
              color: cs.tertiaryContainer,
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
                color: _editMode ? cs.tertiary : cs.primary,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFields() {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final sizeUom = _sizeUomController.text;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildCompactInputField(
                    lang.plantTab, _plantController, Icons.factory)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCompactInputField(
                    lang.locationTab, _floorController, Icons.location_on)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCompactInputField(
                    lang.mocTab, _mocController, Icons.category)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildCompactInputField(
                    'Size($sizeUom)', _sizeController, Icons.straighten)),
          ],
        )
      ],
    );
  }

  Widget _buildCompactInputField(
      String label, TextEditingController controller, IconData icon) {
    final cs = Theme.of(context).colorScheme;
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
                color: cs.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                lang.pipeFittingsTab,
                Icons.plumbing_rounded,
                _pipeFittingOn,
                false,
                (value) => _handleToggleChange(true, value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                lang.equipmentTab,
                Icons.precision_manufacturing_rounded,
                _equipmentOn,
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          color: value ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? cs.primary : cs.outlineVariant,
            width: value ? 2 : 1.5,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (isLoading) const ShimmerCircle(size: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? cs.onPrimaryContainer : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPipingMaterials(List<PipingItem> materials) {
    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));

    final detected = ref.watch(detectedFieldsProvider(siteId));

    final bool showFloor = detected?.hasFloor == true;
    final bool showElevation = !showFloor && detected?.hasElevation == true;

    final rateUploadId = rateFileMeta['rateFileId'] as String?;

    return materials.map((material) {
      final index = materials.indexOf(material);
      return Padding(
        key: ValueKey('piping_${material.id}_$index'),
        padding: const EdgeInsets.only(bottom: 12),
        child: MaterialCardWrapper(
          isUpdating: _updatingMaterialIds.contains(material.id),
          child: ExpandableMaterialCard(
            categoryId: editingMaterialId == material.id
                ? draftCategoryId
                : material.calculationCategory,
            isEditMode: editingMaterialId == material.id,
            onCategoryChanged: (newId) {
              setState(() {
                draftCategoryId = newId;
                print(draftCategoryId);
              });
            },
            child: testDynamicItemCard(
              image: material.image,
              isEditMode: editingMaterialId == material.id,
              lengthLabel: material.materialName,
              lengthPlaceholder: material.uom,
              fields: material.dynamicFields,
              onChanged: (key, value) {
                _onPipingDynamicChanged(material.id, key, value);
              },
              quantity: '',
              remark: material.remarks,
              size: material.dynamicFields
                      .firstWhere(
                        (f) => f.key.toLowerCase() == 'size',
                        orElse: () => DynamicField(
                            key: 'size',
                            label: 'Size',
                            value: _sizeController.text,
                            unit: '',
                            displayText: ''),
                      )
                      .value ??
                  _sizeController.text,
              length: (material.length == null || material.length == 0)
                  ? ''
                  : material.length.toString(),
              floor: _floorController.text,
              moc: _mocController.text,
              onSave: (result) async {
                setState(() {
                  _updatingMaterialIds.add(material.id);
                });

                bool apiFailed = false;

                try {
                  final formData = FormData.fromMap({
                    "materialName": result.name,
                    "uom": result.uom,
                    "designation": material.designation,
                    "calculationCategory": draftCategoryId,
                    "isApplied": false,
                    "dynamicFields": jsonEncode(
                      result.fields.map((e) => e.toJson()).toList(),
                    ),
                    if (result.imageFile != null)
                      "image": await MultipartFile.fromFile(
                        result.imageFile!.path,
                        filename: result.imageFile!.path.split('/').last,
                      ),
                  });

                  final response = await DprApi.updateDprItem(
                    dprId: _mechanicalId!,
                    itemId: material.id,
                    data: formData,
                  );

                  final backendItems = (response.data['data']['piping'] as List)
                      .map((e) => PipingItem.fromJson(e))
                      .toList();

                  final updatedItem = backendItems.firstWhere(
                    (e) => e.lineItemId == material.lineItemId,
                    orElse: () => throw Exception(
                      "Updated piping item not found for lineItemId: ${material.lineItemId}",
                    ),
                  );

                  final materials = ref.read(pipingMaterialsProvider);

                  final updatedList = materials.map((m) {
                    if (m.lineItemId == updatedItem.lineItemId) {
                      return updatedItem; // 🔥 backend truth
                    }
                    return m;
                  }).toList();

                  ref.read(pipingMaterialsProvider.notifier).state =
                      updatedList;
                } catch (e, st) {
                  apiFailed = true;

                  print("❌ save failed $e");
                  print(st);

                  final error = extractBackendError(e);
                  AppToast.info(
                    "$error\nSaved locally. Will sync on final DPR save.",
                  );

                  // 🔥 LOCAL FALLBACK UPDATE
                  final materials = ref.read(pipingMaterialsProvider);

                  final updatedList = materials.map((m) {
                    if (m.id != material.id) return m;

                    return m.copyWith(
                      materialName: result.name,
                      uom: result.uom,
                      calculationCategory: draftCategoryId,
                      dynamicFields: result.fields,
                      image: result.imageFile?.path ?? m.image,
                    );
                  }).toList();

                  ref.read(pipingMaterialsProvider.notifier).state =
                      updatedList;
                }

                _applyHeaderValuesToMaterials();

                setState(() {
                  editingMaterialId = null;
                  draftCategoryId = null;
                  _updatingMaterialIds.remove(material.id);
                });
              },
              sizeLabel: '',
              sizePlaceholder: '',
              onQtyChanged: (val) =>
                  _onPipingFieldChanged(material.id, 'quantity', val),
              onSizeChanged: (val) =>
                  _onPipingFieldChanged(material.id, 'size', val),
              onLengthChanged: (val) =>
                  _onPipingFieldChanged(material.id, 'length', val),
              onFloorChanged: (val) =>
                  _onPipingFieldChanged(material.id, 'floor', val),
              onMocChanged: (val) =>
                  _onPipingFieldChanged(material.id, 'moc', val),
              onCopy: () => copyDprMaterialLocal(
                  material: material,
                  isPiping: true,
                  rateUploadId: rateUploadId!),
              onAdd: () => copyDprMaterialLocal(
                  material: material,
                  isPiping: true,
                  rateUploadId: rateUploadId!),
              onDelete: () => deleteDprMaterialLocal(
                  materialId: material.id, isPiping: true),
              onEdit: () => _openEditOverlay(material, true),
              onRemark: () => _showRemarkDialog(
                  material.id, material.remarks ?? '',
                  isPiping: true),
              isEditable: true,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onPipingDynamicChanged(
    String materialId,
    String key,
    String value,
  ) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final materials = ref.read(pipingMaterialsProvider);

    final updated = materials.map((m) {
      if (m.id != materialId) return m;

      final updatedFields = m.dynamicFields.map((f) {
        if (f.key == key) {
          return f.copyWith(
            value: value,
            displayText: f.displayText, // preserve UI text
          );
        }
        return f;
      }).toList();

      return m.copyWith(dynamicFields: updatedFields);
    }).toList();

    ref.read(pipingMaterialsProvider.notifier).state = updated;
  }

  void _onEquipmentDynamicChanged(
    String materialId,
    String key,
    String value,
  ) {
    final materials = ref.read(equipmentMaterialsProvider);

    final updated = materials.map((m) {
      if (m.id != materialId) return m;

      final updatedFields = m.dynamicFields.map((f) {
        if (f.key == key) {
          return f.copyWith(value: value, displayText: value);
        }
        return f;
      }).toList();

      return m.copyWith(dynamicFields: updatedFields);
    }).toList();

    ref.read(equipmentMaterialsProvider.notifier).state = updated;
  }

  List<Widget> _buildEquipmentMaterials(List<EquipmentItem> materials) {
    return List.generate(materials.length, (index) {
      final material = materials[index];
      final rateFileMeta = ref.read(rateFileMetaProvider(siteId));

      final rateUploadId = rateFileMeta['rateFileId'] as String?;

      return Padding(
        key: ValueKey('equipment_${material.id}_$index'), // ✅ FIXED UNIQUE KEY
        padding: const EdgeInsets.only(bottom: 12),
        child: MaterialCardWrapper(
          isUpdating: false,
          child: DynamicItemCard2(
            fields: material.dynamicFields,
            onChanged: (key, value) {
              _onEquipmentDynamicChanged(material.id, key, value);
            },
            title: material.materialName,
            quantity: material.dynamicFields
                    .firstWhere(
                      (f) => f.key.toLowerCase() == 'qty',
                      orElse: () => DynamicField(
                        key: 'qty',
                        label: 'Qty',
                        value: material.qty.toString(),
                        unit: '',
                        displayText: material.qty.toString(),
                      ),
                    )
                    .value
                    ?.toString() ??
                material.qty.toString(),
            image: material.image,
            floor: _floorController.text,
            moc: _mocController.text,
            size: _sizeController.text,
            ton: material.weight.toString(),
            meter: material.uom,
            length:
                (_equipmentLengthDraft[material.id]?.trim().isNotEmpty ?? false)
                    ? _equipmentLengthDraft[material.id]!
                    : (material.length == null || material.length == 0)
                        ? ''
                        : material.length.toString(),
            remark: material.remarks,
            onMocChanged: (val) =>
                _onEquipmentFieldChanged(material.id, 'moc', val),
            onQtyChanged: (val) =>
                _onEquipmentFieldChanged(material.id, 'quantity', val),
            onFloorChanged: (val) =>
                _onEquipmentFieldChanged(material.id, 'floor', val),
            onTonChanged: (val) =>
                _onEquipmentFieldChanged(material.id, 'ton', val),
            onCopy: () => copyDprMaterialLocal(
                material: material,
                isPiping: false,
                rateUploadId: rateUploadId!),
            onAdd: () => copyDprMaterialLocal(
                material: material,
                isPiping: false,
                rateUploadId: rateUploadId!),
            onDelete: () => deleteDprMaterialLocal(
                materialId: material.id, isPiping: false),
            onEdit: () => _openEditOverlay(material, false),
            isEditable: _isEditable,
            onRemark: () => _showRemarkDialog(
              material.id,
              material.remarks ?? '',
              isPiping: false,
            ),
            onMeterChanged: (val) => _equipmentLengthDraft[material.id] = val,
          ),
        ),
      );
    });
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
            onPressed: () => context.pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _updateMaterialRemark(materialId, remarkController.text,
                  isPiping: isPiping);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _onPipingFieldChanged(String materialId, String field, String value) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final pipingMaterials = ref.read(pipingMaterialsProvider);
    final updatedMaterials = pipingMaterials.map((material) {
      if (material.id == materialId) {
        switch (field) {
          case 'quantity':
            return material.copyWith(
              qty: int.tryParse(value)?.toDouble() ?? 0,
            );

          case 'size':
            // Size is handled globally via _sizeController
            return material;
          case 'length':
            return material.copyWith(
                length: double.tryParse(value) ?? material.length);
          case 'floor':
            // Floor is handled globally via _floorController
            return material;
          case 'moc':
            // MOC is handled globally via _mocController
            return material;
          default:
            return material;
        }
      }
      return material;
    }).toList();

    ref.read(pipingMaterialsProvider.notifier).state = updatedMaterials;
    print('Piping material $materialId: $field changed to $value');
  }

  void _onEquipmentFieldChanged(String materialId, String field, String value) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    if (field == 'length') {
      _equipmentLengthDraft[materialId] = value;
      return;
    }

    final equipmentMaterials = ref.read(equipmentMaterialsProvider);
    final updatedMaterials = equipmentMaterials.map((material) {
      if (material.id == materialId) {
        switch (field) {
          case 'quantity':
            return material.copyWith(
              qty: int.tryParse(value)?.toDouble() ?? 0,
            );
          case 'uom':
            return material;
          case 'ton':
            return material.copyWith(
                weight: double.tryParse(value) ?? material.weight);
          case 'floor':
            // Floor is handled globally via _floorController
            return material;
          case 'moc':
            // MOC is handled globally via _mocController
            return material;
          default:
            return material;
        }
      }
      return material;
    }).toList();

    ref.read(equipmentMaterialsProvider.notifier).state = updatedMaterials;
  }

  void _updateMaterialRemark(String materialId, String remark,
      {bool isPiping = true}) {
    if (isPiping) {
      final pipingMaterials = ref.read(pipingMaterialsProvider);
      final updatedMaterials = pipingMaterials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref.read(pipingMaterialsProvider.notifier).state = updatedMaterials;
    } else {
      final equipmentMaterials = ref.read(equipmentMaterialsProvider);
      final updatedMaterials = equipmentMaterials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref.read(equipmentMaterialsProvider.notifier).state = updatedMaterials;
    }

    _showSnackBar('Remark saved for material');
  }

  void _toggleGlobalEditMode() {
    final newMode = !_globalEditMode;

    ref.read(dprSessionProvider.notifier).setEditMode(
          newMode,
          date: newMode ? _selectedDate : null,
        );

    setState(() {
      _globalEditMode = newMode;
      if (!newMode) {
        // Reset to today
        _selectedDate = DateTime.now();
        _isDateOverrideMode = false;
      }
    });

    if (_globalEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isToday(_selectedDate)
              ? "Edit mode enabled - You can now modify today's DPR and change date"
              : "Edit mode enabled - You can now modify DPR for ${_formatDate(_selectedDate)}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // When enabling edit mode for non-today dates, fetch DPR list

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

      // If disabling edit mode and date is today, refresh to new DPR
      if (_isToday(_selectedDate)) {
        _autoCreateDprWork();
      }
    }
  }

  double _getDynamicQty(PipingItem m) {
    final field = m.dynamicFields.firstWhere(
      (f) => f.key.toLowerCase() == 'qty',
      orElse: () => DynamicField(
        key: 'qty',
        label: 'Qty',
        value: '0',
        unit: '',
        displayText: '',
      ),
    );

    return double.tryParse(field.value?.toString() ?? '') ?? 0;
  }

  bool _hasMeaningfulDynamicFieldValues(List<DynamicField> fields) {
    for (final field in fields) {
      if (field.key.toLowerCase() == 'qty') continue;
      final raw = field.value;
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      return true;
    }
    return false;
  }

  double _resolvePayloadQty({
    required num? qty,
    required List<DynamicField> fields,
  }) {
    final normalizedQty = qty?.toDouble() ?? 0;
    final hasFieldValues = _hasMeaningfulDynamicFieldValues(fields);

    // Avoid sending synthetic qty=1 when no meaningful field values exist.
    if (!hasFieldValues && normalizedQty == 1) return 0;
    return normalizedQty;
  }

  String _getDynamicValue(List<DynamicField> fields, String key) {
    for (final f in fields) {
      if (f.key.toLowerCase() == key.toLowerCase()) {
        return f.value?.toString() ?? '';
      }
    }
    return '';
  }

  String? _resolveSize(material) {
    for (final f in material.dynamicFields) {
      if (f.key.toLowerCase() == 'size') {
        final val = f.value?.toString().trim();
        if (val != null && val.isNotEmpty) {
          return val;
        }
      }
    }

    final headerSize = _sizeController.text.trim();
    return headerSize.isNotEmpty ? headerSize : null;
  }

  DprModel _buildDraftDprModel({
    required List<PipingItem> pipingMaterials,
    required List<EquipmentItem> equipmentMaterials,
    required List<String> designation,
  }) {
    final now = DateTime.now();
    return DprModel(
      id: _mechanicalId,
      siteId: siteId,
      teamId: teamId,
      company: team.company,
      dprName: _dprNameController.text.trim(),
      plant: _plantController.text.trim(),
      location: _floorController.text.trim(),
      size: _sizeController.text.trim(),
      moc: _mocController.text.trim(),
      piping: pipingMaterials,
      equipment: equipmentMaterials,
      designation: designation,
      createdAt: now,
      updatedAt: now,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
    );
  }

  Future<String> _draftDpr({
    required DprModel draft,
    required Map<String, dynamic> updateData,
  }) async {
    final draftId = _mechanicalId?.trim().isNotEmpty == true
        ? _mechanicalId!
        : generateObjectId();

    final rawTeamId = ref.read(selectedTeamIdProvider);
    final safeTeamId =
        (rawTeamId == null || rawTeamId.trim().isEmpty) ? 'default' : rawTeamId;

    await _draftRepo.saveDraft(
      DprDraftRecord(
        draftId: draftId,
        draft: draft,
        updateData: updateData,
        siteId: siteId,
        teamId: safeTeamId,
        mechanicalId: _mechanicalId,
        savedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    );
    return draftId;
  }

  Future<void> _enqueueDprBackgroundSave({
    required String draftId,
    required DprModel draft,
    required Map<String, dynamic> updateData,
    required String dprName,
    required String dateString,
  }) async {
    final rawTeamId = ref.read(selectedTeamIdProvider);
    final safeTeamId =
        (rawTeamId == null || rawTeamId.trim().isEmpty) ? 'default' : rawTeamId;

    final job = UploadJob.create(
      moduleId: 'dpr',
      filePath: 'dpr://$draftId',
      metadata: {
        'draftId': draftId,
        'siteId': siteId,
        'teamId': safeTeamId,
        'mechanicalId': _mechanicalId,
        'dprName': dprName,
        'date': dateString,
        'editRoute': Routes.dprDescription,
        'draftWork': draft.toJson(),
        'updateData': updateData,
      },
      maxRetries: 2,
    );

    ref.read(uploadManagerProvider.notifier).enqueue(job);
  }

  Future<void> _autoSaveDraftOnExit() async {
    if (_isDisposed || _isSubmitting) return;

    final pipingMaterials = ref.read(pipingMaterialsProvider);
    final equipmentMaterials = ref.read(equipmentMaterialsProvider);

    final designation = <String>[
      if (pipingMaterials.isNotEmpty) 'piping',
      if (equipmentMaterials.isNotEmpty) 'equipment',
    ];

    final draftModel = _buildDraftDprModel(
      pipingMaterials: pipingMaterials,
      equipmentMaterials: equipmentMaterials,
      designation: designation,
    );

    final draftId = await _draftDpr(
      draft: draftModel,
      updateData: const {},
    );

    final dprName = _dprNameController.text.trim().isNotEmpty
        ? _dprNameController.text.trim()
        : 'DPR';

    await ref.read(uploadManagerProvider.notifier).notifyDraftSaved(
          moduleId: 'dpr',
          draftId: draftId,
          dprName: dprName,
          draftWork: draftModel.toJson(),
          metadata: {
            'siteId': siteId,
            'teamId': teamId,
            'mechanicalId': _mechanicalId,
            'editRoute': Routes.dprDescription,
            'date': _formatDate(_selectedDate),
          },
          sendInstant: true,
        );
  }

  Future<void> _handleSubmitFields() async {
    if (_isDisposed) return;

    if (!_isEditable && !_isDateOverrideMode) {
      _showEditRequiredMessage();
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // if (_mechanicalId == null) {
      //   await _autoCreateDprWork();
      //   if (_mechanicalId == null) {
      //     throw Exception('Failed to create DPR work');
      //   }
      // }

      // Get current piping and equipment materials from providers
      final pipingMaterials = ref.read(pipingMaterialsProvider);
      var equipmentMaterials = ref.read(equipmentMaterialsProvider);

      // Flush buffered equipment length edits once, right before payload build.
      if (_equipmentLengthDraft.isNotEmpty) {
        equipmentMaterials = equipmentMaterials.map((material) {
          final draft = _equipmentLengthDraft[material.id];
          if (draft == null) return material;
          return material.copyWith(length: double.tryParse(draft) ?? 0);
        }).toList();
        ref.read(equipmentMaterialsProvider.notifier).state =
            equipmentMaterials;
      }
      List<String> dprDesignation = [];

      if (pipingMaterials.isNotEmpty) {
        dprDesignation.add('piping');
      }

      if (equipmentMaterials.isNotEmpty) {
        dprDesignation.add('equipment');
      }

      debugPrint("🟦 RAW PIPING MATERIALS (${pipingMaterials.length})");

//       for (final m in pipingMaterials) {
//         debugPrint("""
// 🧱 PIPING
//   id: ${m.id}
//
//   🔍 TRACEABILITY
//   rawName: ${m.rawMaterialName}
//   normalizedName: ${m.normalizedMaterialName}
//   displayName: ${m.materialName}
//   isFromRateFile: ${m.isFromRateFile}
//   rateFileId: ${m.rateFileId}
//   rateVariantId: ${m.rateVariantId}
//   rateId: ${m.rateId}
//
//
//
//   📦 VALUES
//   qty(dynamic): ${_getDynamicQty(m)}
//   size(dynamic): ${_getDynamicValue(m.dynamicFields, 'size')}
//   length: ${m.length}
//   uom: ${m.uom}
//   moc: ${m.moc}
//   calcCat: ${m.calculationCategory}
//   remarks: ${m.remarks}
// """);
//
//         if (m.dynamicFields.isEmpty) {
//           debugPrint("  ⚠️ No dynamic fields");
//         } else {
//           debugPrint("  🔸 Dynamic Fields:");
//           for (final f in m.dynamicFields) {
//             debugPrint(
//               "     → key: ${f.key}, label: ${f.label}, value: ${f.value}, unit: ${f.unit}, display: ${f.displayText}",
//             );
//           }
//         }
//       }
//       debugPrint("🟩 RAW EQUIPMENT MATERIALS (${equipmentMaterials.length})");
//
//
      for (final m in equipmentMaterials) {
        debugPrint("""
🔩 EQUIPMENT
  id: ${m.id}

  🔍 TRACEABILITY
  rawName: ${m.rawMaterialName}
  normalizedName: ${m.normalizedMaterialName}
  displayName: ${m.materialName}
  isFromRateFile: ${m.isFromRateFile}
  rateFileId: ${m.rateFileId}
  rateVariantId: ${m.rateVariantId}

  📦 VALUES
  qty: ${m.qty}
  weight: ${m.weight}
  length: ${m.length}
  diameter: ${m.diameter}
  power: ${m.power}
  uom: ${m.uom}
  moc: ${m.moc}
  calcCat: ${m.calculationCategory}
  remarks: ${m.remarks}
""");

        if (m.dynamicFields.isEmpty) {
          debugPrint("  ⚠️ No dynamic fields");
        } else {
          debugPrint("  🔸 Dynamic Fields:");
          for (final f in m.dynamicFields) {
            debugPrint(
              "     → key: ${f.key}, label: ${f.label}, value: ${f.value}, unit: ${f.unit}, display: ${f.displayText}",
            );
          }
        }
      }

      // Transform piping materials to API format
      // ✅ merge piping + equipment into ONE list
      final items = [
        ...pipingMaterials.map((material) {
          return {
            'lineItemId': material.id,

            // 🔥 TRACEABILITY
            'rawMaterialName': material.rawMaterialName,
            'normalizedMaterialName': material.normalizedMaterialName,
            'materialName': material.materialName,
            'image': material.image,
            'rateId': material.rateId,

            // 🔥 CORE VALUES
            'qty': _resolvePayloadQty(
              qty: _getDynamicQty(material),
              fields: material.dynamicFields,
            ),
            'length': material.length,
            'rmt': material.rmt,
            'diameter': material.diameter,
            'weight': material.weight,
            'power': material.power,
            'uom': material.uom,

            'actualRate': 0,
            'rate': 0,

            // 🔥 HEADER SYNC
            'moc': _mocController.text.trim(),
            'size': _resolveSize(material),
            'location': _floorController.text.trim(),
            'plant': _plantController.text.trim(),

            'designation': ['piping'],
            'calculationCategory': material.calculationCategory,

            // 🔥 DYNAMIC FIELDS
            'dynamicFields': material.dynamicFields.map((f) {
              dynamic parsedValue;

              if (f.value == null || f.value.toString().isEmpty) {
                parsedValue = null;
              } else {
                final raw = f.value.toString().trim();

                // Try int first
                final intVal = int.tryParse(raw);
                if (intVal != null) {
                  parsedValue = intVal;
                } else {
                  // Try double
                  final doubleVal = double.tryParse(raw);
                  if (doubleVal != null) {
                    parsedValue = doubleVal;
                  } else {
                    parsedValue = raw; // keep as string (like CS)
                  }
                }
              }

              return {
                'key': f.key,
                'label': f.label,
                'value': parsedValue,
                'unit': f.unit,
                'displayText': f.displayText,
              };
            }).toList(),

            'remarks': material.remarks,

            // 🔥 RATE FILE META
            'isFromRateFile': material.isFromRateFile,
            'rateFileId': material.rateFileId,
            'rateVariantId': material.rateVariantId,
          };
        }),
        ...equipmentMaterials.map((material) {
          return {
            'lineItemId': material.id,

            // 🔥 TRACEABILITY
            'rawMaterialName': material.rawMaterialName,
            'normalizedMaterialName': material.normalizedMaterialName,
            'materialName': material.materialName,
            'image': material.image,

            // 🔥 CORE VALUES
            'qty': _resolvePayloadQty(
              qty: material.qty,
              fields: material.dynamicFields,
            ),
            'length': material.length,
            'rmt': material.rmt,
            'diameter': material.diameter,
            'weight': material.weight,
            'power': material.power,
            'uom': material.uom,

            'actualRate': 0,
            'rate': 0,

            // 🔥 HEADER SYNC
            'moc': _mocController.text.trim(),
            'size': _resolveSize(material),
            'location': _floorController.text.trim(),
            'plant': _plantController.text.trim(),

            'designation': ['equipment'],
            'calculationCategory': material.calculationCategory,

            // 🔥 DYNAMIC FIELDS (YOU WERE MISSING THIS)
            'dynamicFields': material.dynamicFields.map((f) {
              dynamic parsedValue;

              if (f.value == null || f.value.toString().isEmpty) {
                parsedValue = null;
              } else {
                final raw = f.value.toString().trim();

                // Try int first
                final intVal = int.tryParse(raw);
                if (intVal != null) {
                  parsedValue = intVal;
                } else {
                  // Try double
                  final doubleVal = double.tryParse(raw);
                  if (doubleVal != null) {
                    parsedValue = doubleVal;
                  } else {
                    parsedValue = raw; // keep as string (like CS)
                  }
                }
              }

              return {
                'key': f.key,
                'label': f.label,
                'value': parsedValue,
                'unit': f.unit,
                'displayText': f.displayText,
              };
            }).toList(),
            'remarks': material.remarks,

            // 🔥 RATE FILE META
            'isFromRateFile': material.isFromRateFile,
            'rateFileId': material.rateFileId,
            'rateVariantId': material.rateVariantId,
          };
        }),
      ];
      final pureDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final dateString = DateFormat('yyyy-MM-dd').format(pureDate);

      final Map<String, dynamic> updateData;

      if (_isDateOverrideMode) {
        updateData = {
          'date': dateString,
          'dprName': _dprNameController.text.trim(),
          'moc': _mocController.text.trim(),
          'size': _sizeController.text.trim(),
          'sizeUom': _sizeUomController.text.trim(),
          'location': _floorController.text.trim(),
          'plant': _plantController.text.trim(),
          if (items.isNotEmpty) 'items': items,
        };
      } else {
        updateData = {
          'dprName': _dprNameController.text.trim(),
          'moc': _mocController.text.trim(),
          'size': _sizeController.text.trim(),
          'sizeUom': _sizeUomController.text.trim(),
          'location': _floorController.text.trim(),
          'plant': _plantController.text.trim(),
          (_mechanicalId == null || _mechanicalId!.isEmpty)
              ? 'date'
              : 'updatedDate': dateString,
          if (_mechanicalId == null && dprDesignation.isNotEmpty)
            'designation': dprDesignation,
          if (items.isNotEmpty) 'items': items,
        };
      }

      print('Sending update data: ${dateString}');

      print('----- BEFORE SAVE (PROVIDER STATE) -----');

      for (final p in pipingMaterials) {
        print({
          'type': 'piping',
          'id': p.id,
          'name': p.materialName,
          'qty': p.qty,
          'length': p.length,
          'uom': p.uom,
          'remarks': p.remarks,
        });
      }

      for (final e in equipmentMaterials) {
        print({
          'type': 'equipment',
          'id': e.id,
          'name': e.materialName,
          'qty': e.qty,
          'weight': e.weight,
          'uom': e.uom,
          'remarks': e.remarks,
        });
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(updateData);

      print("🚀 FULL DPR UPDATE JSON:");
      printLongString(jsonString);
      print('---------------------------------------');
      final draftModel = _buildDraftDprModel(
        pipingMaterials: pipingMaterials,
        equipmentMaterials: equipmentMaterials,
        designation: dprDesignation,
      );
      final draftId = await _draftDpr(
        draft: draftModel,
        updateData: updateData,
      );

      await _enqueueDprBackgroundSave(
        draftId: draftId,
        draft: draftModel,
        updateData: updateData,
        dprName: _dprNameController.text.trim(),
        dateString: dateString,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          int count = 0;

          if (widget.work == null) {
            Navigator.of(context).popUntil((_) => count++ >= 4);
          } else {
            context.pop(true);
          }

          _showSnackBar("Saved locally. Syncing in background");

          // ❌ DO NOT auto-disable edit mode for past dates
        }
      });
    } catch (e, st) {
      if (mounted && !_isDisposed) {
        print('❌ ERROR: $e');
        print('📍 STACKTRACE:\n$st');

        final message = extractBackendError(e);
        AppToast.error(message);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void printLongString(String text) {
    const int chunkSize = 800; // safe size
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      print(text.substring(i, end));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _dprNameController.dispose();
    _mocController.dispose();
    _sizeController.dispose();
    _plantController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> getd(DprModel dpr) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(dpr.toJson());
    debugPrint('🔴 DROPDOWN DPR JSON:');
    for (int i = 0; i < jsonString.length; i += 800) {
      final end = (i + 800 < jsonString.length) ? i + 800 : jsonString.length;
      debugPrint(jsonString.substring(i, end));
    }
  }
}

class MaterialCardWrapper extends StatelessWidget {
  final bool isUpdating;
  final Widget child;

  const MaterialCardWrapper({
    required this.isUpdating,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ShimmerCircle(size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
