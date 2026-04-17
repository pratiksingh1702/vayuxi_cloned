import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';

class GetPremiumScreen extends StatelessWidget {
  const GetPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // HEADER
              const Text(
                "Get Premium",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Unlock all the power of this mobile tool and enjoy digital experience like never before!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              // ILLUSTRATION IMAGE
              Container(
                color: Colors.black,
                child: SvgPicture.asset(
                  "assets/images/premium_box.webp",
                ),
              ),

              const SizedBox(height: 20),

              /// PLAN CARD – ANNUAL
              _subscriptionCard(
                title: "Annual",
                subtitle: "First 7 days free – Then \$1500/Year",
                highlight: "Best Value",
                highlightColor: Colors.amber,
              ),

              const SizedBox(height: 12),

              /// PLAN CARD – MONTHLY
              _subscriptionCard(
                title: "Monthly",
                subtitle: "First 7 days free – Then \$99/Month",
              ),

              const SizedBox(height: 12),

              /// DUPLICATE MONTHLY CARD (as per screenshot)
              _subscriptionCard(
                title: "Monthly",
                subtitle: "First 7 days free – Then \$99/Month",
              ),

              const SizedBox(height: 35),

              // CTA BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Start 30-day free trial",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // TERMS TEXT
              const Text(
                "By placing this order, you agree to the Terms of Service and Privacy Policy. "
                    "Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              // BACK BUTTON
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Subscription Card widget
  static Widget _subscriptionCard({
    required String title,
    required String subtitle,
    String? highlight,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (highlight != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (highlightColor ?? Colors.orange)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          highlight,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: highlightColor ?? Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

