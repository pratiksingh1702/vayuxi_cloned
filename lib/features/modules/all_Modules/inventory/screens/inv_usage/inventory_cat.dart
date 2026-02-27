import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../dpr/screens/widgets/select_card.dart';

import 'checkout_managment_page.dart';
import 'inv_usage.dart';

class InventoryCategorySelectionScreen extends StatelessWidget {
  const InventoryCategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: "Select Category"),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                /// ---------------- CONSUMABLE ----------------
                SelectCard(
                  icon: Image.asset(
                    "assets/images/icons/_con.webp", // change if needed
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  label: "Consumable",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventorySelectionPage(),
                      ),
                    );
                  },
                ),

                /// ---------------- FIXED ----------------
                SelectCard(
                  icon: Image.asset(
                    "assets/images/icons/fix.webp", // change if needed
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  label: "Fixed",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// ---------------- INFO CARD ----------------
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose inventory type",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "• Consumable: Record material usage like cement, fuel, etc.\n"
                      "• Fixed: Issue & return assets like tools or machines.",
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
    );
  }
}
