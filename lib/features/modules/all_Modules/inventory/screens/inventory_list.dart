import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/offline/repo/inventory_sync.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';
import 'add_inven.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _search = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            // ----- SEARCH -----
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search item...",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon:
                      Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  fillColor: colorScheme.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(38),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
              ),
            ),

            Expanded(
              child: inventoryAsync.when(
                loading: () => const ShimmerList(
                  type: ShimmerListType.tile,
                  itemCount: 8,
                ),
                error: (e, _) => Center(
                  child: Text(
                    "Failed to load inventory",
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
                data: (inventoryList) {
                  final filtered = inventoryList.where((item) {
                    return item.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No inventory found",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return CustomScrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final inventory = filtered[i];
                          final num totalQuantity =
                              inventory.type == "consumable"
                                  ? (inventory.totalQuantityAdded ?? 0)
                                  : (inventory.totalUnits ?? 0);
                          debugPrint("Inventory -> Name: ${inventory.name}, "
                              "Type: ${inventory.type}, "
                              "TotalQty: $totalQuantity");

                          return Card(
                            elevation: 0,
                            color: colorScheme.surface,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withOpacity(0.45)),
                            ),
                            child: ListTile(
                              title: Text(
                                inventory.name,
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                "Qty: ${totalQuantity} | Min: ${inventory.minimumStockLevel} | UOM: ${inventory.uom}",
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.mode_edit_outline_outlined,
                                        color: colorScheme.primary),
                                    onPressed: () async {
                                      await context.push(
                                        Routes.editInventory,
                                        extra: inventory,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: colorScheme.error),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) {
                                          final cs = Theme.of(ctx).colorScheme;
                                          return AlertDialog(
                                            title: const Text("Delete Item"),
                                            content: const Text(
                                                "Are you sure you want to delete this item?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    ctx.pop(false),
                                                style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        cs.primary),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    ctx.pop(true),
                                                style: TextButton.styleFrom(
                                                    foregroundColor: cs.error),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed == true && siteId != null) {
                                        try {
                                          await ref.read(
                                              deleteInventoryProvider(
                                                  DeleteInventoryParams(
                                            siteId: siteId,
                                            inventoryId: inventory.id,
                                          )).future);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "Failed to delete: $e"),
                                                backgroundColor:
                                                    colorScheme.error,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await context.push(
                                  Routes.editInventory,
                                  extra: inventory,
                                );
                              },
                            ),
                          );
                        },
                      ));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
