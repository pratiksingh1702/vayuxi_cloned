import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/service/insulation_dpr_service.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/widgets/piping_card.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';


import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../offline/data/constants/material_constants.dart';
import '../../offline/data/local/local_material.dart';
import '../../offline/data/repo/material_provider.dart';
import '../../offline/data/repo/material_repo_provider.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';
import '../widgets/equipment_card.dart';

class AllInsulationMaterialsScreen extends ConsumerStatefulWidget {
  const AllInsulationMaterialsScreen({super.key});

  @override
  ConsumerState<AllInsulationMaterialsScreen> createState() => _AllInsulationMaterialsScreenState();
}

class _AllInsulationMaterialsScreenState extends ConsumerState<AllInsulationMaterialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selection mode state
  bool _isSelectionMode = false;
  Set<int> _selectedMaterialIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ CONVERT LocalMaterial → PipingMaterial (UI edge only)
  PipingMaterial _toPiping(LocalMaterial m) {
    if (m.materialDataJson != null) {
      return PipingMaterial.fromJson(
        jsonDecode(m.materialDataJson!),
      );
    }

    // fallback first time
    final material = PipingMaterial(
      id: m.serverId ?? m.id.toString(),
      name: m.name,
      image: m.images,
      uom: m.uom ?? '',
      size: '',
      sizeUom: 'inch',
      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',
    );

    // 🔥 persist initial json
    m.materialDataJson = jsonEncode(material.toJson());

    return material;
  }
  // ✅ CONVERT LocalMaterial → EquipmentMaterial
  EquipmentMaterial _toEquipment(LocalMaterial m) {
    return EquipmentMaterial(
      id: m.serverId ?? m.id.toString(),
      name: m.name,
      image: m.images,
      uom: m.uom ?? '',

      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',
    );
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMaterialIds.clear();
      }
    });
  }

  /// Toggle individual material selection
  void _toggleMaterialSelection(int materialId) {
    setState(() {
      if (_selectedMaterialIds.contains(materialId)) {
        _selectedMaterialIds.remove(materialId);
      } else {
        _selectedMaterialIds.add(materialId);
      }
    });
  }

  /// Select all materials in current category
  void _selectAllMaterials(List<LocalMaterial> materials) {
    setState(() {
      for (var material in materials) {
        _selectedMaterialIds.add(material.id);
      }
    });
  }
  Future<void> _updatePipingMaterial(
      LocalMaterial local,
      PipingMaterial updated,
      ) async {
    final repo = ref.read(materialRepositoryProvider);
    print(local.materialDataJson);

    local
      ..name = updated.name
      ..uom = updated.uom
      ..images = updated.image
      ..materialDataJson = jsonEncode(updated.toJson())
      ..isDirty = false
      ..updatedAt = DateTime.now();

    await repo.update(local);
  }
  // 1. UPDATE METHOD — add this alongside _updatePipingMaterial
  Future<void> _updateEquipmentMaterial(
      LocalMaterial local,
      EquipmentMaterial updated,
      ) async {
    final repo = ref.read(materialRepositoryProvider);
    print(local.materialDataJson);

    local
      ..name = updated.name
      ..uom = updated.uom
      ..images = updated.image
      ..materialDataJson = jsonEncode(updated.toJson())
      ..isDirty = false
      ..updatedAt = DateTime.now();

    await repo.update(local);
  }
  /// Delete selected materials (OFFLINE)
  Future<void> _deleteSelectedMaterials(List<LocalMaterial> materials) async {
    if (_selectedMaterialIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Materials'),
        content: Text(
          'Delete ${_selectedMaterialIds.length} materials?',
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

    try {
      final repo = ref.read(materialRepositoryProvider);

      // 🔥 Get selected materials
      final selectedMaterials = materials
          .where((m) => _selectedMaterialIds.contains(m.id))
          .toList();

      // 🔥 Extract server IDs (ignore null ones)
      final serverIds = selectedMaterials
          .where((m) => m.serverId != null)
          .map((m) => m.serverId!)
          .toList();

      // 🔥 1. Delete on server first
      if (serverIds.isNotEmpty) {
        await InsulationDprApi.bulkDeleteMaterials(ids: serverIds);
      }

      // 🔥 2. Delete locally
      for (final material in selectedMaterials) {
        await repo.delete(material);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${selectedMaterials.length} materials'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedMaterialIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Bulk delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);

    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text('No site selected')),
      );
    }

    // ✅ READ FROM OFFLINE REPOSITORY
    final pipingAsync = ref.watch(materialsStreamProvider((
    siteId: siteId,
    domain: MaterialDomain.insulation.key,
    designation: MaterialDesignation.piping.key,
    )));

    final equipmentAsync = ref.watch(materialsStreamProvider((
    siteId: siteId,
    domain: MaterialDomain.insulation.key,
    designation: MaterialDesignation.equipment.key,
    )));

    return Scaffold(
      drawer: CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: _isSelectionMode
            ? '${_selectedMaterialIds.length} Selected'
            : 'Insulation Materials',
      ),
      body: pipingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pipingMaterials) {
          final equipmentMaterials = equipmentAsync.value ?? [];

          return _buildBody(
            siteId: siteId,
            pipingMaterials: pipingMaterials,
            equipmentMaterials: equipmentMaterials,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required String siteId,
    required List<LocalMaterial> pipingMaterials,
    required List<LocalMaterial> equipmentMaterials,
  }) {
    final bool isEmpty = pipingMaterials.isEmpty && equipmentMaterials.isEmpty;

    if (isEmpty) {
      return _buildSetupState(siteId);
    }

    return SafeArea(
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
                  text: 'Piping Insulation',
                  icon: Icon(Icons.precision_manufacturing),
                ),
                Tab(
                  text: 'Equipment Insulation',
                  icon: Icon(Icons.build),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaterialsTab(
                  siteId: siteId,
                  materials: pipingMaterials,
                  icon: Icons.precision_manufacturing,
                  color: Colors.blue,
                  emptyMessage: 'No piping insulation materials found',
                  category: 'piping',
                ),
                _buildMaterialsTab(
                  siteId: siteId,
                  materials: equipmentMaterials,
                  icon: Icons.build,
                  color: Colors.green,
                  emptyMessage: 'No equipment insulation materials found',
                  category: 'equipment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupState(String siteId) {
    return Center(
      child: Text("Getting your Material...")
    );
  }

  void _showAddMaterialSheet(String siteId) {
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
              title: const Text('Add Piping Insulation'),
              onTap: () {
                Navigator.pop(context);
                _addNewMaterial(siteId, 'piping');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Add Equipment Insulation'),
              onTap: () {
                Navigator.pop(context);
                _addNewMaterial(siteId, 'equipment');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsTab({
    required String siteId,
    required List<LocalMaterial> materials,
    required IconData icon,
    required Color color,
    required String emptyMessage,
    required String category,
  }) {
    // if (materials.isEmpty) {
    //   return _buildSetupState(siteId);
    // }

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
                      onPressed: _toggleSelectionMode,
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
                          : () => _deleteSelectedMaterials(materials),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      onPressed: materials.isEmpty ? null : _toggleSelectionMode,
                      tooltip: 'Select Items',
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: color),
                      onPressed: () => _addNewMaterial(siteId, category),
                      tooltip: 'Add Material',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
       if(materials.isNotEmpty) Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final localMaterial = materials[index];

              if (category == 'piping') {
                final material = localMaterial.toPiping();
                return _buildPipingCard(localMaterial, material, color);
              } else {
                final material = localMaterial.toEquipment();
                return _buildEquipmentCard(localMaterial, material, color);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipingCard(LocalMaterial localMaterial, PipingMaterial material, Color color) {
    final isSelected = _selectedMaterialIds.contains(localMaterial.id);

    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: PipingMaterialCard(
            key: ValueKey(localMaterial.materialDataJson),

            material: material,
            onChanged: (updated) async {
              await _updatePipingMaterial(localMaterial, updated);
            },
            onAdd: () => _copyMaterial(localMaterial),
            onEdit: () {},
            onDelete: () => _deleteMaterial(localMaterial),
            onRemark: () {},
          ),
        ),
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleMaterialSelection(localMaterial.id),
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

  Widget _buildEquipmentCard(LocalMaterial localMaterial, EquipmentMaterial material, Color color) {
    final isSelected = _selectedMaterialIds.contains(localMaterial.id);

    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: EquipmentMaterialCard(
            material: material,
            onChanged: (updated) async {
              await _updateEquipmentMaterial(localMaterial, updated);
            },
            onAdd: () => _copyMaterial(localMaterial),
            onEdit: () {},
            onDelete: () => _deleteMaterial(localMaterial),
            onRemark: () {},
          ),
        ),
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleMaterialSelection(localMaterial.id),
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

  // ✅ OFFLINE COPY
  Future<void> _copyMaterial(LocalMaterial original) async {
    try {
      final repo = ref.read(materialRepositoryProvider);

      // 1️⃣ Await the API call
      final response = await InsulationDprApi.copyInsulationMaterial(
        materialId: original.serverId!,
      );

      // 2️⃣ Extract new server ID
      final newServerId = response["data"]["_id"] as String;

      // 3️⃣ Create local copy using SERVER data (not original name)
      final copy = LocalMaterial()
        ..serverId = newServerId
        ..siteId = original.siteId
        ..domain = original.domain
        ..designation = original.designation
        ..name = response["data"]["name"] // use backend name
        ..uom = response["data"]["uom"]
        ..images = List<String>.from(response["data"]["image"] ?? [])
        ..isDirty = false; // IMPORTANT: already synced

      // 4️⃣ Save locally
      await repo.add(copy);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material copied $newServerId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Copy failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copy failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ✅ OFFLINE DELETE
  Future<void> _deleteMaterial(LocalMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text(
          'Are you sure you want to delete "${material.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(materialRepositoryProvider);

      // 🔥 1. Delete from server if synced
      if (material.serverId != null) {
        await InsulationDprApi.deleteInsulationMaterial(
          materialId: material.serverId!,
        );
      }

      // 🔥 2. Delete locally
      await repo.delete(material);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to delete: $e');
    }
  }
  // ✅ OFFLINE ADD
  Future<void> _addNewMaterial(String siteId, String category) async {
    try {
      final repo = ref.read(materialRepositoryProvider);

      await repo.add(
        LocalMaterial()
          ..siteId = siteId
          ..domain = MaterialDomain.insulation.key
          ..designation = category == 'piping'
              ? MaterialDesignation.piping.key
              : MaterialDesignation.equipment.key
          ..name = 'New Material'
          ..uom = 'Nos'
          ..isDirty = true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Add failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}