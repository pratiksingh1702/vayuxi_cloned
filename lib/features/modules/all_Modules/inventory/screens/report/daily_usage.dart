import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';

import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../provider/inventory_provider.dart';
import '../edit_inventory.dart';
import 'package:file_picker/file_picker.dart';

class DailyUsagePage extends ConsumerStatefulWidget {
  const DailyUsagePage({super.key});

  @override
  ConsumerState<DailyUsagePage> createState() => _DailyUsagePageState();
}

class _DailyUsagePageState extends ConsumerState<DailyUsagePage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedStartDate = picked);
  }

  Future<void> _generateReport() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null || _selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a date")));
      return;
    }

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Permission required")));
      return;
    }

    try {
      final result = await ref.read(generateReportProvider(
        (siteId: siteId, from: _selectedStartDate!, to: _selectedEndDate!),
      ).future);

      final fileName =
          "daily_usage_${_selectedStartDate!.toString().split(' ')[0]}.xlsx";

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: "Save Inventory Usage Report",
        fileName: fileName,
        bytes: result,
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsBytes(result);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Report saved")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ---------------------- STORAGE PERMISSION ----------------------
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;

      PermissionStatus status;
      status = await Permission.manageExternalStorage.request();

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      }
      return false;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Storage permission is required to save files. Please allow it in settings."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

// ---------------------- GENERATE CSV ----------------------
  String _generateCSV(dynamic report) {
    // Your API probably returns List<Map>
    final buffer = StringBuffer();
    buffer.writeln("Item,Category,Subcategory,Quantity Used,UOM,Date,Used By");

    for (var r in report) {
      buffer.writeln(
          "${r['itemName']},${r['category']},${r['subcategory']},${r['quantityUsed']},${r['uom']},${r['date']},${r['usedBy']}"
      );
    }
    return buffer.toString();
  }

// ---------------------- SAVE CSV USING FILE PICKER ----------------------
  Future<void> _saveCSVFile(String fileName, String csvContent) async {
    final csvBytes = utf8.encode(csvContent);

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save Daily Usage Report",
      fileName: fileName,
      bytes: csvBytes,
      lockParentWindow: true,
    );

    if (savePath == null) {
      throw Exception("User cancelled save");
    }

    final file = File(savePath);
    await file.writeAsBytes(csvBytes);
  }


  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("No site selected")),
      );
    }

    final dailyUsageAsync =
    ref.watch(dailyUsageProvider((siteId: siteId, date: _selectedStartDate)));

    return Scaffold(
      appBar: CustomAppBar(title: "Daily Inventory Usage"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Download Report",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: _generateReport,
            ),
          ),
        ],
        child: Column(
          children: [
            // Optional date picker at top
        Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // START DATE FIELD
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedStartDate = picked);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedStartDate != null
                              ? "Start: ${_selectedStartDate!.toLocal().toString().split(' ')[0]}"
                              : "Start Date",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // END DATE FIELD
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedEndDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedEndDate = picked);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedEndDate != null
                              ? "End: ${_selectedEndDate!.toLocal().toString().split(' ')[0]}"
                              : "End Date",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),


            // List of usages
            Expanded(
              child: dailyUsageAsync.when(
                data: (usages) {
                  if (usages.isEmpty) {
                    return const Center(
                        child: Text("No usage records found."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: usages.length,
                    itemBuilder: (context, index) {
                      final usage = usages[index];
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(usage.displayItemName),
                          trailing: IconButton(
                              onPressed: () {
                                if (usage.inventory != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditInventoryScreen(
                                          inventory: usage.inventory!),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.edit_outlined)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Category: ${usage.displayCategoryName} | Subcategory: ${usage.displaySubcategoryName}"),
                              Text(
                                  "Quantity Used: ${usage.quantityUsed} ${usage.inventory?.uom ?? ''}"),
                              Text("Used By: ${usage.usedByName ?? 'Unknown'}"),
                              Text(
                                  "Date: ${usage.usageDate.toLocal().toString().split(' ')[0]}"),
                            ],
                          ),
                          onTap: () {
                            if (usage.inventory != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditInventoryScreen(
                                      inventory: usage.inventory!),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
