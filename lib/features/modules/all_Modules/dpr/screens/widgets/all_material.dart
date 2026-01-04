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
  bool _isLoading = false;
  bool _isInitialized = false;
  final DefaultMaterialService _materialService = DefaultMaterialService();
  String? siteId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      siteId = ref.read(selectedSiteIdProvider);
      await _initializeMaterials();
    });
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

      final pipingMaterials = materials.whereType<PipingItem>().toList();
      final equipmentMaterials = materials.whereType<EquipmentItem>().toList();

      ref.read(pipingMaterialsProvider.notifier).setMaterials(pipingMaterials);
      ref.read(equipmentMaterialsProvider.notifier).setMaterials(equipmentMaterials);

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
      ref.read(equipmentMaterialsProvider.notifier).setMaterials(equipmentMaterials);

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
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final pipingMaterials = ref.watch(pipingMaterialsProvider);
    final equipmentMaterials = ref.watch(equipmentMaterialsProvider);

    final bool needsSetupDpr =
        !_isLoading &&
            _isInitialized &&
            pipingMaterials.isEmpty &&
            equipmentMaterials.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: 'All Materials',
      ),
      body: _isLoading && !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : needsSetupDpr
          ? _buildSetupDprState()
          : SafeArea(
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
                ],
              ),
            ),

            if (_isLoading && _isInitialized)
              const LinearProgressIndicator(),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMaterialsTab(
                    materials: pipingMaterials,
                    icon: Icons.precision_manufacturing,
                    color: Colors.blue,
                    emptyMessage: 'No piping materials found',
                    category: 'piping',
                  ),
                  _buildMaterialsTab(
                    materials: equipmentMaterials,
                    icon: Icons.build,
                    color: Colors.green,
                    emptyMessage: 'No equipment materials found',
                    category: 'equipment',
                  ),
                ],
              ),
            ),
          ],
        ),
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
            const Icon(Icons.settings, size: 72, color: Colors.blueGrey),
            const SizedBox(height: 24),

            const Text(
              'Setup DPR Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            const Text(
              'Default materials are not configured for this site.\n\n'
                  'You must set up DPR materials before creating or managing DPRs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Setup DPR Materials'),
              onPressed: _showSetupDprDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
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
                subtitle: const Text('Make these materials available across all sites'),
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
      return _buildSetupDprState(

      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${category == 'piping' ? 'Piping' : 'Equipment'}: ${materials.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: color),
                    onPressed: () => _showFilterOptions(context, category),
                    tooltip: 'Filter',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    onPressed: materials.isEmpty
                        ? null
                        : () => _bulkDeleteMaterials(category),
                    tooltip: 'Bulk Delete All',
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: color),
                    onPressed: () => _addNewMaterial(category),
                    tooltip: 'Add Material',
                  ),
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

  /// Bulk delete all materials in a category
  Future<void> _bulkDeleteMaterials(String category) async {
    final materials = category == 'piping'
        ? ref.read(pipingMaterialsProvider)
        : ref.read(equipmentMaterialsProvider);

    if (materials.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete Confirmation'),
        content: Text(
          'Are you sure you want to delete ALL ${materials.length} '
              '${category == 'piping' ? 'piping' : 'equipment'} materials?\n\n'
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
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      if (category == 'piping') {
        final List<PipingItem> materials =
        ref.read(pipingMaterialsProvider);

        final ids = materials.map((m) => m.id).toList();
        await _materialService.bulkDelete(ids);
        ref.read(pipingMaterialsProvider.notifier).setMaterials([]);
      } else {
        final List<EquipmentItem> materials =
        ref.read(equipmentMaterialsProvider);

        final ids = materials.map((m) => m.id).toList();
        await _materialService.bulkDelete(ids);
        ref.read(equipmentMaterialsProvider.notifier).setMaterials([]);
      }


      await _refreshMaterials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted  materials'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Widget _buildPipingCard(PipingItem material, Color color) {
    final imageUrl = _cleanImageUrl(material.image);

    return DynamicItemCard(
      quantity: material.qty.toString(),
      size: material.size,
      length: material.length.toString(),
      floor: '',
      moc: material.moc,
      image: imageUrl.isNotEmpty ? imageUrl : null,
      sizeLabel: "Size",
      lengthLabel: material.materialName,
      sizePlaceholder: material.uom,
      lengthPlaceholder: material.uom,
      onQtyChanged: (value) => _updatePipingField(material.id, 'qty', value),
      onSizeChanged: (value) => _updatePipingField(material.id, 'size', value),
      onLengthChanged: (value) => _updatePipingField(material.id, 'length', value),
      onFloorChanged: (value) => _updatePipingField(material.id, 'floor', value),
      onMocChanged: (value) => _updatePipingField(material.id, 'moc', value),
      onDelete: () => _deleteMaterial(material.id, material.materialName, 'piping'),
      onRemark: () => _showRemarksDialog(material, 'piping'),
      onEdit: () => _editMaterial(material, 'piping'),
      onCopy: () => _copyMaterial(material, 'piping'),
      onAdd: () => _copyMaterial(material, 'piping'),
      isEditable: true,
    );
  }

  Widget _buildEquipmentCard(EquipmentItem material, Color color) {
    final imageUrl = _cleanImageUrl(material.image);

    return DynamicItemCard2(
      title: material.materialName,
      quantity: material.qty.toString(),
      image: imageUrl.isNotEmpty ? imageUrl : null,
      moc: material.moc,
      floor: '',
      ton: material.weight.toString(),
      meter: material.length.toString(),
      onAdd: () => _copyMaterial(material.id, 'equipment'),
      onEdit: () => _editMaterial(material, 'equipment'),
      onMocChanged: (value) => _updateEquipmentField(material.id, 'moc', value),
      onDelete: () => _deleteMaterial(material.id, material.materialName, 'equipment'),
      onRemark: () => _showRemarksDialog(material, 'equipment'),
      onQtyChanged: (value) => _updateEquipmentField(material.id, 'qty', value),
      onFloorChanged: (value) => _updateEquipmentField(material.id, 'floor', value),
      onTonChanged: (value) => _updateEquipmentField(material.id, 'weight', value),
      onMeterChanged: (value) => _updateEquipmentField(material.id, 'length', value),
      isEditable: true,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
    required String category,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _addNewMaterial(category),
            icon: Icon(Icons.add, color: color),
            label: Text(
              'Add New Material',
              style: TextStyle(color: color),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePipingField(String id, String field, String value) async {
    try {
      final updates = {field: _parseValue(field, value)};
      await ref.read(pipingMaterialsProvider.notifier).updatePipingMaterialField(id, updates);
    } catch (e) {
      debugPrint('❌ Failed to update piping field: $e');
    }
  }

  Future<void> _updateEquipmentField(String id, String field, String value) async {
    try {
      final updates = {field: _parseValue(field, value)};
      await ref.read(equipmentMaterialsProvider.notifier).updateEquipmentMaterialField(id, updates);
    } catch (e) {
      debugPrint('❌ Failed to update equipment field: $e');
    }
  }

  dynamic _parseValue(String field, String value) {
    if (field == 'qty' || field == 'length' || field == 'weight' || field == 'diameter' || field == 'power') {
      return double.tryParse(value) ?? 0.0;
    }
    return value;
  }

  void _editMaterial(dynamic material, String category) {
    if (material is PipingItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'piping',
            pipingMaterial: material,
          ),
        ),
      ).then((_) {
        _refreshMaterials();
      });
    } else if (material is EquipmentItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersistDPRScreen(
            editMaterialId: material.id,
            designation: 'equipment',
            equipmentMaterial: material,
          ),
        ),
      ).then((_) {
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

  Future<void> _deleteMaterial(String materialId, String materialName, String category) async {
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
        notifier.setMaterials(materials.where((m) => m.id != materialId).toList());
      } else {
        final notifier = ref.read(equipmentMaterialsProvider.notifier);
        final materials = ref.read(equipmentMaterialsProvider);
        notifier.setMaterials(materials.where((m) => m.id != materialId).toList());
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersistDPRScreen(
          designation: category,
        ),
      ),
    ).then((_) {
      _refreshMaterials();
    });
  }

  void _showRemarksDialog(dynamic material, String category) {
    final remarksController = TextEditingController(text: material.remarks ?? '');

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
                _updatePipingField(material.id, 'remarks', remarksController.text);
              } else {
                _updateEquipmentField(material.id, 'remarks', remarksController.text);
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