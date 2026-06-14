import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

import 'boq_import_sheet.dart';
import 'boq_item_details.dart';

class BoqEntrySelectScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const BoqEntrySelectScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<BoqEntrySelectScreen> createState() =>
      _BoqEntrySelectScreenState();
}

class _BoqEntrySelectScreenState extends ConsumerState<BoqEntrySelectScreen> with ScreenOwnedTourMixin<BoqEntrySelectScreen> {
  static const _adapter = TourPackageAdapter();
  final _manualKey = GlobalKey(debugLabel: 'boq_manual_entry');
  final _importKey = GlobalKey(debugLabel: 'boq_import_sheet');
  String? _lastStep;

  void _syncTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}_entry_method',
      title: 'Add BOQ',
      description: 'Choose how to add BOQ data.',
      icon: Icons.playlist_add_rounded,
      steps: [
        AppTourStep(
          id: 'boq_manual_entry',
          title: 'Manual Entry',
          body: 'Use this when you want to create BOQ marks one by one.',
          targetKey: _manualKey,
          progressLabel: 'Manual',
        ),
        AppTourStep(
          id: 'boq_import_sheet',
          title: 'Import Sheet',
          body: 'Use this to upload many BOQ items from an Excel sheet.',
          targetKey: _importKey,
          progressLabel: 'Excel',
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
          policyTourId: SetupModuleTours.boqUploadId,
        );
      }
      final tour = controller.activeTour;
      final step = controller.currentStep;
      if (tour == null || tour.id != definition.id) {
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
    final cs = Theme.of(context).colorScheme;
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: cs.surfaceContainerLowest,
          appBar: CustomAppBar(title: 'Select Entry Method'),
          body: BottomButtonWrapper(
            onBackPressed: () => Navigator.pop(context),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                _target(
                  _manualKey,
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                    ),
                    label: 'Manual Entry',
                    onTap: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BoqItemDetailsScreen(
                            siteId: widget.siteId,
                            siteName: widget.siteName,
                            item: null,
                          ),
                        ),
                      );
                      if (saved == true && mounted) Navigator.pop(context, true);
                    },
                  ),
                ),
                _target(
                  _importKey,
                  SelectCard(
                    icon: const SelectCardIcon(
                      icon: Icons.upload_file_rounded,
                      color: Colors.deepOrange,
                    ),
                    label: 'Import Sheet',
                    onTap: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BoqImportSheetScreen(
                            siteId: widget.siteId,
                            siteName: widget.siteName,
                          ),
                        ),
                      );
                      if (saved == true && mounted) Navigator.pop(context, true);
                    },
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
