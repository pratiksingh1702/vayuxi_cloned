import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/rate_file_isar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/rate_image_resolver.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/test_dynamic.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../../../../../core/local/isar_db.dart';
import '../../dpr-setup/screens/add/add_material.dart';
import '../../models/data/eqipment_provider.dart';
import '../../models/data/piping_provider.dart';
import '../../models/equipmentModel.dart';
import '../../models/pipingModel.dart';
import '../../models/rate_file_models.dart';
import '../../offline/mech/repo/rate_Repo.dart';
import '../../offline/mech/repo/sync_controller.dart';
import '../../providers/material_service.dart';
import '../../providers/rate_variant_provider.dart';
import '../../providers/service/rate_upload_material_dpr.dart';
import 'calculation/expand_wrapper.dart';
import 'dynamic_item_card.dart';
import 'dynamic_item_card2.dart';
import 'edit_material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../dpr-setup/screens/add/add_material.dart';
import '../../models/data/eqipment_provider.dart';
import '../../models/data/piping_provider.dart';
import '../../models/equipmentModel.dart';
import '../../models/pipingModel.dart';
import '../../providers/material_service.dart';
import 'dynamic_item_card.dart';
import 'dynamic_item_card2.dart';
import 'edit_material.dart';

class AllMaterialsScreen extends ConsumerStatefulWidget {
  const AllMaterialsScreen({
    super.key,
  });

  @override
  ConsumerState<AllMaterialsScreen> createState() => _AllMaterialsScreenState();
}

class _AllMaterialsScreenState extends ConsumerState<AllMaterialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? editingMaterialId;

  bool _isLoading = false;
  bool _isInitialized = false;
  final DefaultMaterialService _materialService = DefaultMaterialService();
  String? siteId;
  bool _isSetupCompleted = false;
  String? draftCategoryId;

  // Selection mode test
  bool _isSelectionMode = false;
  Set<String> _selectedMaterialIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize materials from the Default Material API
  Future<void> _initializeMaterials() async {
    if (_isInitialized || siteId == null) return;

    setState(() => _isLoading = true);

    try {
      final materials = await _materialService.getDefaultMaterials(
        siteId: siteId,
      );
      _isSetupCompleted = true;

      final pipingMaterials = materials.whereType<PipingItem>().toList();
      final equipmentMaterials = materials.whereType<EquipmentItem>().toList();

      ref.read(pipingMaterialsProvider.notifier).setMaterials(pipingMaterials);
      ref
          .read(equipmentMaterialsProvider.notifier)
          .setMaterials(equipmentMaterials);

      _isInitialized = true;

      debugPrint('✅ Loaded ${pipingMaterials.length} piping materials');
      debugPrint('✅ Loaded ${equipmentMaterials.length} equipment materials');
    } catch (e, st) {
      debugPrint('❌ Failed to initialize materials: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load materials: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Refresh materials from server
  Future<void> _refreshMaterials() async {
    setState(() => _isLoading = true);

    try {
      final materials = await _materialService.getDefaultMaterials(
        siteId: siteId,
      );

      final pipingMaterials = materials.whereType<PipingItem>().toList();
      final equipmentMaterials = materials.whereType<EquipmentItem>().toList();

      ref.read(pipingMaterialsProvider.notifier).setMaterials(pipingMaterials);
      ref
          .read(equipmentMaterialsProvider.notifier)
          .setMaterials(equipmentMaterials);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materials refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh materials: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url
        .trim()
        .replaceAll(RegExp(r'%20+$'), '')
        .replaceAll(RegExp(r'\s+$'), '');
  }

  /// Toggle selection mode
  void _toggleSelectionMode(String category) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMaterialIds.clear();
      }
    });
  }

  /// Toggle individual material selection
  void _toggleMaterialSelection(String materialId) {
    setState(() {
      if (_selectedMaterialIds.contains(materialId)) {
        _selectedMaterialIds.remove(materialId);
      } else {
        _selectedMaterialIds.add(materialId);
      }
    });
  }

  /// Select all materials in current category
  void _selectAllMaterials(List<dynamic> materials) {
    setState(() {
      for (var material in materials) {
        _selectedMaterialIds.add(material.id);
      }
    });
  }

  /// Delete selected materials
  Future<void> _deleteSelectedMaterials(String category) async {
    if (_selectedMaterialIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No materials selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Materials'),
        content: Text(
          'Are you sure you want to delete ${_selectedMaterialIds.length} selected materials?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final siteId = ref.read(selectedSiteIdProvider)!;
      final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
      final rateUploadId = rateFileMeta['rateFileId'] as String?;

      if (rateUploadId == null) {
        throw Exception("Rate upload not initialized");
      }

      await RateUploadApi.bulkDeleteLineItems(
        rateUploadId: rateUploadId,
        materialIds: _selectedMaterialIds.toList(),
      );

// 🔥 FORCE BACKGROUND SYNC (THIS WAS MISSING)
      final repo = RateRepository(AppIsarDB.isar);
      await repo.syncRateFile(siteId);
      await AppIsarDB.isar.writeTxn(() async {
        await AppIsarDB.isar.rateFileMaterialIsars
            .filter()
            .anyOf(
              _selectedMaterialIds.toList(),
              (q, id) => q.materialIdEqualTo(id),
            )
            .deleteAll();
      });

// 🔄 now refresh providers
      ref.invalidate(rateFileAnalysisProvider(siteId));

      if (category == 'piping') {
        final materials = ref.read(pipingMaterialsProvider);
        ref.read(pipingMaterialsProvider.notifier).setMaterials(
              materials
                  .where((m) => !_selectedMaterialIds.contains(m.id))
                  .toList(),
            );
      } else {
        final materials = ref.read(equipmentMaterialsProvider);
        ref.read(equipmentMaterialsProvider.notifier).setMaterials(
              materials
                  .where((m) => !_selectedMaterialIds.contains(m.id))
                  .toList(),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully deleted ${_selectedMaterialIds.length} materials'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedMaterialIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PipingItem> _toApprovedPipingItems(
    List<RateFileMaterial> materials,
  ) {
    return materials.where((m) => m.availableVariants.isNotEmpty).map((m) {
      final v = m.availableVariants.first;

      final item = PipingItem.fromRateMaterial(m, v);
      return item.copyWith(
        image: m.image.isNotEmpty
            ? m.image
            : m.resolveImage(),
      );

    }).toList();
  }

  List<EquipmentItem> _toApprovedEquipmentItems(
    List<RateFileMaterial> materials,
  ) {
    return materials.where((m) => m.availableVariants.isNotEmpty).map((m) {
      final v = m.availableVariants.first;

      final item = EquipmentItem.fromRateMaterial(m, v);

      return item.copyWith(
        image: m.resolveImage(), // 🔥 HERE
      );
    }).toList();
  }

  Future<void> _copyRateLineItem({
    required String siteId,
    required String rateUploadId,
    required String lineItemId,
  }) async {
    try {
      setState(() => _isLoading = true);

      await RateUploadApi.copyLineItem(
        rateUploadId: rateUploadId,
        lineItemId: lineItemId,
      );

      ref.invalidate(rateFileAnalysisProvider(siteId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Line item copied successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Copy line item failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copy failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectSelectedMaterials({
    required String siteId,
    required String rateUploadId,
  }) async {
    if (_selectedMaterialIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No materials selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reason = await _askRejectReason();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await RateUploadApi.rejectMaterials(
        rateUploadId: rateUploadId,
        materialIds: _selectedMaterialIds.toList(),
        rejectionReason: reason.trim(),
      );

      // Refresh UI
      ref.invalidate(rateFileAnalysisProvider(siteId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedMaterialIds.length} materials rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _selectedMaterialIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint("❌ Reject failed: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reject failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _askRejectReason() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Reject Materials"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter rejection reason...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRateLineItem({
    required String siteId,
    required String rateUploadId,
    required String lineItemId,
    required String materialName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Material"),
        content: Text('Are you sure you want to delete "$materialName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await RateUploadApi.deleteLineItem(
        rateUploadId: rateUploadId,
        lineItemId: lineItemId,
      );

      ref.invalidate(rateFileAnalysisProvider(siteId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Line item deleted"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Delete line item failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveSelectedMaterials({
    required String siteId,
    required String rateUploadId,
  }) async {
    if (_selectedMaterialIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No materials selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Materials'),
        content: Text(
          'Approve ${_selectedMaterialIds.length} selected materials?\n\n'
          'They will move to Approved list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await RateUploadApi.approveMaterials(
        rateUploadId: rateUploadId,
        materialIds: _selectedMaterialIds.toList(),
      );
      final repo = RateRepository(AppIsarDB.isar);
      await repo.syncRateFile(siteId);

      // 🔄 refresh rate file everywhere
      ref.invalidate(rateFileAnalysisProvider(siteId));
//////////
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedMaterialIds.length} materials approved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedMaterialIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider)!;
    ref.watch(rateSyncControllerProvider(siteId));

    final detected = ref.watch(detectedFieldsProvider(siteId));

    final bool showFloor = detected?.hasFloor == true;
    final bool showElevation = !showFloor && detected?.hasElevation == true;

// approved
    final approvedPipingRateMaterials =
        ref.watch(approvedPipingMaterialsProvider(siteId));
    final approvedEquipmentRateMaterials =
        ref.watch(approvedEquipmentMaterialsProvider(siteId));

// suggested
    final suggestedPipingRateMaterials =
        ref.watch(suggestedPipingMaterialsProvider(siteId));
    final suggestedEquipmentRateMaterials =
        ref.watch(suggestedEquipmentMaterialsProvider(siteId));

    return Stack(children: [
      Scaffold(
        backgroundColor: AppColors.lightBlue,
        appBar: CustomAppBar(
          title: _isSelectionMode
              ? '${_selectedMaterialIds.length} Selected'
              : 'All Materials',
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(
                      text: 'Piping Materials',
                      icon: Icon(Icons.precision_manufacturing),
                    ),
                    Tab(
                      text: 'Equipment Materials',
                      icon: Icon(Icons.build),
                    ),
                    Tab(text: 'Suggested', icon: Icon(Icons.search)),
                  ],
                ),
              ),
              if (_isLoading && _isInitialized) const LinearProgressIndicator(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ✅ APPROVED – PIPING
                    _buildMaterialsTab(
                      materials:
                          _toApprovedPipingItems(approvedPipingRateMaterials),
                      icon: Icons.precision_manufacturing,
                      color: Colors.blue,
                      emptyMessage: 'No approved piping materials',
                      category: 'piping',
                    ),

                    // ✅ APPROVED – EQUIPMENT
                    _buildMaterialsTab(
                      materials: _toApprovedEquipmentItems(
                          approvedEquipmentRateMaterials),
                      icon: Icons.build,
                      color: Colors.green,
                      emptyMessage: 'No approved equipment materials',
                      category: 'equipment',
                    ),

                    // 💡 SUGGESTED TAB
                    _buildSuggestedTab(
                      suggestedPipingRateMaterials,
                      suggestedEquipmentRateMaterials,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (_isLoading)
        Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ]);
  }

  Widget _buildSuggestedTab(
    List<RateFileMaterial> piping,
    List<RateFileMaterial> equipment,
  ) {
    List<PipingItem> pipingItems = {
      for (final m in _toApprovedPipingItems(piping)) m.id: m,
    }.values.toList();

    List<EquipmentItem> equipmentItems = {
      for (final m in _toApprovedEquipmentItems(equipment)) m.id: m,
    }.values.toList();

    if (pipingItems.isEmpty && equipmentItems.isEmpty) {
      return const Center(
        child: Text('No suggested materials'),
      );
    }
    final siteid = ref.read(selectedSiteIdProvider);

    final rateFileMeta = ref.read(rateFileMetaProvider(siteid!));
    final rateUploadId = rateFileMeta['rateFileId'] as String?;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 🔹 TOP ACTION BAR (Approve flow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Row(
                  children: [
                    if (_isSelectionMode) ...[
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedMaterialIds.clear();
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          final allSuggested = [
                            ...pipingItems,
                            ...equipmentItems,
                          ];
                          _selectAllMaterials(allSuggested);
                        },
                        child: const Text('Select All'),
                      ),

                      // ✅ APPROVE button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        onPressed: rateUploadId == null
                            ? null
                            : () {
                                final siteid =
                                    ref.read(selectedSiteIdProvider)!;
                                _approveSelectedMaterials(
                                  siteId: siteid,
                                  rateUploadId: rateUploadId,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ✅ REJECT button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        onPressed: rateUploadId == null
                            ? null
                            : () {
                                final siteid =
                                    ref.read(selectedSiteIdProvider)!;
                                _rejectSelectedMaterials(
                                  siteId: siteid,
                                  rateUploadId: rateUploadId,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text('Select'),
                        onPressed: () {
                          setState(() => _isSelectionMode = true);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 🔹 INNER TAB BAR
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(
                  text: 'Piping',
                  icon: Icon(Icons.precision_manufacturing),
                ),
                Tab(
                  text: 'Equipment',
                  icon: Icon(Icons.build),
                ),
              ],
            ),
          ),

          // 🔹 INNER TAB VIEW
          Expanded(
            child: TabBarView(
              children: [
                // Suggested Piping
                pipingItems.isEmpty
                    ? const Center(
                        child: Text('No suggested piping materials'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: pipingItems.length,
                        itemBuilder: (context, index) {
                          print(pipingItems[index].image);
                          return _buildPipingCard(
                            pipingItems[index],
                            Colors.orange,
                          );
                        },
                      ),

                // Suggested Equipment
                equipmentItems.isEmpty
                    ? const Center(
                        child: Text('No suggested equipment materials'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: equipmentItems.length,
                        itemBuilder: (context, index) {
                          return _buildEquipmentCard(
                            equipmentItems[index],
                            Colors.orange,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMaterialsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No materials found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have deleted all materials.\nAdd a new one to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Material'),
            onPressed: () => _addNewMaterial('piping'), // or show choice dialog
          ),
        ],
      ),
    );
  }

  Widget _buildSetupDprState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 24),

            const Text(
              'No Materials Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            const Text(
              'Either DPR materials are not set up yet\n'
              'or all materials have been deleted.\n\n'
              'You can set up default DPR materials\n'
              'or directly add a new material.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),

            // ✅ PRIMARY ACTIONS
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Setup DPR Materials'),
                  onPressed: _showSetupDprDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material Manually'),
                  onPressed: () => _showAddMaterialSheet(), // or show chooser
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMaterialSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.precision_manufacturing),
              title: const Text('Add Piping Material'),
              onTap: () {
                Navigator.pop(context);
                _addNewMaterial('piping');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Add Equipment Material'),
              onTap: () {
                Navigator.pop(context);
                _addNewMaterial('equipment');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show setup DPR dialog with options
  Future<void> _showSetupDprDialog() async {
    String selectedDesignation = 'both';
    bool isApplied = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Setup DPR Materials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select material type to setup:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Both (Piping + Equipment)'),
                value: 'both',
                groupValue: selectedDesignation,
                onChanged: (value) {
                  setDialogState(() => selectedDesignation = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Piping Only'),
                value: 'piping',
                groupValue: selectedDesignation,
                onChanged: (value) {
                  setDialogState(() => selectedDesignation = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Equipment Only'),
                value: 'equipment',
                groupValue: selectedDesignation,
                onChanged: (value) {
                  setDialogState(() => selectedDesignation = value!);
                },
              ),
              const Divider(height: 24),
              CheckboxListTile(
                title: const Text('Apply to all sites'),
                subtitle: const Text(
                    'Make these materials available across all sites'),
                value: isApplied,
                onChanged: (value) {
                  setDialogState(() => isApplied = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'designation': selectedDesignation,
                'isApplied': isApplied,
              }),
              child: const Text('Setup'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _handleSetupDpr(
        designation: result['designation'],
        isApplied: result['isApplied'],
      );
    }
  }

  Future<void> _handleSetupDpr({
    required String designation,
    required bool isApplied,
  }) async {
    if (siteId == null) return;

    setState(() => _isLoading = true);

    try {
      await _materialService.setupDpr(
        siteId: siteId!,
        designation: designation,
        isApplied: isApplied,
      );

      _isSetupCompleted = true; // ✅ IMPORTANT

      await _refreshMaterials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'DPR materials initialized successfully'
              '${isApplied ? ' and applied to all sites' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMaterialsTab({
    required List<dynamic> materials,
    required IconData icon,
    required Color color,
    required String emptyMessage,
    required String category,
  }) {
    if (materials.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSelectionMode
                    ? '${_selectedMaterialIds.length} / ${materials.length} selected'
                    : 'Total ${category == 'piping' ? 'Piping' : 'Equipment'}: ${materials.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Row(
                children: [
                  if (_isSelectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _toggleSelectionMode(''),
                    ),
                    TextButton(
                      onPressed: () => _selectAllMaterials(materials),
                      child: const Text('Select All'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Delete'),
                      onPressed: _selectedMaterialIds.isEmpty
                          ? null
                          : () => _deleteSelectedMaterials(category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      icon: Icon(Icons.filter_list, color: color),
                      onPressed: () => _showFilterOptions(context, category),
                      tooltip: 'Filter',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      onPressed: materials.isEmpty
                          ? null
                          : () => _toggleSelectionMode(category),
                      tooltip: 'Select Items',
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: color),
                      onPressed: () => _addNewMaterial(category),
                      tooltip: 'Add Material',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshMaterials,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                if (category == 'piping') {
                  final material = materials[index] as PipingItem;
                  return _buildPipingCard(material, color);
                } else {
                  final material = materials[index] as EquipmentItem;
                  return _buildEquipmentCard(material, color);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipingCard(PipingItem material, Color color,
      {bool isSuggested = false}) {
    final imageUrl = _cleanImageUrl(material.image);
    final isSelected = _selectedMaterialIds.contains(material.id);
    final siteId = ref.read(selectedSiteIdProvider)!;
    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));

    final detected = ref.watch(detectedFieldsProvider(siteId));

    final bool showFloor = detected?.hasFloor == true;
    final bool showElevation = !showFloor && detected?.hasElevation == true;

    final rateUploadId = rateFileMeta['rateFileId'] as String?;
    print("🧠 UI IMAGE = ${material.image}");


    return Stack(
      children: [
        Opacity(
            opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
            child:ExpandableMaterialCard(
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
                key: ValueKey(material.id + material.image),

                isDpr: false,


                  image: material.image,
                  lengthLabel: material.materialName,
                  lengthPlaceholder: material.uom,
                  fields: material.dynamicFields,

                  isEditable: !_isSelectionMode && editingMaterialId == null,

                  isEditMode: editingMaterialId == material.id,

                  onCancel: () {
                    setState(() => editingMaterialId = null);
                  },

                    onSave: (result) async {
                      try {
                        setState(() => _isLoading = true);
                        print("🥲🥲🥲🥲🥲🥲 $draftCategoryId");

                        final formData = FormData.fromMap({
                          "materialName": result.name,
                          "uom": result.uom,
                          "designation": material.designation,
                          "calculationCategory": draftCategoryId,
                          "isApplied": false,
                          "dynamicFields":
                          jsonEncode(result.fields.map((e) => e.toJson()).toList()),

                          if (result.imageFile != null)
                            "image": await MultipartFile.fromFile(
                              result.imageFile!.path,
                              filename: result.imageFile!.path.split('/').last,
                            ),
                        });
                        print("📤 sending image = ${result.imageFile?.path}");
                        print("📤 fields = ${jsonEncode(result.fields.map((e) => e.toJson()).toList())}");


                        await RateUploadApi.updateLineItem(
                          rateUploadId: rateUploadId!,
                          lineItemId: material.id,
                          data: formData,
                        );

                        final repo = RateRepository(AppIsarDB.isar);
                        await repo.syncRateFile(siteId);

                        ref.invalidate(rateFileAnalysisProvider(siteId));
                        ref.invalidate(approvedPipingMaterialsProvider(siteId));
                        ref.invalidate(approvedEquipmentMaterialsProvider(siteId));
                        ref.invalidate(suggestedPipingMaterialsProvider(siteId));
                        ref.invalidate(suggestedEquipmentMaterialsProvider(siteId));
                        ref.invalidate(allRateVariantsProvider);

                        setState(() {
                          editingMaterialId = null;
                          draftCategoryId = null;
                        });

                      } catch (e) {
                        print("❌ save failed $e");
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },


                  onChanged: (key, value) {
                    _updatePipingField(material.id, key, value);
                  },

                  onEdit: _isSelectionMode
                      ? null
                      : () {
                    setState(() {
                      editingMaterialId = material.id;
                    });
                  },

                  onDelete: editingMaterialId != null || rateUploadId == null
                      ? null
                      : () => _deleteRateLineItem(
                    siteId: siteId,
                    rateUploadId: rateUploadId,
                    lineItemId: material.id,
                    materialName: material.materialName,
                  ),

                  onCopy: editingMaterialId != null || rateUploadId == null
                      ? null
                      : () => _copyRateLineItem(
                    siteId: siteId,
                    rateUploadId: rateUploadId,
                    lineItemId: material.rateFileId ?? '',
                  ),

                  onAdd: editingMaterialId != null
                      ? null
                      : () => _copyMaterial(material, 'piping'),

                  quantity: '',
                  size: '',
                  length: '',
                  floor: '',
                  moc: '',
                  sizeLabel: '',
                  sizePlaceholder: '',
                  onQtyChanged: (_) {},
                  onSizeChanged: (_) {},
                  onLengthChanged: (_) {},
                  onFloorChanged: (_) {},
                  onMocChanged: (_) {}, onRemark: () {  },
                ),

            )),
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleMaterialSelection(material.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.white,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildEquipmentCard(EquipmentItem material, Color color,
      {bool isSuggested = false}) {
    final isSelected = _selectedMaterialIds.contains(material.id);
    final siteId = ref.read(selectedSiteIdProvider)!;
    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
    final rateUploadId = rateFileMeta['rateFileId'] as String?;

    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: ExpandableMaterialCard(
            categoryId: editingMaterialId == material.id
                ? draftCategoryId
                : material.calculationCategory,
            isEditMode: editingMaterialId == material.id,
            onCategoryChanged: (newId) {
              setState(() {
                draftCategoryId = newId;
              });
            },
            child: DynamicItemCard2(
              key: ValueKey(material.id + (material.image ?? '')),
              isDpr: false,
              image: material.image,
              title: material.materialName,
              quantity: material.qty.toString(),
              moc: material.moc,
              fields: material.dynamicFields,
              isEditMode: editingMaterialId == material.id,
              isEditable: !_isSelectionMode && editingMaterialId == null,
              onCancel: () {
                setState(() => editingMaterialId = null);
              },
              onSave: (result) async {
                try {
                  setState(() => _isLoading = true);

                  final formData = FormData.fromMap({
                    "materialName": result.name,
                    "uom": result.uom,
                    "designation": material.designation,
                    "calculationCategory": draftCategoryId,
                    "isApplied": false,
                    "dynamicFields":
                    jsonEncode(result.fields.map((e) => e.toJson()).toList()),
                    if (result.imageFile != null)
                      "image": await MultipartFile.fromFile(
                        result.imageFile!.path,
                        filename: result.imageFile!.path.split('/').last,
                      ),
                  });

                  await RateUploadApi.updateLineItem(
                    rateUploadId: rateUploadId!,
                    lineItemId: material.id,
                    data: formData,
                  );

                  final repo = RateRepository(AppIsarDB.isar);
                  await repo.syncRateFile(siteId);

                  ref.invalidate(rateFileAnalysisProvider(siteId));
                  ref.invalidate(approvedPipingMaterialsProvider(siteId));
                  ref.invalidate(approvedEquipmentMaterialsProvider(siteId));
                  ref.invalidate(suggestedPipingMaterialsProvider(siteId));
                  ref.invalidate(suggestedEquipmentMaterialsProvider(siteId));

                  setState(() {
                    editingMaterialId = null;
                    draftCategoryId = null;
                  });
                } catch (e) {
                  debugPrint("❌ equipment save failed: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Save failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              onChanged: (key, value) {
                _updateEquipmentField(material.id, key, value);
              },
              onEdit: _isSelectionMode
                  ? null
                  : () {
                setState(() {
                  editingMaterialId = material.id;
                  draftCategoryId = material.calculationCategory;
                });
              },
              onDelete: editingMaterialId != null || rateUploadId == null
                  ? null
                  : () => _deleteRateLineItem(
                siteId: siteId,
                rateUploadId: rateUploadId,
                lineItemId: material.rateFileId ?? '',
                materialName: material.materialName,
              ),
              onCopy: editingMaterialId != null || rateUploadId == null
                  ? null
                  : () => _copyRateLineItem(
                siteId: siteId,
                rateUploadId: rateUploadId,
                lineItemId: material.rateFileId ?? '',
              ),
              onAdd: editingMaterialId != null
                  ? null
                  : () => _copyMaterial(material, 'equipment'),
              onRemark: _isSelectionMode
                  ? () {}
                  : () => _showRemarksDialog(material, 'equipment'),
              // legacy field callbacks (still needed for DPR mode)
              floor: '',
              ton: material.weight.toString(),
              meter: material.length.toString(),
              onQtyChanged: (_) {},
              onTonChanged: (_) {},
              onFloorChanged: (_) {},
              onMocChanged: (_) {},
              onMeterChanged: (_) {},
            ),
          ),
        ),
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleMaterialSelection(material.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.white,
                  border: Border.all(color: Colors.red, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
      ],
    );
  }


  Future<void> _updatePipingField(String id, String field, String value) async {
    try {
      final updates = {field: _parseValue(field, value)};
      await ref
          .read(pipingMaterialsProvider.notifier)
          .updatePipingMaterialField(id, updates);
    } catch (e) {
      debugPrint('❌ Failed to update piping field: $e');
    }
  }

  Future<void> _updateEquipmentField(
      String id, String field, String value) async {
    try {
      final updates = {field: _parseValue(field, value)};
      await ref
          .read(equipmentMaterialsProvider.notifier)
          .updateEquipmentMaterialField(id, updates);
    } catch (e) {
      debugPrint('❌ Failed to update equipment field: $e');
    }
  }

  dynamic _parseValue(String field, String value) {
    if (field == 'qty' ||
        field == 'length' ||
        field == 'weight' ||
        field == 'diameter' ||
        field == 'power') {
      return double.tryParse(value) ?? 0.0;
    }
    return value;
  }

  void _editMaterial(dynamic material, String category) {
    if (material is PipingItem) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'piping',
            pipingMaterial: material,
          ),
        ),
      )
          .then((_) {
        _refreshMaterials();
      });
    } else if (material is EquipmentItem) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'equipment',
            equipmentMaterial: material,
          ),
        ),
      )
          .then((_) {
        _refreshMaterials();
      });
    }
  }

  Future<void> _copyMaterial(dynamic material, String category) async {
    try {
      final materialId = material.id;
      debugPrint('🔄 Copying material: $materialId');

      if (category == 'piping') {
        final materials = ref.read(pipingMaterialsProvider);
        final original = materials.firstWhere((m) => m.id == materialId);

        await _materialService.createMaterial(
          materialName: '${original.materialName}',
          uom: original.uom,
          calculationCategory: original.calculationCategory,
          designation: 'piping',
          siteId: siteId,
          isApplied: false,
        );
      } else {
        final materials = ref.read(equipmentMaterialsProvider);
        final original = materials.firstWhere((m) => m.id == materialId);

        await _materialService.createMaterial(
          materialName: '${original.materialName} (Copy)',
          uom: original.uom,
          calculationCategory: original.calculationCategory,
          designation: 'equipment',
          siteId: siteId,
          isApplied: false,
        );
      }

      await _refreshMaterials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material copied successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to copy material: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMaterial(
      String materialId, String materialName, String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text(
          'Are you sure you want to delete "$materialName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _materialService.deleteMaterial(materialId);

      if (category == 'piping') {
        final notifier = ref.read(pipingMaterialsProvider.notifier);
        final materials = ref.read(pipingMaterialsProvider);
        notifier
            .setMaterials(materials.where((m) => m.id != materialId).toList());
      } else {
        final notifier = ref.read(equipmentMaterialsProvider.notifier);
        final materials = ref.read(equipmentMaterialsProvider);
        notifier
            .setMaterials(materials.where((m) => m.id != materialId).toList());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to delete material: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewMaterial(String category) {
    final siteID=ref.read(selectedSiteIdProvider)!;
    final rateFileMeta = ref.read(rateFileMetaProvider(siteID));





    final rateUploadId = rateFileMeta['rateFileId'] as String?;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => PersistDPRScreen(
          designation: category,
          rateUploadId:rateUploadId ,
        ),
      ),
    )
        .then((_) {
      _refreshMaterials();
    });
  }

  void _showRemarksDialog(dynamic material, String category) {
    final remarksController =
        TextEditingController(text: material.remarks ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remarks for ${material.materialName}'),
        content: TextField(
          controller: remarksController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your remarks here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (category == 'piping') {
                _updatePipingField(
                    material.id, 'remarks', remarksController.text);
              } else {
                _updateEquipmentField(
                    material.id, 'remarks', remarksController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context, String category) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter ${category == 'piping' ? 'Piping' : 'Equipment'} Materials',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('By MOC', Icons.category),
            _buildFilterOption('By Floor', Icons.construction),
            _buildFilterOption('By Calculation Category', Icons.calculate),
            _buildFilterOption('By UOM', Icons.straighten),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Clear Filters'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Implement filter logic
      },
    );
  }
}
