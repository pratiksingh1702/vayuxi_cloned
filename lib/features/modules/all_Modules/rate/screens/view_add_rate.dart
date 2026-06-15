// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate_entry_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/site_rate_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import 'package:untitled2/features/tour/widgets/no_cutout_tour_target.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

class RateSelectCardGrid extends ConsumerStatefulWidget {
  const RateSelectCardGrid({super.key});

  @override
  ConsumerState<RateSelectCardGrid> createState() => _RateSelectCardGridState();
}

class _RateSelectCardGridState extends ConsumerState<RateSelectCardGrid> with ScreenOwnedTourMixin<RateSelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _viewTourKey = GlobalKey(debugLabel: 'rate_selector_view');
  final GlobalKey _addTourKey = GlobalKey(debugLabel: 'rate_selector_add');

  void _syncRateSelectorTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.rateId}_selector',
      title: 'Rate Setup',
      description: 'Choose how to use Rate Setup.',
      icon: Icons.currency_rupee_rounded,
      steps: [
        const AppTourStep(
          id: 'rate_selector_intro',
          title: 'Rate Setup',
          body: 'Use this module to view rates or add new rates for site work.',
          progressLabel: 'Rate setup',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'rate_selector_view',
          title: 'View Rates',
          body: 'Open this to see, edit, delete, and download existing rates.',
          targetKey: _viewTourKey,
          progressLabel: 'View',
        ),
        AppTourStep(
          id: 'rate_selector_add',
          title: 'Add Rates',
          body: 'Open this to add rates manually or upload a rate sheet.',
          targetKey: _addTourKey,
          progressLabel: 'Add',
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SiteRateModuleTours.rateId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
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
      // No-cutout tour overlay handles target presentation.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return NoCutoutTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncRateSelectorTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(title: "Select Rate "),
          body: BottomButtonWrapper(
        onBackPressed: () {
          context.pop();
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16), // Add side padding
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12, // Reduced vertical space between cards
                crossAxisSpacing: 10, // Reduced horizontal space between cards
                childAspectRatio: 1,
                children: [
                  _tourTarget(
                    _viewTourKey,
                    SelectCard(
                      icon: const SelectCardIcon(
                        icon: Icons.visibility_rounded,
                        color: Colors.blue,
                      ),
                      label: "View",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RateScreen()),
                        );
                      },
                    ),
                  ),
                  _tourTarget(
                    _addTourKey,
                    SelectCard(
                      icon: const SelectCardIcon(
                        icon: Icons.add_circle_outline_rounded,
                        color: Colors.green,
                      ),
                      label: "add",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RateEntrySelectCardGrid()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ---------------- INFO CARD UNDER GRID ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? colorScheme.shadow.withOpacity(0.12)
                        : colorScheme.shadow.withOpacity(0.06),
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• View: You can view your sites and also edit them.\n"
                    "• Add: You can create and register a new site.",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
          ),
        );
      },
    );
  }
}
