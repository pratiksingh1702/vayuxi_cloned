// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';

import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../screens/widgets/select_card.dart';
import 'add/select_page.dart';


class DprSelectCardGrid extends StatelessWidget {
  const DprSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select View or Add"),
      body: BottomButtonWrapper(
        child: Column(
          children: [
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
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
                      MaterialPageRoute(builder: (context) => ViewSelectCardGrid()),
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
                  label: "add",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>AddSelectCardGrid() ),
                    );
                  },
                ),

              ],
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
                    "Choose an option",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• View: You can view your sites and also edit them.\n"
                        "• Add: You can create and register a new site.",
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
