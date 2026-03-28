// lib/features/modules/all_Modules/dpr/dpr_insu/screens/allinsulationmaterial.dart

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
import '../../offline/data/local/local_material_dao.dart';
import '../../offline/data/repo/material_provider.dart';
import '../../offline/data/repo/material_repo_provider.dart';
import '../../offline/data/material_sync_service.dart';
import '../../screens/widgets/delete_mode_mixin.dart';
import '../model/card_form_state.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';
import '../model/material_setup.dart';
import '../widgets/equipment_card.dart';

class AllInsulationMaterialsScreen extends ConsumerStatefulWidget {
  const AllInsulationMaterialsScreen({super.key});

  @override
  ConsumerState<AllInsulationMaterialsScreen> createState() =>
      _AllInsulationMaterialsScreenState();
}

class _AllInsulationMaterialsScreenState
    extends ConsumerState<AllInsulationMaterialsScreen>
    with SingleTickerProviderStateMixin, DeleteModeMixin<int> {
  late TabController _tabController;

  // Material setup state
  final MaterialSyncService _syncService = MaterialSyncService();
  List<MaterialSetup> _pipingSetups = [];
  List<MaterialSetup> _equipmentSetups = [];
  bool _setupsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteId = ref.read(selectedSiteIdProvider);
      if (siteId == null) return;

      // Background sync for offline materials
      ref.read(materialRepositoryProvider).syncInBackground(
        siteId: siteId,
        domain: 'insulation',
        designation: '',
      );

      // Load MaterialSetup configs for dynamic card rendering
      _loadMaterialSetups(siteId);
    });
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
    } catch (e) {
      debugPrint('❌ Failed to load material setups: $e');
      if (mounted) setState(() => _setupsLoaded = true);
    }
  }

  /// Find the [MaterialSetup] that corresponds to [localMaterial].
  ///
  /// Matching order:
  /// 1. Exact materialCode match
  /// 2. First setup of matching designation (fallback)
  ///
  /// Returns null only when no setups are available at all.
  MaterialSetup? _findMaterialSetup(LocalMaterial localMaterial) {
    if (!_setupsLoaded) return null;

    final code = localMaterial.materialCode;
    final designation = localMaterial.designation;
    final pool = designation == MaterialDesignation.piping.key
        ? _pipingSetups
        : _equipmentSetups;

    if (pool.isEmpty) return null;

    // 1. Exact code match
    if (code != null && code.isNotEmpty) {
      try {
        return pool.firstWhere((s) => s.materialCode == code);
      } catch (_) {
        // Not found — fall through to fallback
      }
    }

    // 2. Fallback: first setup of same designation
    return pool.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // MATERIAL CONVERSION (LocalMaterial → domain)
  // ─────────────────────────────────────────────

  PipingMaterial _toPiping(LocalMaterial m) {
    // Try to restore calculated fields from cached JSON
    Map<String, dynamic>? cachedJson;
    if (m.materialDataJson != null && m.materialDataJson!.isNotEmpty) {
      try {
        cachedJson = jsonDecode(m.materialDataJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return PipingMaterial(
      // ✅ ALWAYS use local DB fields — never the stale JSON
      id: m.serverId ?? m.id.toString(),
      name: m.name,                    // ← from local.name, NOT json
      image: m.images,                 // ← from local.images, NOT json
      uom: m.uom ?? '',
      materialCode: m.materialCode,
      cardFormState: m.savedCardFormState,
      size: m.size ?? '',
      sizeUom: m.sizeUom ?? 'inch',
      qty: m.qty,
      length: m.length,
      circumference: m.circumference,
      zHeight: m.zHeight,
      remarks: m.remarks ?? '',
      // Restore calculated fields from cached JSON if available
      circumference1: (cachedJson?['circumference_1'] as num?)?.toDouble() ?? 0,
      circumference2: (cachedJson?['circumference_2'] as num?)?.toDouble() ?? 0,
      circumference3: (cachedJson?['circumference_3'] as num?)?.toDouble() ?? 0,
      SlantHeight: (cachedJson?['slant_height'] as num?)?.toDouble() ?? 0,
      constant: (cachedJson?['constant'] as num?)?.toDouble() ?? 0,
      totalArea: (cachedJson?['total_area'] as num?)?.toDouble() ?? 0,
      diameterA3: (cachedJson?['diameter_a3'] as num?)?.toDouble() ?? 0,
      diameterB3: (cachedJson?['diameter_b3'] as num?)?.toDouble() ?? 0,
      diameterA2: (cachedJson?['diameter_a2'] as num?)?.toDouble() ?? 0,
      diameterB2: (cachedJson?['diameter_b2'] as num?)?.toDouble() ?? 0,
      diameterA1: (cachedJson?['diameter_a1'] as num?)?.toDouble() ?? 0,
      diameterB1: (cachedJson?['diameter_b1'] as num?)?.toDouble() ?? 0,
      circumferenceFinal: (cachedJson?['circumference_final'] as num?)?.toDouble() ?? 0,
      layer1Area: (cachedJson?['layer_1_area'] as num?)?.toDouble() ?? 0,
      layer2Area: (cachedJson?['layer_2_area'] as num?)?.toDouble() ?? 0,
      layer3Area: (cachedJson?['layer_3_area'] as num?)?.toDouble() ?? 0,
      circumference2Calc: (cachedJson?['circumference_2_calc'] as num?)?.toDouble() ?? 0,
      circumference1Calc: (cachedJson?['circumference_1_calc'] as num?)?.toDouble() ?? 0,
      o3: (cachedJson?['o3'] as num?)?.toDouble() ?? 0,
      o2: (cachedJson?['o2'] as num?)?.toDouble() ?? 0,
      o1: (cachedJson?['o1'] as num?)?.toDouble() ?? 0,
    );
  }

  EquipmentMaterial _toEquipment(LocalMaterial m) {
    if (m.materialDataJson != null && m.materialDataJson!.isNotEmpty) {
      try {
        return EquipmentMaterial.fromJson(
            jsonDecode(m.materialDataJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    return EquipmentMaterial(
      id: m.serverId ?? m.id.toString(),
      name: m.name,
      image: m.images,
      uom: m.uom ?? '',
      materialCode: m.materialCode,
      cardFormState: m.savedCardFormState, // ← restore isolated state
      qty: m.qty,
      length: m.length,
      circumference: m.circumference,
      circumference1: 0,
      circumference2: 0,
      zHeight: m.zHeight,
      SlantHeight: 0,
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
      remarks: m.remarks,
    );
  }

  // ─────────────────────────────────────────────
  // UPDATE HELPERS
  // ─────────────────────────────────────────────

  Future<void> _updatePipingMaterial(
      LocalMaterial local,
      PipingMaterial updated,
      ) async {
    final repo = ref.read(materialRepositoryProvider);
    final dao = LocalMaterialDao();

    local
      ..name = updated.name
      ..uom = updated.uom
      ..images = updated.image
      ..materialDataJson = jsonEncode(updated.toJson())
      ..isDirty = false
      ..updatedAt = DateTime.now();

    await repo.update(local);

    // Persist isolated card form state separately so it is never lost
    if (updated.cardFormState != null) {
      await dao.saveCardFormState(
        isarId: local.id,
        state: updated.cardFormState!,
      );
    }
  }

  Future<void> _updateEquipmentMaterial(
      LocalMaterial local,
      EquipmentMaterial updated,
      ) async {
    final repo = ref.read(materialRepositoryProvider);
    final dao = LocalMaterialDao();

    local
      ..name = updated.name
      ..uom = updated.uom
      ..images = updated.image
      ..materialDataJson = jsonEncode(updated.toJson())
      ..isDirty = false
      ..updatedAt = DateTime.now();

    await repo.update(local);

    // Persist isolated card form state
    if (updated.cardFormState != null) {
      await dao.saveCardFormState(
        isarId: local.id,
        state: updated.cardFormState!,
      );
    }
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  Future<void> _deleteSelectedMaterials(
      List<LocalMaterial> materials) async {
    if (selectedIds.isEmpty) return;

    final confirmed = await _confirmDialog(
      title: 'Delete Selected Materials',
      message:
      'Delete ${selectedIds.length} material(s)?',
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(materialRepositoryProvider);
      final selected = materials
          .where((m) => selectedIds.contains(m.id))
          .toList();
      final serverIds = selected
          .where((m) => m.serverId != null)
          .map((m) => m.serverId!)
          .toList();

      if (serverIds.isNotEmpty) {
        await InsulationDprApi.bulkDeleteMaterials(ids: serverIds);
      }
      for (final m in selected) {
        await repo.delete(m);
      }

      if (!mounted) return;
      _showSnack('Deleted ${selected.length} material(s)',
          isError: false);
      setState(() {
        selectedIds.clear();
        isDeleteMode = false;
      });
    } catch (e) {
      debugPrint('❌ Bulk delete failed: $e');
    }
  }

  Future<void> _deleteMaterial(LocalMaterial material) async {
    final confirmed = await _confirmDialog(
      title: 'Delete Material',
      message: 'Delete "${material.name}"?',
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(materialRepositoryProvider);
      if (material.serverId != null) {
        await InsulationDprApi.deleteInsulationMaterial(
            materialId: material.serverId!);
      }
      await repo.delete(material);
      if (mounted) _showSnack('Deleted successfully', isError: false);
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // COPY
  // ─────────────────────────────────────────────

  Future<void> _copyMaterial(LocalMaterial original) async {
    try {
      final repo = ref.read(materialRepositoryProvider);
      final response = await InsulationDprApi.copyInsulationMaterial(
          materialId: original.serverId!);
      final newServerId = response['data']['_id'] as String;

      final copy = LocalMaterial()
        ..serverId = newServerId
        ..siteId = original.siteId
        ..domain = original.domain
        ..designation = original.designation
        ..name = response['data']['name'] as String
        ..uom = response['data']['uom'] as String?
        ..images =
        List<String>.from(response['data']['image'] ?? [])
        ..isDirty = false;
      // Note: cardFormStateJson is intentionally NOT copied —
      // the copied card starts fresh (no shared state).

      await repo.add(copy);
      if (mounted) _showSnack('Material copied', isError: false);
    } catch (e) {
      debugPrint('❌ Copy failed: $e');
      if (mounted) _showSnack('Copy failed', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // ADD NEW
  // ─────────────────────────────────────────────

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
      if (mounted) _showSnack('Material added', isError: false);
    } catch (e) {
      debugPrint('❌ Add failed: $e');
      if (mounted) _showSnack('Add failed: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);

    if (siteId == null) {
      return const Scaffold(
          body: Center(child: Text('No site selected')));
    }

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
        title: isDeleteMode
            ? '${selectedIds.length} Selected'
            : 'Insulation Materials',
      ),
      body: pipingAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pipingMaterials) {
          final equipmentMaterials = equipmentAsync.value ?? [];
          final isEmpty =
              pipingMaterials.isEmpty && equipmentMaterials.isEmpty;

          if (isEmpty) return _buildSetupState(siteId);

          return _buildBody(
            siteId: siteId,
            pipingMaterials: pipingMaterials,
            equipmentMaterials: equipmentMaterials,
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────

  Widget _buildBody({
    required String siteId,
    required List<LocalMaterial> pipingMaterials,
    required List<LocalMaterial> equipmentMaterials,
  }) {
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
                  emptyMessage:
                  'No piping insulation materials found',
                  category: 'piping',
                ),
                _buildMaterialsTab(
                  siteId: siteId,
                  materials: equipmentMaterials,
                  icon: Icons.build,
                  color: Colors.green,
                  emptyMessage:
                  'No equipment insulation materials found',
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
    final progressAsync = ref.watch(syncProgressProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync, size: 48, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Loading your materials…',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            progressAsync.when(
              data: (progress) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Sync error'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MATERIAL TAB
  // ─────────────────────────────────────────────

  Widget _buildMaterialsTab({
    required String siteId,
    required List<LocalMaterial> materials,
    required IconData icon,
    required Color color,
    required String emptyMessage,
    required String category,
  }) {
    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeleteMode
                    ? '${selectedIds.length} / ${materials.length} selected'
                    : 'Total: ${materials.length}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color),
              ),
              Row(
                children: [
                  if (isDeleteMode) ...[
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => toggleDeleteMode()),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        handleSelectAllToggle(materials.map((m) => m.id).toList());
                      }),
                      child: Text(selectAllLabel(materials.map((m) => m.id).toList())),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon:
                      const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Delete'),
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () =>
                          _deleteSelectedMaterials(materials),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.delete_sweep,
                          color: Colors.red),
                      onPressed: materials.isEmpty
                          ? null
                          : () => setState(() => toggleDeleteMode()),
                      tooltip: 'Select Items',
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: color),
                      onPressed: () =>
                          _addNewMaterial(siteId, category),
                      tooltip: 'Add Material',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // List
        if (materials.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final local = materials[index];
                return category == 'piping'
                    ? _buildPipingCard(local, color)
                    : _buildEquipmentCard(local, color);
              },
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CARD BUILDERS
  // ─────────────────────────────────────────────

  Widget _buildPipingCard(LocalMaterial local, Color color) {
    final material = _toPiping(local);
    final isSelected = selectedIds.contains(local.id);

    // ✅ Correct MaterialSetup lookup — never falls back incorrectly
    final materialSetup = _findMaterialSetup(local);

    return Stack(
      children: [
        Opacity(
          opacity:
          isDeleteMode && !isSelected ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isDeleteMode,
            child: PipingMaterialCard(
              // Key by materialDataJson so card rebuilds when data changes
              key: ValueKey('piping_${local.id}_${local.materialDataJson?.hashCode}'),
              material: material,
              materialSetup: materialSetup, // ✅ drives dynamic mode
              onChanged: (updated) =>
                  _updatePipingMaterial(local, updated),
              onAdd: () => _copyMaterial(local),
              onEdit: () {},
              onDelete: () => _deleteMaterial(local),
              onRemark: () {},
            ),
          ),
        ),
        if (isDeleteMode) _selectionOverlay(local.id, isSelected),
      ],
    );
  }

  Widget _buildEquipmentCard(LocalMaterial local, Color color) {
    final material = _toEquipment(local);
    final isSelected = selectedIds.contains(local.id);

    // ✅ Correct MaterialSetup lookup
    final materialSetup = _findMaterialSetup(local);

    return Stack(
      children: [
        Opacity(
          opacity:
          isDeleteMode && !isSelected ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isDeleteMode,
            child: EquipmentMaterialCard(
              key: ValueKey('equipment_${local.id}_${local.materialDataJson?.hashCode}'),
              material: material,
              materialSetup: materialSetup, // ✅ drives dynamic mode
              onChanged: (updated) =>
                  _updateEquipmentMaterial(local, updated),
              onAdd: () => _copyMaterial(local),
              onEdit: () {},
              onDelete: () => _deleteMaterial(local),
              onRemark: () {},
            ),
          ),
        ),
        if (isDeleteMode) _selectionOverlay(local.id, isSelected),
      ],
    );
  }

  Widget _selectionOverlay(int materialId, bool isSelected) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => toggleSelection(materialId)),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withOpacity(0.05),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
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
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UTILITY DIALOGS / SNACKS
  // ─────────────────────────────────────────────

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMaterialSheet(String siteId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
              const Icon(Icons.precision_manufacturing),
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
}