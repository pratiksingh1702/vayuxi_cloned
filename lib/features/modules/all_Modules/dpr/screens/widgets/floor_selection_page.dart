// screens/floor_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../models/floorModel.dart';
import '../../providers/floorProvider.dart';
import '../../providers/selectedSize_provider.dart';
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
    this.siteId,
    this.teamId,
    this.teamName,
  });

  @override
  ConsumerState<FloorSelectionPage> createState() =>
      _FloorSelectionPageState();
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
      filtered = ref
          .read(floorProvider.notifier)
          .orderedFloors
          .where((floor) => filtered.contains(floor))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((floor) =>
      floor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          floor.code.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _showSizeInputDialog(BuildContext context) {
    final TextEditingController sizeController = TextEditingController();
    final FocusNode sizeFocusNode = FocusNode();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.straighten,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Size',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Please specify the size in inches',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Size input field
                TextField(
                  controller: sizeController,
                  focusNode: sizeFocusNode,
                  decoration: InputDecoration(
                    hintText: 'e.g., 10, 12.5, 8, etc.',
                    labelText: 'Size (inches)',
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: const Icon(Icons.construction, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _saveSizeAndNavigate(context, value.trim());
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Enter the size measurement in inches',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (sizeController.text.trim().isNotEmpty) {
                            _saveSizeAndNavigate(
                                context, sizeController.text.trim());
                          } else {
                            // Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a size'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      sizeController.dispose();
      sizeFocusNode.dispose();
    });
  }

  void _saveSizeAndNavigate(BuildContext context, String size) {
    // Save the size (you might want to save it to a provider or state)
    // For now, just navigate to next page
    Navigator.pop(context); // Close the dialog

    // You can save the size to a provider here if needed
    ref.read(selectedSizeProvider.notifier).state = size;

    // Navigate to description page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDescriptionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floorState = ref.watch(floorProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final filteredFloors = _getFilteredFloors(floorState.floorList);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Floor List"),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: "Save & Submit",
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: () {
                  if (selectedFloor == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a floor first'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  // Show the size input dialog
                  _showSizeInputDialog(context);
                },
              ),
            )
          ],
          child: Column(
            children: [
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search floors...',
                      prefixIcon: const Icon(Icons.search),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
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
                          ref
                              .read(floorProvider.notifier)
                              .loadFloors();
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
                      const Icon(Icons.search_off,
                          size: 64, color: Colors.grey),
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
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                        isSelected:
                        selectedFloor?.id == floor.id,
                        showEditButton: widget.showEditOptions,
                        onTap: () {
                          // JUST select. Nothing else.
                          ref
                              .read(floorProvider.notifier)
                              .selectFloor(floor);
                        },
                        onEdit: () {
                          _showAddEditFloorDialog(context,
                              floor: floor);
                        },
                        onDelete: () {
                          _showDeleteConfirmationDialog(
                              context, floor);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    behavior: SnackBarBehavior.floating,
                  ),
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
            child:
            const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}