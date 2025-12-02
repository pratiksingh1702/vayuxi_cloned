import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MaterialSelectionDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> pipingMaterials;
  final List<Map<String, dynamic>> equipmentMaterials;
  final Function(List<Map<String, dynamic>>) onMaterialsSelected;

  const MaterialSelectionDialog({
    required this.title,
    required this.pipingMaterials,
    required this.equipmentMaterials,
    required this.onMaterialsSelected,
    super.key,
  });

  @override
  State<MaterialSelectionDialog> createState() => _MaterialSelectionDialogState();
}

class _MaterialSelectionDialogState extends State<MaterialSelectionDialog> {
  final Set<String> _selectedMaterialIds = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Piping'),
                        Tab(text: 'Equipment'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildMaterialList(widget.pipingMaterials),
                          _buildMaterialList(widget.equipmentMaterials),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final allMaterials = [
                        ...widget.pipingMaterials,
                        ...widget.equipmentMaterials,
                      ];
                      final selectedMaterials = allMaterials
                          .where((material) => _selectedMaterialIds.contains(material['id']))
                          .toList();
                      widget.onMaterialsSelected(selectedMaterials);
                      Navigator.pop(context);
                    },
                    child: const Text('Add Selected'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialList(List<Map<String, dynamic>> materials) {
    if (materials.isEmpty) {
      return const Center(child: Text('No materials available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return MaterialSelectionItem(
          material: material,
          isSelected: _selectedMaterialIds.contains(material['id']),
          onSelectionChanged: (selected) {
            setState(() {
              if (selected) {
                _selectedMaterialIds.add(material['id']);
              } else {
                _selectedMaterialIds.remove(material['id']);
              }
            });
          },
        );
      },
    );
  }
}

class MaterialSelectionItem extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const MaterialSelectionItem({
    required this.material,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: CheckboxListTile(
        title: Text(material['materialName'] ?? 'Unknown Material'),
        subtitle: Text('Unit: ${material['uom'] ?? 'N/A'}'),
        secondary: SizedBox(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: _cleanImageUrl(material['image'] ?? ''),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 20, color: Colors.grey),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
            ),
          ),
        ),
        value: isSelected,
        onChanged: (value) => onSelectionChanged(value ?? false),
      ),
    );
  }
}