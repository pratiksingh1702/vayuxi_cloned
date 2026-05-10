import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../providers/crm_provider.dart';
import '../models/crm_model.dart';

class CrmLeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const CrmLeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crmProvider);
    final lead = state.leads.firstWhere((l) => l.id == leadId,
        orElse: () => throw 'Lead not found');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lead Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, lead),
            _buildActionButtons(context, lead),
            _buildInfoSection(context, lead),
            _buildActivityTimeline(context, ref, lead),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CrmLead lead) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primary,
            child: Text(
              lead.customerName[0].toUpperCase(),
              style: TextStyle(
                  fontSize: 32,
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lead.customerName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            lead.companyName,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CrmLead lead) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            onTap: () => context.push(Routes.coldCall, extra: lead),
          ),
          _ActionButton(
            icon: Icons.description_rounded,
            label: 'Quotation',
            onTap: () =>
                context.push(Routes.quotationCreate, extra: {'lead': lead}),
          ),
          _ActionButton(
            icon: Icons.mail_rounded,
            label: 'Email',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, CrmLead lead) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _InfoTile(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: lead.phoneNumber),
          _InfoTile(
              icon: Icons.email_rounded, label: 'Email', value: lead.email),
          _InfoTile(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: lead.address),
          const SizedBox(height: 24),
          const Text('Project Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _InfoTile(
              icon: Icons.category_rounded,
              label: 'Type',
              value: lead.projectType),
          _InfoTile(
              icon: Icons.notes_rounded, label: 'Notes', value: lead.notes),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(
      BuildContext context, WidgetRef ref, CrmLead lead) {
    // In a real app, this would be fetched from a provider
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('Add Note')),
            ],
          ),
          const SizedBox(height: 8),
          const _TimelineItem(
            title: 'Initial Discovery Call',
            subtitle: 'Completed - 3m 20s',
            date: 'May 10, 2024',
            icon: Icons.call_rounded,
            color: Colors.green,
          ),
          const _TimelineItem(
            title: 'Follow-up Scheduled',
            subtitle: 'Pending - Tomorrow at 10 AM',
            date: 'May 12, 2024',
            icon: Icons.event_rounded,
            color: Colors.orange,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text(date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cold Call Screen ────────────────────────────────────────────────────────
class ColdCallScreen extends StatefulWidget {
  final CrmLead lead;
  const ColdCallScreen({super.key, required this.lead});

  @override
  State<ColdCallScreen> createState() => _ColdCallScreenState();
}

class _ColdCallScreenState extends State<ColdCallScreen> {
  late Timer _timer;
  int _seconds = 0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'On Call: ${widget.lead.customerName}'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(
                  fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const Text('DURATION',
                style: TextStyle(color: Colors.grey, letterSpacing: 1.5)),
            const Spacer(),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter call notes here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Save logic here
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SAVE & END'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
