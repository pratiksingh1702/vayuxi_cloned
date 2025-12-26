import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../models/data/eqipment_provider.dart';
import '../../models/data/piping_provider.dart';
import '../../providers/dpr.dart';
import 'dynamic_item_card.dart';
import 'dynamic_item_card2.dart';
import 'edit_material.dart';

class AllMaterialsScreen extends ConsumerStatefulWidget {
  final String? siteId;
  final String? teamId;
  final String? teamName;

  const AllMaterialsScreen({
    this.siteId,
    this.teamId,
    this.teamName,
    super.key,
  });

  @override
  ConsumerState<AllMaterialsScreen> createState() => _AllMaterialsScreenState();
}

class _AllMaterialsScreenState extends ConsumerState<AllMaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    // Get piping and equipment materials directly from providers
    final pipingMaterials = ref.watch(pipingMaterialsProvider);
    final equipmentMaterials = ref.watch(equipmentMaterialsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: widget.teamName ?? 'All Materials',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
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

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Piping Materials Tab
                  _buildMaterialsTab(
                    materials: pipingMaterials,
                    icon: Icons.precision_manufacturing,
                    color: Colors.blue,
                    emptyMessage: 'No piping materials found',
                    category: 'piping',
                  ),

                  // Equipment Materials Tab
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

  Widget _buildMaterialsTab({
    required List<dynamic> materials,
    required IconData icon,
    required Color color,
    required String emptyMessage,
    required String category,
  }) {
    if (materials.isEmpty) {
      return _buildEmptyState(
        icon: icon,
        message: emptyMessage,
        color: color,
      );
    }

    return Column(
      children: [
        // Header with counts
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
              IconButton(
                icon: Icon(Icons.filter_list, color: color),
                onPressed: () {
                  _showFilterOptions(context, category);
                },
              ),
            ],
          ),
        ),

        // Materials List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return category == 'piping'
                  ? _buildPipingCard(material, color)
                  : _buildEquipmentCard(material, color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipingCard(dynamic material, Color color) {
    final materialName = _getMaterialName(material, 'piping');
    final uom = _getUOM(material, 'piping');
    final imageUrl = _getImageUrl(material, 'piping');
    final dprName = _getDPRName(material, 'piping');

    return DynamicItemCard(
      quantity: "0", // Default quantity
      size: _getSize(material, 'piping'),
      length: _getLength(material, 'piping'),
      floor: _getFloor(material, 'piping'),
      moc: _getMOC(material, 'piping'),
      image: imageUrl.isNotEmpty ? imageUrl : null,
      sizeLabel: "Size",
      lengthLabel: materialName,
      sizePlaceholder: "Enter size",
      lengthPlaceholder: uom,
      onQtyChanged: (value) {
        // Handle quantity change
        _updatePipingMaterial(material, 'quantity', value);
      },
      onSizeChanged: (value) {
        // Handle size change
        _updatePipingMaterial(material, 'size', value);
      },
      onLengthChanged: (value) {
        // Handle length change
        _updatePipingMaterial(material, 'length', value);
      },
      onFloorChanged: (value) {
        // Handle floor change
        _updatePipingMaterial(material, 'floor', value);
      },
      onMocChanged: (value) {
        // Handle MOC change
        _updatePipingMaterial(material, 'moc', value);
      },
      onDelete: () {
        _deleteMaterial(material, 'piping');
      },
      onRemark: () {
        _showRemarksDialog(context, material, 'piping');
      },
      onEdit: () {
        _editMaterial(material, 'piping');
      },
      onCopy: () {
        _duplicateMaterial(material, 'piping');
      },
      onAdd: () {
        _duplicateMaterial(material, 'piping');
      },
      isEditable: true, // You can make this dynamic based on user role
    );
  }

  Widget _buildEquipmentCard(dynamic material, Color color) {
    final materialName = _getMaterialName(material, 'equipment');
    final uom = _getUOM(material, 'equipment');
    final imageUrl = _getImageUrl(material, 'equipment');
    final dprName = _getDPRName(material, 'equipment');

    return DynamicItemCard2(
      title: materialName,
      quantity: "0", // Default quantity
      image: imageUrl.isNotEmpty ? imageUrl : null,
      moc: _getMOC(material, 'equipment'),
      floor: _getFloor(material, 'equipment'),
      ton: _getTon(material, 'equipment'),
      meter: _getMeter(material, 'equipment'),
      onAdd: () {
        _duplicateMaterial(material, 'equipment');
      },
      onEdit: () {
        _editMaterial(material, 'equipment');
      },
      onMocChanged: (value) {
        _updateEquipmentMaterial(material, 'moc', value);
      },
      onDelete: () {
        _deleteMaterial(material, 'equipment');
      },
      onRemark: () {
        _showRemarksDialog(context, material, 'equipment');
      },
      onQtyChanged: (value) {
        _updateEquipmentMaterial(material, 'quantity', value);
      },
      onFloorChanged: (value) {
        _updateEquipmentMaterial(material, 'floor', value);
      },
      onTonChanged: (value) {
        _updateEquipmentMaterial(material, 'ton', value);
      },
      isEditable: true, // You can make this dynamic based on user role
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
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
            onPressed: () {
              // Add new material
              _addNewMaterial(context, color == Colors.blue ? 'piping' : 'equipment');
            },
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

  // Helper methods to extract properties from material objects
  String _getMaterialName(dynamic material, String category) {
    try {
      if (category == 'piping') {
        return material.materialName?.toString() ?? 'Unknown Piping Material';
      } else if (category == 'equipment') {
        return material.materialName?.toString() ?? 'Unknown Equipment';
      }
    } catch (e) {
      // Handle the error silently
    }
    return 'Unknown Material';
  }

  String _getUOM(dynamic material, String category) {
    try {
      if (category == 'piping') {
        return material.uom?.toString() ?? 'N/A';
      } else if (category == 'equipment') {
        return material.uom?.toString() ?? 'N/A';
      }
    } catch (e) {
      // Handle the error silently
    }
    return 'N/A';
  }

  String _getImageUrl(dynamic material, String category) {
    try {
      if (category == 'piping') {
        return _cleanImageUrl(material.image?.toString() ?? '');
      } else if (category == 'equipment') {
        return _cleanImageUrl(material.image?.toString() ?? '');
      }
    } catch (e) {
      // Handle the error silently
    }
    return '';
  }

  String _getDPRName(dynamic material, String category) {
    try {
      if (material.dprName != null) {
        return material.dprName.toString();
      } else if (material.dpr != null) {
        return material.dpr.toString();
      } else if (material.parentDprName != null) {
        return material.parentDprName.toString();
      }
    } catch (e) {
      // Handle the error silently
    }
    return 'Unknown DPR';
  }

  String _getSize(dynamic material, String category) {
    try {
      if (category == 'piping') {
        return material.size?.toString() ?? '';
      }
    } catch (e) {
      // Handle the error silently
    }
    return '';
  }

  String _getLength(dynamic material, String category) {
    try {
      if (category == 'piping') {
        return material.length?.toString() ?? '';
      }
    } catch (e) {
      // Handle the error silently
    }
    return '';
  }

  String _getFloor(dynamic material, String category) {
    try {
      return material.floor?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getMOC(dynamic material, String category) {
    try {
      return material.moc?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getTon(dynamic material, String category) {
    try {
      if (category == 'equipment') {
        return material.ton?.toString() ?? '';
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  String _getMeter(dynamic material, String category) {
    try {
      if (category == 'equipment') {
        return material.meter?.toString() ?? '';
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  // Material CRUD operations
  void _updatePipingMaterial(dynamic material, String field, String value) {
    // Update the material in your state management
    print('Updating piping material: ${material.id} - $field: $value');
    // Add your update logic here
  }

  void _updateEquipmentMaterial(dynamic material, String field, String value) {
    // Update the material in your state management
    print('Updating equipment material: ${material.id} - $field: $value');
    // Add your update logic here
  }

  void _deleteMaterial(dynamic material, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${_getMaterialName(material, category)}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final notifier = category == 'piping'
                  ? ref.read(pipingMaterialsProvider.notifier)
                  : ref.read(equipmentMaterialsProvider.notifier);

              if (category == 'piping') {
                final piping=ref.read(pipingMaterialsProvider.notifier);
                piping.deletePipingMaterial(material.id);
              } else{
                final equipment=ref.read(equipmentMaterialsProvider.notifier);
                equipment.deleteEquipmentMaterial(material.id);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category material deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRemarksDialog(BuildContext context, dynamic material, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remarks for ${_getMaterialName(material, category)}'),
        content: TextField(
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
              // Save remarks logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editMaterial(dynamic material, String category) {
    // Extract material ID based on your model structure
    String materialId;

    try {
      // Try different possible property names for ID
      if (material.id != null) {
        materialId = material.id.toString();
      } else if (material.materialId != null) {
        materialId = material.materialId.toString();
      } else if (material.code != null) {
        materialId = material.code.toString();
      } else {
        // Generate a fallback ID
        materialId = '${category}_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      materialId = '${category}_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Navigate to edit screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMaterialScreen(
          material: material,
          category: category,
          materialId: materialId,
          siteId: widget.siteId,
          teamId: widget.teamId,
        ),
      ),
    );
  }

  void _duplicateMaterial(dynamic material, String category) async {
    try {
      print('Duplicating ${category} material: ${material.id}');

      // Get the provider instance
      final dprNotifier = ref.read(dprProvider.notifier);
      final siteId=ref.read(selectedSiteIdProvider)!;

      // Call the copyMaterial method
      await dprNotifier.copyMaterial(
        siteId: siteId, // Assuming material has siteId
        materialId: material.id,
      );

      // Optional: Show success message or refresh data
      print('Material duplicated successfully');

      // If you need to refresh the current DPR data after duplication:
      // await dprNotifier.fetchDprById(
      //   siteId: material.siteId,
      //   teamId: material.teamId,
      //   workId: material.workId,
      // );

    } catch (e) {
      print('Error duplicating material: $e');
      // You might want to show an error snackbar here
    }
  }

  void _addNewMaterial(BuildContext context, String category) {
    // Navigate to add new material screen
    print('Adding new ${category} material');
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
            _buildFilterOption('By DPR', Icons.folder_open),
            _buildFilterOption('By MOC', Icons.category),
            _buildFilterOption('By Floor', Icons.construction),
            _buildFilterOption('By Status', Icons.flag),
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
        // Implement filter logic
      },
    );
  }
}

// Navigation Helper
extension AllMaterialsNavigation on BuildContext {
  void navigateToAllMaterials({
    required String siteId,
    required String teamId,
    String? teamName,
  }) {
    Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => AllMaterialsScreen(
          siteId: siteId,
          teamId: teamId,
          teamName: teamName,
        ),
      ),
    );
  }
}