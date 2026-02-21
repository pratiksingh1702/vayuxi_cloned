// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
// import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/models/data/equipment_material_data.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
// import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
// import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
// import 'package:untitled2/core/utlis/widgets/buttons.dart';
// import 'package:untitled2/core/utlis/widgets/custom.dart';
// import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
// import '../models/data/eqipment_provider.dart';
// import '../models/data/piping_provider.dart';
// import '../models/dprModel.dart';
// import '../models/equipmentModel.dart';
// import '../models/pipingModel.dart';
// import '../providers/dpr.dart';
// import '../providers/selectedSize_provider.dart';
// import 'add_description.dart';
// import 'material_sync_util.dart';
// import 'package:dio/dio.dart';
//
// class AddDescriptionScreen extends ConsumerStatefulWidget {
//   final String? workId;
//
//   const AddDescriptionScreen({super.key, this.workId});
//
//   @override
//   ConsumerState<AddDescriptionScreen> createState() => _AddDescriptionScreenState();
// }
//
// class _AddDescriptionScreenState extends ConsumerState<AddDescriptionScreen>
//     with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
//
//   late final TextEditingController _dprNameController;
//   late final TextEditingController _mocController;
//   late final TextEditingController _sizeController;
//   late final TextEditingController _plantController;
//   late final TextEditingController _floorController;
//
//   late String siteId;
//   late String teamId;
//   late TeamModel team;
//
//   String? _mechanicalId;
//   String? _selectedDprId;
//
//   bool _pipeFittingOn = true;
//   bool _equipmentOn = true;
//   bool _editMode = true;
//   bool _globalEditMode = false;
//   bool _showPipingMaterials = true;
//   bool _showEquipmentMaterials = true;
//
//   DateTime _selectedDate = DateTime.now();
//
//   bool _isLoadingMaterials = false;
//   bool _isSubmitting = false;
//   bool _isCreatingWork = false;
//   bool _isDisposed = false;
//   bool _initialDataLoaded = false;
//   bool _autoCreateAttempted = false;
//
//   List<DprModel> _dprListForSelectedDate = [];
//   bool _isLoadingDprList = false;
//
//   // Selection mode state
//   bool _isSelectionMode = false;
//   Set<String> _selectedMaterialIds = {};
//   String _currentCategory = ''; // 'piping' or 'equipment'
//
//   // Track updating materials
//   Set<String> _updatingMaterialIds = {};
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeControllers();
//     _initializeData();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadInitialData();
//     });
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       // Clear any pending updates
//     }
//   }
//
//   void _initializeControllers() {
//     _dprNameController = TextEditingController(text: 'New DPR Entry');
//     _mocController = TextEditingController();
//     _sizeController = TextEditingController();
//     _plantController = TextEditingController();
//     _floorController = TextEditingController();
//   }
//
//   void _initializeData() {
//     siteId = ref.read(selectedSiteIdProvider)!;
//     teamId = ref.read(selectedTeamIdProvider)!;
//     team = ref.read(currentTeamProvider)!;
//     _mocController.text = ref.read(selectedMOCProvider)!.name;
//     _floorController.text = ref.read(selectedFloorProvider)!.name;
//     _sizeController.text = ref.read(selectedSizeProvider)!;
//   }
//
//   Future<void> _loadInitialData() async {
//     if (_isDisposed) return;
//
//     if (mounted) setState(() => _isLoadingMaterials = true);
//
//     try {
//       if (widget.workId != null) {
//         _mechanicalId = widget.workId;
//         await _fetchDprWorkById();
//       } else {
//         if (_isToday(_selectedDate)) {
//           await _autoCreateDprWork();
//         } else {
//           await _fetchDprListForDate(_selectedDate);
//
//           if (_dprListForSelectedDate.isNotEmpty) {
//             ref.read(pipingMaterialsProvider.notifier).clear();
//             ref.read(equipmentMaterialsProvider.notifier).clear();
//             await _loadDprWork(_dprListForSelectedDate.first);
//           } else {
//             setState(() {
//               _mechanicalId = null;
//               _selectedDprId = null;
//               _dprNameController.text = 'New DPR Entry';
//               _pipeFittingOn = false;
//               _equipmentOn = false;
//               _showPipingMaterials = false;
//               _showEquipmentMaterials = false;
//             });
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted && !_isDisposed) {
//         print('Error loading initial data: $e');
//         _showSnackBar('Failed to load DPR data: $e', isError: true);
//       }
//     } finally {
//       if (mounted && !_isDisposed) {
//         setState(() {
//           _isLoadingMaterials = false;
//           _initialDataLoaded = true;
//         });
//       }
//     }
//   }
//
//   Future<void> _fetchDprListForDate(DateTime date) async {
//     if (_isDisposed) return;
//
//     setState(() => _isLoadingDprList = true);
//
//     try {
//       final List<DprModel> allDprs = await DprApi.fetchDprWork(
//         siteId: siteId,
//         teamId: teamId,
//       );
//
//       _dprListForSelectedDate = allDprs.where((dpr) {
//         final dprDate = dpr.updatedAt;
//         return dprDate.year == date.year &&
//             dprDate.month == date.month &&
//             dprDate.day == date.day;
//       }).toList();
//
//       print('Found ${_dprListForSelectedDate.length} DPR(s) for ${_formatDate(date)}');
//     } catch (e) {
//       print('Error fetching DPR list: $e');
//       _dprListForSelectedDate = [];
//     } finally {
//       if (mounted && !_isDisposed) {
//         setState(() => _isLoadingDprList = false);
//       }
//     }
//   }
//
//   Future<void> _loadDprWork(DprModel dpr) async {
//     if (_isDisposed) return;
//
//     _mechanicalId = dpr.id;
//     _selectedDprId = dpr.id;
//
//     _dprNameController.text = dpr.dprName;
//     _mocController.text = dpr.moc;
//     _sizeController.text = dpr.size;
//     _floorController.text = dpr.location;
//     _plantController.text = dpr.plant;
//
//     await _fetchDprWorkById();
//
//     if (mounted && !_isDisposed) {
//       setState(() {
//         if (dpr.piping.isNotEmpty) {
//           _pipeFittingOn = true;
//           _showPipingMaterials = true;
//         }
//         if (dpr.equipment.isNotEmpty) {
//           _equipmentOn = true;
//           _showEquipmentMaterials = true;
//         }
//       });
//     }
//   }
//
//   Future<void> _autoCreateDprWork() async {
//     if (_isDisposed || _autoCreateAttempted) return;
//
//     _autoCreateAttempted = true;
//     if (mounted) setState(() => _isCreatingWork = true);
//
//     try {
//       final postData = {
//         'dprName': _dprNameController.text.trim(),
//         'plant': _plantController.text.trim(),
//         'location': _floorController.text.trim(),
//         'size': _sizeController.text.trim(),
//         'moc': _mocController.text.trim(),
//         'designation': ['piping', 'equipment'],
//         'date': _selectedDate.toIso8601String(),
//       };
//
//       print('Auto-creating DPR work with data: $postData');
//
//       final DprModel response = await DprApi.postDprWork(
//         data: postData,
//         siteId: siteId,
//         teamId: teamId,
//       );
//
//       if (response != null && response.id != null) {
//         _mechanicalId = response.id;
//         _selectedDprId = response.id;
//         await _fetchDprWorkById();
//
//         print('Auto-created DPR work with ID: $_mechanicalId');
//
//         _dprListForSelectedDate.add(response);
//
//         if (mounted) {
//           setState(() {
//             _pipeFittingOn = true;
//             _equipmentOn = true;
//             _showPipingMaterials = true;
//             _showEquipmentMaterials = true;
//           });
//         }
//
//         _showSnackBar('DPR work created successfully!');
//       } else {
//         throw Exception('Failed to create DPR work - no ID returned');
//       }
//     } catch (e) {
//       if (mounted && !_isDisposed) {
//         print('Error auto-creating DPR work: $e');
//         _showSnackBar('Failed to create DPR work: $e', isError: true);
//       }
//     } finally {
//       if (mounted && !_isDisposed) {
//         setState(() => _isCreatingWork = false);
//       }
//     }
//   }
//
//   String materialKey(String name, String designation) {
//     return '${designation.toLowerCase()}::${name.trim().toLowerCase()}';
//   }
//
//   void _syncLocalMaterialsWithServer(DprModel dpr) {
//     final mergedPiping = MaterialSyncService.syncPiping(
//       local: PipingMaterialsData.materials,
//       server: dpr.piping,
//     );
//
//     final mergedEquipment = MaterialSyncService.syncEquipment(
//       local: EquipmentMaterialsData.materials,
//       server: dpr.equipment,
//     );
//
//     ref.read(pipingMaterialsProvider.notifier).setMaterials(mergedPiping);
//     ref.read(equipmentMaterialsProvider.notifier).setMaterials(mergedEquipment);
//
//     print('----- AFTER SYNC (LOCAL STATE) -----');
//
//     for (final p in mergedPiping) {
//       print({
//         'type': 'piping',
//         'id': p.id,
//         'name': p.materialName,
//         'qty': p.qty,
//         'length': p.length,
//         'uom': p.uom,
//         'remarks': p.remarks,
//       });
//     }
//
//     for (final e in mergedEquipment) {
//       print({
//         'type': 'equipment',
//         'id': e.id,
//         'name': e.materialName,
//         'qty': e.qty,
//         'weight': e.weight,
//         'uom': e.uom,
//         'remarks': e.remarks,
//       });
//     }
//
//     print('-----------------------------------');
//   }
//
//   Future<void> _fetchDprWorkById() async {
//     if (_isDisposed || _mechanicalId == null) return;
//     ref.read(pipingMaterialsProvider.notifier).clear();
//     ref.read(equipmentMaterialsProvider.notifier).clear();
//
//     if (mounted) setState(() => _isLoadingMaterials = true);
//
//     try {
//       print('Fetching DPR work with ID: $_mechanicalId');
//
//       await ref.read(dprProvider.notifier).fetchDprById(
//         siteId: siteId,
//         teamId: teamId,
//         workId: _mechanicalId!,
//       );
//
//       if (_isDisposed) return;
//
//       final dprState = ref.read(dprProvider);
//
//       if (dprState.data != null && dprState.data is DprModel) {
//         final dprWork = dprState.data as DprModel;
//         _syncLocalMaterialsWithServer(dprWork);
//
//         _dprNameController.text = dprWork.dprName ?? 'New DPR Entry';
//         _mocController.text = dprWork.moc ?? _mocController.text;
//         _sizeController.text = dprWork.size ?? _sizeController.text;
//         _floorController.text = dprWork.location ?? _floorController.text;
//         _plantController.text = dprWork.plant ?? _plantController.text;
//
//         if (mounted) {
//           setState(() {
//             if (dprWork.piping.isNotEmpty) {
//               _pipeFittingOn = true;
//               _showPipingMaterials = true;
//             }
//             if (dprWork.equipment.isNotEmpty) {
//               _equipmentOn = true;
//               _showEquipmentMaterials = true;
//             }
//           });
//         }
//
//         print('Fetched DPR work successfully with ${dprWork.piping.length} piping and ${dprWork.equipment.length} equipment materials');
//       } else {
//         throw Exception('Invalid DPR data format received');
//       }
//     } catch (e) {
//       if (mounted && !_isDisposed) {
//         print('Error fetching DPR work: $e');
//         _showSnackBar('Failed to load DPR work: $e', isError: true);
//       }
//     } finally {
//       if (mounted && !_isDisposed) {
//         setState(() => _isLoadingMaterials = false);
//       }
//     }
//   }
//
//   bool _isToday(DateTime date) {
//     final now = DateTime.now();
//     return date.year == now.year &&
//         date.month == now.month &&
//         date.day == now.day;
//   }
//
//   bool get _isEditable => _isToday(_selectedDate) || _globalEditMode;
//
//   Future<void> _selectDate(BuildContext context) async {
//     if (!_globalEditMode) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_isToday(_selectedDate)
//               ? "Click 'Edit' to change date"
//               : "Click 'Edit' to modify DPR for ${_formatDate(_selectedDate)}"),
//           backgroundColor: Colors.orange,
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//
//     if (picked != null && picked != _selectedDate) {
//       setState(() => _selectedDate = picked);
//
//       if (_isToday(picked)) {
//         await _autoCreateDprWork();
//       } else {
//         await _fetchDprListForDate(picked);
//
//         if (_dprListForSelectedDate.isNotEmpty) {
//           ref.read(pipingMaterialsProvider.notifier).clear();
//           ref.read(equipmentMaterialsProvider.notifier).clear();
//           await _loadDprWork(_dprListForSelectedDate.first);
//         } else {
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
//   }
//
//   String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";
//
//   void _handleToggleChange(bool isPiping, bool newValue) {
//     if (_isDisposed) return;
//
//     setState(() {
//       if (isPiping) {
//         _pipeFittingOn = newValue;
//         if (!newValue) {
//           _showPipingMaterials = false;
//         } else {
//           final materials = ref.read(pipingMaterialsProvider);
//           if (materials.isNotEmpty) {
//             _showPipingMaterials = true;
//           }
//         }
//       } else {
//         _equipmentOn = newValue;
//         if (!newValue) {
//           _showEquipmentMaterials = false;
//         } else {
//           final materials = ref.read(equipmentMaterialsProvider);
//           if (materials.isNotEmpty) {
//             _showEquipmentMaterials = true;
//           }
//         }
//       }
//     });
//   }
//
//   void _toggleMaterialVisibility(bool isPiping) {
//     if (isPiping) {
//       setState(() {
//         _showPipingMaterials = !_showPipingMaterials;
//       });
//     } else {
//       setState(() {
//         _showEquipmentMaterials = !_showEquipmentMaterials;
//       });
//     }
//   }
//
//   void _showEditRequiredMessage() {
//     if (_isToday(_selectedDate)) {
//       _showSnackBar("You can edit today's DPR directly", isError: true);
//     } else {
//       _showSnackBar("Please enable edit mode to make changes", isError: true);
//     }
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted || _isDisposed) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[700] : Colors.green[700],
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: isError ? 3 : 2),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   // ==================== MATERIAL OPERATIONS ====================
//
//   /// Toggle selection mode
//   void _toggleSelectionMode(String category) {
//     setState(() {
//       _isSelectionMode = !_isSelectionMode;
//       _currentCategory = category;
//       if (!_isSelectionMode) {
//         _selectedMaterialIds.clear();
//       }
//     });
//   }
//
//   /// Toggle individual material selection
//   void _toggleMaterialSelection(String materialId) {
//     setState(() {
//       if (_selectedMaterialIds.contains(materialId)) {
//         _selectedMaterialIds.remove(materialId);
//       } else {
//         _selectedMaterialIds.add(materialId);
//       }
//     });
//   }
//
//   /// Select all materials in current category
//   void _selectAllMaterials(List<dynamic> materials) {
//     setState(() {
//       for (var material in materials) {
//         _selectedMaterialIds.add(material.id);
//       }
//     });
//   }
//
//   /// Delete selected materials (bulk delete)
//   Future<void> _deleteSelectedMaterials(String category) async {
//     if (_selectedMaterialIds.isEmpty || _mechanicalId == null) {
//       _showSnackBar('No materials selected', isError: true);
//       return;
//     }
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Selected Materials'),
//         content: Text(
//           'Are you sure you want to delete ${_selectedMaterialIds.length} selected materials?\n\n'
//               'This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed != true) return;
//
//     setState(() => _isLoadingMaterials = true);
//
//     try {
//       // Delete each material
//       for (String materialId in _selectedMaterialIds) {
//         final formData = FormData.fromMap({
//           'materialId': materialId,
//         });
//
//         await DprApi().deleteMaterial(
//           data: formData,
//           mechanicalId: _mechanicalId!,
//         );
//       }
//
//       // Update local state
//       if (category == 'piping') {
//         final materials = ref.read(pipingMaterialsProvider);
//         ref.read(pipingMaterialsProvider.notifier).setMaterials(
//           materials.where((m) => !_selectedMaterialIds.contains(m.id)).toList(),
//         );
//       } else {
//         final materials = ref.read(equipmentMaterialsProvider);
//         ref.read(equipmentMaterialsProvider.notifier).setMaterials(
//           materials.where((m) => !_selectedMaterialIds.contains(m.id)).toList(),
//         );
//       }
//
//       _showSnackBar('Successfully deleted ${_selectedMaterialIds.length} materials');
//
//       setState(() {
//         _selectedMaterialIds.clear();
//         _isSelectionMode = false;
//       });
//
//       // Refresh DPR data
//       await _fetchDprWorkById();
//     } catch (e) {
//       print('❌ Failed to bulk delete: $e');
//       _showSnackBar('Bulk delete failed: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingMaterials = false);
//       }
//     }
//   }
//
//   /// Delete single material
//   Future<void> _deleteMaterial(String materialId, String materialName, String category) async {
//     if (_mechanicalId == null) {
//       _showSnackBar('No DPR work selected', isError: true);
//       return;
//     }
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Material'),
//         content: Text(
//           'Are you sure you want to delete "$materialName"?\n\nThis action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed != true) return;
//
//     setState(() => _updatingMaterialIds.add(materialId));
//
//     try {
//       final formData = FormData.fromMap({
//         'materialId': materialId,
//       });
//
//       await DprApi().deleteMaterial(
//         data: formData,
//         mechanicalId: _mechanicalId!,
//       );
//
//       // Update local state
//       if (category == 'piping') {
//         final materials = ref.read(pipingMaterialsProvider);
//         ref.read(pipingMaterialsProvider.notifier).setMaterials(
//           materials.where((m) => m.id != materialId).toList(),
//         );
//       } else {
//         final materials = ref.read(equipmentMaterialsProvider);
//         ref.read(equipmentMaterialsProvider.notifier).setMaterials(
//           materials.where((m) => m.id != materialId).toList(),
//         );
//       }
//
//       _showSnackBar('Material deleted successfully');
//
//       // Refresh DPR data
//       await _fetchDprWorkById();
//     } catch (e) {
//       print('❌ Failed to delete material: $e');
//       _showSnackBar('Failed to delete: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _updatingMaterialIds.remove(materialId));
//       }
//     }
//   }
//
//   /// Copy/Duplicate material
//   Future<void> _copyMaterial(dynamic material, String category) async {
//     if (_mechanicalId == null) {
//       _showSnackBar('No DPR work selected', isError: true);
//       return;
//     }
//
//     setState(() => _isLoadingMaterials = true);
//
//     try {
//       if (category == 'piping') {
//         final original = material as PipingItem;
//
//         await DprApi.addMechanicalMaterial(
//           dprId: _mechanicalId!,
//           materialName: '${original.materialName} (Copy)',
//           uom: original.uom,
//           file: null,
//         );
//       } else {
//         final original = material as EquipmentItem;
//
//         await DprApi.addMechanicalMaterial(
//           dprId: _mechanicalId!,
//           materialName: '${original.materialName} (Copy)',
//           uom: original.uom,
//           file: null,
//         );
//       }
//
//       _showSnackBar('Material copied successfully');
//
//       // Refresh DPR data
//       await _fetchDprWorkById();
//     } catch (e) {
//       print('❌ Failed to copy material: $e');
//       _showSnackBar('Failed to copy: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingMaterials = false);
//       }
//     }
//   }
//
//   /// Update material field
//   Future<void> _updateMaterialField(
//       String materialId,
//       String field,
//       String value,
//       String category,
//       ) async {
//     if (_mechanicalId == null) return;
//
//     setState(() => _updatingMaterialIds.add(materialId));
//
//     try {
//       final formData = FormData.fromMap({
//         'materialId': materialId,
//         field: _parseValue(field, value),
//       });
//
//       await DprApi().updateMaterial(
//         data: formData,
//         mechanicalId: _mechanicalId!,
//       );
//
//       print('✅ Updated $field for material $materialId');
//
//       // Update local state
//       if (category == 'piping') {
//         final materials = ref.read(pipingMaterialsProvider);
//         final updatedMaterials = materials.map((m) {
//           if (m.id == materialId) {
//             return _updatePipingItem(m, field, value);
//           }
//           return m;
//         }).toList();
//         ref.read(pipingMaterialsProvider.notifier).setMaterials(updatedMaterials);
//       } else {
//         final materials = ref.read(equipmentMaterialsProvider);
//         final updatedMaterials = materials.map((m) {
//           if (m.id == materialId) {
//             return _updateEquipmentItem(m, field, value);
//           }
//           return m;
//         }).toList();
//         ref.read(equipmentMaterialsProvider.notifier).setMaterials(updatedMaterials);
//       }
//     } catch (e) {
//       print('❌ Failed to update material field: $e');
//       _showSnackBar('Failed to update: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _updatingMaterialIds.remove(materialId));
//       }
//     }
//   }
//
//   PipingItem _updatePipingItem(PipingItem item, String field, String value) {
//     switch (field) {
//       case 'qty':
//         return item.copyWith(qty: int.tryParse(value) ?? item.qty);
//       case 'length':
//         return item.copyWith(length: double.tryParse(value) ?? item.length);
//       case 'size':
//         return item.copyWith(size: value);
//       case 'moc':
//         return item.copyWith(moc: value);
//       case 'remarks':
//         return item.copyWith(remarks: value);
//       default:
//         return item;
//     }
//   }
//
//   EquipmentItem _updateEquipmentItem(EquipmentItem item, String field, String value) {
//     switch (field) {
//       case 'qty':
//         return item.copyWith(qty: int.tryParse(value) ?? item.qty);
//       case 'weight':
//         return item.copyWith(weight: double.tryParse(value) ?? item.weight);
//       case 'moc':
//         return item.copyWith(moc: value);
//       case 'remarks':
//         return item.copyWith(remarks: value);
//       default:
//         return item;
//     }
//   }
//
//   dynamic _parseValue(String field, String value) {
//     if (field == 'qty') {
//       return int.tryParse(value) ?? 0;
//     } else if (field == 'length' || field == 'weight') {
//       return double.tryParse(value) ?? 0.0;
//     }
//     return value;
//   }
//
//   // ==================== UI BUILDERS ====================
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     final pipingMaterials = ref.watch(pipingMaterialsProvider);
//     final equipmentMaterials = ref.watch(equipmentMaterialsProvider);
//
//     final hasPipingMaterials = pipingMaterials.isNotEmpty;
//     final hasEquipmentMaterials = equipmentMaterials.isNotEmpty;
//     final shouldShowPiping = _pipeFittingOn && _showPipingMaterials &&
//         hasPipingMaterials;
//     final shouldShowEquipment = _equipmentOn && _showEquipmentMaterials &&
//         hasEquipmentMaterials;
//
//     final shouldShowDropdown = _globalEditMode &&
//         _dprListForSelectedDate.isNotEmpty;
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: NestedScrollView(
//         headerSliverBuilder: (context, innerBoxIsScrolled) {
//           return [
//             CustomSliverAppBar(
//                 title: _isSelectionMode
//                     ? '${_selectedMaterialIds.length} Selected'
//                     : "Add DPR"
//             )
//           ];
//         },
//         body: BottomButtonWrapper(
//           customButtons: [
//             CustomButton(
//               button: RoundedButton(
//                 text: _isSubmitting ? 'Saving..' : 'Save',
//                 color: _isEditable ? const Color(0xFF1B6DCE) : Colors.grey,
//                 textColor: Colors.white,
//                 onPressed: _isSubmitting ? () {} : _handleSubmitFields,
//                 isOutlined: false,
//               ),
//             ),
//           ],
//           child: Column(
//             children: [
//               if (_isLoadingMaterials || _isCreatingWork)
//                 const LinearProgressIndicator(
//                   backgroundColor: Colors.transparent,
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6DCE)),
//                 ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(6),
//                   physics: const BouncingScrollPhysics(),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           _buildEditModeButton(),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       _buildDateSection(),
//                       const SizedBox(height: 16),
//                       _buildDprInfoCard(shouldShowDropdown),
//                       const SizedBox(height: 16),
//                       _buildToggleSection(),
//                       const SizedBox(height: 16),
//
//                       // Material sections with selection mode support
//                       Column(
//                         children: [
//                           if (_pipeFittingOn && hasPipingMaterials)
//                             _buildMaterialToggleCard(
//                               'Pipe Fitting Materials',
//                               pipingMaterials.length,
//                               _showPipingMaterials,
//                                   () => _toggleMaterialVisibility(true),
//                               'piping',
//                             ),
//
//                           if (shouldShowPiping)
//                             ..._buildPipingMaterials(pipingMaterials),
//
//                           if (_equipmentOn && hasEquipmentMaterials)
//                             _buildMaterialToggleCard(
//                               'Equipment Materials',
//                               equipmentMaterials.length,
//                               _showEquipmentMaterials,
//                                   () => _toggleMaterialVisibility(false),
//                               'equipment',
//                             ),
//
//                           if (shouldShowEquipment)
//                             ..._buildEquipmentMaterials(equipmentMaterials),
//
//                           if (_pipeFittingOn && !hasPipingMaterials)
//                             _buildEmptyMaterialsCard(
//                                 'No piping materials available'),
//
//                           if (_equipmentOn && !hasEquipmentMaterials)
//                             _buildEmptyMaterialsCard(
//                                 'No equipment materials available'),
//
//                           if (!_pipeFittingOn && !_equipmentOn &&
//                               _initialDataLoaded)
//                             _buildEmptyState(
//                                 'Materials will appear here once loaded',
//                                 Icons.downloading),
//                         ],
//                       ),
//
//                       const SizedBox(height: 100),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildMaterialToggleCard(
//       String title,
//       int count,
//       bool isExpanded,
//       VoidCallback onToggle,
//       String category,
//       ) {
//     return GestureDetector(
//       onTap: onToggle,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.blue.shade100),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   isExpanded ? Icons.expand_less : Icons.expand_more,
//                   color: Colors.blue,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.blue,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '$count',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.blue,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 if (_isSelectionMode && _currentCategory == category) ...[
//                   IconButton(
//                     icon: const Icon(Icons.close, size: 18),
//                     onPressed: () => _toggleSelectionMode(''),
//                     tooltip: 'Cancel',
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
//                     onPressed: _selectedMaterialIds.isEmpty
//                         ? null
//                         : () => _deleteSelectedMaterials(category),
//                     tooltip: 'Delete Selected',
//                   ),
//                 ] else ...[
//                   if (_isEditable)
//                     IconButton(
//                       icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
//                       onPressed: () => _toggleSelectionMode(category),
//                       tooltip: 'Select Items',
//                     ),
//                   Text(
//                     isExpanded ? 'Hide' : 'Show',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<Widget> _buildPipingMaterials(List<PipingItem> materials) {
//     return materials.map((material) {
//       final isSelected = _selectedMaterialIds.contains(material.id);
//       final isUpdating = _updatingMaterialIds.contains(material.id);
//
//       return Padding(
//         key: ValueKey(
//           material.id.isNotEmpty
//               ? 'piping_${material.id}'
//               : 'piping_${material.materialName}',
//         ),
//         padding: const EdgeInsets.only(bottom: 12),
//         child: Stack(
//           children: [
//             Opacity(
//               opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
//               child: MaterialCardWrapper(
//                 isUpdating: isUpdating,
//                 child: DynamicItemCard(
//                   quantity: material.qty.toString(),
//                   size: _sizeController.text,
//                   length: material.length.toString(),
//                   floor: _floorController.text,
//                   moc: _mocController.text,
//                   image: material.image,
//                   sizeLabel: 'Size',
//                   remark: material.remarks,
//                   lengthLabel: material.materialName,
//                   sizePlaceholder: _sizeController.text,
//                   lengthPlaceholder: material.uom,
//                   onQtyChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _updateMaterialField(material.id, 'qty', val, 'piping'),
//                   onSizeChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _updateMaterialField(material.id, 'size', val, 'piping'),
//                   onLengthChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _updateMaterialField(material.id, 'length', val, 'piping'),
//                   onFloorChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _onPipingFieldChanged(material.id, 'floor', val),
//                   onMocChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _onPipingFieldChanged(material.id, 'moc', val),
//                   onDelete: _isSelectionMode
//                       ? null
//                       : () => _deleteMaterial(material.id, material.materialName, 'piping'),
//                   onRemark: _isSelectionMode
//                       ? () {}
//                       : () => _showRemarkDialog(material.id, material.remarks ?? '', isPiping: true),
//                   onCopy: _isSelectionMode
//                       ? null
//                       : () => _copyMaterial(material, 'piping'),
//                   isEditable: !_isSelectionMode && _isEditable,
//                 ),
//               ),
//             ),
//             if (_isSelectionMode && _currentCategory == 'piping')
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: GestureDetector(
//                   onTap: () => _toggleMaterialSelection(material.id),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: isSelected ? Colors.red : Colors.white,
//                       border: Border.all(
//                         color: Colors.red,
//                         width: 2,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: isSelected
//                         ? const Icon(
//                       Icons.check,
//                       color: Colors.white,
//                       size: 20,
//                     )
//                         : null,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       );
//     }).toList();
//   }
//
//
//
//
//
//   List<Widget> _buildEquipmentMaterials(List<EquipmentItem> materials) {
//     return materials.map((material) {
//       final isSelected = _selectedMaterialIds.contains(material.id);
//       final isUpdating = _updatingMaterialIds.contains(material.id);
//
//       return Padding(
//         key: ValueKey(
//           material.id.isNotEmpty
//               ? 'equipment_${material.id}'
//               : 'equipment_${material.materialName}',
//         ),
//         padding: const EdgeInsets.only(bottom: 12),
//         child: Stack(
//           children: [
//             Opacity(
//               opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
//               child: MaterialCardWrapper(
//                 isUpdating: isUpdating,
//                 child: DynamicItemCard2(
//                   title: material.materialName,
//                   quantity: material.qty.toString(),
//                   image: material.image,
//                   floor: _floorController.text,
//                   moc: _mocController.text,
//                   size: _sizeController.text,
//                   ton: material.weight.toString(),
//                   meter: material.uom,
//                   remark: material.remarks,
//                   onMocChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _onEquipmentFieldChanged(material.id, 'moc', val),
//                   onQtyChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _updateMaterialField(material.id, 'qty', val, 'equipment'),
//                   onFloorChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _onEquipmentFieldChanged(material.id, 'floor', val),
//                   onTonChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) => _updateMaterialField(material.id, 'weight', val, 'equipment'),
//                   onMeterChanged: _isSelectionMode
//                       ? (_) {}
//                       : (val) {},
//                   onDelete: _isSelectionMode
//                       ? null
//                       : () => _deleteMaterial(material.id, material.materialName, 'equipment'),
//                   onRemark: _isSelectionMode
//                       ? () {}
//                       : () => _showRemarkDialog(material.id, material.remarks ?? '', isPiping: false),
//                   onCopy: _isSelectionMode
//                       ? null
//                       : () => _copyMaterial(material, 'equipment'),
//                   isEditable: !_isSelectionMode && _isEditable,
//                 ),
//               ),
//             ),
//             if (_isSelectionMode && _currentCategory == 'equipment')
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: GestureDetector(
//                   onTap: () => _toggleMaterialSelection(material.id),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: isSelected ? Colors.red : Colors.white,
//                       border: Border.all(
//                         color: Colors.red,
//                         width: 2,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: isSelected
//                         ? const Icon(
//                       Icons.check,
//                       color: Colors.white,
//                       size: 20,
//                     )
//                         : null,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       );
//     }).toList();
//   }
//
// // Update the _showRemarkDialog to use the update API
//   void _showRemarkDialog(String materialId, String currentRemark, {bool isPiping = true}) {
//     final remarkController = TextEditingController(text: currentRemark);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Add Remark'),
//         content: TextField(
//           controller: remarkController,
//           maxLines: 3,
//           decoration: InputDecoration(
//             hintText: 'Enter remark...',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _updateMaterialField(
//                 materialId,
//                 'remarks',
//                 remarkController.text,
//                 isPiping ? 'piping' : 'equipment',
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1B6DCE),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             ),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
