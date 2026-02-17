// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';
import '../../rate/screens/import_sheet.dart';
import 'addManpower.dart';
import 'man_import.dart';



class ManEntrySelectCardGrid extends StatelessWidget {
  const ManEntrySelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( drawer: const CustomDrawer(),

      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Manpower Entry"),
      body: BottomButtonWrapper(
        onBackPressed: (){Navigator.pop(context);},
        child: Column(
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
                      "assets/images/icons/manual_entry.webp",

                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,

                    ),
                    label: "Manual Entry",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>NewManpowerScreen() ),
                      );

                    },
                  ),
                  SelectCard(
                    icon: Image.asset(
                      "assets/images/icons/import_sheet.webp",

                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,

                    ),
                    label: "Import Sheet",
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>ManImportCsvScreen() ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Choose the entry method",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Manual Entry: Enter site details step-by-step manually.\n"
                        "• Import Sheet: Upload an Excel/CSV sheet — our AI will analyze your file and map fields automatically.",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
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
