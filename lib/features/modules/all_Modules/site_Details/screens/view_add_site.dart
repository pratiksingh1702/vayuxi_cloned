import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import '../../dpr/screens/widgets/select_card.dart';

class SiteSelectCardGrid extends ConsumerWidget {
  const SiteSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Select Card"),
      body: BottomButtonWrapper(
        onBackPressed: () => Navigator.pop(context),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            // ---------------- VIEW ----------------
            SelectCard(
              icon: Image.asset(
                "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              label: "View",
              onTap: () {
                // ❗ Reset previously selected site
                ref.read(selectedSiteIdProvider.notifier).state = null;

                context.push("/site-list/site");
              },
            ),

            // ---------------- ADD ----------------
            SelectCard(
              icon: Image.asset(
                "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              label: "add",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SiteEntrySelectCardGrid()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
