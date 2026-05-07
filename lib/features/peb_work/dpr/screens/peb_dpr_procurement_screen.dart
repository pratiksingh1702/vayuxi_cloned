import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'peb_dpr_widgets.dart';
import '../../../../core/utlis/widgets/custom_appBar.dart';

class PebDprProcurementScreen extends StatefulWidget {
  const PebDprProcurementScreen({super.key});

  @override
  State<PebDprProcurementScreen> createState() => _PebDprProcurementScreenState();
}

class _PebDprProcurementScreenState extends State<PebDprProcurementScreen> {
  final Map<String, bool> _procurementChecks = {
    'Material Requested': false,
    'RFQ Sent': false,
    'Quotation Received': false,
    'Vendor Finalized': false,
    'PO Created': false,
    'Advance Paid': false,
    'Dispatch Started': false,
    'Material Received': false,
    'QC Checked': false,
    'Closed': false,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'Procurement',
        showDrawer: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const PebSectionHeader(
            title: 'Procurement Tracking',
            subtitle: 'Manage material requests, vendor communications, and delivery schedules.',
            icon: LucideIcons.truck,
          ),
          const SizedBox(height: 24),
          PebChecklistSection(
            title: 'Supply Chain Status',
            checks: _procurementChecks,
            onChanged: (key, value) => setState(() {
              _procurementChecks[key] = value;
            }),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

