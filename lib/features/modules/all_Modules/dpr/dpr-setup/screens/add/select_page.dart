import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

import '../../../screens/widgets/select_card.dart';
import '../../../screens/workTeamList.dart';
import 'add_floor.dart';
import 'add_material.dart';
import 'add_moc.dart';

class AddSelectCardGrid extends ConsumerStatefulWidget {
  const AddSelectCardGrid({super.key});

  @override
  ConsumerState<AddSelectCardGrid> createState() => _AddSelectCardGridState();
}

class _AddSelectCardGridState extends ConsumerState<AddSelectCardGrid> {
  static const _adapter = TourPackageAdapter();
  final _mocKey = GlobalKey(debugLabel: 'dpr_add_moc');
  final _floorKey = GlobalKey(debugLabel: 'dpr_add_floor');
  final _screenKey = GlobalKey(debugLabel: 'dpr_add_screen');
  String? _lastStep;

  void _syncTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.dprSetupId}_add_options',
      title: 'Add DPR Setup',
      description: 'Choose the DPR value to configure.',
      icon: Icons.add_task_rounded,
      steps: [
        AppTourStep(
          id: 'dpr_add_moc',
          title: 'Add MOC',
          body: 'Create a material-of-construction option with its image.',
          targetKey: _mocKey,
          progressLabel: 'MOC',
        ),
        AppTourStep(
          id: 'dpr_add_floor',
          title: 'Add Floor',
          body: 'Create floor or level values used during DPR entry.',
          targetKey: _floorKey,
          progressLabel: 'Floor',
        ),
        AppTourStep(
          id: 'dpr_add_screen',
          title: 'DPR Screen',
          body: 'Configure the DPR entry screen and its work values.',
          targetKey: _screenKey,
          progressLabel: 'DPR Screen',
        ),
      ],
    );
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
      if (tour == null || !tour.id.startsWith(SetupModuleTours.dprSetupId)) {
        if (_lastStep != null) _adapter.dismiss(showcaseContext);
        _lastStep = null;
        return;
      }
      final key = step == null ? null : '${tour.id}:${step.id}';
      if (step == null || key == _lastStep) return;
      _lastStep = key;
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
          appBar: CustomAppBar(title: 'Select DPR Values'),
          body: CornerClippedScreenSimple(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
              children: [
                _target(
                  _mocKey,
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.account_tree_rounded,
                      color: Colors.deepPurple,
                    ),
                    label: 'MOC',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddMOCPage()),
                    ),
                  ),
                ),
                _target(
                  _floorKey,
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.layers_rounded,
                      color: Colors.teal,
                    ),
                    label: 'Floor',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFloorPage()),
                    ),
                  ),
                ),
                _target(
                  _screenKey,
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.dashboard_customize_rounded,
                      color: Colors.indigo,
                    ),
                    label: 'DPR Screen',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PersistDPRScreen()),
                    ),
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
