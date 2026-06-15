// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/site_rate_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import 'package:untitled2/features/tour/widgets/no_cutout_tour_target.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../dpr/screens/widgets/select_card.dart';
import 'addRate.dart';
import 'import_sheet.dart';

class RateEntrySelectCardGrid extends ConsumerStatefulWidget {
  const RateEntrySelectCardGrid({super.key});

  @override
  ConsumerState<RateEntrySelectCardGrid> createState() =>
      _RateEntrySelectCardGridState();
}

class _RateEntrySelectCardGridState
    extends ConsumerState<RateEntrySelectCardGrid>
    with ScreenOwnedTourMixin<RateEntrySelectCardGrid> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _manualTourKey =
      GlobalKey(debugLabel: 'rate_entry_manual');
  final GlobalKey _importTourKey =
      GlobalKey(debugLabel: 'rate_entry_import');

  void _syncRateEntryTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.rateId}_entry_method',
      title: 'Add Rate',
      description: 'Choose how to add rate details.',
      icon: Icons.add_card_rounded,
      steps: [
        const AppTourStep(
          id: 'rate_entry_intro',
          title: 'Add Rate',
          body: 'Choose whether to type one rate or upload many rates from a sheet.',
          progressLabel: 'Entry method',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'rate_entry_manual',
          title: 'Manual Entry',
          body: 'Use this to add one product, service, or work rate manually.',
          targetKey: _manualTourKey,
          progressLabel: 'Manual',
        ),
        AppTourStep(
          id: 'rate_entry_import',
          title: 'Import Sheet',
          body: 'Use this to upload many rates at once from a file.',
          targetKey: _importTourKey,
          progressLabel: 'Import',
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
    final siteId = ref.watch(selectedSiteIdProvider);
    final type = ref.watch(typeProvider);
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncRateEntryTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(title: "Select Rate Entry"),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRateScreen(
                              initialSiteId: siteId,
                              initialType: type,
                            ),
                          ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImportCsvScreen()),
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
