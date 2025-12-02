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
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_import.dart';

import '../../dpr/screens/widgets/select_card.dart';
import '../../rate/screens/import_sheet.dart';



class SiteEntrySelectCardGrid extends StatelessWidget {
  const SiteEntrySelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Card"),
      body: BottomButtonWrapper(
        onBackPressed: (){Navigator.pop(context);},
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            SelectCard(
              icon: Image.asset(
                "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.webp",

                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,

              ),
              label: "Manual Entry",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>SiteDetailScreen() ),
                );

              },
            ),
            SelectCard(
              icon: Image.asset(
                "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.webp",

                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,

              ),
              label: "Import Sheet",
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>SiteImportCsvScreen() ),
                );

              },
            ),

          ],
        ),
      ),
    );
  }
}
