import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/auth/service/auth_client.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../data/rate_provider.dart';
import '../domain/rateModel.dart';
import 'addRate.dart';
import 'editRate.dart';
import 'import_sheet.dart';

class RateScreen extends ConsumerStatefulWidget {
  const RateScreen({super.key});

  @override
  ConsumerState<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends ConsumerState<RateScreen> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedRateIds = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch rates when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);
      if (type != null) {
        ref.read(rateNotifierProvider.notifier).fetchRate(type, siteId!);
      }
    });
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRateIds.clear();
      }
    });
  }

  /// Toggle individual rate selection
  void _toggleRateSelection(String rateId) {
    setState(() {
      if (_selectedRateIds.contains(rateId)) {
        _selectedRateIds.remove(rateId);
      } else {
        _selectedRateIds.add(rateId);
      }
    });
  }

  /// Select all rates
  void _selectAllRates(List<Rate> rates) {
    setState(() {
      for (var rate in rates) {
        _selectedRateIds.add(rate.id);
      }
    });
  }

  /// Delete selected rates
  Future<void> _deleteSelectedRates() async {
    if (_selectedRateIds.isEmpty) {
      AppToast.info('No rates selected');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Rates'),
        content: Text(
          'Are you sure you want to delete ${_selectedRateIds.length} selected rates?\n\n'
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
      final result = await RateApiClient().bulkDeleteRates(_selectedRateIds.toList());

      if (result['success'] == true) {
        // Refresh rates list
        final type = ref.read(typeProvider);
        final siteId = ref.read(selectedSiteIdProvider);
        if (type != null && siteId != null) {
          ref.read(rateNotifierProvider.notifier).fetchRate(type, siteId);
        }

        if (!mounted) return;

        AppToast.success("✅ Successfully deleted ${_selectedRateIds.length} rates");

        setState(() {
          _selectedRateIds.clear();
          _isSelectionMode = false;
        });
      } else {
        if (!mounted) return;

        AppToast.error(result['message'] ?? '❌ Failed to delete rates');
      }
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');
      if (!mounted) return;

      final error = extractBackendError(e); // ✅ if you already have this helper
      AppToast.error("❌ Bulk delete failed: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rateNotifierProvider);
    final site = ref.read(currentSiteProvider);
    final rates = state.data ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: _isSelectionMode
                  ? '${_selectedRateIds.length} Selected'
                  : "Rates",
            ),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: "View Sheet",
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                onPressed: () {
                  final type = ref.read(typeProvider);
                  if (type != null) {
                    saveCsvWithDialog(context, type, site!.id);
                  }
                },
              ),
            ),
          ],
          child: Column(
            children: [
              // Top action bar with selection controls
              if (rates.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    Row(
                      children: [
                        if (_isSelectionMode) ...[
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleSelectionMode,
                            tooltip: 'Cancel',
                          ),
                          TextButton(
                            onPressed: () => _selectAllRates(rates),
                            child: const Text('Select All'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text('Delete'),
                            onPressed: _selectedRateIds.isEmpty
                                ? null
                                : _deleteSelectedRates,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            icon: Icon(Icons.delete_sweep, color: colorScheme.error),
                            onPressed: rates.isEmpty ? null : _toggleSelectionMode,
                            tooltip: 'Select Rates to Delete',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

              // Rates list
              Expanded(
                child: state.loading
                    ? const ShimmerList(
                        type: ShimmerListType.tile,
                        itemCount: 8,
                      )
                    : state.error != null
                    ? Center(child: Text('Error: ${state.error}'))
                    : state.data == null || state.data!.isEmpty
                    ? const Center(child: Text('No rates available'))
                    : CustomScrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.data!.length,
                    itemBuilder: (context, index) {
                      final rate = state.data![index];
                    final isSelected = _selectedRateIds.contains(rate.id);

                    return _buildRateTile(
                      context,
                      rate,
                      site!,
                      ref,
                      isSelected,
                    );
                  },
                ),
              ),)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateTile(
      BuildContext context,
      Rate rate,
      SiteModel site,
      WidgetRef ref,
      bool isSelected,
      ) {
    final type = ref.read(typeProvider);
    final notifier = ref.read(rateNotifierProvider.notifier);

    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleRateSelection(rate.id)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Service name (multi-line)
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rate.serviceName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    // Right side: Rate with UOM and edit button
                    if (!_isSelectionMode)
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✏️ Edit
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditRateScreen(
                                        site: site,
                                        rate: rate,
                                      ),
                                    ),
                                  );

                                  if (result == true && type != null) {
                                    notifier.fetchRate(type, site.id);
                                  }
                                },
                              ),

                              // 🗑 Delete
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () {
                                  _confirmDeleteRate(
                                    context,
                                    rate.id,
                                    notifier,
                                    type!,
                                    site.id,
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // 💰 Rate badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${rate.rate.toStringAsFixed(0)} / ${rate.uom}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
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
              onTap: () => _toggleRateSelection(rate.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.onError,
                  size: 20,
                )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> saveCsvWithDialog(BuildContext context, String type, String siteId) async {
    final result = await RateApiClient().getCsv(type, siteId);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating CSV: ${result['error']}')),
      );
      return;
    }

    try {
      String? path;

      if (Platform.isAndroid || Platform.isIOS) {
        // Convert CSV string to bytes for mobile
        final bytes = utf8.encode(result['data'].toString());

        path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV file',
          fileName: 'rates_$siteId.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: bytes,
        );
      } else {
        // On desktop, use file_selector or path_provider
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/rates_$siteId.csv';

        final file = File(path);
        await file.writeAsString(result['data'].toString());
      }

      if (path == null) return; // user canceled

      // For mobile, the file is already saved by FilePicker, so no need to write again
      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(path);
        await file.writeAsString(result['data'].toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV saved at $path')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CSV: $e')),
      );
    }
  }
}

Future<void> _confirmDeleteRate(
    BuildContext context,
    String rateId,
    RateNotifier notifier,
    String type,
    String siteId,
    ) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Rate"),
      content: const Text(
        "Are you sure you want to delete this rate?\n\n"
            "This action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    _deleteRate(context, rateId, notifier, type, siteId);
  }
}

Future<void> _deleteRate(
    BuildContext context, // keep if your caller needs it, but NOT used anymore
    String rateId,
    RateNotifier notifier,
    String type,
    String siteId,
    ) async {
  try {
    final res = await RateApiClient().deleteRate(siteId, rateId);

    if (res['success'] == true) {
      notifier.fetchRate(type, siteId);
      AppToast.success("✅ Rate deleted");
    } else {
      AppToast.error(res['message'] ?? "❌ Delete failed");
    }
  } catch (e) {
    final error = extractBackendError(e); // if you have this helper
    AppToast.error("❌ Error deleting rate: $error");
  }
}
