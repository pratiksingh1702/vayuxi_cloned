import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart';

class StructureSheetDownloadPage extends ConsumerWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  const StructureSheetDownloadPage({
    super.key,
    this.selectedStartDate,
    this.selectedEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetDownloadPage(
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
    );
  }
}
