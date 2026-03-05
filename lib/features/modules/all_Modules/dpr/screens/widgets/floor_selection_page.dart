import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../language/service/providers.dart';

import '../../../site_Details/providers/site_current_provider.dart';
import '../../dpr-setup/screens/add/add_floor.dart';
import '../../providers/floorProvider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/rate_variant_provider.dart';

import '../widgets/size_Selection.dart';
import '../widgets/floor_card.dart';
import '../../models/floorModel.dart';

class FloorSelectionPage extends ConsumerStatefulWidget {
  final Function(String floor)? onFloorSelected;
  final String? siteId;
  final String? teamId;
  final String? teamName;

  final bool showEditOptions;
  final bool showSearch;
  final bool showOnlyActive;
  final bool ordered;

  const FloorSelectionPage({
    super.key,
    this.onFloorSelected,
    this.siteId,
    this.teamId,
    this.teamName,
    this.showEditOptions = false,
    this.showSearch = true,
    this.showOnlyActive = true,
    this.ordered = true,
  });

  @override
  ConsumerState<FloorSelectionPage> createState() =>
      _FloorSelectionPageState();
}

class _FloorSelectionPageState extends ConsumerState<FloorSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFloor;

  bool _isSelectionMode = false;
  final Set<String> _selectedFloorIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /* ===============================
     DELETE SINGLE FLOOR
  =============================== */

  Future<void> _deleteFloor(Floor floor) async {
    final siteId = ref.read(selectedSiteIdProvider)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Floor"),
        content: Text("Delete ${floor.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
    final rateUploadId = rateFileMeta['rateFileId'];

    final existingNames =
    ref.read(floorListDetectedProvider(siteId));

    final existingFloors =
    ref.read(floorWithImagesProvider(siteId));

    final updatedNames =
    existingNames.where((e) => e != floor.name).toList();

    final updatedFloors =
    existingFloors.where((e) => e.name != floor.name).toList();

    await ref.read(floorProvider.notifier).create(
      name: "",
      rateUploadId: rateUploadId,
      existingFloorNames: updatedNames,
      existingFloorsWithImages: updatedFloors,
      image: null,
    );

    ref.invalidate(rateFileAnalysisProvider(siteId));
  }

  /* ===============================
     MULTI SELECT
  =============================== */

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedFloorIds.clear();
    });
  }

  void _toggleFloorSelection(String id) {
    setState(() {
      if (_selectedFloorIds.contains(id)) {
        _selectedFloorIds.remove(id);
      } else {
        _selectedFloorIds.add(id);
      }
    });
  }

  void _selectAll(List<Floor> floors) {
    setState(() {
      _selectedFloorIds
        ..clear()
        ..addAll(floors.map((e) => e.id));
    });
  }

  Future<void> _deleteSelected() async {
    final siteId = ref.read(selectedSiteIdProvider)!;

    if (_selectedFloorIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Selected Floors"),
        content: Text(
            "Delete ${_selectedFloorIds.length} floors?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
    final rateUploadId = rateFileMeta['rateFileId'];

    final existingNames =
    ref.read(floorListDetectedProvider(siteId));

    final existingFloors =
    ref.read(floorWithImagesProvider(siteId));

    final updatedNames = existingNames
        .where((e) => !_selectedFloorIds.contains(e))
        .toList();

    final updatedFloors = existingFloors
        .where((e) => !_selectedFloorIds.contains(e.id))
        .toList();

    await ref.read(floorProvider.notifier).create(
      name: "",
      rateUploadId: rateUploadId,
      existingFloorNames: updatedNames,
      existingFloorsWithImages: updatedFloors,
      image: null,
    );

    setState(() {
      _isSelectionMode = false;
      _selectedFloorIds.clear();
    });

    ref.invalidate(rateFileAnalysisProvider(siteId));
  }

  /* ===============================
     FILTER + SORT
  =============================== */

  List<Floor> _filterFloors(List<Floor> floors) {
    var result = floors;

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((f) => f.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return result;
  }

  /* ===============================
     UI
  =============================== */

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final siteId = ref.watch(selectedSiteIdProvider);

    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("Site not selected")),
      );
    }

    final floors = ref.watch(floorWithImagesProvider(siteId));
    final filteredFloors = _filterFloors(floors);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          CustomSliverAppBar(title: lang.chooseFloorTitle),
        ],
        body: BottomButtonWrapper(
          customButtons: [
            if (!widget.showEditOptions)
              CustomButton(
                button: RoundedButton(
                  text: lang.saveSubmitButton,
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: _selectedFloor == null
                      ? () {}
                      : () {
                    widget.onFloorSelected
                        ?.call(_selectedFloor!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const SizeSelectionPage(),
                      ),
                    );
                  },
                ),
              ),
          ],
          child: Column(
            children: [

              /* SEARCH */
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search floors...',
                      prefixIcon:
                      const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  ),
                ),

              /* DELETE ICON ROW */
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: !_isSelectionMode
                      ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: _toggleSelectionMode,
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _selectAll(filteredFloors),
                        child:
                        const Text("Select All"),
                      ),
                      TextButton(
                        onPressed: _deleteSelected,
                        child: Text(
                          "Delete (${_selectedFloorIds.length})",
                          style: const TextStyle(
                              color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon:
                        const Icon(Icons.close),
                        onPressed:
                        _toggleSelectionMode,
                      )
                    ],
                  ),
                ),
              ),

              /* GRID */
              Expanded(
                child: filteredFloors.isEmpty
                    ? const Center(
                  child: Text("No floors"),
                )
                    : Padding(
                  padding:
                  const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount:
                    filteredFloors.length,
                    itemBuilder: (_, index) {
                      final floor =
                      filteredFloors[index];

                      final multiSelected =
                      _selectedFloorIds
                          .contains(floor.id);

                      return Stack(
                        children: [

                          FloorCard(
                            floor: floor,
                            showEditButton:
                            widget.showEditOptions &&
                                !_isSelectionMode,
                            isSelected:
                            !_isSelectionMode &&
                                _selectedFloor ==
                                    floor.name,
                            onEdit: () async {
                              final result =
                              await Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddFloorPage(
                                          floor:
                                          floor),
                                ),
                              );

                              if (result ==
                                  true) {
                                ref.invalidate(
                                    rateFileAnalysisProvider(
                                        siteId));
                              }
                            },
                            onDelete: () =>
                                _deleteFloor(
                                    floor),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleFloorSelection(
                                    floor.id);
                              } else {
                                setState(() =>
                                _selectedFloor =
                                    floor
                                        .name);
                                ref
                                    .read(
                                    selectedFloorNameProvider
                                        .notifier)
                                    .state =
                                    floor.name;
                              }
                            },
                          ),

                          /* CIRCLE OVERLAY */
                          if (_isSelectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: AnimatedContainer(
                                duration:
                                const Duration(
                                    milliseconds:
                                    200),
                                width: 26,
                                height: 26,
                                decoration:
                                BoxDecoration(
                                  shape: BoxShape
                                      .circle,
                                  color:
                                  multiSelected
                                      ? Colors
                                      .red
                                      : Colors
                                      .white,
                                  border:
                                  Border.all(
                                    color:
                                    Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: multiSelected
                                    ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors
                                      .white,
                                )
                                    : null,
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
}