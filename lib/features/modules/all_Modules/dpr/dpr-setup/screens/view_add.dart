import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

import '../../screens/widgets/select_card.dart';
import 'add/select_page.dart';
import 'view/view_select_page.dart';

class DprSelectCardGrid extends ConsumerStatefulWidget {
  const DprSelectCardGrid({super.key});

  @override
  ConsumerState<DprSelectCardGrid> createState() => _DprSelectCardGridState();
}

class _DprSelectCardGridState extends ConsumerState<DprSelectCardGrid> with ScreenOwnedTourMixin<DprSelectCardGrid> {
  static const TourPackageAdapter _adapter = TourPackageAdapter();
  final _viewKey = GlobalKey(debugLabel: 'dpr_setup_view');
  final _addKey = GlobalKey(debugLabel: 'dpr_setup_add');
  String? _lastStep;

  void _syncTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.dprSetupId}_chooser',
      title: 'DPR Setup',
      description: 'Choose how to configure DPR values.',
      icon: Icons.settings_suggest_rounded,
      steps: [
        const AppTourStep(
          id: 'dpr_setup_intro',
          title: 'DPR Setup',
          body: 'View existing DPR values or add new setup values.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'dpr_setup_view',
          title: 'View Setup',
          body: 'Open this to review and edit existing MOC, floor, elevation, and DPR values.',
          targetKey: _viewKey,
          progressLabel: 'View',
        ),
        AppTourStep(
          id: 'dpr_setup_add',
          title: 'Add Setup',
          body: 'Open this to add MOC, floor, or DPR screen configuration.',
          targetKey: _addKey,
          progressLabel: 'Add',
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      final controller = ref.read(appTourControllerProvider.notifier);
      if (ref.read(appTourControllerProvider).status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.dprSetupId,
        );
      }
      final tour = controller.activeTour;
      final step = controller.currentStep;
      if (tour == null || tour.id != definition.id) {
        if (_lastStep != null) _adapter.dismiss(showcaseContext);
        _lastStep = null;
        return;
      }
      final stepKey = step == null ? null : '${tour.id}:${step.id}';
      if (step == null || stepKey == _lastStep) return;
      _lastStep = stepKey;
      _adapter.showStep(showcaseContext, step);
    });
  }

  Widget _target(GlobalKey key, Widget child) => Showcase.withWidget(
        key: key,
        container: const SizedBox.shrink(),
        overlayOpacity: 0.72,
        targetPadding: const EdgeInsets.all(8),
        targetBorderRadius: BorderRadius.circular(16),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: AppColors.lightBlue,
          appBar: CustomAppBar(title: 'Select View or Add'),
          body: BottomButtonWrapper(
            child: Column(
              children: [
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                  children: [
                    _target(
                      _viewKey,
                      SelectCard(
                        icon: const SelectCardIcon(
                          icon: Icons.visibility_rounded,
                          color: Colors.blue,
                        ),
                        label: 'View',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewSelectCardGrid(),
                          ),
                        ),
                      ),
                    ),
                    _target(
                      _addKey,
                      SelectCard(
                        icon: const SelectCardIcon(
                          icon: Icons.add_circle_outline_rounded,
                          color: Colors.green,
                        ),
                        label: 'Add',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddSelectCardGrid(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                  child: const Text(
                    'View: Review and edit existing DPR setup values.\n'
                    'Add: Create new MOC, floor, or DPR screen values.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
