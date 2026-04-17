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

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';

class SiteEntrySelectCardGrid extends ConsumerWidget {
  const SiteEntrySelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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

                      // ---------------- Import Sheet ----------------
                      Showcase(
                        key: SiteRegistry.importSheetCardKey,
                        description: 'Tap Import Sheet for guided upload.',
                        child: SelectCard(
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
