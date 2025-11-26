import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/dprModel.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dpr.dart';

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
  List<DprModel> _availableMaterials = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Cached material lists
  List<Map<String, dynamic>>? _cachedPipingMaterials;
  List<Map<String, dynamic>>? _cachedEquipmentMaterials;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _fetchMaterials();
      });


  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMaterials() async {
    if (widget.siteId == null || widget.teamId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Site ID or Team ID is missing';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await ref.read(dprProvider.notifier).fetchDprWork(
        siteId: widget.siteId!,
        teamId: widget.teamId!,
      );

      final dprState = ref.read(dprProvider);
      if (dprState.data != null && dprState.data is List<DprModel>) {
        setState(() {
          _availableMaterials = dprState.data as List<DprModel>;
          // Clear cache when new data arrives
          _cachedPipingMaterials = null;
          _cachedEquipmentMaterials = null;
        });
        _printMaterialSummary();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'No materials data found';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load materials: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _printMaterialSummary() {
    print('📊 MATERIALS SUMMARY:');
    print('   Total DPR Entries: ${_availableMaterials.length}');
    print('   Total Piping Materials: ${_getPipingMaterials().length}');
    print('   Total Equipment Materials: ${_getEquipmentMaterials().length}');
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  List<Map<String, dynamic>> _getPipingMaterials() {
    if (_cachedPipingMaterials != null) {
      return _cachedPipingMaterials!;
    }

    final List<Map<String, dynamic>> pipingMaterials = [];

    for (final dpr in _availableMaterials) {
      for (final piping in dpr.piping) {
        pipingMaterials.add({
          'id': piping.id,
          'materialName': piping.materialName,
          'uom': piping.uom,
          'image': _cleanImageUrl(piping.image),
          'category': 'piping',
          'dprName': dpr.dprName,
          'originalData': piping,
        });
      }
    }

    _cachedPipingMaterials = pipingMaterials;
    return pipingMaterials;
  }

  List<Map<String, dynamic>> _getEquipmentMaterials() {
    if (_cachedEquipmentMaterials != null) {
      return _cachedEquipmentMaterials!;
    }

    final List<Map<String, dynamic>> equipmentMaterials = [];

    for (final dpr in _availableMaterials) {
      for (final equipment in dpr.equipment) {
        equipmentMaterials.add({
          'id': equipment.id,
          'materialName': equipment.materialName,
          'uom': equipment.uom,
          'image': _cleanImageUrl(equipment.image),
          'category': 'equipment',
          'dprName': dpr.dprName,
          'originalData': equipment,
        });
      }
    }

    _cachedEquipmentMaterials = equipmentMaterials;
    return equipmentMaterials;
  }

  @override
  Widget build(BuildContext context) {
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

            // Loading Indicator
            if (_isLoading) _buildLoadingIndicator(),

            // Error Message
            if (_hasError && !_isLoading) _buildErrorWidget(),

            // Content
            if (!_isLoading && !_hasError) _buildContent(),

            // Empty State
            if (!_isLoading && !_hasError && _availableMaterials.isEmpty) _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading materials...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading Materials',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchMaterials,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // Piping Materials Tab
          _buildMaterialsList(
            materials: _getPipingMaterials(),
            emptyMessage: 'No piping materials found',
            icon: Icons.precision_manufacturing,
            color: Colors.blue,
          ),

          // Equipment Materials Tab
          _buildMaterialsList(
            materials: _getEquipmentMaterials(),
            emptyMessage: 'No equipment materials found',
            icon: Icons.build,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Materials Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Materials will appear here once they are added to DPR entries.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchMaterials,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsList({
    required List<Map<String, dynamic>> materials,
    required String emptyMessage,
    required IconData icon,
    required Color color,
  }) {
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            color: color.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${materials.length} items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Materials List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return _buildMaterialCard(material, color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material, Color color) {
    final materialName = material['materialName'] ?? 'Unknown Material';
    final uom = material['uom'] ?? 'N/A';
    final imageUrl = material['image'] ?? '';
    final dprName = material['dprName'] ?? 'Unknown DPR';
    final category = material['category'] ?? 'material';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Icon(
                    category == 'piping' ? Icons.precision_manufacturing : Icons.build,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Material Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materialName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.square_foot, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Unit: $uom',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Icon(Icons.folder_open, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'DPR: $dprName',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Icon
            Icon(
              category == 'piping' ? Icons.precision_manufacturing : Icons.build,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
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