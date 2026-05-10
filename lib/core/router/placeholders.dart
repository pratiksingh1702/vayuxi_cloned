import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              '$title entry coming soon',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We are building this feature for you.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Specific Placeholders
class CivilDprPlaceholder extends StatelessWidget {
  const CivilDprPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(title: 'Civil DPR');
}

class ErectionDprPlaceholder extends StatelessWidget {
  const ErectionDprPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(title: 'Erection DPR');
}

class RoofingDprPlaceholder extends StatelessWidget {
  const RoofingDprPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(title: 'Roofing DPR');
}

class FabricationDprPlaceholder extends StatelessWidget {
  const FabricationDprPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(title: 'Fabrication DPR');
}

class ReportPlaceholder extends StatelessWidget {
  final String reportName;
  const ReportPlaceholder({super.key, required this.reportName});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: '$reportName Report');
}
