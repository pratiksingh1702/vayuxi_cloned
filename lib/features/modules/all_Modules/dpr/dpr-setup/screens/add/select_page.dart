// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../screens/dprTeamDetails.dart';
import '../../../screens/widgets/select_card.dart';
import '../../../screens/workTeamList.dart';
import 'add_floor.dart';
import 'add_material.dart';
import 'add_moc.dart';
class AddSelectCardGrid extends StatelessWidget {
  const AddSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Dpr Values"),
      body: CornerClippedScreenSimple(
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            FractionallySizedBox(
              widthFactor: 0.88,
              heightFactor: 0.88,
              child: SelectCard(
                icon: const SelectCardIcon(
                  icon: Icons.account_tree_rounded,
                  color: Colors.deepPurple,
                ),
                label: "Moc",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddMOCPage()),
                  );
                },
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.88,
              heightFactor: 0.88,
              child: SelectCard(
                icon: const SelectCardIcon(
                  icon: Icons.layers_rounded,
                  color: Colors.teal,
                ),
                label: "Floor",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddFloorPage()),
                  );
                },
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.88,
              heightFactor: 0.88,
              child: SelectCard(
                icon: const SelectCardIcon(
                  icon: Icons.dashboard_customize_rounded,
                  color: Colors.indigo,
                ),
                label: "DPR Screen",
                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersistDPRScreen(


                              )
                      ,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
