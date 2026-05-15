import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../../core/router/routes.dart';
import '../../../../../core/utlis/widgets/empty_module_state.dart';

enum RateSortOption {
  latestFirst,
  nameAsc,
  nameDesc,
  rateHighToLow,
  rateLowToHigh
}

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

  // Filter & Sort State
  RateSortOption _currentSort = RateSortOption.latestFirst;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _filterUOM = {};
  Set<String> _filterType = {};
  double? _filterRateMin;
  double? _filterRateMax;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _filterUOM.isNotEmpty ||
      _filterType.isNotEmpty ||
      _filterRateMin != null ||
      _filterRateMax != null ||
      _currentSort != RateSortOption.latestFirst;

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          final rates = ref.read(rateNotifierProvider).data ?? [];
          
          final uoms = rates.map((e) => e.uom).toSet().toList()..sort();
          final types = rates.map((e) => e.type).toSet().toList()..sort();
          
          double maxRate = 0;
          if (rates.isNotEmpty) {
            maxRate = rates.map((e) => e.rate).reduce((a, b) => a > b ? a : b);
          }
          if (maxRate < 1000) maxRate = 5000; // default max if data is small

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _currentSort = RateSortOption.latestFirst;
                            _filterUOM = {};
                            _filterType = {};
                            _filterRateMin = null;
                            _filterRateMax = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Sorting
                  _buildFilterLabel('Sort By'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Latest First',
                        selected: _currentSort == RateSortOption.latestFirst,
                        onSelected: (val) {
                          setSheetState(() => _currentSort = RateSortOption.latestFirst);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Name (A-Z)',
                        selected: _currentSort == RateSortOption.nameAsc,
                        onSelected: (val) {
                          setSheetState(() => _currentSort = RateSortOption.nameAsc);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Rate (High-Low)',
                        selected: _currentSort == RateSortOption.rateHighToLow,
                        onSelected: (val) {
                          setSheetState(() => _currentSort = RateSortOption.rateHighToLow);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // UOM
                  if (uoms.isNotEmpty) ...[
                    _buildFilterLabel('Unit of Measurement (UOM)'),
                    Wrap(
                      spacing: 8,
                      children: uoms.map((uom) {
                        return _buildFilterChip(
                          label: uom,
                          selected: _filterUOM.contains(uom),
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                _filterUOM.add(uom);
                              } else {
                                _filterUOM.remove(uom);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Type
                  if (types.isNotEmpty) ...[
                    _buildFilterLabel('Rate Type'),
                    Wrap(
                      spacing: 8,
                      children: types.map((t) {
                        return _buildFilterChip(
                          label: t,
                          selected: _filterType.contains(t),
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                _filterType.add(t);
                              } else {
                                _filterType.remove(t);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rate Range
                  _buildFilterLabel(
                      'Rate Range: ₹${_filterRateMin?.toStringAsFixed(0) ?? "0"} - ₹${_filterRateMax?.toStringAsFixed(0) ?? maxRate.toStringAsFixed(0)}'),
                  _buildSliderRange(
                    min: 0,
                    max: maxRate,
                    values: RangeValues(_filterRateMin ?? 0, _filterRateMax ?? maxRate),
                    onChanged: (values) {
                      setSheetState(() {
                        _filterRateMin = values.start;
                        _filterRateMax = values.end;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? colorScheme.primary : colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildSliderRange({
    required double min,
    required double max,
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return RangeSlider(
      values: values,
      min: min,
      max: max,
      divisions: max > 0 ? (max / 10).toInt().clamp(1, 100) : 1,
      labels: RangeLabels(
        values.start.toStringAsFixed(0),
        values.end.toStringAsFixed(0),
      ),
      activeColor: colorScheme.primary,
      inactiveColor: colorScheme.primaryContainer,
      onChanged: onChanged,
    );
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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Selected Rates'),
          content: Text(
            'Are you sure you want to delete ${_selectedRateIds.length} selected rates?\n\n'
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
      final result =
          await RateApiClient().bulkDeleteRates(_selectedRateIds.toList());

      if (result['success'] == true) {
        // Refresh rates list
        final type = ref.read(typeProvider);
        final siteId = ref.read(selectedSiteIdProvider);
        if (type != null && siteId != null) {
          ref.read(rateNotifierProvider.notifier).fetchRate(type, siteId);
        }

        if (!mounted) return;

        AppToast.success(
            "✅ Successfully deleted ${_selectedRateIds.length} rates");

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
      backgroundColor: colorScheme.surfaceContainerLowest,
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
              // Search and Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search service...',
                            prefixIcon: Icon(Icons.search,
                                color: colorScheme.primary, size: 20),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showFilterSortBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hasActiveFilters
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasActiveFilters
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: hasActiveFilters
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                            icon: Icon(Icons.delete_sweep,
                                color: colorScheme.error),
                            onPressed:
                                rates.isEmpty ? null : _toggleSelectionMode,
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
                        ? EmptyModuleState(
                            title: "Connection Error",
                            subtitle: "Could not load rate records right now. Please try again.",
                            icon: Icons.error_outline_rounded,
                            actionLabel: "Retry",
                            onAction: () {
                              final type = ref.read(typeProvider);
                              final siteId = ref.read(selectedSiteIdProvider);
                              if (type != null && siteId != null) {
                                ref.read(rateNotifierProvider.notifier).fetchRate(type, siteId);
                              }
                            },
                          )
                        : state.data == null || state.data!.isEmpty
                            ? EmptyModuleState(
                                title: "No Rates Added",
                                subtitle: "Add your first rate to get started",
                                icon: Icons.currency_rupee_rounded,
                                actionLabel: "Add Rate",
                                onAction: () => context.push(Routes.addRate),
                              )
                            : () {
                                // Apply Filtering
                                var filteredList = rates.where((rate) {
                                  // Search
                                  if (_searchQuery.isNotEmpty &&
                                      !rate.serviceName
                                          .toLowerCase()
                                          .contains(_searchQuery.toLowerCase()) &&
                                      !rate.hsnSacCode
                                          .toLowerCase()
                                          .contains(_searchQuery.toLowerCase())) {
                                    return false;
                                  }

                                  // UOM
                                  if (_filterUOM.isNotEmpty &&
                                      !_filterUOM.contains(rate.uom)) {
                                    return false;
                                  }

                                  // Type
                                  if (_filterType.isNotEmpty &&
                                      !_filterType.contains(rate.type)) {
                                    return false;
                                  }

                                  // Rate Range
                                  if (_filterRateMin != null &&
                                      rate.rate < _filterRateMin!) return false;
                                  if (_filterRateMax != null &&
                                      rate.rate > _filterRateMax!) return false;

                                  return true;
                                }).toList();

                                // Apply Sorting
                                filteredList.sort((a, b) {
                                  switch (_currentSort) {
                                    case RateSortOption.latestFirst:
                                      return b.createdAt.compareTo(a.createdAt);
                                    case RateSortOption.nameAsc:
                                      return a.serviceName.compareTo(b.serviceName);
                                    case RateSortOption.nameDesc:
                                      return b.serviceName.compareTo(a.serviceName);
                                    case RateSortOption.rateHighToLow:
                                      return b.rate.compareTo(a.rate);
                                    case RateSortOption.rateLowToHigh:
                                      return a.rate.compareTo(b.rate);
                                  }
                                });

                                if (filteredList.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_outlined,
                                          size: 64,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No results found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Try adjusting your search or filters.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return CustomScrollbar(
                                  controller: _scrollController,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredList.length,
                                    itemBuilder: (context, index) {
                                      final rate = filteredList[index];
                                      final isSelected =
                                          _selectedRateIds.contains(rate.id);

                                      return _buildRateTile(
                                        context,
                                        rate,
                                        site!,
                                        ref,
                                        isSelected,
                                      );
                                    },
                                  ),
                                );
                              }() as Widget
              )
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
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: Card(
            elevation: 0,
            color: colorScheme.surface,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: InkWell(
              onTap:
                  _isSelectionMode ? () => _toggleRateSelection(rate.id) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
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
                                  color: colorScheme.primary,
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
                                  color: colorScheme.error,
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
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${rate.rate.toStringAsFixed(0)} / ${rate.uom}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
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
                  color: isSelected ? colorScheme.error : colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.error,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.16),
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
  }

  Future<void> saveCsvWithDialog(
      BuildContext context, String type, String siteId) async {
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
    builder: (_) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: const Text("Delete Rate"),
        content: const Text(
          "Are you sure you want to delete this rate?\n\n"
          "This action cannot be undone.",
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
