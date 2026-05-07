import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'peb_dpr_widgets.dart';
import '../../../../core/utlis/widgets/custom_appBar.dart';

class PebDprGaScreen extends StatefulWidget {
  const PebDprGaScreen({super.key});

  @override
  State<PebDprGaScreen> createState() => _PebDprGaScreenState();
}

class _PebDprGaScreenState extends State<PebDprGaScreen> {
  final Map<String, bool> _gaDrawingChecks = {
    'Drawing Started': false,
    'Drawing Completed': false,
    'Internal Review Done': false,
    'Sent To Client': false,
    'Client Reviewed': false,
    'Revision Required': false,
    'Revised Drawing Submitted': false,
    'Final Approved': false,
    'IFC Released': false,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'GA Drawing',
        showDrawer: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const PebSectionHeader(
            title: 'GA Drawing Status',
            subtitle: 'Monitor and update the progress of General Arrangement drawings and client approvals.',
            icon: LucideIcons.fileText,
          ),
          const SizedBox(height: 24),
          PebChecklistSection(
            title: 'Approvals Checklist',
            checks: _gaDrawingChecks,
            onChanged: (key, value) => setState(() {
              _gaDrawingChecks[key] = value;
            }),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

