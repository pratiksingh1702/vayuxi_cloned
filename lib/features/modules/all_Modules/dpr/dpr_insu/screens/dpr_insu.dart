// screens/dpr_insulation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';
import '../providers/insu_equipment.dart';
import '../providers/insu_piping.dart';

import '../providers/material_load.dart';
import '../service/material_service.dart';
import '../widgets/equipment_card.dart';
import '../widgets/piping_card.dart';

class DprInsulationScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String siteName;
  final String teamName;

  const DprInsulationScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.siteName,
    required this.teamName,
  }) : super(key: key);

  @override
  ConsumerState<DprInsulationScreen> createState() => _DprInsulationScreenState();
}

class _DprInsulationScreenState extends ConsumerState<DprInsulationScreen> {
  final InsulationMaterialSetupService _service = InsulationMaterialSetupService();

  @override
  void initState() {
    super.initState();
    // Load materials when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterials();
    });
  }

  Future<void> _loadMaterials() async {
    final apiNotifier = ref.read(insulationMaterialsApiProvider.notifier);
    try {
      final siteID=ref.read(selectedSiteIdProvider)!;
      await apiNotifier.fetchAndSetMaterials(siteId: siteID);
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

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(insulationMaterialsApiProvider);
    final pipingMaterials = ref.watch(insulationPipingMaterialsProvider);
    final equipmentMaterials = ref.watch(insulationEquipmentMaterialsProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'DPR Insulation - Materials',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: apiState.isLoading ? null : _loadMaterials,
          ),
        ],
      ),
      body: apiState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : apiState.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Error loading materials',
              style: TextStyle(color: Colors.red[700]),
            ),
            Text(
              apiState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadMaterials,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Piping',
                    count: pipingMaterials.length,
                    color: Colors.blue,
                    icon: Icons.construction,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Equipment',
                    count: equipmentMaterials.length,
                    color: Colors.green,
                    icon: Icons.build,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Total Materials: ${apiState.totalCount}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Piping Materials Section
            _pipingMaterialsSection(),

            const SizedBox(height: 24),

            _equipmentMaterialsSection(),

            const SizedBox(height: 30),

            // Create DPR Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _createDpr(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create DPR with Selected Materials',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count items',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  //
  // Widget _materialsSection({
  //   required String title,
  //   required bool isPiping,
  // }) {
  //   final materials = isPiping
  //       ? ref.watch(insulationPipingMaterialsProvider)
  //       : ref.watch(insulationEquipmentMaterialsProvider);
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         '$title (${materials.length})',
  //         style: const TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //
  //       if (materials.isEmpty)
  //         const Padding(
  //           padding: EdgeInsets.all(12),
  //           child: Text(
  //             'No materials available',
  //             style: TextStyle(color: Colors.grey),
  //           ),
  //         ),
  //
  //       ...materials.map((material) {
  //         if (isPiping) {
  //           return PipingMaterialCard(
  //             material: material,
  //             onChanged: (updated) {
  //
  //             },
  //             onAdd: () {
  //               // copy
  //             },
  //             onEdit: () {
  //               // edit
  //             },
  //             onDelete: () {
  //
  //             },
  //             onRemark: () {
  //               // open remark modal
  //             },
  //           );
  //         } else {
  //           return EquipmentMaterialCard(
  //             material: material,
  //             onChanged: (updated) {
  //
  //             },
  //             onAdd: () {
  //               // copy
  //             },
  //             onEdit: () {
  //               // edit
  //             },
  //             onDelete: () {
  //
  //             },
  //             onRemark: () {
  //               // open remark modal
  //             },
  //           );
  //         }
  //       }).toList(),
  //     ],
  //   );
  // }
  Widget _pipingMaterialsSection() {
    final materials = ref.watch(insulationPipingMaterialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Piping Materials (${materials.length})'),

        if (materials.isEmpty) _EmptyHint(),

        ...materials.map((PipingMaterial material) {
          return PipingMaterialCard(
            material: material,
            onChanged: (updated) {
              ref
                  .read(insulationPipingMaterialsProvider.notifier)
                  .editPipingMaterial(material.id, updated);
            },
            onAdd: () {
              // copy
            },
            onEdit: () {},
            onDelete: () {
              ref
                  .read(insulationPipingMaterialsProvider.notifier)
                  .deletePipingMaterial(material.id);
            },
            onRemark: () {},
          );
        }),
      ],
    );
  }
  Widget _equipmentMaterialsSection() {
    final materials = ref.watch(insulationEquipmentMaterialsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Equipment Materials (${materials.length})'),

        if (materials.isEmpty) _EmptyHint(),

        ...materials.map((EquipmentMaterial material) {
          return EquipmentMaterialCard(
            material: material,
            onChanged: (updated) {
              ref
                  .read(insulationEquipmentMaterialsProvider.notifier)
                  .editEquipmentMaterial(material.id, updated);
            },
            onAdd: () {},
            onEdit: () {},
            onDelete: () {
              ref
                  .read(insulationEquipmentMaterialsProvider.notifier)
                  .deleteEquipmentMaterial(material.id);
            },
            onRemark: () {},
          );
        }),
      ],
    );
  }
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  Widget _EmptyHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Text(
        'No materials available',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }





  Widget _materialCard({
    required dynamic material,
    required int index,
    required bool isPiping,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Index Badge
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Material Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width:120,
                        child: Text(
                          material.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(

                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPiping ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPiping ? 'PIPING' : 'EQUIPMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPiping ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UOM: ${material.uom}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (isPiping && material.size != null)
                    Text(
                      'Size: ${material.size}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            // Image Grid
            if (material.image.isNotEmpty)
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: material.image.length,
                  itemBuilder: (context, imgIndex) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        material.image[imgIndex],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 10, color: Colors.grey),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _createDpr(BuildContext context) {
    final pipingMaterials = ref.read(insulationPipingMaterialsProvider);
    final equipmentMaterials = ref.read(insulationEquipmentMaterialsProvider);

    if (pipingMaterials.isEmpty && equipmentMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No materials available to create DPR'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to DPR creation screen with materials
    context.push('/dpr-insulation-create', extra: {
      'siteId': widget.siteId,
      'teamId': widget.teamId,
      'siteName': widget.siteName,
      'teamName': widget.teamName,
      'pipingMaterials': pipingMaterials,
      'equipmentMaterials': equipmentMaterials,
    });
  }
}