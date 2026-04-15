// floor_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';

import '../../../../../../core/utlis/widgets/afd.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../models/floorModel.dart';
import '../../screens/widgets/floor_card.dart';

import '../model/insu_step_date.dart';
import 'insulation-layer.dart';

class FloorSelectionScreen extends ConsumerWidget {
  final String siteId;
  final String teamId;
  final String name;
  final String teamName;

  FloorSelectionScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.name,
    required this.teamName,
  }) : super(key: key);

  final List<Floor> allFloors = [
    Floor(
      id: 'floor_ground',
      name: 'Ground',
      image: 'assets/floor/groundfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_first',
      name: 'First',
      image: 'assets/floor/firstfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_second',
      name: 'Second',
      image: 'assets/floor/secondfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_third',
      name: 'Third',
      image: 'assets/floor/thirdfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_fourth',
      name: 'Fourth',
      image: 'assets/floor/fourthfloor.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Floor(
      id: 'floor_terrace',
      name: 'Terrace',
      image: 'assets/floor/terrace.webp',
      siteId: null,
      isApplied: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFloor = ref.watch(insulationStateProvider).floor;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(title: "Choose Floor"),
      body: BottomButtonWrapper(
        child: Column(
          children: [
            // --- Skip button row ---
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LayerSelectionScreen(
                            siteId: siteId,
                            teamId: teamId,
                            siteName: name,
                            teamName: teamName,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.6)),
                ),
                child: Text(
                  'Select floor to set up insulation details.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // --- Grid ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: allFloors.length,
                  itemBuilder: (context, index) {
                    final floor = allFloors[index];
                    final isSelected = selectedFloor == floor.name;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withOpacity(0.7)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withOpacity(0.45),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloorCard(
                        floor: floor,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(insulationStateProvider.notifier)
                              .setFloor(floor.name);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LayerSelectionScreen(
                                siteId: siteId,
                                teamId: teamId,
                                siteName: name,
                                teamName: teamName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _navArgs() {
    return {
      'siteId': siteId,
      'teamId': teamId,
      'siteName': name,
      'teamName': teamName,
    };
  }
}
