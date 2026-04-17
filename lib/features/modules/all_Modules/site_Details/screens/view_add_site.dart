import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import 'package:untitled2/features/tour/domain/tour_events.dart';
import 'package:untitled2/features/tour/registry/site_registry.dart';
import 'package:untitled2/features/tour/domain/tour_controller.dart';
import 'package:untitled2/features/tour/domain/tour_presistent.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

class SiteSelectCardGrid extends ConsumerWidget {
  const SiteSelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ctrl = ref.read(tourControllerProvider.notifier);
          final persistence = TourPersistence();

          // ✅ Auto-start Site tour if not done yet
          final siteDone = await persistence.isModuleDone('site');
          final savedIndex = await persistence.getModuleStepIndex('site');
          final alreadyRunningSite =
              ctrl.isRunning && ctrl.activeModule?.id == SiteRegistry.module.id;

          debugPrint(
              '🎬 [SiteSelectCardGrid] PostFrame: siteDone=$siteDone, savedIndex=$savedIndex, alreadyRunningSite=$alreadyRunningSite');

          if (!siteDone) {
            if (alreadyRunningSite) {
              final runningStep = ctrl.currentStep;
              debugPrint(
                  '🎬 [SiteSelectCardGrid] Module already running at step=${runningStep?.id} route=${runningStep?.route}');
              // Self-heal: if module is running but not on /site, reset to step 0
              // so Buddy/showcase are visible on this screen.
              if (runningStep == null || runningStep.route != Routes.site) {
                debugPrint(
                    '🎬 [SiteSelectCardGrid] SELF-HEAL: Module running on ${runningStep?.route} while at /site → reset to step 0');
                await ctrl
                    .resetModuleAndStartFromBeginning(SiteRegistry.module);
              } else {
                debugPrint(
                    '🎬 [SiteSelectCardGrid] Already running on correct route, skipping reset');
              }
            } else {
              // If user lands on /site with stale persisted progress (e.g. step=1),
              // force restart from step 0.
              if (savedIndex > 0) {
                debugPrint(
                    '🎬 [SiteSelectCardGrid] STALE STEP: persisted step=$savedIndex → resetting to step 0');
                await ctrl
                    .resetModuleAndStartFromBeginning(SiteRegistry.module);
              } else {
                debugPrint(
                    '🎬 [SiteSelectCardGrid] FRESH START: savedIndex=$savedIndex → calling startModule');
                await ctrl.startModule(SiteRegistry.module);
              }
            }
          } else {
            debugPrint(
                '🎬 [SiteSelectCardGrid] Site tour already completed, skipping startup');
          }

          // ⚡ IMMEDIATE syncToRoute (no 60ms delay) - fixes GoRouter lag
          // When startModule() changes state, GlobalTourOverlay rebuilds before GoRouter updates.
          // By calling syncToRoute immediately, we ensure the buddy sees the correct route.
          debugPrint(
              '🎬 [SiteSelectCardGrid] IMMEDIATE syncToRoute (no delay) to beat GoRouter lag');
          ctrl.syncToRoute(Routes.site);

          final step = ctrl.currentStep;
          debugPrint(
              '🎬 [SiteSelectCardGrid] After immediate syncToRoute: step=${step?.id}, isRunning=${ctrl.isRunning}');

          if (step == null || !ctrl.isRunning) {
            debugPrint(
                '🎬 [SiteSelectCardGrid] No step or not running, skipping showcase');
            return;
          }

          debugPrint(
              '🎬 [SiteSelectCardGrid] Step route=${step.route} vs Routes.site=${Routes.site}, autoShowcase=${step.autoShowcase}');
          if (step.route != Routes.site || !step.autoShowcase) {
            debugPrint(
                '🎬 [SiteSelectCardGrid] Route mismatch or autoShowcase=false, skipping showcase');
            return;
          }

          final sc = ShowCaseWidget.of(showcaseContext);
          if (sc == null) {
            debugPrint(
                '🎬 [SiteSelectCardGrid] ShowCaseWidget context is null!');
            return;
          }

          debugPrint(
              '🎬 [SiteSelectCardGrid] STARTING SHOWCASE with key=${step.showcaseKey}');
          sc.startShowCase([step.showcaseKey]);
        });

        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
          appBar: CustomAppBar(title: "Select Site Entry"),
          body: BottomButtonWrapper(
            onBackPressed: () => context.pop(),
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
                        icon: const SelectCardIcon(
                          icon: Icons.visibility_rounded,
                          color: Colors.blue,
                        ),
                        label: "View",
                        onTap: () {
                          ref.read(selectedSiteIdProvider.notifier).state =
                              null;
                          context.push("/site-list/site");
                        },
                      ),

                      // ---------------- ADD ----------------
                      Showcase(
                        key: SiteRegistry.addSiteCardKey,
                        description: 'Tap Add to create your first Site.',
                        child: SelectCard(
                          icon: const SelectCardIcon(
                            icon: Icons.add_circle_outline_rounded,
                            color: Colors.green,
                          ),
                          label: "Add",
                          onTap: () {
                            ref
                                .read(tourControllerProvider.notifier)
                                .onEvent(TourEvents.addSiteTapped);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteEntrySelectCardGrid(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ---------------- INFO CARD UNDER GRID ----------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainer : cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? cs.outline.withOpacity(0.35)
                            : cs.outlineVariant.withOpacity(0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(isDark ? 0.24 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Choose an option",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• View: You can view your sites and also edit them.\n"
                          "• Add: You can create and register a new site.",
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: cs.onSurfaceVariant,
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
      },
    );
  }
}
