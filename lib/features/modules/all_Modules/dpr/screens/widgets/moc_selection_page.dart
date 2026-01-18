// screens/moc_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../dpr-setup/screens/add/add_moc.dart';
import '../../models/moc.dart';
import '../../providers/mocProvider.dart';

import 'floor_selection_page.dart';
import 'moc_card_widget.dart';

class MOCSelectionPage extends ConsumerStatefulWidget {
  final bool showEditOptions;
  final Function(MOC)? onMOCSelected;
  final String? title;
  final String? siteId;
  final String? teamId;
  final String? teamName;

  const MOCSelectionPage({
    super.key,
    this.showEditOptions = false,
    this.onMOCSelected,
    this.title,
    this.siteId,
    this.teamId,
    this.teamName,
  });

  @override
  ConsumerState<MOCSelectionPage> createState() => _MOCSelectionPageState();
}

class _MOCSelectionPageState extends ConsumerState<MOCSelectionPage> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedMOCIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteID = ref.read(selectedSiteIdProvider);
      ref.read(mocProvider.notifier).fetchBySite(siteID!);
    });
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMOCIds.clear();
      }
    });
  }

  /// Toggle individual MOC selection
  void _toggleMOCSelection(String mocId) {
    setState(() {
      if (_selectedMOCIds.contains(mocId)) {
        _selectedMOCIds.remove(mocId);
      } else {
        _selectedMOCIds.add(mocId);
      }
    });
  }

  /// Select all MOCs
  void _selectAllMOCs(List<MOC> mocs) {
    setState(() {
      for (var moc in mocs) {
        _selectedMOCIds.add(moc.id);
      }
    });
  }

  /// Delete selected MOCs
  Future<void> _deleteSelectedMOCs() async {
    if (_selectedMOCIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No MOCs selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected MOCs'),
        content: Text(
          'Are you sure you want to delete ${_selectedMOCIds.length} selected MOCs?\n\n'
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
      await ref.read(mocApiProvider).bulkDeleteMoc(ids:_selectedMOCIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted ${_selectedMOCIds.length} MOCs'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedMOCIds.clear();
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
    final mocState = ref.watch(mocProvider);
    final mocs = ref.watch(mocListProvider);
    final selectedMOC = ref.watch(selectedMOCProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Choose MOC"),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            if (!widget.showEditOptions)
              CustomButton(
                button: RoundedButton(
                  text: "Save & Submit",
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: selectedMOC == null
                      ? (){}
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FloorSelectionPage(
                          teamName: widget.teamName,
                          teamId: widget.teamId,
                          siteId: widget.siteId,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
          child: Column(
            children: [
              // Bulk delete controls
              if (widget.showEditOptions && mocs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          onPressed: () => _selectAllMOCs(mocs),
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete'),
                          onPressed: _selectedMOCIds.isEmpty
                              ? null
                              : _deleteSelectedMOCs,
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
                          tooltip: 'Select MOCs to Delete',
                        ),
                      ],
                    ],
                  ),
                ),

              Expanded(
                child: mocState.isLoading
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
                          ref
                              .read(mocProvider.notifier)
                              .fetchBySite(widget.siteId!);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : mocs.isEmpty
                    ? const Center(
                  child: Text('No materials available'),
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
                    itemCount: mocs.length,
                    itemBuilder: (context, index) {
                      final moc = mocs[index];
                      final isSelected =
                      _selectedMOCIds.contains(moc.id);

                      return Stack(
                        children: [
                          Opacity(
                            opacity: _isSelectionMode && !isSelected
                                ? 0.5
                                : 1.0,
                            child: MOCCard(
                              moc: moc,
                              isSelected: !widget.showEditOptions
                                  ? selectedMOC?.id == moc.id
                                  : false,
                              showEditButton:
                              widget.showEditOptions &&
                                  !_isSelectionMode,
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleMOCSelection(moc.id);
                                } else {
                                  if (!widget.showEditOptions) {
                                    ref
                                        .read(mocProvider.notifier)
                                        .select(moc);
                                  }
                                  if (widget.onMOCSelected !=
                                      null) {
                                    widget.onMOCSelected!(moc);
                                  }
                                }
                              },
                              onEdit: _isSelectionMode
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddMOCPage(moc: moc),
                                  ),
                                );
                              },
                              onDelete: _isSelectionMode
                                  ? null
                                  : () {
                                _showDeleteConfirmationDialog(
                                    context, moc);
                              },
                            ),
                          ),
                          if (_isSelectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    _toggleMOCSelection(moc.id),
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
                                        offset:
                                        const Offset(0, 2),
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
            onPressed: () async {
              await ref.read(mocProvider.notifier).delete(moc.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}