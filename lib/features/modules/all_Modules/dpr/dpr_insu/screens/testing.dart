import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../offline/data/repo/material_repo_provider.dart';
import '../../providers/selectedSize_provider.dart';
import '../../screens/add_description.dart';
import '../model/dpr_model_insu.dart';
import '../model/eqip_insu.dart';
import '../model/insu_step_date.dart';
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


class AddInsulationDescriptionScreen extends ConsumerStatefulWidget {
  final InsulationDprModel? work;

  const AddInsulationDescriptionScreen({super.key, this.work});

  @override
  ConsumerState<AddInsulationDescriptionScreen> createState() => _AddInsulationDescriptionScreenState();
}

class _AddInsulationDescriptionScreenState extends ConsumerState<AddInsulationDescriptionScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

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

  late String siteId;
  late String teamId;
  late TeamModel team;

  InsulationDprApi service=InsulationDprApi();

  String? _insulationId;
  String? _selectedDprId;

  bool _pipeInsulationOn = true;
  bool _equipmentInsulationOn = true;
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
  bool _removeLagging = false;
  bool _removeCladding = false;


  List<InsulationDprModel> _dprListForSelectedDate = [];
  bool _isLoadingDprList = false;

  // Insulation layer state
  LayerType _selectedLayerType = LayerType.single;
  final List<LayerData> _layers = [];
  LayerData _cladding = LayerData.empty();

  bool get isCreatingDpr => _insulationId == null;
  bool get isEditingDpr => _insulationId != null;
  bool get isEditing => _insulationId != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.work != null) {
        _initializeFromWork(widget.work!);
      } else {
        setState(() {
          _loadLayersFromProvider();
        });

        _hydrateFromMaterialStream();   // ← clean hydration
      }
    });
  }
  void _hydrateFromMaterialStream() {
    final siteId = ref.read(selectedSiteIdProvider)!;

    ref.listenManual(
      materialsStreamProvider((
      siteId: siteId,
      domain: 'insulation',
      designation: '', // we’ll filter ourselves
      )),
          (previous, next) {
        next.whenData((localMaterials) {
          if (localMaterials.isEmpty) return;

          final piping = <PipingMaterial>[];
          final equipment = <EquipmentMaterial>[];

          for (final local in localMaterials) {
            if (local.designation == 'piping') {
              piping.add(local.toPiping());
            } else if (local.designation == 'equipment') {
              equipment.add(local.toEquipment());
            }
          }

          ref
              .read(insulationPipingMaterialsProvider.notifier)
              .setMaterials(piping);

          ref
              .read(insulationEquipmentMaterialsProvider.notifier)
              .setMaterials(equipment);

          // propagate global size + unit
          final size = ref.read(selectedSizeProvider) ?? '';
          final unit = ref.read(selectedUnitProvider);

          ref
              .read(insulationPipingMaterialsProvider.notifier)
              .updateAllSizes(
            size: size,
            unit: unit,
          );
        });
      },
    );
  }
  void _initializeControllers() {
    _dprNameController = TextEditingController(text: 'New Insulation DPR');
    _mocController = TextEditingController();
    _sizeController = TextEditingController();
    _plantController = TextEditingController();
    _floorController = TextEditingController();

    // Insulation-specific controllers
    _layerNameController = TextEditingController();
    _thicknessController = TextEditingController();
    _claddingNameController = TextEditingController();
    _claddingThicknessController = TextEditingController();
  }
  void _initializeFromWork(InsulationDprModel work) {
    setState(() {
      // ---- CORE ----
      _insulationId = work.id;
      _selectedDprId = work.id;

      _dprNameController.text = work.workDescription;
      _plantController.text = work.plant ?? '';
      _floorController.text = work.location;
      ref.read(dprSizeProvider.notifier).state = work.size.toString();
      _sizeController.text = work.size.toString();

      // ---- TOGGLES ----
      _pipeInsulationOn = work.pipingMaterials.isNotEmpty;
      _equipmentInsulationOn = work.equipmentMaterials.isNotEmpty;
      _showPipingMaterials = _pipeInsulationOn;
      _showEquipmentMaterials = _equipmentInsulationOn;

      // ---- LAYERS LOCAL ----
      _loadLayersFromModel(work);
    });

    // ---- MATERIAL PROVIDERS ----
    ref.read(insulationPipingMaterialsProvider.notifier)
        .setMaterials(work.pipingMaterials);

    ref.read(insulationEquipmentMaterialsProvider.notifier)
        .setMaterials(work.equipmentMaterials);
  }
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

    _selectedLayerType = state.layerType ?? LayerType.single;

    _layers
      ..clear()
      ..addAll(state.layers);

    _cladding = state.cladding;
  }



  void _initializeData() {
    siteId = ref.read(selectedSiteIdProvider)!;
    teamId = ref.read(selectedTeamIdProvider)??"";


    // ONLY read, never watch
    final insulationState = ref.read(insulationStateProvider);
    _floorController.text = insulationState.floor;

    _mocController.text = "";
    _sizeController.text = ref.read(selectedSizeProvider)??'';
  }

  Future<void> loadScreenState() async {
    ref.read(insulationPipingMaterialsProvider.notifier).clear();
    ref.read(insulationEquipmentMaterialsProvider.notifier).clear();

    if (_insulationId != null) {
      // 🔵 EDITING INSULATION DPR
      await _loadInsulationDprMaterials();
    } else {
      // 🟢 CREATING NEW INSULATION DPR
      await _loadDefaultInsulationMaterials();
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
      final siteID=ref.read(selectedSiteIdProvider)!;
      await apiNotifier.fetchAndSetMaterials(siteId: siteID);
      final size=ref.read(selectedSizeProvider);
      final unit = ref.read(selectedUnitProvider);
      ref
          .read(insulationPipingMaterialsProvider.notifier)
          .updateAllSizes(
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

      // Materials
      ref
          .read(insulationPipingMaterialsProvider.notifier)
          .setMaterials(dpr.pipingMaterials);

      ref
          .read(insulationEquipmentMaterialsProvider.notifier)
          .setMaterials(dpr.equipmentMaterials);

      // Controllers
      _dprNameController.text = dpr.workDescription;
      _sizeController.text = dpr.size.toString();
      _floorController.text = dpr.location;

    } catch (e, s) {
      debugPrint('Error loading insulation DPR: $e');
      debugPrintStack(stackTrace: s);
      _showSnackBar('Failed to load DPR', isError: true);
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
      final List<InsulationDprModel> allDprs = await InsulationDprApi.fetchInsulationDprList(
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
      _dprNameController.text = 'New Insulation DPR';
    }

    await loadScreenState();
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
      final notifier =
      ref.read(insulationPipingMaterialsProvider.notifier);
      final materials =
      ref.read(insulationPipingMaterialsProvider);

      if (material is! PipingMaterial) return;

      final updated =
      materials.where((m) => m.id != material.id).toList();

      notifier.setMaterials(updated);
    } else {
      final notifier =
      ref.read(insulationEquipmentMaterialsProvider.notifier);
      final materials =
      ref.read(insulationEquipmentMaterialsProvider);
      print("😂😂😂😂😂😂😂");

      if (material is! EquipmentMaterial) return;
      print("😂😂😂😂😂😂😂");
      final updated =
      materials.where((m) => m.id != material.id).toList();

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
    final seconds =
    (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toRadixString(16)
        .padLeft(8, '0');

    final random = Random.secure();
    final randomPart = List.generate(10, (_) => random.nextInt(16))
        .map((e) => e.toRadixString(16))
        .join();

    final counter = random.nextInt(0xffffff)
        .toRadixString(16)
        .padLeft(6, '0');

    return seconds + randomPart + counter;
  }

  void copyInsulationMaterial({
    required dynamic material,
    required bool isPiping,
  }) {
    if (isPiping) {
      final notifier =
      ref.read(insulationPipingMaterialsProvider.notifier);
      final materials =
      ref.read(insulationPipingMaterialsProvider);

      if (material is! PipingMaterial) return;

      final index = materials.indexWhere((m) => m.id == material.id);
      if (index == -1) return;

      final copied = material.copyWith(
        id: generateObjectId(),
        name: '${material.name} (Copy)',
      );

      final updated = [...materials];
      updated.insert(index + 1, copied);

      notifier.setMaterials(updated);
    } else {
      final notifier =
      ref.read(insulationEquipmentMaterialsProvider.notifier);
      final materials =
      ref.read(insulationEquipmentMaterialsProvider);

      if (material is! EquipmentMaterial) return;

      final index = materials.indexWhere((m) => m.id == material.id);
      if (index == -1) return;

      final copied = material.copyWith(
        id: generateObjectId(),
        name: '${material.name} (Copy)',
      );

      final updated = [...materials];
      updated.insert(index + 1, copied);

      notifier.setMaterials(updated);
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
  }}

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

  bool get _isEditable => _isToday(_selectedDate) || _globalEditMode;
  static const List<String> insulationMaterials = [
    'Nitrile Rubber',
    'PUF',
    'LRB',
  ];
  static const List<String> claddingMaterials = [
    'SS',
    'Aluminium',
  ];
  List<String> get layerTypeOptions =>
      LayerType.values.map((e) => e.name.toUpperCase()).toList();
  Widget _buildLayerTypeSection() {
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
                        if (_layers.length > 1) _layers.removeRange(1, _layers.length);
                      } else if (_selectedLayerType == LayerType.double) {
                        while (_layers.length < 2) _layers.add(LayerData.empty());
                        if (_layers.length > 2) _layers.removeRange(2, _layers.length);
                      } else if (_selectedLayerType == LayerType.triple) {
                        while (_layers.length < 3) _layers.add(LayerData.empty());
                        if (_layers.length > 3) _layers.removeRange(3, _layers.length);
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
                            initialValue: layer.thickness == 0 ? '' : layer.thickness.toString(),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                child:Column(
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
                        initialValue: _cladding.thickness == 0 ? '' : _cladding.thickness.toString(),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
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
          fillColor: const Color(0xFFE3F2FD)
,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
    super.build(context);

    final pipingMaterials = ref.watch(insulationPipingMaterialsProvider);
    final equipmentMaterials = ref.watch(insulationEquipmentMaterialsProvider);
    final insulationState = ref.watch(insulationStateProvider);
    final insulationNotifier = ref.read(insulationStateProvider.notifier);


    final hasPipingMaterials = pipingMaterials.isNotEmpty;
    final hasEquipmentMaterials = equipmentMaterials.isNotEmpty;
    final shouldShowPiping = _pipeInsulationOn && _showPipingMaterials && hasPipingMaterials;
    final shouldShowEquipment = _equipmentInsulationOn && _showEquipmentMaterials && hasEquipmentMaterials;

    final shouldShowDropdown = _globalEditMode && _dprListForSelectedDate.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        await _autoSaveDraft();
        return true;
      },
      child: Scaffold(
        drawer: const CustomDrawer(),

        backgroundColor: Colors.grey[50],
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [const CustomSliverAppBar(title: "Add Insulation DPR")];
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6DCE)),
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

                            if (_pipeInsulationOn && !hasPipingMaterials)
                              _buildEmptyMaterialsCard('No pipe insulation materials available'),

                            if (_equipmentInsulationOn && !hasEquipmentMaterials)
                              _buildEmptyMaterialsCard('No equipment insulation materials available'),

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
                      initialValue:
                      lagging.thickness == 0 ? '' : lagging.thickness.toString(),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    return Container(
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
              SizedBox(width: 8),
              Text(
                'Insulation Daily Report',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _globalEditMode ? Colors.blue.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _globalEditMode ? Colors.blue.shade200 : Colors.transparent,
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
                      color: _globalEditMode ? Colors.blue : Colors.black,
                    ),
                  ),
                  if (!_globalEditMode) const SizedBox(width: 6),
                  if (_globalEditMode)
                    const Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: Colors.blue,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        if (shouldShowDropdown)
          _buildDprDropdown(),

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

              items: _dprListForSelectedDate.map<DropdownMenuItem<String>>((InsulationDprModel dpr) {
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Enter Insulation DPR Name',
              prefixIcon: const Icon(Icons.insights, size: 20),
            ),
          )
              : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

              ref.read(dprSizeProvider.notifier).state =value;

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
                      final size = (ref.read(dprSizeProvider)?.trim().isNotEmpty ?? false)
                          ? ref.read(dprSizeProvider)!
                          : (ref.read(selectedSizeProvider)?.trim().isNotEmpty ?? false)
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
            value: value != null && value.isNotEmpty ? value : null,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFE3F2FD)
,
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
            colors: [Colors.blue, Colors.blue
            ],
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

  List<Widget> _buildPipingMaterials(List<PipingMaterial> materials) {
    return materials.map((material) {
      return Padding(
        key: ValueKey(
          material.id.isNotEmpty
              ? 'piping_${material.id}'
              : 'piping_${material.name}',
        ),
        padding: const EdgeInsets.only(bottom: 12),
        child:  PipingMaterialCard(
          material: material,
          onChanged: (updated) {
            ref
                .read(insulationPipingMaterialsProvider.notifier)
                .editPipingMaterial(material.id, updated);
          },
          onAdd: () {
            copyInsulationMaterial(material: material,isPiping: true);
          },
          onEdit: () {},
          onDelete: () {
            deleteInsulationMaterial(
              material: material,
              isPiping: true,
            );
          },
          onRemark: () {},
        )
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials(List<EquipmentMaterial> materials) {
    return materials.map((material) {
      return Padding(
        key: ValueKey(
          material.id.isNotEmpty
              ? 'equipment_${material.id}'
              : 'equipment_${material.name}',
        ),
        padding: const EdgeInsets.only(bottom: 12),
        child: EquipmentMaterialCard(
          material: material,
          onChanged: (updated) {
            ref
                .read(insulationEquipmentMaterialsProvider.notifier)
                .editEquipmentMaterial(material.id, updated);
          },
          onAdd: () {
            copyInsulationMaterial(material: material,isPiping: false);
          },
          onEdit: () {},
          onDelete: () {

              deleteInsulationMaterial(
                material: material,
                isPiping: false,
              );


          },
          onRemark: () {},
        )
      );
    }).toList();
  }

  void _showRemarkDialog(String materialId, String currentRemark, {bool isPiping = true}) {
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
              _updateMaterialRemark(materialId, remarkController.text, isPiping: isPiping);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateMaterialRemark(String materialId, String remark, {bool isPiping = true}) {
    if (isPiping) {
      final materials = ref.read(insulationPipingMaterialsProvider);
      final updatedMaterials = materials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref.read(insulationPipingMaterialsProvider.notifier).setMaterials(updatedMaterials);
    } else {
      final materials = ref.read(insulationEquipmentMaterialsProvider);
      final updatedMaterials = materials.map((material) {
        if (material.id == materialId) {
          return material.copyWith(remarks: remark);
        }
        return material;
      }).toList();
      ref.read(insulationEquipmentMaterialsProvider.notifier).setMaterials(updatedMaterials);
    }

    _showSnackBar('Remark saved for material');
  }

  void _toggleGlobalEditMode() {
    setState(() {
      _globalEditMode = !_globalEditMode;
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
    final state = ref.read(insulationStateProvider);

    final designation = <String>[];
    if (pipingMaterials.isNotEmpty) designation.add('piping');
    if (equipmentMaterials.isNotEmpty) designation.add('equipment');

    final validLayers =
    state.layers.where((l) => l.name.trim().isNotEmpty).toList();

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
    final size =
    [ref.read(dprSizeProvider), ref.read(selectedSizeProvider), _sizeController.text]
        .firstWhere(
          (v) => v != null && v.trim().isNotEmpty && (num.tryParse(v.trim()) ?? 0) != 0,
      orElse: () => '',
    );
    final sizeUom=ref.read(selectedUnitProvider);


    return {
      'designation': designation,
      'plant': _plantController.text.trim(),
      'location': _floorController.text.trim(),
      'layer': state.layerType?.name,
      'work_description':_dprNameController.text,
      'size':size,
      'sizeUom':sizeUom,


      'legging_material_1': lm1,
      'legging_thickness_1': lt1,
      'legging_material_2': lm2,
      'legging_thickness_2': lt2,
      'legging_material_3': lm3,
      'legging_thickness_3': lt3,

      'cladding_material': state.cladding.name.isNotEmpty ? state.cladding.name : null,
      'cladding_swg': state.cladding.thickness.toInt(),

      'lagging_removal': _removeLagging,
      'cladding_removal': _removeCladding,

      if (equipmentMaterials.isNotEmpty)
        'equipment_materials': equipmentMaterials.map((e) => e.toJson()).toList(),

      if (pipingMaterials.isNotEmpty)
        'piping_materials': pipingMaterials.map((p) => p.toJson()).toList(),
    };
  }
  InsulationDprModel _buildDraftModel() {
    final pipingMaterials =
    ref.read(insulationPipingMaterialsProvider);

    final equipmentMaterials =
    ref.read(insulationEquipmentMaterialsProvider);

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
      leggingThickness1: validLayers.length > 0
          ? validLayers[0].thickness.toInt()
          : null,

      leggingMaterial2: validLayers.length > 1 ? validLayers[1].name : null,
      leggingThickness2: validLayers.length > 1
          ? validLayers[1].thickness.toInt()
          : null,

      leggingMaterial3: validLayers.length > 2 ? validLayers[2].name : null,
      leggingThickness3: validLayers.length > 2
          ? validLayers[2].thickness.toInt()
          : null,

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
    debugPrint("PIPING COUNT: ${ref.read(insulationPipingMaterialsProvider).length}");
    debugPrint("EQUIPMENT COUNT: ${ref.read(insulationEquipmentMaterialsProvider).length}");


    ref.read(insulationDraftProvider.notifier)
        .saveDraft(draft);


    debugPrint("💾 Draft Auto Saved");
  }


  Future<void> _handleSubmitFields() async {
    if (!_isEditable || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final pipingMaterials =
      ref.read(insulationPipingMaterialsProvider);
      final equipmentMaterials =
      ref.read(insulationEquipmentMaterialsProvider);

      final payload = buildInsulationDprPayload(
        pipingMaterials: pipingMaterials,
        equipmentMaterials: equipmentMaterials,
      );

      debugPrint("📤 INSULATION DPR PAYLOAD:");
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

      if (_insulationId == null) {
        await InsulationDprApi.createInsulationDpr(
          data: payload,
          siteId: siteId,
          teamId: teamId,
        );
      } else {
        await InsulationDprApi.updateInsulationDpr(
          dprId: _insulationId!,
          data: payload,
        );
      }

      _showSnackBar("Insulation DPR Saved Successfully");
    } catch (e) {
      await _autoSaveDraft();

      _showSnackBar(
        'Failed to save Insulation DPR: ${extractBackendError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    _layerNameController.dispose();
    _thicknessController.dispose();
    _claddingNameController.dispose();
    _claddingThicknessController.dispose();
    super.dispose();
  }
}