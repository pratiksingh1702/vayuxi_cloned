import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_entry_select.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/screens/boq_item_list.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

class ViewAddBoqScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const ViewAddBoqScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<ViewAddBoqScreen> createState() => _ViewAddBoqScreenState();
}

class _ViewAddBoqScreenState extends ConsumerState<ViewAddBoqScreen> with ScreenOwnedTourMixin<ViewAddBoqScreen> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final GlobalKey _viewTourKey = GlobalKey(debugLabel: 'boq_upload_view');
  final GlobalKey _addTourKey = GlobalKey(debugLabel: 'boq_upload_add');
  String? _lastShowcasedTourStepId;

  void _syncBoqUploadTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}',
      title: 'BOQ Upload',
      description: 'View BOQ items or add new BOQ data.',
      icon: Icons.table_rows_rounded,
      steps: [
        const AppTourStep(
          id: 'boq_upload_intro',
          title: 'BOQ Upload',
          body:
              'Use BOQ to keep project quantities ready for structure, fabrication, civil, or roofing work.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'boq_upload_view',
          title: 'View BOQ',
          body: 'Open this to view existing BOQ items and edit them if needed.',
          targetKey: _viewTourKey,
          progressLabel: 'View',
        ),
        AppTourStep(
          id: 'boq_upload_add',
          title: 'Add or Upload BOQ',
          body:
              'Open this to add BOQ items manually or import them from an Excel sheet.',
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
          policyTourId: SetupModuleTours.boqUploadId,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncBoqUploadTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(title: 'Select BOQ Option'),
          body: BottomButtonWrapper(
            onBackPressed: () {
              context.pop();
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      _tourTarget(
                        _viewTourKey,
                        SelectCard(
                          icon: const SelectCardIcon(
                            icon: Icons.visibility_rounded,
                            color: Colors.blue,
                          ),
                          label: 'View',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BoqItemListScreen(
                                  siteId: widget.siteId,
                                  siteName: widget.siteName,
                                ),
                              ),
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
                          label: 'Add',
                          onTap: () async {
                            final saved = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BoqEntrySelectScreen(
                                  siteId: widget.siteId,
                                  siteName: widget.siteName,
                                ),
                              ),
                            );
                            if (saved == true && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BoqItemListScreen(
                                    siteId: widget.siteId,
                                    siteName: widget.siteName,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? colorScheme.shadow.withValues(alpha: 0.12)
                            : colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose an option',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View: You can view your BOQ items and also edit them.\n'
                        'Add: You can create and register new BOQ items manually or import an Excel sheet.',
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
