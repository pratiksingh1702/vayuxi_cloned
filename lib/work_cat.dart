import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/card.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'core/router/routes.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/modules/screen/device_id.dart';
import 'features/noti_system/noti_providers/noti_provider.dart';

class WorkCategoryScreen extends ConsumerStatefulWidget {
  const WorkCategoryScreen({super.key});

  @override
  ConsumerState<WorkCategoryScreen> createState() => _WorkCategoryScreenState();
}

class _WorkCategoryScreenState extends ConsumerState<WorkCategoryScreen> {
  String? selectedImage;

  Future<void> handlePress({
    required String id,
    required String title,
    required String imagePath,
  }) async {
    setState(() => selectedImage = id);

    final typeNotifier = ref.read(typeProvider.notifier);
    await ref
        .read(notificationsStateProvider.notifier)
        .sendInstantNotification(
          title: 'Hello!',
          body: '${id} as a type has been set for further progess in app. Enjoy 😊',
        );
    await ref
        .read(notificationsStateProvider.notifier)
        .scheduleDailyNotification(
          title: 'Morning Reminder',
          body: 'Good morning! Time to start your day.',
          hour: 23,
          minute: 00,
        );
    print("notification sent");

    if (id == "mechanical") {
      typeNotifier.setType("mechanical_work");
    } else if (id == "insulation") {
      typeNotifier.setType("insulation_work");
    }

    context.push(
      Routes.selectModule,
      extra: {"title": title, "image": imagePath}, // 🔥 send dynamic values
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (!authState.isLoggedIn) {
      Future.microtask(() => context.go(Routes.login));
    }

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Select Category"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [      

              /// 🔹 Category Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  children: [
                    CompanyCard(

                      imagePath: "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",
                      companyName: "Mechanichal Work",
                      onTap: () => handlePress(
                        id: "mechanical",
                        title: "Mechanical Work",
                        imagePath:
                            "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600",
                      ),
                    ),
                    CompanyCard(

                      imagePath: "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png",
                      companyName: "Insulation Work",
                      onTap: () => handlePress(
                        id: "insulation",
                        title: "Insulation Work",
                        imagePath:
                        "https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=600",
                      ),
                    ),
                    // _buildCategoryCard(
                    //   title: "Mechanical Work",
                    //   subtitle: "Piping • Welding",
                    //   icon: Icons.build_circle,
                    //   imagePath:
                    //       "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600",
                    //   isSelected: selectedImage == "mechanical",
                    //   onTap: () => handlePress(
                    //     id: "mechanical",
                    //     title: "Mechanical Work",
                    //     imagePath:
                    //         "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600",
                    //   ),
                    // ),
                    // _buildCategoryCard(
                    //   title: "Insulation Work",
                    //   subtitle: "Heat • Cooling",
                    //   icon: Icons.ac_unit,
                    //   imagePath:
                    //       "https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=600",
                    //   isSelected: selectedImage == "insulation",
                    //   onTap: () => handlePress(
                    //     id: "insulation",
                    //     title: "Insulation Work",
                    //     imagePath:
                    //         "https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=600",
                    //   ),
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 Refresh User Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeviceOtpScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text("Refresh User Info"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              /// 🔹 Hero for smooth transition
              Hero(
                tag: title,
                flightShuttleBuilder:
                    (
                      flightContext,
                      animation,
                      flightDirection,
                      fromHeroContext,
                      toHeroContext,
                    ) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          ),
                        ),
                        child: toHeroContext.widget,
                      );
                    },
                // ✅ unique tag (use title or custom id)
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
