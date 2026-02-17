import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../language/service/providers.dart';

import '../../../site_Details/providers/site_current_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/rate_variant_provider.dart';

import '../widgets/size_Selection.dart';
import '../widgets/floor_card.dart'; // 👈 FloorCard
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
  Set<String> _selectedFloorIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Floor> _filterFloors(List<Floor> floors) {
    var result = floors;


    if (_searchQuery.isNotEmpty) {
      result = result
          .where((f) =>
          f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (widget.ordered) {
      result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedFloorIds.clear();
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
                    widget.onFloorSelected?.call(_selectedFloor!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SizeSelectionPage(),
                      ),
                    );
                  },
                ),
              ),
          ],
          child: Column(
            children: [
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
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

              // if (widget.showEditOptions)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     child: Align(
              //       alignment: Alignment.centerRight,
              //       child: IconButton(
              //         icon: const Icon(Icons.delete_sweep, color: Colors.red),
              //         onPressed: _toggleSelectionMode,
              //       ),
              //     ),
              //   ),

              Expanded(
                child: filteredFloors.isEmpty
                    ? const Center(child: Text("No floors"))
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredFloors.length,
                    itemBuilder: (_, index) {
                      final floor = filteredFloors[index];
                      final isSelected =
                          _selectedFloor == floor.name;
                      final multiSelected =
                      _selectedFloorIds.contains(floor.id);

                      return Stack(
                        children: [
                          Opacity(
                            opacity: _isSelectionMode && !multiSelected
                                ? 0.5
                                : 1,
                            child: FloorCard(
                              floor: floor,
                              isSelected:
                              !_isSelectionMode && isSelected,
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleFloorSelection(floor.id);
                                } else {
                                  setState(() =>
                                  _selectedFloor = floor.name);
                                  ref
                                      .read(
                                    selectedFloorNameProvider
                                        .notifier,
                                  )
                                      .state = floor.name;
                                }
                              },
                            ),
                          ),
                          if (_isSelectionMode)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: multiSelected
                                    ? Colors.red
                                    : Colors.white,
                              ),
                            )
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
