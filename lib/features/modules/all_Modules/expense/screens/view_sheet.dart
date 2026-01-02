// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';

import '../../dpr/screens/widgets/select_card.dart';
import 'download_sheet.dart';
import 'expense_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';




class ExpenseEntrySelectCardGrid extends ConsumerWidget{
  const ExpenseEntrySelectCardGrid({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final site=ref.read(selectedSiteIdProvider);
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
                  "assets/images/icons/manual_entry.webp",

                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,

                ),
                label: "Download Sheet",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>ExpenseReportScreen(siteId: site!,) ),
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
                label: "View",
                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>ExpenseListScreen(siteId: site!,) ),
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
