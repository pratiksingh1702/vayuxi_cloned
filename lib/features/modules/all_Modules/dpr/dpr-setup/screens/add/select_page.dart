// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../screens/widgets/select_card.dart';
import 'add_floor.dart';
import 'add_material.dart';
import 'add_moc.dart';
class AddSelectCardGrid extends StatelessWidget {
  const AddSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title:"Select Card"),
      body: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1,
        children: [
          SelectCard(
            icon: Image.asset(
              "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",

              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,

            ),
            label: "Moc",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMOCPage()),
              );
            },
          ),
          SelectCard(
            icon: Image.asset(
              "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",

              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,

            ),
            label: "Floor",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFloorPage()),
              );
            },
          ),
          SelectCard(
            icon: Image.asset(
              "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",

              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,

            ),
            label: "DPR Screen",
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PersistDPRScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
