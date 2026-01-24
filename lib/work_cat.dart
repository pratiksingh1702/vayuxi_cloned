import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/card.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'core/router/routes.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/modules/screen/device_id.dart';
import 'features/noti_system/noti_providers/noti_provider.dart';
import 'features/profile_page/provider/userProvider.dart';

class WorkCategoryScreen extends ConsumerStatefulWidget {
  const WorkCategoryScreen({super.key});

  @override
  ConsumerState<WorkCategoryScreen> createState() => _WorkCategoryScreenState();
}

class _WorkCategoryScreenState extends ConsumerState<WorkCategoryScreen> {
  String? selectedImage;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userNotifierProvider.notifier).getCurrentUser();
    });

  }

  Future<void> handlePress({
    required String id,
    required String title,
    required String imagePath,
  }) async {
    setState(() => selectedImage = id);

    final typeNotifier = ref.read(typeProvider.notifier);
    // Send instant notification
    await ref
        .read(notificationsStateProvider.notifier)
        .sendInstantNotification(
      title: 'Hello!',
      body: '${id} as a type has been set for further progress in app. Enjoy 😊',
    );

// Morning notification at 07:30
    await ref
        .read(notificationsStateProvider.notifier)
        .scheduleDailyNotification(
      title: '🌅 Morning Reminder',
      body: 'Takes 1 min — update today\'s attendance.',
      hour: 7,
      minute: 30,
    );


// Evening notification at 19:30
    await ref
        .read(notificationsStateProvider.notifier)
        .scheduleDailyNotification(
      title: '🌇 Evening Reminder',
      body: 'Quick close: attendance, expenses, inventory & work update.',
      hour: 19,
      minute: 30,
    );
    print("notification sent");

    if (id == "mechanical") {
      typeNotifier.setType("mechanical_work");
    } else if (id == "insulation") {
      typeNotifier.setType("insulation_work");
    }

    context.push(
      Routes.selectModule,
      extra: {"title": title, "image": imagePath},
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
      body: CornerClippedScreenSimple(
        child: SafeArea(
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
                    childAspectRatio: 0.8, // Better aspect ratio for cards
                    children: [
                      CompanyCard(
                        imagePath: "assets/images/mech.webp",
                        companyName: "Mechanical Work",
                        isSelected: selectedImage == "mechanical",
                        onTap: () => handlePress(
                          id: "mechanical",
                          title: "Mechanical Work",
                          imagePath: "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600",
                        ),
                      ),
                      CompanyCard(
                        imagePath: "assets/images/insu.webp",
                        companyName: "Insulation Work",
                        isSelected: selectedImage == "insulation",
                        onTap: () => handlePress(
                          id: "insulation",
                          title: "Insulation Work",
                          imagePath: "https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=600",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyCard extends StatelessWidget {
  final String imagePath;
  final String companyName;
  final bool isSelected;
  final VoidCallback? onTap;

  const CompanyCard({
    super.key,
    required this.imagePath,
    required this.companyName,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive heights based on screen size
    final cardImageHeight = size.height * 0.15; // ~15% of screen
    final textAreaHeight = size.height * 0.05;  // consistent across cards

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Responsive image container
            Container(
              padding: EdgeInsets.all(size.height * 0.01),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  imagePath,
                  height: cardImageHeight,
                  width: double.infinity,
                  fit: BoxFit.fill,
                ),
              ),
            ),



            // Responsive text area
            SizedBox(
              height: textAreaHeight,
              child: Center(
                child: Text(
                  companyName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size.height * 0.02,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
