// screens/floor_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/add/add_floor.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/size_Selection.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../language/service/providers.dart';
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
  final String? siteId;
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

  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedFloorIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteId = ref.read(selectedSiteIdProvider);
      ref.read(floorProvider.notifier).fetchBySite(siteId!);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Floor> _getFilteredFloors(List<Floor> floors) {
    if (_searchQuery.isEmpty) return floors;

    return floors
        .where((f) =>
        f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFloorIds.clear();
      }
    });
  }

  /// Toggle individual floor selection
  void _toggleFloorSelection(String floorId) {
    setState(() {
      if (_selectedFloorIds.contains(floorId)) {
        _selectedFloorIds.remove(floorId);
      } else {
        _selectedFloorIds.add(floorId);
      }
    });
  }

  /// Select all floors
  void _selectAllFloors(List<Floor> floors) {
    setState(() {
      for (var floor in floors) {
        _selectedFloorIds.add(floor.id);
      }
    });
  }

  /// Delete selected floors
  Future<void> _deleteSelectedFloors() async {
    if (_selectedFloorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No floors selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Floors'),
        content: Text(
          'Are you sure you want to delete ${_selectedFloorIds.length} selected floors?\n\n'
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(floorApiProvider).bulkDeleteFloor(ids:_selectedFloorIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted ${_selectedFloorIds.length} floors'),
            backgroundColor: Colors.green,
          ),
        );
      }
      final siteId = ref.read(selectedSiteIdProvider);
      ref.read(floorProvider.notifier).fetchBySite(siteId!);

      setState(() {
        _selectedFloorIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final floorState = ref.watch(floorProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final filteredFloors = _getFilteredFloors(floorState.floors);
    final lang=ref.watch(dailyEntryTranslationHelperProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: lang.chooseFloorTitle),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            if (!widget.showEditOptions)
              CustomButton(
                button: RoundedButton(
                  text: lang.saveSubmitButton,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SizeSelectionPage(),
                      ),
                    );
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

              // Bulk delete controls
              if (widget.showEditOptions && filteredFloors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isSelectionMode) ...[
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSelectionMode,
                          tooltip: 'Cancel',
                        ),
                        TextButton(
                          onPressed: () => _selectAllFloors(filteredFloors),
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete'),
                          onPressed: _selectedFloorIds.isEmpty
                              ? null
                              : _deleteSelectedFloors,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          onPressed: _toggleSelectionMode,
                          tooltip: 'Select Floors to Delete',
                        ),
                      ],
                    ],
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
                              .fetchBySite(widget.siteId!);
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
                      final isSelected =
                      _selectedFloorIds.contains(floor.id);

                      return Stack(
                        children: [
                          Opacity(
                            opacity: _isSelectionMode && !isSelected
                                ? 0.5
                                : 1.0,
                            child: FloorCard(
                              floor: floor,
                              isSelected: !widget.showEditOptions
                                  ? selectedFloor?.id == floor.id
                                  : false,
                              showEditButton: widget.showEditOptions &&
                                  !_isSelectionMode,
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleFloorSelection(floor.id);
                                } else {
                                  ref
                                      .read(floorProvider.notifier)
                                      .select(floor);
                                }
                              },
                              onEdit: _isSelectionMode
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddFloorPage(
                                            floor: floor),
                                  ),
                                );
                              },
                              onDelete: _isSelectionMode
                                  ? null
                                  : () {
                                _showDeleteConfirmationDialog(
                                    context, floor);
                              },
                            ),
                          ),
                          if (_isSelectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    _toggleFloorSelection(floor.id),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.white,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                      : null,
                                ),
                              ),
                            ),
                        ],
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
              ref.read(floorProvider.notifier).delete(floor.id);
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