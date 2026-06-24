import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/offline/repo/inventory_sync.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../../../../core/utlis/widgets/empty_module_state.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';
import 'add_inven.dart';

enum InventorySortOption { latestFirst, nameAsc, nameDesc, stockLowToHigh }

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _search = "";
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  String? _selectedType;
  String? _selectedCategory;
  InventorySortOption _sortOption = InventorySortOption.latestFirst;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedCategory != null ||
      _sortOption != InventorySortOption.latestFirst;

  List<Inventory> _visibleInventory(List<Inventory> items) {
    final filtered = items.where((item) {
      final matchesSearch = _search.isEmpty ||
          item.name.toLowerCase().contains(_search) ||
          item.category.name.toLowerCase().contains(_search);
      final matchesType = _selectedType == null || item.type == _selectedType;
      final matchesCategory =
          _selectedCategory == null || item.category.name == _selectedCategory;
      return matchesSearch && matchesType && matchesCategory;
    }).toList();
    filtered.sort((a, b) {
      switch (_sortOption) {
        case InventorySortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case InventorySortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case InventorySortOption.stockLowToHigh:
          final aQty = a.type == 'consumable'
              ? (a.currentBalance ?? 0)
              : (a.availableUnits ?? 0);
          final bQty = b.type == 'consumable'
              ? (b.currentBalance ?? 0)
              : (b.availableUnits ?? 0);
          return aQty.compareTo(bQty);
        case InventorySortOption.latestFirst:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return filtered;
  }

  String _csvCell(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';

  Future<void> _downloadInventory(List<Inventory> items) async {
    if (items.isEmpty) {
      AppToast.info('No inventory records to download');
      return;
    }
    try {
      final rows = <List<Object?>>[
        ['Item', 'Category', 'Type', 'Quantity', 'UOM', 'Minimum Stock'],
        ...items.map((item) => [
              item.name,
              item.category.name,
              item.type,
              item.type == 'consumable'
                  ? (item.currentBalance ?? item.totalQuantityAdded ?? 0)
                  : (item.availableUnits ?? item.totalUnits ?? 0),
              item.uom ?? 'Nos',
              item.minimumStockLevel ?? '',
            ]),
      ];
      final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/inventory-list-${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Inventory list export',
      );
    } catch (e) {
      debugPrint('Inventory export failed: $e');
      AppToast.error('Failed to export inventory list');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _deleteSelected(String siteId) async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text(
          'Delete ${_selectedIds.length} selected inventory item(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      for (final inventoryId in _selectedIds.toList()) {
        await ref.read(
          deleteInventoryProvider(
            DeleteInventoryParams(
              siteId: siteId,
              inventoryId: inventoryId,
            ),
          ).future,
        );
      }
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      AppToast.success('Selected inventory items deleted');
    } catch (e) {
      AppToast.error('Failed to delete selected inventory items');
    }
  }

  void _showFilters(List<Inventory> items) {
    final categories = items
        .map((item) => item.category.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedType = null;
                          _selectedCategory = null;
                          _sortOption = InventorySortOption.latestFirst;
                        });
                        setState(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                DropdownButtonFormField<InventorySortOption>(
                  value: _sortOption,
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownMenuItem(
                      value: InventorySortOption.latestFirst,
                      child: Text('Latest first'),
                    ),
                    DropdownMenuItem(
                      value: InventorySortOption.nameAsc,
                      child: Text('Name A-Z'),
                    ),
                    DropdownMenuItem(
                      value: InventorySortOption.nameDesc,
                      child: Text('Name Z-A'),
                    ),
                    DropdownMenuItem(
                      value: InventorySortOption.stockLowToHigh,
                      child: Text('Stock low to high'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() => _sortOption = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Item type'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All types')),
                    DropdownMenuItem(
                        value: 'consumable', child: Text('Consumable')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                  ],
                  onChanged: (value) {
                    setSheetState(() => _selectedType = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All categories')),
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => _selectedCategory = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteId = ref.read(selectedSiteIdProvider);

      if (siteId != null) {
        // SINGLE sync trigger in screen init ONLY
        ref.read(inventorySyncControllerProvider(siteId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final inventoryAsync = ref.watch(inventoryProvider(siteId!));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: "Inventory List"),
      backgroundColor: colorScheme.surfaceContainerLowest,
      drawer: const CustomDrawer(),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: RoundedButton(
            text: "Add",
            color: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateInventoryScreen()),
              );
            },
          ))
        ],
        child: Column(
          children: [
            Expanded(
              child: inventoryAsync.when(
                loading: () => const ShimmerList(
                  type: ShimmerListType.tile,
                  itemCount: 8,
                ),
                error: (e, _) => EmptyModuleState(
                  title: "Failed to load inventory",
                  subtitle: "An error occurred while fetching your data.",
                  icon: Icons.error_outline_rounded,
                  actionLabel: "Retry",
                  onAction: () => ref.refresh(inventoryProvider(siteId)),
                ),
                data: (inventoryList) {
                  final filtered = _visibleInventory(inventoryList);

                  return Column(
                    children: [
                      if (inventoryList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) => setState(() =>
                                        _search = value.trim().toLowerCase()),
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'Search inventory...',
                                      prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          size: 20),
                                      suffixIcon: _search.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() => _search = '');
                                              },
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 18),
                                            ),
                                      filled: true,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _toolbarButton(
                                tooltip: 'Filter and sort',
                                icon: Icons.tune_rounded,
                                active: _hasActiveFilters,
                                onPressed: () => _showFilters(inventoryList),
                              ),
                              const SizedBox(width: 6),
                              _toolbarButton(
                                tooltip: 'Download Sheet',
                                icon: Icons.download_rounded,
                                onPressed: () => _downloadInventory(filtered),
                              ),
                              const SizedBox(width: 6),
                              ..._selectionControls(filtered, siteId),
                            ],
                          ),
                        ),
                      Expanded(
                        child: filtered.isEmpty
                            ? EmptyModuleState(
                                title: inventoryList.isEmpty
                                    ? "No Inventory Items"
                                    : "No Inventory Found",
                                subtitle: inventoryList.isEmpty
                                    ? "Add materials to start tracking inventory"
                                    : "Try adjusting your search or filters.",
                                icon: inventoryList.isEmpty
                                    ? Icons.inventory_2_rounded
                                    : Icons.search_off_rounded,
                                actionLabel: inventoryList.isEmpty
                                    ? "Add Item"
                                    : "Clear Filters",
                                onAction: () {
                                  if (inventoryList.isEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateInventoryScreen(),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      _searchController.clear();
                                      _search = '';
                                      _selectedType = null;
                                      _selectedCategory = null;
                                      _sortOption =
                                          InventorySortOption.latestFirst;
                                    });
                                  }
                                },
                              )
                            : CustomScrollbar(
                                controller: _scrollController,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final inventory = filtered[i];
                                    final isSelected =
                                        _selectedIds.contains(inventory.id);
                                    final num totalQuantity = inventory.type ==
                                            "consumable"
                                        ? (inventory.totalQuantityAdded ?? 0)
                                        : (inventory.totalUnits ?? 0);

                                    return Opacity(
                                      opacity: _isSelectionMode && !isSelected
                                          ? 0.55
                                          : 1,
                                      child: Card(
                                        elevation: 0,
                                        color: colorScheme.surface,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.outlineVariant
                                                    .withOpacity(0.45),
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: _isSelectionMode
                                              ? Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) =>
                                                      _toggleSelection(
                                                          inventory.id),
                                                )
                                              : null,
                                          title: Text(inventory.name),
                                          subtitle: Text(
                                            "Qty: $totalQuantity | Min: ${inventory.minimumStockLevel} | UOM: ${inventory.uom}",
                                          ),
                                          trailing: _isSelectionMode
                                              ? null
                                              : Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons
                                                              .mode_edit_outline_outlined,
                                                          color: colorScheme
                                                              .primary),
                                                      onPressed: () =>
                                                          context.push(
                                                        Routes.editInventory,
                                                        extra: inventory,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.delete_outline,
                                                          color: colorScheme
                                                              .error),
                                                      onPressed: () =>
                                                          _deleteOne(
                                                        siteId,
                                                        inventory,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          onTap: _isSelectionMode
                                              ? () =>
                                                  _toggleSelection(inventory.id)
                                              : () => context.push(
                                                    Routes.editInventory,
                                                    extra: inventory,
                                                  ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOne(String siteId, Inventory inventory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete ${inventory.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(
      deleteInventoryProvider(
        DeleteInventoryParams(siteId: siteId, inventoryId: inventory.id),
      ).future,
    );
  }

  Widget _toolbarButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool active = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? cs.onPrimary : cs.primary,
          ),
        ),
      ),
    );
  }

  List<Widget> _selectionControls(List<Inventory> visibleItems, String siteId) {
    final allSelected = visibleItems.isNotEmpty &&
        visibleItems.every((item) => _selectedIds.contains(item.id));
    if (!_isSelectionMode) {
      return [
        _toolbarButton(
          tooltip: 'Select Inventory',
          icon: Icons.checklist_rounded,
          onPressed: visibleItems.isEmpty ? null : _toggleSelectionMode,
        ),
      ];
    }
    return [
      SizedBox(
        height: 40,
        child: TextButton(
          onPressed: () => setState(() {
            if (allSelected) {
              _selectedIds
                  .removeAll(visibleItems.map((inventory) => inventory.id));
            } else {
              _selectedIds
                  .addAll(visibleItems.map((inventory) => inventory.id));
            }
          }),
          child: Text(allSelected ? 'Deselect' : 'Select All'),
        ),
      ),
      _toolbarButton(
        tooltip: 'Delete Selected',
        icon: Icons.delete_sweep_rounded,
        active: _selectedIds.isNotEmpty,
        onPressed: _selectedIds.isEmpty ? null : () => _deleteSelected(siteId),
      ),
      const SizedBox(width: 4),
      _toolbarButton(
        tooltip: 'Cancel',
        icon: Icons.close_rounded,
        onPressed: _toggleSelectionMode,
      ),
    ];
  }
}
