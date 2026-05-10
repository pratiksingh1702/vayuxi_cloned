import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class DprEntryScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String title;
  const DprEntryScreen({super.key, required this.siteId, required this.title});

  @override
  ConsumerState<DprEntryScreen> createState() => _DprEntryScreenState();
}

class _DprEntryScreenState extends ConsumerState<DprEntryScreen> {
  // Mock items - in real app these come from DprSetup
  final List<Map<String, dynamic>> _items = [
    {'id': '1', 'name': 'Excavation', 'unit': 'CUM', 'total': 500.0, 'completed': 120.0},
    {'id': '2', 'name': 'PCC Work', 'unit': 'SQM', 'total': 250.0, 'completed': 45.0},
    {'id': '3', 'name': 'Reinforcement', 'unit': 'MT', 'total': 15.0, 'completed': 2.5},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: widget.title),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => _DprItemCard(
          item: _items[index],
          onUpdate: (qty) {
            // Update logic here
          },
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(cs),
    );
  }

  Widget _buildSubmitBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('SUBMIT DAILY PROGRESS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DprItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(double) onUpdate;
  const _DprItemCard({required this.item, required this.onUpdate});

  @override
  State<_DprItemCard> createState() => _DprItemCardState();
}

class _DprItemCardState extends State<_DprItemCard> {
  final _qtyController = TextEditingController();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = widget.item['completed'] / widget.item['total'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            title: Text(widget.item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item['completed']} / ${widget.item['total']} ${widget.item['unit']} completed',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ],
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Today\'s Quantity',
                            hintText: 'Enter qty in ${widget.item['unit']}',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.add_a_photo_rounded),
                        tooltip: 'Add Photos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Remarks / Hurdles',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
