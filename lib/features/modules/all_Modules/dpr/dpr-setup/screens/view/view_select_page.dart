import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/rate_file_isar.dart';

import 'package:untitled2/typeProvider/type_provider.dart';

import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/floor_selection_page.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';

import '../../../../../../../core/local/isar_db.dart';
import '../../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../site_Details/providers/site_current_provider.dart';
import '../../../dpr_insu/screens/all_insulation_material.dart';
import '../../../providers/rate_variant_provider.dart';
import '../../../screens/widgets/all_material.dart';
import '../../../screens/widgets/elevation_file.dart';
import '../../../screens/widgets/select_card.dart';

class ViewSelectCardGrid extends ConsumerWidget {
  const ViewSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(selectedSiteIdProvider)!;

    final floors = ref.watch(floorWithImagesProvider(siteId));
    print(floors);
    final elevations = ref.watch(elevationListDetectedProvider(siteId));
    final mocs = ref.watch(mocListDetectedProvider(siteId)); // if you add this

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Select Dpr Values"),
      body: BottomButtonWrapper(
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            /// ✅ MOC

              SelectCard(
                icon: Image.asset(
                  "assets/images/icons/moc.webp",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                label: "MOC",
                onTap: mocs.isNotEmpty ?(){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MOCSelectionPage(showEditOptions: true,),
                    ),
                  );
                }:(){},
              ),

            /// ✅ FLOOR

              SelectCard(
                icon: Image.asset(
                  "assets/images/icons/floor.webp",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                label: "Floor",
                onTap: floors.isNotEmpty
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FloorSelectionPage(showEditOptions: true),
                    ),
                  );
                }
                    : (){},
              ),

            /// ✅ ELEVATION (if you have a page for it)
            if (elevations.isNotEmpty)
              SelectCard(
                icon: Image.asset(
                  "assets/images/icons/elevation.webp",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                label: "Elevation",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ElevationSelectionPage(),
                    ),
                  );
                },
              ),

            /// DPR SCREEN (always visible)
            SelectCard(
              icon: Image.asset(
                "assets/images/icons/dpr_setup_icon.webp",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              label: "DPR Screen",
              onTap: () {
                final type = ref.read(typeProvider);
                if (type == "mechanical_work") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllMaterialsScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const AllInsulationMaterialsScreen(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}