import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/offline/repo/inventory_sync.dart';
import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';
import 'add_inven.dart';
import 'edit_inventory.dart';


class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _search = "";
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteId = ref.read(selectedSiteIdProvider);

      if (siteId != null) {
        // force provider to re-run even if cached
        ref.invalidate(inventorySyncControllerProvider(siteId));
        ref.read(inventorySyncControllerProvider(siteId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final siteId = ref.watch(selectedSiteIdProvider);
    final inventoryAsync = ref.watch(inventoryProvider(siteId!));

    return Scaffold(
      appBar: CustomAppBar(title: "Inventory List"),
      backgroundColor: AppColors.lightBlue,
      drawer: const CustomDrawer(),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(button:RoundedButton(
            text: "Add",
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>CreateInventoryScreen()),
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
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(38),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              ),
            ),

            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Failed to load inventory")),
                data: (inventoryList) {
                  final filtered = inventoryList.where((item) {
                    return item.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No inventory found"));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final inventory = filtered[i];
                      final num totalQuantity = inventory.type == "consumable"
                          ? (inventory.totalQuantityAdded ?? 0)
                          : (inventory.totalUnits ?? 0);
                      debugPrint(
                          "Inventory -> Name: ${inventory.name}, "
                              "Type: ${inventory.type}, "
                              "TotalQty: $totalQuantity"
                      );

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(inventory.name),
                          subtitle: Text(
                            "Qty: ${totalQuantity} | Min: ${inventory.minimumStockLevel} | UOM: ${inventory.uom}",
                          ),
                          trailing: const Icon(Icons.mode_edit_outline_outlined),
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditInventoryScreen(inventory: inventory),
                              ),
                            );

                            if (updated == true) {
                              // 🔥 Refresh API
                              ref.invalidate(inventoryProvider);
                            }

                          },
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
