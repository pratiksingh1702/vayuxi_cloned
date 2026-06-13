// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/ManFieldMappingScreen.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import '../../../../tour/definitions/manpower_team_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../../dpr/screens/widgets/select_card.dart';
import 'addManpower.dart';

class ManEntrySelectCardGrid extends ConsumerStatefulWidget {
  const ManEntrySelectCardGrid({super.key});

  @override
  ConsumerState<ManEntrySelectCardGrid> createState() =>
      _ManEntrySelectCardGridState();
}

class _ManEntrySelectCardGridState
    extends ConsumerState<ManEntrySelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _manualTourKey =
      GlobalKey(debugLabel: 'manpower_entry_manual');
  final GlobalKey _importTourKey =
      GlobalKey(debugLabel: 'manpower_entry_import');

  void _syncEntryTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${ManpowerTeamModuleTours.manpowerId}_entry_method',
      title: 'Add Manpower',
      description: 'Choose how to add manpower.',
      icon: Icons.badge_rounded,
      steps: [
        const AppTourStep(
          id: 'manpower_entry_intro',
          title: 'Add Manpower',
          body: 'Choose manual entry for one worker or import a sheet for many workers.',
          progressLabel: 'Entry method',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'manpower_entry_manual',
          title: 'Manual Entry',
          body: 'Use this when you want to enter one worker step by step.',
          targetKey: _manualTourKey,
          progressLabel: 'Manual',
        ),
        AppTourStep(
          id: 'manpower_entry_import',
          title: 'Import Sheet',
          body: 'Use this when you want to upload a sheet and map its fields.',
          targetKey: _importTourKey,
          progressLabel: 'Import',
        ),
      ],
    );
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
      if (activeTour == null ||
          !activeTour.id.startsWith(ManpowerTeamModuleTours.manpowerId)) {
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
        _syncEntryTour(showcaseContext);
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Select Manpower Entry"),
      body: BottomButtonWrapper(
        onBackPressed: () {
          Navigator.pop(context);
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
                    _manualTourKey,
                    SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                    ),
                    label: "Manual Entry",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NewManpowerScreen()),
                      );
                    },
                    ),
                  ),
                  _tourTarget(
                    _importTourKey,
                    SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.upload_file_rounded,
                      color: Colors.deepOrange,
                    ),
                    label: "Import Sheet",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ManFieldMappingScreen()),
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
                    "Choose the entry method",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Manual Entry: Enter site details step-by-step manually.\n"
                    "• Import Sheet: Upload an Excel/CSV sheet — our AI will analyze your file and map fields automatically.",
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
