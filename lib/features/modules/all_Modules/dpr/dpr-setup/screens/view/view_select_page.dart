// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/floor_selection_page.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';

import '../../../dpr_insu/screens/all_insulation_material.dart';
import '../../../screens/dprTeamDetails.dart';
import '../../../screens/widgets/all_material.dart';
import '../../../screens/widgets/select_card.dart';
import '../../../dpr_report/screens/download_sheets.dart';
import '../../../screens/workTeamList.dart';

class ViewSelectCardGrid extends StatelessWidget {
  const ViewSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Card"),
      body: BottomButtonWrapper(
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
                "assets/images/icons/moc.webp",
        
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
        
              ),
              label: "Moc",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MOCSelectionPage(showEditOptions: true,)),
                );
              },
            ),
            SelectCard(
              icon: Image.asset(
                "assets/images/icons/floor.webp",
        
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
        
              ),
              label: "Floor",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FloorSelectionPage(showEditOptions: true,)),
                );
              },
            ),
            SelectCard(
              icon: Image.asset(
                "assets/images/icons/dpr_setup_icon.webp",
        
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
        
              ),
              label: "DPR Screen",
              onTap: () {


                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllInsulationMaterialsScreen(


                            )
                    ,
                  ),
                );

              },
            ),
          ],
        ),
      ),
    );
  }
}
