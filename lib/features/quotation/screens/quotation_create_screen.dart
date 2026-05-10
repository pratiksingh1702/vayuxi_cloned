import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../models/quotation_model.dart';
import '../providers/quotation_provider.dart';

class QuotationCreateScreen extends ConsumerStatefulWidget {
  const QuotationCreateScreen({super.key});

  @override
  ConsumerState<QuotationCreateScreen> createState() => _QuotationCreateScreenState();
}

class _QuotationCreateScreenState extends ConsumerState<QuotationCreateScreen> {
  final List<QuotationItem> _items = [];
  final _projectNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  double _marginPercent = 15.0;
  double _taxPercent = 18.0;

  @override
  void dispose() {
    _projectNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _marginAmount => _subtotal * (_marginPercent / 100);
  double get _taxableAmount => _subtotal + _marginAmount;
  double get _taxAmount => _taxableAmount * (_taxPercent / 100);
  double get _total => _taxableAmount + _taxAmount;

  void _addItem() {
    setState(() {
      _items.add(QuotationItem(
        description: 'New Item',
        quantity: 1,
        unit: 'MT',
        rate: 50000,
        amount: 50000,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Quotation'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectDetails(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            ..._items.asMap().entries.map((entry) => _buildItemTile(entry.key, entry.value)),
            const Divider(height: 48),
            _buildCalculationSection(colorScheme),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save logic
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('GENERATE QUOTATION', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Column(
      children: [
        TextField(
          controller: _projectNameController,
          decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _companyNameController,
          decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildItemTile(int index, QuotationItem item) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        title: Text(item.description),
        subtitle: Text('${item.quantity} ${item.unit} @ ₹${item.rate}'),
        trailing: Text('₹${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        onLongPress: () => setState(() => _items.removeAt(index)),
      ),
    );
  }

  Widget _buildCalculationSection(ColorScheme cs) {
    return Column(
      children: [
        _calcRow('Subtotal', _subtotal),
        _calcRow('Margin ($_marginPercent%)', _marginAmount),
        _calcRow('GST ($_taxPercent%)', _taxAmount),
        const Divider(),
        _calcRow('Total Amount', _total, isBold: true, color: cs.primary),
      ],
    );
  }

  Widget _calcRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
