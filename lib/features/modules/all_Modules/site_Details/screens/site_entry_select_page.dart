// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/site_import.dart';
import 'package:untitled2/features/tour/domain/tour_controller.dart';
import 'package:untitled2/features/tour/domain/tour_events.dart';
import 'package:untitled2/features/tour/registry/site_registry.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/definitions/site_rate_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

bool get _phase1DeepSiteTourEnabled => false;

class SiteEntrySelectCardGrid extends ConsumerStatefulWidget {
  const SiteEntrySelectCardGrid({super.key});

  @override
  ConsumerState<SiteEntrySelectCardGrid> createState() =>
      _SiteEntrySelectCardGridState();
}

class _SiteEntrySelectCardGridState
    extends ConsumerState<SiteEntrySelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _manualTourKey = GlobalKey(debugLabel: 'site_entry_manual');
  final GlobalKey _importTourKey = GlobalKey(debugLabel: 'site_entry_import');

  void _syncSiteEntryTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.siteDetailsId}_entry_method',
      title: 'Add Site',
      description: 'Choose how to add site details.',
      icon: Icons.add_business_rounded,
      steps: [
        const AppTourStep(
          id: 'site_entry_intro',
          title: 'Add Site',
          body:
              'Choose whether you want to type site details or upload a file.',
          progressLabel: 'Entry method',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'site_entry_manual',
          title: 'Manual Entry',
          body: 'Use this when you want to type site details step by step.',
          targetKey: _manualTourKey,
          progressLabel: 'Manual',
        ),
        AppTourStep(
          id: 'site_entry_import',
          title: 'Import Sheet',
          body:
              'Use this to upload a filled file and create site details faster.',
          targetKey: _importTourKey,
          progressLabel: 'Import',
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
        _syncSiteEntryTour(showcaseContext);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_phase1DeepSiteTourEnabled) return;
          final ctrl = ref.read(tourControllerProvider.notifier);
          ctrl.syncToRoute(Routes.siteEntrySelect);
          final step = ctrl.currentStep;
          if (step == null || !ctrl.isRunning) return;
          if (step.route != Routes.siteEntrySelect || !step.autoShowcase)
            return;
          final sc = ShowCaseWidget.of(showcaseContext);
          if (sc == null) return;
          sc.startShowCase([step.showcaseKey]);
        });

        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
          appBar: CustomAppBar(title: "Select Card"),
          body: BottomButtonWrapper(
            onBackPressed: () {
              context.pop();
            },
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
                      // ---------------- Manual Entry ----------------
                      _tourTarget(
                        _manualTourKey,
                        SelectCard(
                          icon: const SelectCardIcon(
                            icon: Icons.edit_note_rounded,
                            color: Colors.blue,
                          ),
                          label: "Manual Entry",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      // ---------------- Import Sheet ----------------
                      _tourTarget(
                        _importTourKey,
                        SelectCard(
                          icon: const SelectCardIcon(
                            icon: Icons.upload_file_rounded,
                            color: Colors.deepOrange,
                          ),
                          label: "Import Sheet",
                          onTap: () {
                            ref
                                .read(tourControllerProvider.notifier)
                                .onEvent(TourEvents.importSheetTapped);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SiteImportCsvScreen(),
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
                          "Choose the entry method",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• Manual Entry: Enter site details step-by-step manually.\n"
                          "• Import Sheet: Upload an Excel/CSV sheet — our AI will analyze your file and map fields automatically.",
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
