// screens/floor_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../models/floorModel.dart';
import '../../providers/floorProvider.dart';

import '../add_description.dart';
import '../widgets/floor_card.dart';

class FloorSelectionPage extends ConsumerStatefulWidget {
  final bool showEditOptions;
  final Function(Floor)? onFloorSelected;
  final String? title;
  final bool showSearch;
  final bool showOnlyActive;
  final bool ordered;
  final String? siteId; // Add these parameters
  final String? teamId;
  final String? teamName;

  const FloorSelectionPage({
    super.key,
    this.showEditOptions = false,
    this.onFloorSelected,
    this.title,
    this.showSearch = true,
    this.showOnlyActive = true,
    this.ordered = true,
    this.siteId, this.teamId, this.teamName,
  });

  @override
  ConsumerState<FloorSelectionPage> createState() => _FloorSelectionPageState();
}

class _FloorSelectionPageState extends ConsumerState<FloorSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load Floors when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floorProvider.notifier).loadFloors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Floor> _getFilteredFloors(List<Floor> allFloors) {
    List<Floor> filtered = widget.showOnlyActive
        ? allFloors.where((floor) => floor.isActive).toList()
        : allFloors;

    if (widget.ordered) {
      filtered = ref.read(floorProvider.notifier).orderedFloors
          .where((floor) => filtered.contains(floor))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((floor) =>
      floor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          floor.code.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final floorState = ref.watch(floorProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final filteredFloors = _getFilteredFloors(floorState.floorList);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar:CustomAppBar(title: "Select Floor"),
      body: Column(
        children: [
          // Search Bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search floors...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // Floors Grid
          Expanded(
            child: floorState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : floorState.error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${floorState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(floorProvider.notifier).loadFloors();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : filteredFloors.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No floors available'
                        : 'No floors found for "$_searchQuery"',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: filteredFloors.length,
                itemBuilder: (context, index) {
                  final floor = filteredFloors[index];
                  return FloorCard(
                    floor: floor,
                    isSelected: selectedFloor?.id == floor.id,
                    showEditButton: widget.showEditOptions,
                    onTap: () {
                      ref.read(floorProvider.notifier).selectFloor(floor);
                      if (widget.onFloorSelected != null) {
                        widget.onFloorSelected!(floor);
                      }
                      // If this is a selection screen, pop back
                      if (widget.onFloorSelected != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDescriptionScreen(
                              siteId:widget.siteId,
                              teamId: widget.teamId,
                              teamName: widget.teamName,
                            ),
                          ),
                        );
                      }
                    },
                    onEdit: () {
                      _showAddEditFloorDialog(context, floor: floor);
                    },
                    onDelete: () {
                      _showDeleteConfirmationDialog(context, floor);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditFloorDialog(BuildContext context, {Floor? floor}) {
    final nameController = TextEditingController(text: floor?.name);
    final codeController = TextEditingController(text: floor?.code);
    final imageController = TextEditingController(text: floor?.image);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(floor == null ? 'Add Floor' : 'Edit Floor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Floor Name',
                hintText: 'e.g., Ground Floor, First Floor',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Floor Code',
                hintText: 'e.g., ground, first, basement',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(
                labelText: 'Image Path/URL',
                hintText: 'assets/dpr/floor/groundfloor.png',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final image = imageController.text.trim();

              if (name.isEmpty || code.isEmpty || image.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final updatedFloor = Floor(
                id: floor?.id ?? code, // Use code as ID for new floors
                name: name,
                code: code,
                image: image,
                createdAt: floor?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              if (floor == null) {
                ref.read(floorProvider.notifier).addFloor(updatedFloor);
              } else {
                ref.read(floorProvider.notifier).updateFloor(updatedFloor);
              }

              Navigator.pop(context);
            },
            child: Text(floor == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Floor floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Floor'),
        content: Text('Are you sure you want to delete ${floor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(floorProvider.notifier).deleteFloor(floor.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}