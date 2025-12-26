// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate_entry_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';

import '../../dpr/screens/widgets/select_card.dart';
import 'manpowerList.dart';
import 'manpower_entry_select.dart';



class ManSelectCardGrid extends StatelessWidget {
  const ManSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Card"),
      body: BottomButtonWrapper(
        onBackPressed: (){Navigator.pop(context);},
        child: Container(
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
                    MaterialPageRoute(builder: (context) =>ManpowerListScreen() ),
                  );

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
                    MaterialPageRoute(builder: (context) =>ManEntrySelectCardGrid() ),
                  );

                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
