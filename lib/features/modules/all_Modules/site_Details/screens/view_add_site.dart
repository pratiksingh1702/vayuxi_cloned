import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

class SiteSelectCardGrid extends ConsumerWidget {
  const SiteSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Select Site Entry"),
      body: BottomButtonWrapper(
        onBackPressed: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ---------------- GRID ----------------
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
                children: [
                  // ---------------- VIEW ----------------
                  SelectCard(
                    icon: Image.asset(
                      "assets/images/icons/view.webp",
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    label: "View",
                    onTap: () {
                      ref.read(selectedSiteIdProvider.notifier).state = null;
                      context.push("/site-list/site");
                    },
                  ),

                  // ---------------- ADD ----------------
                  SelectCard(
                    icon: Image.asset(
                      "assets/images/icons/add.webp",
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    label: "Add",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SiteEntrySelectCardGrid(),
                        ),
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
      ),
    );
  }
}
