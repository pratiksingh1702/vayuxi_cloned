import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import '../models/boq_structure_model.dart';
import '../providers/boq_structure_provider.dart';
import 'boq_item_details.dart';

enum BoqSortOption {
  markAsc,
  markDesc,
  descAsc,
  descDesc,
  weightHighToLow,
  weightLowToHigh,
}

class BoqItemListScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const BoqItemListScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<BoqItemListScreen> createState() => _BoqItemListScreenState();
}

class _BoqItemListScreenState extends ConsumerState<BoqItemListScreen> {
  String _searchQuery = '';
  BoqSortOption _currentSort = BoqSortOption.markAsc;
  String? _selectedDescription;
  double? _minWeight;
  double? _maxWeight;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(boqStructureProvider.notifier).fetchBOQs(widget.siteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(boqStructureProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: "View BOQ Items",
            ),
          ];
        },
        body: BottomButtonWrapper(
          child: state.isLoading
              ? const ShimmerList(
                  type: ShimmerListType.tile,
                  itemCount: 8,
                )
              : state.error != null && state.boqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 56, color: colorScheme.error),
                          const SizedBox(height: 12),
                          Text(
                            "Failed to load BOQ",
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
                              state.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(boqStructureProvider.notifier)
                                .fetchBOQs(widget.siteId),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(colorScheme, state.boqs),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, List<BOQStructure> boqs) {
    if (boqs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "No BOQ Items Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "There are no items uploaded for this site.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Flatten all items from all BOQs for this view
    List<BOQStructureItem> allItems = [];
    for (var boq in boqs) {
      allItems.addAll(boq.items);
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "BOQs are empty",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "The uploaded BOQs do not contain any items.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Apply Filter
    var filteredList = allItems.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final desc = item.typeDescription.toLowerCase();
        final mark = item.assemblyMark.toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!desc.contains(query) && !mark.contains(query)) {
          return false;
        }
      }
      
      // Description filter
      if (_selectedDescription != null && item.typeDescription != _selectedDescription) {
        return false;
      }
      
      // Weight range filter
      if (_minWeight != null && (item.totalNetWeight ?? 0) < _minWeight!) {
        return false;
      }
      if (_maxWeight != null && (item.totalNetWeight ?? 0) > _maxWeight!) {
        return false;
      }
      
      return true;
    }).toList();

    // Apply Sorting
    filteredList.sort((a, b) {
      switch (_currentSort) {
        case BoqSortOption.markAsc:
          return a.assemblyMark.compareTo(b.assemblyMark);
        case BoqSortOption.markDesc:
          return b.assemblyMark.compareTo(a.assemblyMark);
        case BoqSortOption.descAsc:
          return a.typeDescription.compareTo(b.typeDescription);
        case BoqSortOption.descDesc:
          return b.typeDescription.compareTo(a.typeDescription);
        case BoqSortOption.weightHighToLow:
          return (b.totalNetWeight ?? 0).compareTo(a.totalNetWeight ?? 0);
        case BoqSortOption.weightLowToHigh:
          return (a.totalNetWeight ?? 0).compareTo(b.totalNetWeight ?? 0);
      }
    });

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by mark or description...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
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
              _buildFilterButton(colorScheme),
            ],
          ),
        ),

        // List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                '${filteredList.length} Items Found',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    "No items match your search",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _BoqItemCard(
                      item: item,
                      onTap: () {
                        // Open details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoqItemDetailsScreen(
                              siteId: widget.siteId,
                              siteName: widget.siteName,
                              item: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(ColorScheme colorScheme) {
    final bool hasActiveFilters = _selectedDescription != null ||
        _minWeight != null ||
        _maxWeight != null ||
        _currentSort != BoqSortOption.markAsc;

    return GestureDetector(
      onTap: _showFilterSortBottomSheet,
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
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              color: hasActiveFilters
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter & Sort",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _searchQuery = '';
                            _currentSort = BoqSortOption.markAsc;
                            _selectedDescription = null;
                            _minWeight = null;
                            _maxWeight = null;
                          });
                          setState(() {
                            _searchQuery = '';
                            _currentSort = BoqSortOption.markAsc;
                            _selectedDescription = null;
                            _minWeight = null;
                            _maxWeight = null;
                          });
                        },
                        child: Text(
                          "Reset All",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Sort Section
                      Text(
                        "Sort By",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSortChip(
                            setModalState,
                            "Mark (A-Z)",
                            BoqSortOption.markAsc,
                            Icons.arrow_upward,
                            colorScheme,
                          ),
                          _buildSortChip(
                            setModalState,
                            "Mark (Z-A)",
                            BoqSortOption.markDesc,
                            Icons.arrow_downward,
                            colorScheme,
                          ),
                          _buildSortChip(
                            setModalState,
                            "Desc (A-Z)",
                            BoqSortOption.descAsc,
                            Icons.arrow_upward,
                            colorScheme,
                          ),
                          _buildSortChip(
                            setModalState,
                            "Desc (Z-A)",
                            BoqSortOption.descDesc,
                            Icons.arrow_downward,
                            colorScheme,
                          ),
                          _buildSortChip(
                            setModalState,
                            "Weight ↓",
                            BoqSortOption.weightHighToLow,
                            Icons.trending_down,
                            colorScheme,
                          ),
                          _buildSortChip(
                            setModalState,
                            "Weight ↑",
                            BoqSortOption.weightLowToHigh,
                            Icons.trending_up,
                            colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Weight Range Section
                      Text(
                        "Weight Range (kg)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setModalState(() {
                                  _minWeight = double.tryParse(val);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Min',
                                prefixIcon:
                                    const Icon(Icons.arrow_downward, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: colorScheme.surface,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setModalState(() {
                                  _maxWeight = double.tryParse(val);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Max',
                                prefixIcon:
                                    const Icon(Icons.arrow_upward, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: colorScheme.surface,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Apply Filters",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(
    StateSetter setModalState,
    String label,
    BoqSortOption option,
    IconData icon,
    ColorScheme colorScheme,
  ) {
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
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoqItemCard extends StatelessWidget {
  final BOQStructureItem item;
  final VoidCallback onTap;

  const _BoqItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.assemblyMark.isNotEmpty
                          ? item.assemblyMark.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.typeDescription.isNotEmpty
                            ? item.typeDescription
                            : "Unknown Type",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mark No: ${item.assemblyMark}",
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Trailing Weight
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(item.totalNetWeight ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
