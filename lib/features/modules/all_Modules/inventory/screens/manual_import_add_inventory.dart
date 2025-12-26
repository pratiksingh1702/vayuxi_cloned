// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';

import '../../dpr/screens/widgets/select_card.dart';
import 'add_bulk_inven.dart';
import 'add_inven.dart';


class AddInventorySelection extends StatelessWidget {
  const AddInventorySelection({super.key});

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
              "assets/images/icons/manual_entry.webp",

              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,

            ),
            label: "Manual",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>CreateInventoryScreen()),
              );
              print("implementing");
            },
          ),
          SelectCard(
            icon: Image.asset(
              "assets/images/icons/import_sheet.webp",

              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,

            ),
            label: "Import sheet",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>BulkUploadScreen() ),
              );
            },
          ),

        ],
      ),
    );
  }
}
