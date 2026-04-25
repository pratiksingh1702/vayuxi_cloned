// lib/features/modules/all_Modules/dpr/dpr_insu/screens/allinsulationmaterial.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
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

import 'package:untitled2/core/utlis/widgets/shimmer.dart';

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

  // Reorder state
  bool _isReorderMode = false;
  String? _reorderCategory;
  List<int> _reorderMaterialIds = [];
  List<LocalMaterial> _reorderDisplayMaterials = [];
  int? _draggingReorderIndex;
  String? _draggingMaterialId;
  bool _isOrderSyncing = false;

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
      name: m.name, // ← from local.name, NOT json
      image: m.images, // ← from local.images, NOT json
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
      circumferenceFinal:
          (cachedJson?['circumference_final'] as num?)?.toDouble() ?? 0,
      layer1Area: (cachedJson?['layer_1_area'] as num?)?.toDouble() ?? 0,
      layer2Area: (cachedJson?['layer_2_area'] as num?)?.toDouble() ?? 0,
      layer3Area: (cachedJson?['layer_3_area'] as num?)?.toDouble() ?? 0,
      circumference2Calc:
          (cachedJson?['circumference_2_calc'] as num?)?.toDouble() ?? 0,
      circumference1Calc:
          (cachedJson?['circumference_1_calc'] as num?)?.toDouble() ?? 0,
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

  Future<void> _deleteSelectedMaterials(List<LocalMaterial> materials) async {
    if (selectedIds.isEmpty) return;

    final confirmed = await _confirmDialog(
      title: 'Delete Selected Materials',
      message: 'Delete ${selectedIds.length} material(s)?',
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(materialRepositoryProvider);
      final selected =
          materials.where((m) => selectedIds.contains(m.id)).toList();
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
      _showSnack('Deleted ${selected.length} material(s)', isError: false);
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
        ..images = List<String>.from(response['data']['image'] ?? [])
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

  void _enterReorderMode(String category, List<LocalMaterial> materials) {
    if (materials.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 items are needed to reorder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isDeleteMode = false;
      selectedIds.clear();
      _isReorderMode = true;
      _reorderCategory = category;
      _reorderMaterialIds = materials.map((m) => m.id).toList();
      _reorderDisplayMaterials = List<LocalMaterial>.from(materials);
      _draggingReorderIndex = null;
      _draggingMaterialId = null;
    });
  }

  void _exitReorderMode() {
    _isReorderMode = false;
    _reorderCategory = null;
    _reorderMaterialIds = [];
    _reorderDisplayMaterials = [];
    _draggingReorderIndex = null;
    _draggingMaterialId = null;
  }

  List<LocalMaterial> _effectiveOrderForCategory(
    String category,
    List<LocalMaterial> materials,
  ) {
    final isActive = _isReorderMode && _reorderCategory == category;
    if (!isActive) return materials;

    if (_reorderDisplayMaterials.isNotEmpty) {
      return _reorderDisplayMaterials;
    }

    final mapById = {for (final m in materials) m.id: m};
    return _reorderMaterialIds
        .map((id) => mapById[id])
        .whereType<LocalMaterial>()
        .toList(growable: false);
  }

  Future<void> _persistInsulationDisplayOrder({
    required String siteId,
    required String category,
    required List<int> orderedIds,
  }) async {
    final dao = LocalMaterialDao();
    await dao.persistDisplayOrderForSubset(
      siteId: siteId,
      domain: MaterialDomain.insulation.key,
      designation: category == 'piping'
          ? MaterialDesignation.piping.key
          : MaterialDesignation.equipment.key,
      orderedIsarIds: orderedIds,
    );
  }

  Future<void> _handleMaterialReorder({
    required String category,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (!_isReorderMode || _reorderCategory != category) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;
    if (newIndex < 0 || newIndex >= _reorderMaterialIds.length) return;

    HapticFeedback.mediumImpact();

    final previousIds = List<int>.from(_reorderMaterialIds);
    final previousDisplay = List<LocalMaterial>.from(_reorderDisplayMaterials);

    final updatedIds = List<int>.from(_reorderMaterialIds);
    final updatedDisplay = List<LocalMaterial>.from(_reorderDisplayMaterials);

    final movedId = updatedIds.removeAt(oldIndex);
    updatedIds.insert(newIndex, movedId);

    final movedItem = updatedDisplay.removeAt(oldIndex);
    updatedDisplay.insert(newIndex, movedItem);

    setState(() {
      _reorderMaterialIds = updatedIds;
      _reorderDisplayMaterials = updatedDisplay;
    });

    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    try {
      setState(() => _isOrderSyncing = true);
      await _persistInsulationDisplayOrder(
        siteId: siteId,
        category: category,
        orderedIds: _reorderMaterialIds,
      );
    } catch (e) {
      setState(() {
        _reorderMaterialIds = previousIds;
        _reorderDisplayMaterials = previousDisplay;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to persist order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOrderSyncing = false;
          _draggingReorderIndex = null;
          _draggingMaterialId = null;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA);

    if (siteId == null) {
      return const Scaffold(body: Center(child: Text('No site selected')));
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

    if (pipingAsync.isLoading || equipmentAsync.isLoading) {
      return Scaffold(
        drawer: CustomDrawer(),
        backgroundColor: pageBg,
        appBar: PremiumAppBar(
          title: isDeleteMode
              ? '${selectedIds.length} Selected'
              : 'Insulation Materials',
          subtitle: const Text(
            'Piping and Equipment',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _buildBody(
          siteId: siteId,
          pipingMaterials: const [],
          equipmentMaterials: const [],
          isLoading: true,
        ),
      );
    }

    return Scaffold(
      drawer: CustomDrawer(),
      backgroundColor: pageBg,
      appBar: PremiumAppBar(
        title: isDeleteMode
            ? '${selectedIds.length} Selected'
            : 'Insulation Materials',
        subtitle: const Text(
          'Piping and Equipment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: pipingAsync.when(
        loading: () => const ShimmerList(
          type: ShimmerListType.card,
          itemCount: 4,
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pipingMaterials) {
          final equipmentMaterials = equipmentAsync.value ?? [];
          final isEmpty = pipingMaterials.isEmpty && equipmentMaterials.isEmpty;

          if (isEmpty) {
            return _buildBody(
              siteId: siteId,
              pipingMaterials: const [],
              equipmentMaterials: const [],
              isLoading: true,
            );
          }

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
    bool isLoading = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D21) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: isDark ? 0.28 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: cs.onPrimary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: cs.primary,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.28),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                tabs: const [
                  Tab(
                    height: 40,
                    text: 'Piping',
                    iconMargin: EdgeInsets.only(bottom: 1),
                    icon: Icon(Icons.precision_manufacturing, size: 15),
                  ),
                  Tab(
                    height: 40,
                    text: 'Equipment',
                    iconMargin: EdgeInsets.only(bottom: 1),
                    icon: Icon(Icons.build, size: 15),
                  ),
                ],
              ),
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
                  isLoading: isLoading,
                ),
                _buildMaterialsTab(
                  siteId: siteId,
                  materials: equipmentMaterials,
                  icon: Icons.build,
                  color: Colors.green,
                  emptyMessage: 'No equipment insulation materials found',
                  category: 'equipment',
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ],
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
    bool isLoading = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingState(category: category, color: color);
    }

    final isReorderForCategory = _isReorderMode && _reorderCategory == category;
    final displayMaterials = _effectiveOrderForCategory(category, materials);

    if (displayMaterials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D21) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.24 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isReorderForCategory)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.drag_indicator, size: 16, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isOrderSyncing
                                ? 'Reorder mode active. Saving order...'
                                : 'Reorder mode active. Drag cards to arrange display order.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActionButton(
                          label: 'Done',
                          icon: Icons.check,
                          textColor: Colors.white,
                          bgColor: cs.primary,
                          onTap: () => setState(_exitReorderMode),
                        ),
                      ],
                    ),
                  )
                else if (isDeleteMode)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderActionButton(
                          label: 'Close',
                          icon: Icons.close,
                          textColor: cs.onSurfaceVariant,
                          bgColor: cs.surfaceContainerHighest,
                          onTap: () => setState(() => toggleDeleteMode()),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActionButton(
                          label: selectAllLabel(
                            materials.map((m) => m.id).toList(),
                          ),
                          icon: Icons.done_all,
                          textColor: cs.primary,
                          bgColor: cs.primaryContainer,
                          onTap: () => setState(() {
                            handleSelectAllToggle(
                              materials.map((m) => m.id).toList(),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActionButton(
                          label: 'Delete',
                          icon: Icons.delete_sweep,
                          textColor: Colors.white,
                          bgColor: const Color(0xFFD34747),
                          onTap: selectedIds.isEmpty
                              ? null
                              : () => _deleteSelectedMaterials(materials),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Total ${category == 'piping' ? 'Piping' : 'Equipment'}: ${materials.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: isReorderForCategory
                            ? Icons.checklist_rtl_rounded
                            : Icons.reorder_rounded,
                        tooltip: isReorderForCategory
                            ? 'Exit Reorder Mode'
                            : 'Reorder Materials',
                        iconColor: isReorderForCategory
                            ? const Color(0xFF2B5FAE)
                            : color,
                        onTap: displayMaterials.length < 2
                            ? null
                            : () {
                                if (isReorderForCategory) {
                                  setState(_exitReorderMode);
                                  return;
                                }
                                _enterReorderMode(category, displayMaterials);
                              },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: Icons.delete_sweep,
                        tooltip: 'Select Items',
                        iconColor: const Color(0xFFD34747),
                        onTap: displayMaterials.isEmpty || _isReorderMode
                            ? null
                            : () => setState(() => toggleDeleteMode()),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: Icons.add_circle,
                        tooltip: 'Add Material',
                        iconColor: color,
                        onTap: () => _addNewMaterial(siteId, category),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isReorderForCategory
              ? _buildReorderableList(
                  category: category,
                  color: color,
                  materials: displayMaterials,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: displayMaterials.length,
                  itemBuilder: (context, index) {
                    final local = displayMaterials[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onLongPress: isDeleteMode
                            ? null
                            : () =>
                                _enterReorderMode(category, displayMaterials),
                        child: category == 'piping'
                            ? _buildPipingCard(local, color)
                            : _buildEquipmentCard(local, color),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReorderableList({
    required String category,
    required Color color,
    required List<LocalMaterial> materials,
  }) {
    if (materials.length < 2) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
        children: [
          category == 'piping'
              ? _buildPipingCard(materials.first, color)
              : _buildEquipmentCard(materials.first, color),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
        onReorderStart: (index) {
          HapticFeedback.mediumImpact();
          if (index < _reorderDisplayMaterials.length) {
            setState(() {
              _draggingReorderIndex = index;
              _draggingMaterialId =
                  _reorderDisplayMaterials[index].id.toString();
            });
          }
        },
        onReorderEnd: (_) {
          if (!mounted) return;
          setState(() {
            _draggingReorderIndex = null;
            _draggingMaterialId = null;
          });
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final elevation = Tween<double>(begin: 0, end: 20)
                  .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ))
                  .value;
              final scale = Tween<double>(begin: 1.0, end: 1.04)
                  .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ))
                  .value;

              return Opacity(
                opacity: 0.98,
                child: Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  shadowColor: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(0.0, -6.0, 0.0)
                      ..scale(scale),
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              );
            },
          );
        },
        itemCount: _reorderDisplayMaterials.length,
        onReorder: (oldIndex, newIndex) {
          _handleMaterialReorder(
            category: category,
            oldIndex: oldIndex,
            newIndex: newIndex,
          );
        },
        itemBuilder: (context, index) {
          if (index >= _reorderDisplayMaterials.length) {
            return const SizedBox.shrink(key: ValueKey('empty'));
          }

          final item = _reorderDisplayMaterials[index];
          final isDragging = _draggingMaterialId == item.id.toString();

          return _buildReorderableItem(
            key: ValueKey('reorder_${item.id}'),
            index: index,
            color: color,
            category: category,
            material: item,
            isDragging: isDragging,
          );
        },
      ),
    );
  }

  Widget _buildReorderableItem({
    required Key key,
    required int index,
    required Color color,
    required String category,
    required LocalMaterial material,
    required bool isDragging,
  }) {
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: isDragging ? 0.5 : 1.0,
              child: category == 'piping'
                  ? _buildPipingCard(material, color)
                  : _buildEquipmentCard(material, color),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  color: color.withValues(alpha: 0.10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: color.withValues(alpha: 0.8),
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onTap == null ? bgColor.withOpacity(0.45) : bgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232830) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTabLoadingState({
    required String category,
    required Color color,
  }) {
    return _buildLoadingState(category: category, color: color);
  }

  Widget _buildLoadingState({
    required String category,
    required Color color,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: category == 'piping' ? 180 : 190,
                height: 14,
                borderRadius: 6,
              ),
              Row(
                children: [
                  ShimmerBox(width: 32, height: 32, borderRadius: 10),
                  const SizedBox(width: 8),
                  ShimmerBox(width: 32, height: 32, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return const ShimmerList(
                type: ShimmerListType.card,
                itemCount: 1,
                scrollable: false,
                padding: EdgeInsets.zero,
              );
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
    final isInteractionLocked = isDeleteMode || _isReorderMode;

    // ✅ Correct MaterialSetup lookup — never falls back incorrectly
    final materialSetup = _findMaterialSetup(local);

    return Stack(
      children: [
        Opacity(
          opacity: isDeleteMode && !isSelected ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isInteractionLocked,
            child: PipingMaterialCard(
              // Key by materialDataJson so card rebuilds when data changes
              key: ValueKey(
                  'piping_${local.id}_${local.materialDataJson?.hashCode}'),
              material: material,
              materialSetup: materialSetup, // ✅ drives dynamic mode
              onChanged: (updated) => _updatePipingMaterial(local, updated),
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
    final isInteractionLocked = isDeleteMode || _isReorderMode;

    // ✅ Correct MaterialSetup lookup
    final materialSetup = _findMaterialSetup(local);

    return Stack(
      children: [
        Opacity(
          opacity: isDeleteMode && !isSelected ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isInteractionLocked,
            child: EquipmentMaterialCard(
              key: ValueKey(
                  'equipment_${local.id}_${local.materialDataJson?.hashCode}'),
              material: material,
              materialSetup: materialSetup, // ✅ drives dynamic mode
              onChanged: (updated) => _updateEquipmentMaterial(local, updated),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => toggleSelection(materialId)),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: cs.scrim.withValues(alpha: 0.08),
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
                    color: isSelected
                        ? cs.error
                        : (isDark ? const Color(0xFF232830) : Colors.white),
                    border: Border.all(color: Colors.red, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.2),
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
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? cs.error : cs.tertiary,
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
}
