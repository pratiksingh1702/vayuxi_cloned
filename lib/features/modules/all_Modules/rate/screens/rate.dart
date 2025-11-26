import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/features/auth/service/auth_client.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../data/rate_provider.dart';
import '../domain/rateModel.dart';
import 'addRate.dart';
import 'editRate.dart';
import 'import_sheet.dart';
class RateScreen extends ConsumerStatefulWidget {
  final SiteModel site;

  const RateScreen({super.key, required this.site});

  @override
  ConsumerState<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends ConsumerState<RateScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch rates when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {

      final type = ref.read(typeProvider);
      if (type != null) {
        ref.read(rateNotifierProvider.notifier).fetchRate(type, widget.site.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rateNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Rates",
      ),
      body: Column(
        children: [
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text('Error: ${state.error}'))
                : state.data == null || state.data!.isEmpty
                ? const Center(child: Text('No rates available'))
                : ListView.builder(
              itemCount: state.data!.length,
              itemBuilder: (context, index) {
                final rate = state.data![index];
                return rateTile(context, rate, widget.site, ref);
              },
            ),
          ),
        ],
      ),
      // Floating Action Button for refresh
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bottomButton(
              icon: Icons.download,
              label: "Save CSV",
              onTap: () {
                final type = ref.read(typeProvider);
                if (type != null) {
                  saveCsvWithDialog(context, type, widget.site.id);
                }
              },
            ),
            _bottomButton(
              icon: Icons.upload,
              label: "Import CSV",
              onTap: () {
                final type = ref.read(typeProvider);
                if (type != null) {
                  Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => ImportCsvScreen(site: widget.site, type: type),
                    ),
                  );
                }
              },
            ),
            _bottomButton(
              icon: Icons.add,
              label: "Add Rate",
              onTap: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => AddRateScreen(site: widget.site),
                  ),
                );
              },
            ),
          ],
        ),
      ),

    );
  }
  Widget _bottomButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _showCsvOptionsBottomSheet(BuildContext context, WidgetRef ref) {
    final type = ref.read(typeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'CSV Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Save CSV Button
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Save CSV'),
              subtitle: const Text('Download current rates as CSV file'),
              onTap: () {
                Navigator.pop(context);
                if (type != null) {
                  saveCsvWithDialog(context, type, widget.site.id);
                }
              },
            ),

            // Import CSV Button
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.green),
              title: const Text('Import CSV'),
              subtitle: const Text('Upload CSV file to update rates'),
              onTap: () {
                Navigator.pop(context);
                if (type != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImportCsvScreen(site: widget.site, type: type),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.green),
              title: const Text('Add Rate'),
              subtitle: const Text('Add any new product and service'),
              onTap: () {
                Navigator.pop(context);
                if (type != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRateScreen(site: widget.site)),
                  );
                }
              },
            ),

            const SizedBox(height: 8),

            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveCsvWithDialog(BuildContext context, String type, String siteId) async {
    final result = await RateApiClient().getCsv(type, siteId);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating CSV: ${result['error']}')),
      );
      return;
    }

    try {
      String? path;

      if (Platform.isAndroid || Platform.isIOS) {
        // Convert CSV string to bytes for mobile
        final bytes = utf8.encode(result['data'].toString());

        path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV file',
          fileName: 'rates_$siteId.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: bytes,
        );
      } else {
        // On desktop, use file_selector or path_provider
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/rates_$siteId.csv';

        final file = File(path);
        await file.writeAsString(result['data'].toString());
      }

      if (path == null) return; // user canceled

      // For mobile, the file is already saved by FilePicker, so no need to write again
      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(path);
        await file.writeAsString(result['data'].toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV saved at $path')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CSV: $e')),
      );
    }
  }
}

Widget rateTile(BuildContext context, Rate rate, SiteModel site, WidgetRef ref) {
  final type = ref.read(typeProvider);
  final notifier = ref.read(rateNotifierProvider.notifier);

  return Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Service name (multi-line)
          Expanded(
            child: Container(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rate.serviceName,
                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    rate.site.siteName,
                    maxLines: 1,


                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Right side: Rate with UOM and edit button
          Column(
            children: [

              // Edit icon
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditRateScreen(site: site, rate: rate),
                    ),
                  );
                  // Refresh if updated
                  if (result == true && type != null) {
                    notifier.fetchRate(type, site.id);
                  }
                },
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              // Rate in rounded box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${rate.rate.toStringAsFixed(0)} / ${rate.uom}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}