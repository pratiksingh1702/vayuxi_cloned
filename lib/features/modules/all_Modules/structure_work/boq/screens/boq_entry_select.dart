import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_item_details.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_import_sheet.dart';

class BoqEntrySelectScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const BoqEntrySelectScreen({
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
      appBar: CustomAppBar(title: "Select Entry Method"),
      body: BottomButtonWrapper(
        onBackPressed: () {
          Navigator.pop(context);
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
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                    ),
                    label: "Manual Entry",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoqItemDetailsScreen(
                            siteId: siteId,
                            siteName: siteName,
                            item: null, // Indicates a new entry
                          ),
                        ),
                      );
                    },
                  ),
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.upload_file_rounded,
                      color: Colors.deepOrange,
                    ),
                    label: "Import Sheet",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoqImportSheetScreen(
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
                    "Choose the entry method",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Manual Entry: Create a new BOQ item step-by-step manually.\n"
                    "• Import Sheet: Upload an Excel sheet containing your BOQ items. The system will process and save them automatically.",
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
