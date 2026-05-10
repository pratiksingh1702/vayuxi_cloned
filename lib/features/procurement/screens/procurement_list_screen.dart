import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../models/procurement_model.dart';

class ProcurementListScreen extends StatelessWidget {
  final String siteId;
  const ProcurementListScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final requests = [
      ProcurementRequest(
        id: 'PR1',
        requestNumber: 'PR/2026/001',
        workType: 'civil',
        priority: 'high',
        expectedDeliveryDate: '2026-05-15',
        remarks: 'Urgent cement requirement',
        items: [],
        siteId: siteId,
        description: 'OPC 43 Grade Cement',
        quantity: 500,
        unit: 'Bags',
        status: ProcurementStatus.pending,
        requestedBy: 'Site Engineer Rahul',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ProcurementRequest(
        id: 'PR2',
        requestNumber: 'PR/2026/002',
        workType: 'peb',
        priority: 'medium',
        expectedDeliveryDate: '2026-05-20',
        remarks: 'For roofing work',
        items: [],
        siteId: siteId,
        description: 'TMT Steel Bars 12mm',
        quantity: 5,
        unit: 'MT',
        status: ProcurementStatus.ordered,
        requestedBy: 'Manager Amit',
        requestedAt: DateTime.now().subtract(const Duration(days: 4)),
        expectedDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Procurement Requests'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _RequestCard(request: request);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Request Material'),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ProcurementRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(request.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Qty: ${request.quantity} ${request.unit}'),
            Text('By: ${request.requestedBy}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(request.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.status.displayName,
            style: TextStyle(color: _getStatusColor(request.status), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProcurementStatus status) {
    switch (status) {
      case ProcurementStatus.pending: return Colors.orange;
      case ProcurementStatus.approved: return Colors.blue;
      case ProcurementStatus.ordered: return Colors.purple;
      case ProcurementStatus.received: return Colors.green;
      case ProcurementStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }
}
