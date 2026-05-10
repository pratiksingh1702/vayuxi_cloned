import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class DispatchListScreen extends StatelessWidget {
  const DispatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dispatchItems = [
      {
        'title': 'Dispatch #DSP-1042',
        'subtitle': 'Site A • 24 MT steel sections',
        'status': 'In Transit',
      },
      {
        'title': 'Dispatch #DSP-1043',
        'subtitle': 'Site B • Fasteners and anchor bolts',
        'status': 'Ready for Loading',
      },
      {
        'title': 'Dispatch #DSP-1044',
        'subtitle': 'Site C • Roofing sheets',
        'status': 'Delivered',
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'DISPATCH TRACKING'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dispatchItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = dispatchItems[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.local_shipping_rounded, color: cs.primary),
              title: Text(
                item['title']!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item['subtitle']!),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item['status']!,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HandoverChecklistScreen extends StatefulWidget {
  const HandoverChecklistScreen({super.key});

  @override
  State<HandoverChecklistScreen> createState() => _HandoverChecklistScreenState();
}

class _HandoverChecklistScreenState extends State<HandoverChecklistScreen> {
  final List<Map<String, dynamic>> _checks = [
    {'title': 'Structural Integrity Verified', 'done': true},
    {'title': 'Leakage Test Completed', 'done': false},
    {'title': 'Safety Signage Installed', 'done': true},
    {'title': 'Site Cleanup Done', 'done': false},
    {'title': 'Electrical Systems Tested', 'done': false},
  ];

  final List<String> _pendingWork = [
    'Touch-up painting in Section B',
    'Loose bolt tightening in Rafter 4',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'FINAL HANDOVER'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(cs, 'Completion Checklist', Icons.fact_check_rounded),
            const SizedBox(height: 12),
            _buildChecklist(cs),
            const SizedBox(height: 32),
            _buildSectionHeader(cs, 'Pending Work / Snag List', Icons.assignment_late_rounded),
            const SizedBox(height: 12),
            _buildPendingList(cs),
            const SizedBox(height: 32),
            _buildSectionHeader(cs, 'Client Approval (Digital Signature)', Icons.draw_rounded),
            const SizedBox(height: 12),
            _buildSignatureBox(cs),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(cs),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChecklist(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _checks.map((check) => CheckboxListTile(
          title: Text(check['title'], style: const TextStyle(fontSize: 14)),
          value: check['done'],
          onChanged: (val) => setState(() => check['done'] = val),
          controlAffinity: ListTileControlAffinity.leading,
        )).toList(),
      ),
    );
  }

  Widget _buildPendingList(ColorScheme cs) {
    return Column(
      children: _pendingWork.map((work) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.red.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.withOpacity(0.2)),
        ),
        child: ListTile(
          title: Text(work, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
        ),
      )).toList(),
    );
  }

  Widget _buildSignatureBox(ColorScheme cs) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text('Sign here for Client Approval', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('SUBMIT FINAL HANDOVER', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
