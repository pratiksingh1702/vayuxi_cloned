import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/card.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'core/router/routes.dart';
import 'core/utlis/common_functions.dart';
import 'core/utlis/widgets/language_first_time_popup.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/language/model/language_storage.dart';
import 'features/language/service/lang_providers.dart';
import 'features/modules/all_Modules/dpr/dpr_insu/model/dpr_model_insu.dart';
import 'features/modules/all_Modules/dpr/dpr_insu/providers/draft_insu.dart';
import 'features/modules/all_Modules/dpr/dpr_insu/screens/testing.dart';
import 'features/modules/all_Modules/more/language.dart';
import 'features/modules/screen/device_id.dart';
import 'features/noti_system/noti_providers/noti_provider.dart';
import 'features/profile_page/provider/userProvider.dart';
import 'features/tour/domain/tour_controller.dart';
import 'features/tour/domain/tour_registery.dart';

class WorkCategoryScreen extends ConsumerStatefulWidget {
  const WorkCategoryScreen({super.key});

  @override
  ConsumerState<WorkCategoryScreen> createState() => _WorkCategoryScreenState();
}

class _WorkCategoryScreenState extends ConsumerState<WorkCategoryScreen> {
  String? selectedImage;
  bool showLanguagePopup = false;
  bool languagePopupChecked = false; // avoid re-show loop
  bool _languageFlowDone = false; // <-- add this
  bool _showcaseStarted = false;
  bool _isNavigating = false;
  BuildContext? _showcaseContext;

  Future<void> _ensureEnglishDefault() async {
    const englishCode = 'en-IN';
    final storage = LanguageStorage();

    // Keep a deterministic fallback language so UI text is always available.
    if (storage.getActiveLanguage().trim().isEmpty) {
      await storage.setActiveLanguage(englishCode);
    }

    final user = ref.read(currentUserProvider);
    if (user != null && !storage.isLanguageDownloaded(englishCode)) {
      try {
        await ref
            .read(languageRepositoryProvider)
            .downloadAndStoreLanguage(user.id, englishCode);
      } catch (_) {
        // If network/download fails, fallback still remains English code locally.
      }
    }

    if (!storage.isLanguageDownloaded(storage.getActiveLanguage()) &&
        storage.getActiveLanguage() != englishCode) {
      await storage.setActiveLanguage(englishCode);
    }

    ref.invalidate(activeLanguageProvider);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(userNotifierProvider.notifier).getCurrentUser();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.id);
      }

      await _ensureEnglishDefault();

      final alreadySeen = await LanguagePopupPrefs.hasSeen();

      if (!mounted) return;

      if (!alreadySeen) {
        setState(() => showLanguagePopup = true);
      } else {
        setState(() => _languageFlowDone = true);
      }
    });
  }

  Future<void> handlePress({
    required String id,
    required String title,
    required String imagePath,
  }) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      setState(() => selectedImage = id);

      // Ensure the active highlight/overlay is fully removed before route push
      // so users don't see leftover placeholders during screen transition.
      if (_showcaseContext != null) {
        ShowCaseWidget.of(_showcaseContext!)?.dismiss();
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 90));
      }

      final typeNotifier = ref.read(typeProvider.notifier);

      // Send instant notification
      // await ref
      //     .read(notificationsStateProvider.notifier)
      //     .sendInstantNotification(
      //   title: 'Hello!',
      //   body: '${id} as a type has been set for further progress in app. Enjoy 😊',
      // );

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
      ref.read(siteProvider.notifier).fetchSites();

      await context.push(
        Routes.selectModule,
        extra: {"title": title, "image": imagePath},
      );
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(insulationDraftProvider);

    final authState = ref.watch(authProvider);

    if (!authState.isLoggedIn) {
      Future.microtask(() => context.go(Routes.login));
    }

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _showcaseContext = showcaseContext;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_languageFlowDone) return;
          if (_showcaseStarted) return; // ✅ HARD BLOCK

          final ctrl = ref.read(tourControllerProvider.notifier);
          ctrl.syncToRoute(AppRoutes.workCategory);

          final step = ctrl.currentStep;
          if (step == null) return;

          if (!step.autoShowcase) return;

          final sc = ShowCaseWidget.of(showcaseContext);
          if (sc == null) return;

          _showcaseStarted = true;
          sc.startShowCase([step.showcaseKey]);
        });

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.lightBlue,
              appBar: CustomAppBar(
                title: "Select Category",
                showDrawer: false,
              ),
              body: CornerClippedScreenSimple(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.8,
                            children: [
                              Showcase(
                                key: TourRegistry.workCategoryKey,
                                description:
                                    "Select any Work Type to continue 🚀",
                                child: CompanyCard(
                                  imagePath: "assets/images/mech.webp",
                                  companyName: "Mechanical Work",
                                  isSelected: selectedImage == "mechanical",
                                  onTap: () => handlePress(
                                    id: "mechanical",
                                    title: "Mechanical Work",
                                    imagePath:
                                        "https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600",
                                  ),
                                ),
                              ),
                              CompanyCard(
                                imagePath: "assets/images/insu.webp",
                                companyName: "Insulation Work",
                                isSelected: selectedImage == "insulation",
                                onTap: () => handlePress(
                                  id: "insulation",
                                  title: "Insulation Work",
                                  imagePath:
                                      "https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=600",
                                ),
                              ),
                            ],
                          ),
                        ),
                        //
                        // if (drafts.isNotEmpty)
                        //   ...drafts.map((draft) => DraftCard(draft,context))
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Overlay popup
            if (showLanguagePopup)
              LanguageFirstTimePopup(
                onSelectLanguage: () async {
                  await LanguagePopupPrefs.markSeen(); // ⭐ add this
                  await _ensureEnglishDefault();

                  setState(() => showLanguagePopup = false);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );

                  if (!mounted) return;
                  setState(() => _languageFlowDone = true);
                },
                onSkip: () async {
                  await LanguagePopupPrefs.markSeen(); // ⭐ add this
                  await _ensureEnglishDefault();

                  setState(() {
                    showLanguagePopup = false;
                    _languageFlowDone = true;
                  });
                },
              ),

/**/
          ],
        );
      },
    );
  }
}

Widget DraftCard(InsulationDprModel draft, BuildContext context) {
  return Card(
    color: Colors.orange[50],
    child: ListTile(
      leading: Icon(Icons.save, color: Colors.orange),
      title: Text(draft.workDescription),
      subtitle: Text("Unsaved changes • ${draft.date}"),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInsulationDescriptionScreen(
              work: draft,
            ),
          ),
        );
      },
    ),
  );
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
    final textAreaHeight = size.height * 0.05; // consistent across cards

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Colors.transparent,
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
