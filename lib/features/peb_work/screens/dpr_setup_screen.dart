import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../typeProvider/work_type.dart';
import '../../../typeProvider/type_provider.dart';

class DprSetupScreen extends ConsumerStatefulWidget {
  final String siteId;
  const DprSetupScreen({super.key, required this.siteId});

  @override
  ConsumerState<DprSetupScreen> createState() => _DprSetupScreenState();
}

class _DprSetupScreenState extends ConsumerState<DprSetupScreen> {
  final List<Map<String, dynamic>> _activities = [];
  final _itemController = TextEditingController();
  final _unitController = TextEditingController();
  final _targetController = TextEditingController();

  void _addActivity() {
    if (_itemController.text.isEmpty) return;
    setState(() {
      _activities.add({
        'item': _itemController.text,
        'unit': _unitController.text,
        'target': _targetController.text,
      });
      _itemController.clear();
      _unitController.clear();
      _targetController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workType = ref.watch(typeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${workType?.replaceAll('_', ' ').toUpperCase() ?? 'WORK'} SETUP',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 24),
            _buildInputSection(colorScheme),
            const SizedBox(height: 32),
            const Text(
              'Configured Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _activities.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) => _ActivityCard(
                    activity: _activities[index],
                    onDelete: () => setState(() => _activities.removeAt(index)),
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colorScheme),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_suggest_rounded, color: cs.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Define the activities and target quantities for this site to enable daily progress reporting.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ColorScheme cs) {
    return Column(
      children: [
        _TextField(controller: _itemController, label: 'Work Item / Activity Name', icon: Icons.work_outline),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _TextField(controller: _unitController, label: 'Unit (e.g. SQM)', icon: Icons.straighten)),
            const SizedBox(width: 16),
            Expanded(child: _TextField(controller: _targetController, label: 'Target Qty', icon: Icons.track_changes, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addActivity,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('ADD TO SETUP'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No activities configured yet', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _activities.isEmpty ? null : () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('SAVE SITE CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onDelete;
  const _ActivityCard({required this.activity, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(activity['item'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Target: ${activity['target']} ${activity['unit']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
