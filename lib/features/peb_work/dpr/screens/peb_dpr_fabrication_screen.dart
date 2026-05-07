import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'peb_dpr_widgets.dart';
import '../../../../core/utlis/widgets/custom_appBar.dart';

class PebDprFabricationScreen extends StatefulWidget {
  const PebDprFabricationScreen({super.key});

  @override
  State<PebDprFabricationScreen> createState() => _PebDprFabricationScreenState();
}

class _PebDprFabricationScreenState extends State<PebDprFabricationScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      'Unloading',
      'Shifting',
      'Cutting',
      'Chamfering',
      'Fitup',
      'Saw',
      'Grinding',
      'Weld visual',
      'Loading',
      'Dispatch',
    ];

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'Fabrication',
        showDrawer: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const PebSectionHeader(
            title: 'Fabrication Flow',
            subtitle: 'Track production milestones and daily quantities for structural components.',
            icon: LucideIcons.factory,
          ),
          const SizedBox(height: 24),
          ...steps.map((step) => PebFabricationStepCard(
                title: step,
                hasDistance: step == 'Shifting',
                onCopy: () {},
                onEdit: () {},
                onDelete: () {},
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

