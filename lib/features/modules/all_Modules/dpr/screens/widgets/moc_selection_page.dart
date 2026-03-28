// screens/moc_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';


import '../../../../../../features/language/service/providers.dart';


import '../../../site_Details/providers/site_current_provider.dart';
import '../../dpr-setup/screens/add/add_moc.dart';
import '../../models/moc.dart';
import '../../models/rate_file_models.dart';
import '../../providers/mocProvider.dart';
import '../../providers/rate_variant_provider.dart';
import '../../providers/selection_provider.dart';
import 'floor_selection_page.dart';
import 'moc_card_widget.dart';
import 'delete_mode_mixin.dart';

class MOCSelectionPage extends ConsumerStatefulWidget {
  final Function(String moc)? onMOCSelected;
  final bool showEditOptions;
  final String? siteId;
  final String? teamId;
  final String? teamName;

  const MOCSelectionPage({
    super.key,
    this.showEditOptions = false,
    this.onMOCSelected,
    this.siteId,
    this.teamId,
    this.teamName,
  });

  @override
  ConsumerState<MOCSelectionPage> createState() => _MOCSelectionPageState();
}

class _MOCSelectionPageState extends ConsumerState<MOCSelectionPage> with DeleteModeMixin<String> {
  String? _selectedMoc;

  void _selectAll(List<NamedImage> mocList) {
    setState(() {
      handleSelectAllToggle(mocList.map((e) => e.name).toList());
    });
  }
  Future<void> _deleteSelected() async {
    final siteId = ref.read(selectedSiteIdProvider)!;

    if (selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Selected MOCs"),
        content: Text(
            "Are you sure you want to delete ${selectedIds.length} items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final existingNames = ref.read(mocListDetectedProvider(siteId));
      final existingWithImages =
      ref.read(mocWithImagesProvider(siteId));

      final updatedNames = existingNames
          .where((name) => !selectedIds.contains(name))
          .toList();

      final updatedWithImages = existingWithImages
          .where((e) => !selectedIds.contains(e.name))
          .toList();

      final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
      final rateUploadId = rateFileMeta['rateFileId'];

      await ref.read(mocProvider.notifier).create(
        name: "",
        rateUploadId: rateUploadId,
        existingMocNames: updatedNames,
        existingMocsWithImages: updatedWithImages,
        image: null,
      );

      setState(() {
        isDeleteMode = false;
        selectedIds.clear();
      });

      ref.invalidate(rateFileAnalysisProvider(siteId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  Future<void> _deleteAll() async {
    final siteId = ref.read(selectedSiteIdProvider)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete All MOCs"),
        content: const Text("This will remove all MOCs. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
      final rateUploadId = rateFileMeta['rateFileId'];

      await ref.read(mocProvider.notifier).create(
        name: "",
        rateUploadId: rateUploadId,
        existingMocNames: [],
        existingMocsWithImages: [],
        image: null,
      );

      ref.invalidate(rateFileAnalysisProvider(siteId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteMoc(MOC moc) async {
    final siteId = ref.read(selectedSiteIdProvider)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete MOC"),
        content: Text("Are you sure you want to delete ${moc.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final existingNames =
      ref.read(mocListDetectedProvider(siteId));

      final existingWithImages =
      ref.read(mocWithImagesProvider(siteId));

      final updatedNames =
      existingNames.where((name) => name != moc.name).toList();

      final updatedWithImages =
      existingWithImages.where((e) => e.name != moc.name).toList();

      final rateFileMeta = ref.read(rateFileMetaProvider(siteId));
      final rateUploadId = rateFileMeta['rateFileId'];

      await ref.read(mocProvider.notifier).create(
        name: "", // not used
        rateUploadId: rateUploadId,
        existingMocNames: updatedNames,
        existingMocsWithImages: updatedWithImages,
        image: null,
      );

      ref.invalidate(rateFileAnalysisProvider(siteId));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    // ✅ ONLY RATE UPLOAD SOURCE
    final asyncRateUpload = ref.watch(rateFileAnalysisProvider(siteId));
    final mocList = ref.watch(mocWithImagesProvider(siteId));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: lang.chooseMocTitle),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
           if(!widget.showEditOptions) CustomButton(
              button: RoundedButton(
                text: lang.saveSubmitButton,
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: _selectedMoc == null
                    ? (){}
                    : () {
                  // ✅ callback
                  if (widget.onMOCSelected != null) {
                    widget.onMOCSelected!(_selectedMoc!);
                  }

                  // ✅ go next page
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
          child: asyncRateUpload.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              debugPrint('❌ rateFileAnalysisProvider error: $err');
              debugPrintStack(stackTrace: stack);
              return Center(child: Text('Error loading rate file'));
            },
            data: (_) {
              if (mocList.isEmpty) {
                return const Center(
                  child: Text("No MOC available"),
                );
              }

              final mocImages = ref.watch(mocWithImagesProvider(siteId));

              if (mocImages.isEmpty) {
                return const Center(child: Text("No MOC available"));
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// LEFT SIDE — TITLE OR EMPTY
                    Text(
                      isDeleteMode
                          ? '${selectedIds.length} / ${mocImages.length} selected'
                          : 'Total: ${mocImages.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),

                    /// RIGHT SIDE
                    if (!isDeleteMode)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            toggleDeleteMode();
                          });
                        },
                      )
                    else
                      Row(
                        children: [
                          /// Close Multi-Select
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                toggleDeleteMode();
                              });
                            },
                          ),

                          /// Select All
                          TextButton(
                            onPressed: () => _selectAll(mocImages),
                            child: Text(selectAllLabel(mocImages.map((e) => e.name).toList())),
                          ),

                          const SizedBox(width: 8),

                          /// Delete Selected
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text("Delete"),
                            onPressed: selectedIds.isEmpty ? null : _deleteSelected,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                    /// 🔥 THIS IS REQUIRED
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: mocImages.length,
                        itemBuilder: (context, index) {
                          final item = mocImages[index];

                          final moc = MOC(
                            name: item.name,
                            imageUrl: item.image.isNotEmpty
                                ? item.image
                                : 'assets/images/default_moc.webp',
                          );

                          return Stack(
                            children: [
                              Opacity(
                                opacity: isDeleteMode && !selectedIds.contains(moc.name) ? 0.5 : 1.0,
                                child: IgnorePointer(
                                  ignoring: isDeleteMode,
                                  child: MOCCard(
                                    showEditButton:
                                    widget.showEditOptions && !isDeleteMode,
                                    moc: moc,
                                    isSelected: !isDeleteMode && _selectedMoc == moc.name,
                                    onEdit: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddMOCPage(moc: moc),
                                        ),
                                      );

                                      if (result == true) {
                                        ref.invalidate(rateFileAnalysisProvider(siteId));
                                      }
                                    },
                                    onDelete: () => _deleteMoc(moc),
                                    onTap: () {
                                      setState(() => _selectedMoc = moc.name);
                                      ref
                                          .read(selectedMocNameProvider.notifier)
                                          .state = moc.name;
                                    },
                                  ),
                                ),
                              ),

                              /// 🔥 Selection Circle Overlay
                              if (isDeleteMode)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        toggleSelection(moc.name);
                                      });
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.05),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selectedIds.contains(moc.name)
                                                    ? Colors.red
                                                    : Colors.white,
                                                border: Border.all(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 4,
                                                    color: Colors.black26,
                                                  ),
                                                ],
                                              ),
                                              child: selectedIds.contains(moc.name)
                                                  ? const Icon(
                                                Icons.check,
                                                size: 20,
                                                color: Colors.white,
                                              )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );

            },
          ),
        ),
      ),
    );
  }
}
