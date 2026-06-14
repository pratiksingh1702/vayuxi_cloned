// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate_entry_select_page.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import '../../../../tour/definitions/manpower_team_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../../dpr/screens/widgets/select_card.dart';
import 'manpowerList.dart';
import 'manpower_entry_select.dart';

class ManSelectCardGrid extends ConsumerStatefulWidget {
  const ManSelectCardGrid({super.key});

  @override
  ConsumerState<ManSelectCardGrid> createState() => _ManSelectCardGridState();
}

class _ManSelectCardGridState extends ConsumerState<ManSelectCardGrid> with ScreenOwnedTourMixin<ManSelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _viewTourKey = GlobalKey(debugLabel: 'manpower_selector_view');
  final GlobalKey _addTourKey = GlobalKey(debugLabel: 'manpower_selector_add');

  void _syncSelectorTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${ManpowerTeamModuleTours.manpowerId}_selector',
      title: 'Manpower Options',
      description: 'Choose whether to view or add manpower.',
      icon: Icons.badge_rounded,
      steps: [
        const AppTourStep(
          id: 'manpower_selector_intro',
          title: 'Manpower',
          body: 'Use this module to view workers or add new manpower details.',
          progressLabel: 'Manpower options',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'manpower_selector_view',
          title: 'View Manpower',
          body: 'Open this to see saved workers, search them, edit them, or download records.',
          targetKey: _viewTourKey,
          progressLabel: 'View',
        ),
        AppTourStep(
          id: 'manpower_selector_add',
          title: 'Add Manpower',
          body: 'Open this to add worker details manually or from a sheet.',
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
      final state = ref.read(appTourControllerProvider);
      final controller = ref.read(appTourControllerProvider.notifier);
      if (state.status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: ManpowerTeamModuleTours.manpowerId,
        );
      }
      final step = controller.currentStep;
      final activeTour = controller.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) return;
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      await _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncSelectorTour(showcaseContext);
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Select Manpower"),
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
                        MaterialPageRoute(
                            builder: (context) => ManpowerListScreen()),
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
                            builder: (context) => ManEntrySelectCardGrid()),
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
