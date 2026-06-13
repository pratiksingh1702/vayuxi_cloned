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
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/definitions/site_rate_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

bool get _phase1DeepSiteTourEnabled => false;

class SiteSelectCardGrid extends ConsumerStatefulWidget {
  const SiteSelectCardGrid({super.key});

  @override
  ConsumerState<SiteSelectCardGrid> createState() => _SiteSelectCardGridState();
}

class _SiteSelectCardGridState extends ConsumerState<SiteSelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _viewCardTourKey = GlobalKey(debugLabel: 'site_selector_view');
  final GlobalKey _addCardTourKey = GlobalKey(debugLabel: 'site_selector_add');

  void _syncSiteSelectorTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.siteDetailsId}_selector',
      title: 'Site Details',
      description: 'Choose how to use Site Details.',
      icon: Icons.location_city_rounded,
      steps: [
        const AppTourStep(
          id: 'site_selector_intro',
          title: 'Site Details',
          body: 'Use this module to view existing sites or create a new site.',
          progressLabel: 'Site Details',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'site_selector_view',
          title: 'View Sites',
          body: 'Open this to see your existing project sites and edit them.',
          targetKey: _viewCardTourKey,
          progressLabel: 'View',
        ),
        AppTourStep(
          id: 'site_selector_add',
          title: 'Add Site',
          body: 'Open this to create a new site manually or by import.',
          targetKey: _addCardTourKey,
          progressLabel: 'Add',
        ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SiteRateModuleTours.siteDetailsId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null ||
          !activeTour.id.startsWith(SiteRateModuleTours.siteDetailsId)) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(16),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncSiteSelectorTour(showcaseContext);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!_phase1DeepSiteTourEnabled) return;
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
                      _tourTarget(
                        _viewCardTourKey,
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
                      ),

                      // ---------------- ADD ----------------
                      _tourTarget(
                        _addCardTourKey,
                        SelectCard(
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
