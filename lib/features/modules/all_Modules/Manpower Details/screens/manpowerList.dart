import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/offline/repo/att_sync.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import 'package:untitled2/core/utlis/widgets/shimmer.dart';

import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../attendance/offline/repo/att_offline_provider.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import '../../../../tour/definitions/manpower_team_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';
import '../service/manpowerService.dart';
import '../util/ViewExcel.dart';

enum ManpowerSortOption {
  nameAsc,
  nameDesc,
  createdAtDesc,
  createdAtAsc,
  salaryHighToLow,
  salaryLowToHigh,
}

class ManpowerListScreen extends ConsumerStatefulWidget {
  const ManpowerListScreen({super.key});

  @override
  ConsumerState<ManpowerListScreen> createState() => _ManpowerListScreenState();
}

class _ManpowerListScreenState extends ConsumerState<ManpowerListScreen> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedManpowerIds = {};
  String _searchQuery = '';
  String _lastSortedOrderSignature = '';
  final ScrollController _scrollController = ScrollController();
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _sheetTourKey = GlobalKey(debugLabel: 'manpower_list_sheet');
  final GlobalKey _searchTourKey =
      GlobalKey(debugLabel: 'manpower_list_search');
  final GlobalKey _deleteModeTourKey =
      GlobalKey(debugLabel: 'manpower_list_delete_mode');
  final GlobalKey _firstManpowerTourKey =
      GlobalKey(debugLabel: 'manpower_list_first_record');
  final GlobalKey _emptyTourKey = GlobalKey(debugLabel: 'manpower_list_empty');
  final GlobalKey _noResultsTourKey =
      GlobalKey(debugLabel: 'manpower_list_no_results');

  // Sorting and Filtering State
  ManpowerSortOption _currentSort = ManpowerSortOption.createdAtDesc;
  String? _selectedDesignation;
  double? _minSalary;
  double? _maxSalary;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final type = ref.read(typeProvider);
      if (type != null && type.isNotEmpty) {
        ref.invalidate(manpowerSyncControllerProvider((type: type!)));
        // ref.read(manpowerProvider.notifier).fetchManpower(type);
      } else {
        debugPrint("❌ Type not set in typeProvider");
      }
    });
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedManpowerIds.clear();
      }
    });
  }

  /// Toggle individual manpower selection
  void _toggleManpowerSelection(String manpowerId) {
    setState(() {
      if (_selectedManpowerIds.contains(manpowerId)) {
        _selectedManpowerIds.remove(manpowerId);
      } else {
        _selectedManpowerIds.add(manpowerId);
      }
    });
  }

  /// Select all manpower
  void _selectAllManpower(List<ManpowerModel> manpowerList) {
    setState(() {
      for (var manpower in manpowerList) {
        if (manpower.id != null) {
          _selectedManpowerIds.add(manpower.id!);
        }
      }
    });
  }

  /// Delete selected manpower
  Future<void> _deleteSelectedManpower() async {
    if (_selectedManpowerIds.isEmpty) {
      AppToast.show('No manpower selected');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Selected Manpower'),
          content: Text(
            'Are you sure you want to delete ${_selectedManpowerIds.length} selected manpower records?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final selectedIds = _selectedManpowerIds.toList();

      await repo.deleteManpowerLocalBulk(selectedIds);
      final result = await ManpowerAPI.bulkDeleteManpower(
        selectedIds,
      );

      if (result['success'] == true) {
        // Refresh manpower list
        final type = ref.read(typeProvider);

        if (mounted) {
          AppToast.success(
              'Successfully deleted ${_selectedManpowerIds.length} manpower records');
        }

        setState(() {
          _selectedManpowerIds.clear();
          _isSelectionMode = false;
        });
      } else {
        if (mounted) {
          AppToast.error(result['message'] ?? 'Failed to delete manpower');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');

      if (mounted) {
        AppToast.error('Bulk delete failed: ${e.toString()}');
      }
    }
  }

  Future<void> _confirmLeftManpower(
    BuildContext context,
    ManpowerModel manpower,
  ) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark Manpower as Left"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Optional: Mention reason for leaving",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Reason (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // ❌ Cancel
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text("Cancel"),
          ),

          // ⏭ Skip
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text("Skip"),
          ),

          // ✅ Submit
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text("Mark Left"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _markManpowerLeft(
        manpower.id!,
        reasonController.text.trim(),
      );
    }
  }

  Future<void> _markManpowerLeft(String id, String reason) async {
    final type = ref.read(typeProvider);
    if (type == null) return;

    final data = {
      "reason": reason.isEmpty ? "Not specified" : reason,
    };

    await ref.read(manpowerProvider.notifier).leftManpower(id, data, type);

    AppToast.info("✅ Manpower marked as left");
  }

// ✅ STEP 1: Format selection bottom sheet
  void _showFormatSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                "Select Format",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose file format to export",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Excel
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.table_chart,
                      color: colorScheme.tertiary, size: 24),
                ),
                title: const Text(
                  "Excel (.xlsx)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "Spreadsheet format",
                  style: TextStyle(
                      fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
                onTap: () {
                  context.pop();
                  _showShareOrDownloadDialog(format: 'excel');
                },
              ),

              const SizedBox(height: 12),

              // PDF
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf,
                      color: colorScheme.error, size: 24),
                ),
                title: const Text(
                  "PDF (.pdf)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "Document format",
                  style: TextStyle(
                      fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
                onTap: () {
                  context.pop();
                  _showShareOrDownloadDialog(format: 'pdf');
                },
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                style:
                    TextButton.styleFrom(foregroundColor: colorScheme.primary),
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

// ✅ STEP 2: Share or Download bottom sheet
  void _showShareOrDownloadDialog({required String format}) {
    final fileExt = format == 'pdf' ? 'PDF' : 'Excel';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                "Manpower Sheet",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                "Format: $fileExt",
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                "What would you like to do?",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Share
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.share_rounded,
                      color: colorScheme.primary, size: 24),
                ),
                title: const Text("Share",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text("Send file via apps",
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
                onTap: () {
                  context.pop();
                  _downloadAndShareManpower(format: format);
                },
              ),

              const SizedBox(height: 12),

              // Download
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.download_rounded,
                      color: colorScheme.tertiary, size: 24),
                ),
                title: const Text("Download",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text("Save to your device",
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
                onTap: () {
                  context.pop();
                  _downloadManpowerFile(format: format);
                },
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                style:
                    TextButton.styleFrom(foregroundColor: colorScheme.primary),
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

// ✅ STEP 3a: Share
  Future<void> _downloadAndShareManpower({String format = 'excel'}) async {
    try {
      AppToast.show('Preparing file...');

      final bytes = await ManpowerAPI.downloadManpowerSheet(format: format);

      if (bytes.isEmpty) {
        AppToast.error('No data available');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileExt = format == 'pdf' ? '.pdf' : '.xlsx';
      final mimeType = format == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final fileName =
          'manpower_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final tempPath = '${tempDir.path}/$fileName';

      await File(tempPath).writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: mimeType)],
        text: 'Manpower Sheet',
        subject: 'Manpower Report',
      );

      Future.delayed(const Duration(seconds: 60), () async {
        final f = File(tempPath);
        if (await f.exists()) await f.delete();
      });
    } catch (e) {
      AppToast.error('Failed to share: $e');
    }
  }

// ✅ STEP 3b: Download
  Future<void> _downloadManpowerFile({String format = 'excel'}) async {
    try {
      AppToast.show('Downloading...');

      final bytes = await ManpowerAPI.downloadManpowerSheet(format: format);

      if (bytes.isEmpty) {
        AppToast.error('No data available');
        return;
      }

      final fileExt = format == 'pdf' ? '.pdf' : '.xlsx';
      final fileName =
          'manpower_${DateTime.now().millisecondsSinceEpoch}$fileExt';

      if (Platform.isAndroid || Platform.isIOS) {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Manpower Sheet',
          fileName: fileName,
          bytes: bytes,
        );

        if (outputPath != null) {
          await OpenFile.open(outputPath);
          AppToast.success('✅ File saved successfully');
        } else {
          AppToast.show('Save cancelled');
        }
      } else {
        // Desktop
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Manpower Sheet',
          fileName: fileName,
        );
        if (path != null) {
          await File(path).writeAsBytes(bytes, flush: true);
          await OpenFile.open(path);
          AppToast.success('✅ File saved: $path');
        }
      }
    } catch (e) {
      AppToast.error('Download failed: $e');
    }
  }

  void _syncManpowerListTour(
    BuildContext showcaseContext, {
    required bool hasRecords,
    required bool hasVisibleRecords,
  }) {
    final listState = !hasRecords
        ? 'empty'
        : hasVisibleRecords
            ? 'records'
            : 'no_results';
    final definition = AppTourDefinition(
      id: '${ManpowerTeamModuleTours.manpowerId}_list_$listState',
      title: 'Manpower List',
      description: 'Learn how to manage manpower records.',
      icon: Icons.badge_rounded,
      steps: [
        const AppTourStep(
          id: 'manpower_list_intro',
          title: 'Manpower List',
          body: 'This screen shows workers saved for the selected site.',
          progressLabel: 'Manpower list',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'manpower_list_sheet',
          title: 'View Sheet',
          body: 'Use this button to view or download manpower records in a sheet format.',
          targetKey: _sheetTourKey,
          progressLabel: 'Sheet',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
        if (hasRecords) ...[
          AppTourStep(
            id: 'manpower_list_search',
            title: 'Search and Filter',
            body: 'Search by worker name or code, and use the filter button to narrow the list.',
            targetKey: _searchTourKey,
            progressLabel: 'Search',
          ),
          AppTourStep(
            id: 'manpower_list_delete_mode',
            title: 'Bulk Delete',
            body: 'Use this button when you need to select and delete multiple workers.',
            targetKey: _deleteModeTourKey,
            progressLabel: 'Delete',
          ),
          if (hasVisibleRecords)
            AppTourStep(
              id: 'manpower_list_first_record',
              title: 'Manpower Row',
              body: 'Each row is one worker. Use the actions to edit, mark left, or delete.',
              targetKey: _firstManpowerTourKey,
              progressLabel: 'Record',
              autoScrollToTarget: true,
            )
          else
            AppTourStep(
              id: 'manpower_list_no_results',
              title: 'No Results',
              body: 'If filters hide all workers, this message tells you no matching record was found.',
              targetKey: _noResultsTourKey,
              progressLabel: 'No results',
            ),
        ] else
          AppTourStep(
            id: 'manpower_list_empty',
            title: 'No Manpower Yet',
            body: 'When no worker is saved, this area tells you to add manpower first.',
            targetKey: _emptyTourKey,
            progressLabel: 'Empty',
          ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final state = ref.read(appTourControllerProvider);
      final controller = ref.read(appTourControllerProvider.notifier);
      if (state.status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: ManpowerTeamModuleTours.manpowerId,
        );
      }
      final step = controller.currentStep;
      final activeTour = controller.activeTour;
      if (activeTour == null ||
          !activeTour.id.startsWith(ManpowerTeamModuleTours.manpowerId)) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) return;
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      await _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.read(typeProvider)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSiteId = ref.watch(selectedSiteIdProvider);
    final selectedSite = ref.watch(siteDropdownValueProvider);

    final manpowerAsync = ref.watch(
      manpowerOfflineProvider((type: type)),
    );
    final syncState = ref.watch(manpowerSyncControllerProvider((type: type)));

    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: _isSelectionMode
                  ? '${_selectedManpowerIds.length} Selected'
                  : "View Manpower Details",
            ),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: _tourTarget(
                _sheetTourKey,
                RoundedButton(
                text: "View Sheet",
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                onPressed: () => _showFormatSelectionDialog(context), // ✅
              ),
            ),
            ),
          ],
          child: manpowerAsync.when(
            loading: () {
              return const ShimmerList(
                type: ShimmerListType.tile,
                itemCount: 8,
              );
            },
            error: (e, s) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Manpower data is empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Could not load manpower records right now. Please try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            data: (manpowerList) {
              if (selectedSiteId == null || selectedSiteId.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Please select a site first to view manpower.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              // 1. APPLY FILTERS
              var filteredList = manpowerList.where((m) {
                // Fixed site filter (cannot be changed from this screen)
                if (!m.sites.contains(selectedSiteId)) {
                  return false;
                }

                // Search query filter
                if (_searchQuery.isNotEmpty) {
                  final name = (m.fullName ?? '').toLowerCase();
                  final code = (m.employeeCode ?? '').toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  if (!name.contains(query) && !code.contains(query)) {
                    return false;
                  }
                }

                // Designation filter
                if (_selectedDesignation != null &&
                    m.designation != _selectedDesignation) {
                  return false;
                }

                // Salary range filter
                if (_minSalary != null && (m.salary ?? 0) < _minSalary!) {
                  return false;
                }
                if (_maxSalary != null && (m.salary ?? 0) > _maxSalary!) {
                  return false;
                }

                return true;
              }).toList();

              // 2. APPLY SORTING
              filteredList.sort((a, b) {
                switch (_currentSort) {
                  case ManpowerSortOption.nameAsc:
                    return (a.fullName ?? '')
                        .trim()
                        .toLowerCase()
                        .compareTo((b.fullName ?? '').trim().toLowerCase());
                  case ManpowerSortOption.nameDesc:
                    return (b.fullName ?? '')
                        .trim()
                        .toLowerCase()
                        .compareTo((a.fullName ?? '').trim().toLowerCase());
                  case ManpowerSortOption.createdAtDesc:
                    final aTime = DateTime.tryParse(a.updatedAt ?? "") ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bTime = DateTime.tryParse(b.updatedAt ?? "") ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bTime.compareTo(aTime);
                  case ManpowerSortOption.createdAtAsc:
                    final aTime = DateTime.tryParse(a.updatedAt ?? "") ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bTime = DateTime.tryParse(b.updatedAt ?? "") ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return aTime.compareTo(bTime);
                  case ManpowerSortOption.salaryHighToLow:
                    return (b.salary ?? 0).compareTo(a.salary ?? 0);
                  case ManpowerSortOption.salaryLowToHigh:
                    return (a.salary ?? 0).compareTo(b.salary ?? 0);
                }
              });

              final sortedSignature = filteredList
                  .map((m) =>
                      '${m.id ?? ''}:${(m.fullName ?? '').trim().toLowerCase()}')
                  .join('|');

              if (_lastSortedOrderSignature != sortedSignature) {
                _lastSortedOrderSignature = sortedSignature;
                debugPrint('📋 Sorted manpower order (asc by name):');
                for (int i = 0; i < filteredList.length; i++) {
                  final m = filteredList[i];
                  debugPrint(
                    '  [$i] name="${m.fullName ?? ''}" code="${m.employeeCode ?? ''}" id="${m.id ?? ''}"',
                  );
                }
              }

              if (manpowerList.isEmpty) {
                if (syncState.isLoading) {
                  return const ShimmerList(
                    type: ShimmerListType.tile,
                    itemCount: 8,
                  );
                }

                _syncManpowerListTour(
                  showcaseContext,
                  hasRecords: false,
                  hasVisibleRecords: false,
                );

                return Center(
                  child: _tourTarget(
                    _emptyTourKey,
                    const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64),
                      SizedBox(height: 16),
                      Text(
                        "Manpower data is empty",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "No manpower records found. Please add manpower.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                    ),
                    ),
                );
              }

              _syncManpowerListTour(
                showcaseContext,
                hasRecords: true,
                hasVisibleRecords: filteredList.isNotEmpty,
              );

              return Column(
                children: [
                  _tourTarget(
                    _searchTourKey,
                    Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by name or code...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              isDense: true,
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterButton(
                          manpowerList,
                          selectedSiteName: selectedSite?.siteName,
                        ),
                      ],
                    ),
                    ),
                  ),

                  /// TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isSelectionMode) ...[
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSelectionMode,
                        ),
                        TextButton(
                          onPressed: () => _selectAllManpower(manpowerList),
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete'),
                          onPressed: _selectedManpowerIds.isEmpty
                              ? null
                              : _deleteSelectedManpower,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                        ),
                      ] else ...[
                        _tourTarget(
                          _deleteModeTourKey,
                          IconButton(
                            icon: Icon(Icons.delete_sweep,
                                color: colorScheme.error),
                            onPressed: manpowerList.isEmpty
                                ? null
                                : _toggleSelectionMode,
                          ),
                        ),
                      ],
                    ],
                  ),

                  /// LIST
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: _tourTarget(
                              _noResultsTourKey,
                              const Text("No results found"),
                            ),
                          )
                        : CustomScrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final manpower = filteredList[index];
                                final isSelected =
                                    _selectedManpowerIds.contains(manpower.id);
                                return _buildManpowerTile(
                                  manpower,
                                  isSelected,
                                  tileTourKey:
                                      index == 0 ? _firstManpowerTourKey : null,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildFilterButton(
    List<ManpowerModel> allManpower, {
    String? selectedSiteName,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasActiveFilters = _selectedDesignation != null ||
        _minSalary != null ||
        _maxSalary != null ||
        _currentSort != ManpowerSortOption.createdAtDesc;

    return GestureDetector(
      onTap: () => _showFilterSortBottomSheet(
        allManpower,
        selectedSiteName: selectedSiteName,
      ),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: hasActiveFilters ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasActiveFilters
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          boxShadow: hasActiveFilters
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: hasActiveFilters
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManpowerTile(
    ManpowerModel manpower,
    bool isSelected, {
    GlobalKey? tileTourKey,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tile = Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              onTap: _isSelectionMode
                  ? () => _toggleManpowerSelection(manpower.id!)
                  : null,
              leading: Icon(
                Icons.person_2_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                manpower.fullName!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                manpower.employeeCode ?? "",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              trailing: _isSelectionMode
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // ✏️ Edit
                        IconButton(
                          icon: Icon(Icons.edit, color: colorScheme.primary),
                          onPressed: () {
                            print(const JsonEncoder.withIndent('  ')
                                .convert(manpower.toJson()));
                            context.push('/edit-manpower', extra: manpower);
                          },
                        ),

                        // 🚪 Mark Left
                        IconButton(
                          icon: Icon(
                            Icons.person_off,
                            color: colorScheme.tertiary,
                          ),
                          onPressed: () {
                            _confirmLeftManpower(context, manpower);
                          },
                        ),

                        // 🗑 Delete
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: colorScheme.error),
                          onPressed: () {
                            _confirmDelete(context, manpower.id!);
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // Selection checkbox overlay
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleManpowerSelection(manpower.id!),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.error : colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.error,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: colorScheme.onError,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
    return tileTourKey == null ? tile : _tourTarget(tileTourKey, tile);
  }

  Future<void> _confirmDelete(BuildContext context, String manpowerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text("Delete Manpower"),
          content: const Text(
            "Are you sure you want to delete this manpower?\nThis action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => context.pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteManpower(context, manpowerId);
    }
  }

  void _showFilterSortBottomSheet(
    List<ManpowerModel> allManpower, {
    String? selectedSiteName,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final designations = allManpower
        .map((m) => m.designation)
        .where((d) => d != null && d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sort & Filter",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _currentSort = ManpowerSortOption.createdAtDesc;
                            _selectedDesignation = null;
                            _minSalary = null;
                            _maxSalary = null;
                          });
                          setState(() {});
                        },
                        child: const Text("Reset All"),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSectionTitle(context, "Site"),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: colorScheme.primaryContainer),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedSiteName?.isNotEmpty == true
                                    ? 'Fixed to: $selectedSiteName'
                                    : 'Fixed to selected site',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SORT SECTION
                      _buildSectionTitle(context, "Sort By"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSortChip(
                            context,
                            setModalState,
                            "Newest First",
                            ManpowerSortOption.createdAtDesc,
                            Icons.calendar_today,
                          ),
                          _buildSortChip(
                            context,
                            setModalState,
                            "Oldest First",
                            ManpowerSortOption.createdAtAsc,
                            Icons.history,
                          ),
                          _buildSortChip(
                            context,
                            setModalState,
                            "Name A-Z",
                            ManpowerSortOption.nameAsc,
                            Icons.sort_by_alpha,
                          ),
                          _buildSortChip(
                            context,
                            setModalState,
                            "Name Z-A",
                            ManpowerSortOption.nameDesc,
                            Icons.sort_by_alpha,
                          ),
                          _buildSortChip(
                            context,
                            setModalState,
                            "Salary: High-Low",
                            ManpowerSortOption.salaryHighToLow,
                            Icons.trending_down,
                          ),
                          _buildSortChip(
                            context,
                            setModalState,
                            "Salary: Low-High",
                            ManpowerSortOption.salaryLowToHigh,
                            Icons.trending_up,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // DESIGNATION FILTER
                      _buildSectionTitle(context, "Designation"),
                      const SizedBox(height: 12),
                      designations.isEmpty
                          ? Text(
                              "No designations found",
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: designations.map((d) {
                                final isSelected = _selectedDesignation == d;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(d!),
                                  onSelected: (val) {
                                    setModalState(() {
                                      _selectedDesignation = val ? d : null;
                                    });
                                    setState(() {});
                                  },
                                  backgroundColor: colorScheme.surface,
                                  selectedColor: colorScheme.primaryContainer,
                                  checkmarkColor: colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                      const SizedBox(height: 24),

                      // SALARY RANGE
                      _buildSectionTitle(context, "Salary Range"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Min",
                                prefixText: "₹ ",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              controller: TextEditingController(
                                  text: _minSalary?.toString() ?? ""),
                              onChanged: (val) {
                                _minSalary = double.tryParse(val);
                                setState(() {});
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("-"),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Max",
                                prefixText: "₹ ",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              controller: TextEditingController(
                                  text: _maxSalary?.toString() ?? ""),
                              onChanged: (val) {
                                _maxSalary = double.tryParse(val);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // Apply Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    StateSetter setModalState,
    String label,
    ManpowerSortOption option,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentSort == option;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _currentSort = option;
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteManpower(BuildContext context, String manpowerId) async {
    final repo = ref.read(attendanceRepositoryProvider);

    /// 1️⃣ DELETE LOCALLY FIRST (instant UI update)
    await repo.deleteManpowerLocal(manpowerId);

    try {
      /// 2️⃣ DELETE ON SERVER
      final res = await ManpowerAPI.deleteManpower(manpowerId);

      if (res['success'] != true) {
        throw Exception("Server delete failed");
      }
    } catch (e) {
      /// 3️⃣ OPTIONAL: rollback if server fails
      debugPrint("Server delete failed: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Manpower deleted")),
    );
  }
}
