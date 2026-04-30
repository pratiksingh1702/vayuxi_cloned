// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../../../../core/utlis/widgets/date_picker_Screen.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr/screens/widgets/select_card.dart';
import 'download_sheet.dart';
import 'expense_screen.dart';

class ExpenseEntrySelectCardGrid extends ConsumerWidget {
  const ExpenseEntrySelectCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.read(selectedSiteIdProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: "Select Card"),
      body: BottomButtonWrapper(
        onBackPressed: () {
          context.pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              SelectCard(
                icon: Icon(
                  Icons.download_for_offline_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                label: "Download Sheet",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DateRangeSelectionScreen(
                              onDatesSelected:
                                  (DateTime startDate, DateTime endDate) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ExpenseReportScreen(
                                          siteId: site!,
                                          selectedStartDate: startDate,
                                          selectedEndDate: endDate)),
                                );
                              },
                            )),
                  );
                },
              ),
              SelectCard(
                icon: Icon(
                  Icons.visibility_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                label: "View",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExpenseListScreen(
                              siteId: site!,
                            )),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
