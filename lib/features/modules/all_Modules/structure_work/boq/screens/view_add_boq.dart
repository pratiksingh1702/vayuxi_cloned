import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_entry_select.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_item_list.dart';

class ViewAddBoqScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const ViewAddBoqScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Select BOQ Option"),
      body: BottomButtonWrapper(
        onBackPressed: () {
          context.pop();
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
                children: [
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.visibility_rounded,
                      color: Colors.blue,
                    ),
                    label: "View",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoqItemListScreen(
                            siteId: siteId,
                            siteName: siteName,
                          ),
                        ),
                      );
                    },
                  ),
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green,
                    ),
                    label: "Add",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoqEntrySelectScreen(
                            siteId: siteId,
                            siteName: siteName,
                          ),
                        ),
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
                border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.45)),
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
                    "• View: You can view your BOQ items and also edit them.\n"
                    "• Add: You can create and register new BOQ items manually or import an Excel sheet.",
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
      ),
    );
  }
}
