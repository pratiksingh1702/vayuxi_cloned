import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/equipment_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../dpr-setup/screens/add/add_material.dart';
import '../models/data/eqipment_provider.dart';
import '../models/data/piping_provider.dart';
import '../models/dprModel.dart';
import '../models/equipmentModel.dart';
import '../models/pipingModel.dart';
import '../providers/dpr.dart';
import '../providers/material_service.dart';
import '../providers/selectedSize_provider.dart';
import 'material_sync_util.dart';

class AddDescriptionScreen extends ConsumerStatefulWidget {
  final DprModel? work;

  const AddDescriptionScreen({super.key, this.work});

  @override
  ConsumerState<AddDescriptionScreen> createState() => _AddDescriptionScreenState();
}

class _AddDescriptionScreenState extends ConsumerState<AddDescriptionScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  late final TextEditingController _dprNameController;
  late final TextEditingController _mocController;
  late final TextEditingController _sizeController;
  late final TextEditingController _plantController;
  late final TextEditingController _floorController;

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



  @override
  bool get wantKeepAlive => true;

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

    if (widget.work != null) {
      _mechanicalId = widget.work!.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadScreenState();
    });
  }

  Future<void> loadScreenState() async {
    ref.read(pipingMaterialsProvider.notifier).clear();
    ref.read(equipmentMaterialsProvider.notifier).clear();

    if (_mechanicalId != null) {
      // 🔵 EDITING DPR
      await _loadDprMaterials();
    } else {
      // 🟢 CREATING DPR
      await _loadDefaultMaterials();
    }
  }
  Future<void> _loadDefaultMaterials() async {
    final service = DefaultMaterialService();

    final materials = await service.getDefaultMaterials(
      siteId: siteId,

    );

    ref.read(pipingMaterialsProvider.notifier).setMaterials(
      materials.whereType<PipingItem>().toList(),
    );

    ref.read(equipmentMaterialsProvider.notifier).setMaterials(
      materials.whereType<EquipmentItem>().toList(),
    );
  }
  Future<void> _loadDprMaterials() async {
    final dpr = await ref.read(dprProvider.notifier).fetchDprById(
      siteId: siteId,
      teamId: teamId,
      workId: _mechanicalId!,
    );

    if (dpr == null) return;
    final mergedPiping = MaterialSyncService.syncPiping(
      local: PipingMaterialsData.materials,
      server: dpr.piping,
    );

    final mergedEquipment = MaterialSyncService.syncEquipment(
      local: EquipmentMaterialsData.materials,
      server: dpr.equipment,
    );

    ref.read(pipingMaterialsProvider.notifier).setMaterials(mergedPiping);
    ref.read(equipmentMaterialsProvider.notifier).setMaterials(mergedEquipment);

    _dprNameController.text = dpr.dprName;
    _mocController.text = dpr.moc;
    _sizeController.text = dpr.size;
    _floorController.text = dpr.location;
    _plantController.text = dpr.plant;
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


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Clear any pending updates
    }
  }

  void _initializeControllers() {
    _dprNameController = TextEditingController(text: 'New DPR Entry');
    _mocController = TextEditingController();
    _sizeController = TextEditingController();
    _plantController = TextEditingController();
    _floorController = TextEditingController();
  }

  void _initializeData() {
    siteId = ref.read(selectedSiteIdProvider)!;
    teamId = ref.read(selectedTeamIdProvider)!;
    team = ref.read(currentTeamProvider)!;
    _mocController.text =(widget.work==null? ref.read(selectedMOCProvider)!.name:widget.work?.moc)??"";_floorController.text = (widget.work==null?ref.read(selectedFloorProvider)!.name:widget.work?.location)??"";
    _sizeController.text = (widget.work==null?ref.read(selectedSizeProvider)!:widget.work?.size)??"";
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    if (mounted) setState(() => _isLoadingMaterials = true);

    try {
      if (widget.work != null) {
        // If workId is provided, load that specific DPR
        _mechanicalId = widget.work?.id;
        await _fetchDprWorkById();
      } else {
        // Check if today's date
        if (_isToday(_selectedDate)) {
          // For today's date, always create a new DPR
          await _autoCreateDprWork();
        } else {
          // For other dates, fetch DPR list
          await _fetchDprListForDate(_selectedDate);

          if (_dprListForSelectedDate.isNotEmpty) {
            ref.read(pipingMaterialsProvider.notifier).clear();
            ref.read(equipmentMaterialsProvider.notifier).clear();
            await _loadDprWork(_dprListForSelectedDate.first);
          } else {
            // No DPR found for selected date
            setState(() {
              _mechanicalId = null;
              _selectedDprId = null;
              _dprNameController.text = 'New DPR Entry';
              _pipeFittingOn = false;
              _equipmentOn = false;
              _showPipingMaterials = false;
              _showEquipmentMaterials = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        print('Error loading initial data: $e');
        final message = extractBackendError(e);
        _showSnackBar('Failed to load DPR work: $message', isError: true);

      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoadingMaterials = false;
          _initialDataLoaded = true;
        });
      }
    }
  }
  Future<void> _fetchDprListForDate(DateTime date) async {
    if (_isDisposed) return;

    setState(() => _isLoadingDprList = true);

    try {
      final List<DprModel> allDprs = await DprApi.fetchDprWork(
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
            ? 'Found ${_dprListForSelectedDate.length} DPR(s) for ${_formatDate(date)}'
            : 'No DPR found for ${_formatDate(date)}. Create a new DPR.',
      );


      print('Found ${_dprListForSelectedDate.length} DPR(s) for ${_formatDate(date)}');
    } catch (e) {
      final message = extractBackendError(e);
      _showSnackBar('Error fetching DPR list: $message', isError: true);
      print('Error fetching DPR list: $e');

      _dprListForSelectedDate = [];
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingDprList = false);
      }
    }
  }

  Future<void> _loadDprWork(DprModel dpr) async {
    if (_isDisposed) return;

    _mechanicalId = dpr.id;
    _selectedDprId = dpr.id;

    _dprNameController.text = dpr.dprName;
    _mocController.text = dpr.moc;
    _sizeController.text = dpr.size;
    _floorController.text = dpr.location;
    _plantController.text = dpr.plant;

    await _fetchDprWorkById();

    if (mounted && !_isDisposed) {
      setState(() {
        if (dpr.piping.isNotEmpty) {
          _pipeFittingOn = true;
          _showPipingMaterials = true;
        }
        if (dpr.equipment.isNotEmpty) {
          _equipmentOn = true;
          _showEquipmentMaterials = true;
        }
      });
    }
  }

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
        'designation': ["piping","equipment"],
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
                  Navigator.pop(context, ['piping']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Equipment'),
                onTap: () {
                  Navigator.pop(context, ['equipment']);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text('Both (Piping + Equipment)'),
                onTap: () {
                  Navigator.pop(context, ['piping', 'equipment']);
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
  }/**/

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

      _dprNameController.text = dprWork.dprName ?? 'New DPR Entry';
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

      print('Fetched DPR work successfully with ${dprWork.piping.length} piping and ${dprWork.equipment.length} equipment materials');
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

  bool get _isEditable => _isToday(_selectedDate) || _globalEditMode;

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

    // Fetch DPRs for selected date
    await _fetchDprListForDate(picked);

    if (_dprListForSelectedDate.isNotEmpty) {
      // 🔵 EDITING: DPR exists for this date
      _mechanicalId = _dprListForSelectedDate.first.id;
      _selectedDprId = _mechanicalId;
    } else {
      // 🟢 CREATING: No DPR for this date
      _mechanicalId = null;
      _selectedDprId = null;

      _dprNameController.text = 'New DPR Entry';
    }

    // 🔑 SINGLE SOURCE OF TRUTH
    await loadScreenState();
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
  Future<void> _deleteDprMaterial(String materialId, bool isPiping) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    try {
      await DprApi().deleteMaterial(
        mechanicalId: _mechanicalId!,
        materialId: materialId,

      );

      if (isPiping) {
        final materials = ref.read(pipingMaterialsProvider);
         ref.read(pipingMaterialsProvider.notifier).setMaterials(
           materials.where((m) => m.id != materialId).toList(),
       );
      } else {
        final materials = ref.read(equipmentMaterialsProvider);
         ref.read(equipmentMaterialsProvider.notifier).setMaterials(
           materials.where((m) => m.id != materialId).toList(),
         );
      }

      _showSnackBar('Material deleted');
    } catch (e) {
      final message = extractBackendError(e);

      _showSnackBar('Delete failed: $message', isError: true);
    }
  }
  Future<void> _copyDprMaterial(String materialId,) async {
    try {
      await DprApi.copyDprMaterial(
        dprId: _mechanicalId!,
        matId: materialId,

      );

      await _fetchDprWorkById(); // re-sync server state
      _showSnackBar('Material copied');
    } catch (e) {
      final message = extractBackendError(e);

      _showSnackBar('Copy failed: $message', isError: true);
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
    }

    else if (material is EquipmentItem) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final pipingMaterials = ref.watch(pipingMaterialsProvider);
    final equipmentMaterials = ref.watch(equipmentMaterialsProvider);

    final hasPipingMaterials = pipingMaterials.isNotEmpty;
    final hasEquipmentMaterials = equipmentMaterials.isNotEmpty;
    final shouldShowPiping = _pipeFittingOn && _showPipingMaterials && hasPipingMaterials;
    final shouldShowEquipment = _equipmentOn && _showEquipmentMaterials && hasEquipmentMaterials;

    // Only show dropdown when:
    // 1. In edit mode
    // 2. Not today's date
    // 3. DPR list exists for selected date
    final shouldShowDropdown = _globalEditMode &&

        _dprListForSelectedDate.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [const CustomSliverAppBar(title: "Add DPR")];
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
                      _buildToggleSection(),
                      const SizedBox(height: 16),

                      Column(
                        children: [
                          if (_pipeFittingOn && hasPipingMaterials)
                            _buildMaterialToggleCard(
                              'Pipe Fitting Materials',
                              pipingMaterials.length,
                              _showPipingMaterials,
                                  () => _toggleMaterialVisibility(true),
                            ),

                          if (shouldShowPiping)
                            ..._buildPipingMaterials(pipingMaterials),

                          if (_equipmentOn && hasEquipmentMaterials)
                            _buildMaterialToggleCard(
                              'Equipment Materials',
                              equipmentMaterials.length,
                              _showEquipmentMaterials,
                                  () => _toggleMaterialVisibility(false),
                            ),

                          if (shouldShowEquipment)
                            ..._buildEquipmentMaterials(equipmentMaterials),

                          if (_pipeFittingOn && !hasPipingMaterials)
                            _buildEmptyMaterialsCard('No piping materials available'),

                          if (_equipmentOn && !hasEquipmentMaterials)
                            _buildEmptyMaterialsCard('No equipment materials available'),

                          if (!_pipeFittingOn && !_equipmentOn && _initialDataLoaded)
                            _buildEmptyState('Materials will appear here once loaded', Icons.downloading),
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
            Icons.inventory_2_outlined,
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
            _buildAddDprMaterialButton(),
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
  Widget _buildAddDprMaterialButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        if (_mechanicalId == null) {
          _showSnackBar('DPR not created yet', isError: true);
          return;
        }

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersistDPRScreen(
              isDpr: true,                 // 🔴 critical
              dprId: _mechanicalId!,       // 🔴 DPR ID
              siteId: siteId,
              teamId: teamId,
            ),
          ),
        );

        // Re-fetch DPR after add
        if (result == true) {
          await _fetchDprWorkById();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B6DCE),
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


  Widget _buildLoadingCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(32),
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
            style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
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
                'Daily Report',
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
          'Select DPR',
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
                await loadScreenState();
              },

              items: _dprListForSelectedDate.map<DropdownMenuItem<String>>((DprModel dpr) {
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
                borderSide: const BorderSide(color: Color(0xFF1B6DCE), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Enter DPR Name',
              prefixIcon: const Icon(Icons.edit_document, size: 20),
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
                Icon(Icons.description, color: Colors.grey[700], size: 20),
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
              color: Colors.green[50],
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
                color: _editMode ? Colors.green[700] : Colors.blue[700],
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCompactInputField('Plant', _plantController, Icons.factory)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('Location', _floorController, Icons.location_on)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('MOC', _mocController, Icons.category)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('Size', _sizeController, Icons.straighten)),
          ],
        )
      ],
    );
  }

  Widget _buildCompactInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              filled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1B6DCE), width: 2),
              ),
            ),
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
                'Pipe Fitting',
                Icons.plumbing_rounded,
                _pipeFittingOn,
                false,
                    (value) => _handleToggleChange(true, value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                'Equipment',
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
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
            colors: [Color(0xFF1B6DCE), Color(0xFF1565C0)],
          )
              : null,
          color: value ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? const Color(0xFF1B6DCE) : Colors.grey[300]!,
            width: value ? 2 : 1.5,
          ),
          boxShadow: value
              ? [
            BoxShadow(
              color: const Color(0xFF1B6DCE).withOpacity(0.4),
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
                  color: value ? Colors.white : const Color(0xFF1B6DCE),
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : const Color(0xFF1B6DCE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPipingMaterials(List<PipingItem> materials) {
    return materials.map((material) {
      return Padding(
        key: ValueKey(
          material.id.isNotEmpty
              ? 'piping_${material.id}'
              : 'piping_${material.materialName}',
        ),

        padding: const EdgeInsets.only(bottom: 12),
        child: MaterialCardWrapper(
          isUpdating: false,
          child: DynamicItemCard(
            quantity: material.qty.toString(),
            size: _sizeController.text,
            length: (material.length == null || material.length == 0)
                ? ""
                : material.length.toString(),
            floor: _floorController.text,
            moc:  _mocController.text,
            image: material.image,
            sizeLabel: 'Size',
            remark: material.remarks,
            lengthLabel: material.materialName,
            sizePlaceholder: _sizeController.text,
            lengthPlaceholder: material.uom,
            onQtyChanged: (val) => _onPipingFieldChanged(material.id, 'quantity', val),
            onSizeChanged: (val) => _onPipingFieldChanged(material.id, 'size', val),
            onLengthChanged: (val) => _onPipingFieldChanged(material.id, 'length', val),
            onFloorChanged: (val) => _onPipingFieldChanged(material.id, 'floor', val),
            onMocChanged: (val) => _onPipingFieldChanged(material.id, 'moc', val),
            isEditable: _isEditable,
            onCopy: () => _copyDprMaterial(material.id),
            onAdd: () => _copyDprMaterial(material.id),
            onDelete: ()=>_deleteDprMaterial(material.id, true),
            onEdit: ()=>_editDprMaterial(material,""),

            onRemark: () => _showRemarkDialog(material.id, material.remarks ?? '', isPiping: true),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials(List<EquipmentItem> materials) {
    return materials.map((material) {
      return Padding(
        key: ValueKey(
          material.id.isNotEmpty
              ? 'equipment_${material.id}'
              : 'equipment_${material.materialName}',
        ),

        padding: const EdgeInsets.only(bottom: 12),
        child: MaterialCardWrapper(
          isUpdating: false,
          child: DynamicItemCard2(
            title: material.materialName,
            quantity: material.qty.toString(),
            image: material.image,
            floor: _floorController.text,
            moc:  _mocController.text,
            size: _sizeController.text,
            ton: material.weight.toString(),
            meter: material.uom,
            remark: material.remarks,
            onMocChanged: (val) => _onEquipmentFieldChanged(material.id, 'moc', val),
            onQtyChanged: (val) => _onEquipmentFieldChanged(material.id, 'quantity', val),
            onFloorChanged: (val) => _onEquipmentFieldChanged(material.id, 'floor', val),
            onTonChanged: (val) => _onEquipmentFieldChanged(material.id, 'ton', val),
            onCopy: () => _copyDprMaterial(material.id),
            onAdd: () => _copyDprMaterial(material.id),
            onEdit: ()=>_editDprMaterial(material,""),
            onDelete: ()=>_deleteDprMaterial(material.id, false),

            isEditable: _isEditable,


            onRemark: () => _showRemarkDialog(material.id, material.remarks ?? '', isPiping: false), onMeterChanged: (String p1) {  },
          ),
        ),
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
              backgroundColor: const Color(0xFF1B6DCE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
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
            return material.copyWith(qty: material.qty);
          case 'size':
          // Size is handled globally via _sizeController
            return material;
          case 'length':
            return material.copyWith(length: double.tryParse(value) ?? material.length);
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

    final equipmentMaterials = ref.read(equipmentMaterialsProvider);
    final updatedMaterials = equipmentMaterials.map((material) {
      if (material.id == materialId) {
        switch (field) {
          case 'quantity':
            return material.copyWith(qty: material.qty);
          case 'ton':
            return material.copyWith(weight: double.tryParse(value) ?? material.weight);
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
    print('Equipment material $materialId: $field changed to $value');
  }

  void _updateMaterialRemark(String materialId, String remark, {bool isPiping = true}) {
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
    setState(() {
      _globalEditMode = !_globalEditMode;
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

  Future<void> _handleSubmitFields() async {
    if (_isDisposed) return;

    if (!_isEditable) {
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
      final equipmentMaterials = ref.read(equipmentMaterialsProvider);
      List<String> dprDesignation = [];

      if (pipingMaterials.isNotEmpty) {
        dprDesignation.add('piping');
      }

      if (equipmentMaterials.isNotEmpty) {
        dprDesignation.add('equipment');
      }


      debugPrint("🟦 RAW PIPING MATERIALS (${pipingMaterials.length})");
      for (final m in pipingMaterials) {
        debugPrint("""
🧱 PIPING
  id: ${m.id}
  name: ${m.materialName}
  qty: ${m.qty}
  size: ${m.size}
  length: ${m.length}
  uom: ${m.uom}
  moc: ${m.moc}
  calcCat: ${m.calculationCategory}
  remarks: ${m.remarks}
""");
      }

      debugPrint("🟩 RAW EQUIPMENT MATERIALS (${equipmentMaterials.length})");
      for (final m in equipmentMaterials) {
        debugPrint("""
🔩 EQUIPMENT
  id: ${m.id}
  name: ${m.materialName}
  qty: ${m.qty}
  weight: ${m.weight}
  length: ${m.length}
  uom: ${m.uom}
  moc: ${m.moc}
  calcCat: ${m.calculationCategory}
  remarks: ${m.remarks}
""");
      }


      // Transform piping materials to API format
      final pipingData = pipingMaterials.map((material) {
        return {
          'id': material.id,
          'materialName': material.materialName,
          'qty': material.qty, // Send as integer, not double
          'size': _sizeController.text.trim(),
          'length': material.length, // Keep as number
          'uom': material.uom,
          'actualRate': material.actualRate,
          'location': _floorController.text.trim(),
          'moc': _mocController.text.trim(),
          'calculationCategory': material.calculationCategory, // Required field
          'designation': ['piping'],
          // Don't send the image field - it's a local asset path
          if (material.remarks != null && material.remarks!.isNotEmpty)
            'remarks': material.remarks,
        };
      }).toList();

      // Transform equipment materials to API format
      final equipmentData = equipmentMaterials.map((material) {
        return {
          'id': material.id,
          'materialName': material.materialName,
          'qty': material.qty, // Send as integer, not double
          'weight': material.weight, // Keep as number
          'uom': material.uom,
          'actualRate': material.actualRate,
          'location': _floorController.text.trim(),
          'moc': _mocController.text.trim(),
          'calculationCategory': material.calculationCategory, // Required field
          'designation': ['equipment'],
          // Don't send the image field - it's a local asset path
          if (material.remarks != null && material.remarks!.isNotEmpty)
            'remarks': material.remarks,
        };
      }).toList();

      final updateData = {
        'dprName': _dprNameController.text.trim(),
        'moc': _mocController.text.trim(),
        'size': _sizeController.text.trim(),
        'location': _floorController.text.trim(),
        'plant': _plantController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        if (_mechanicalId == null && dprDesignation.isNotEmpty)
          'designation': dprDesignation,

        if (pipingData.isNotEmpty) 'piping': pipingData,
        if (equipmentData.isNotEmpty) 'equipment': equipmentData,
      };

      print('Sending update data: ${updateData}');

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

      print('---------------------------------------');
      if (_mechanicalId == null) {
        await ref.read(dprProvider.notifier).postDprWork(
               data: updateData,
          siteId: ref.read(selectedSiteIdProvider)!,
          teamId: ref.read(selectedTeamIdProvider)!,

             );
      } else {
        await ref.read(dprProvider.notifier).updateDprWork(
          data: updateData,
          mechanicalId: _mechanicalId!,
        );
      }



 // await ref.read(dprProvider.notifier).postDprWork(
 //        data: updateData,
 //   siteId: ref.read(selectedSiteIdProvider)!,
 //   teamId: ref.read(selectedTeamIdProvider)!,
 //
 //      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          int count = 0;

          // Only pop if you're NOT in global edit mode
          if (!_globalEditMode) {
            Navigator.of(context).popUntil((_) => count++ >= 4);
          }
          _showSnackBar("Successfully Saved");

          // ❌ DO NOT auto-disable edit mode for past dates
        }
      });


    } catch (e) {
      if (mounted && !_isDisposed) {
        print('Error details: $e');
        final message = extractBackendError(e);

        _showSnackBar('Failed to save DPR: $message', isError: true);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isSubmitting = false);
      }
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
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
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