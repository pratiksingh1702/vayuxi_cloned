// screens/moc_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../models/moc.dart';
import '../../providers/mocProvider.dart';

import 'floor_selection_page.dart';
import 'moc_card_widget.dart';

class MOCSelectionPage extends ConsumerStatefulWidget {
  final bool showEditOptions;
  final Function(MOC)? onMOCSelected;
  final String? title;
  final String? siteId; // Add these parameters
  final String? teamId;
  final String? teamName;

  const MOCSelectionPage({
    super.key,
    this.showEditOptions = false,
    this.onMOCSelected,
    this.title,
    this.siteId, this.teamId, this.teamName,
  });

  @override
  ConsumerState<MOCSelectionPage> createState() => _MOCSelectionPageState();
}

class _MOCSelectionPageState extends ConsumerState<MOCSelectionPage> {
  @override
  void initState() {
    super.initState();
    // Load MOCs when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mocProvider.notifier).loadMOCs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mocState = ref.watch(mocProvider);
    final mocs = ref.watch(mocListProvider);

    final selectedMOC = ref.watch(selectedMOCProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Select MOC"),
      body: mocState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mocState.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${mocState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(mocProvider.notifier).loadMOCs();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : mocState.error != null
          ? const Center(
        child: Text('No materials available'),
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
          itemCount: mocs.length,
          itemBuilder: (context, index) {
            final moc = mocs[index];
            return MOCCard(
              moc: moc,
              isSelected: selectedMOC?.id == moc.id,
              showEditButton: widget.showEditOptions,
              onTap: () {
                ref.read(mocProvider.notifier).select(moc);
                if (widget.onMOCSelected != null) {
                  widget.onMOCSelected!(moc);
                }
                // If this is a selection screen, pop back
                if (widget.onMOCSelected != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FloorSelectionPage(
                        teamName: widget.teamName,
                        teamId: widget.teamId,
                        siteId: widget.siteId,
                        onFloorSelected: (selectedFloor) {
                          print('Selected Floor: ${selectedFloor.name}');
                        },
                      ),
                    ),
                  );
                }
              },
              onEdit: () {
                _showAddEditMOCDialog(context, moc: moc);
              },
              onDelete: () {
                _showDeleteConfirmationDialog(context, moc);
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddEditMOCDialog(BuildContext context, {MOC? moc}) {
    final nameController = TextEditingController(text: moc?.name);
    final imageController = TextEditingController(text: moc?.imageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(moc == null ? 'Add MOC' : 'Edit MOC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Material Name',
                hintText: 'e.g., SS304, HDPE, CS',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(
                labelText: 'Image Path/URL',
                hintText: 'assets/images/ss304.png or https://...',
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
              final image = imageController.text.trim();

              if (name.isEmpty || image.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final updatedMOC = MOC(
                id: moc?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                imageUrl: image,
                createdAt: moc?.createdAt ?? DateTime.now(),

              );

              if (moc == null) {
                ref.read(mocProvider.notifier).add(updatedMOC);
              } else {
                ref.read(mocProvider.notifier).update(updatedMOC);
              }

              Navigator.pop(context);
            },
            child: Text(moc == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, MOC moc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete MOC'),
        content: Text('Are you sure you want to delete ${moc.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(mocProvider.notifier).delete(moc.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}