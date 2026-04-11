// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';

import '../../dpr/screens/widgets/select_card.dart';
import 'inventory_list.dart';
import 'manual_import_add_inventory.dart';



class ViewAddInventorySetup extends StatelessWidget {
  const ViewAddInventorySetup({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title:"Select Card"),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Add side padding
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12, // Reduced vertical space between cards
              crossAxisSpacing: 10, // Reduced horizontal space between cards
              childAspectRatio: 1,
              children: [
                SelectCard(
                  icon: Image.asset(
                    "assets/images/icons/view.webp",

                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,

                  ),
                  label: "View",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryListScreen()),
                    );
                    print("implementing");
                  },
                ),
                SelectCard(
                  icon: Image.asset(
                    "assets/images/icons/add.webp",

                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,

                  ),
                  label: "Add",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>AddInventorySelection() ),
                    );
                  },
                ),

              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---------------- INFO CARD UNDER GRID ----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? colorScheme.shadow.withOpacity(0.12)
                      : colorScheme.shadow.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose an option",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "• View: You can view your sites and also edit them.\n"
                      "• Add: You can create and register a new site.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
