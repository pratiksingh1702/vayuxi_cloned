import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class InventoryManagementScreen extends ConsumerStatefulWidget {
  final String siteId;
  const InventoryManagementScreen({super.key, required this.siteId});

  @override
  ConsumerState<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends ConsumerState<InventoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'INVENTORY MANAGEMENT'),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: cs.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: cs.primary,
            tabs: const [
              Tab(text: 'Current Stock'),
              Tab(text: 'Inward'),
              Tab(text: 'Consumption'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStockTab(cs),
                _buildInwardTab(cs),
                _buildConsumptionTab(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab(ColorScheme cs) {
    final stocks = [
      {'item': 'Cement', 'qty': 450, 'unit': 'Bags', 'min': 100},
      {'item': 'Sand', 'qty': 12, 'unit': 'Brass', 'min': 5},
      {'item': 'Steel TMT', 'qty': 4.5, 'unit': 'MT', 'min': 2},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final item = stocks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Min Stock Level: ${item['min']} ${item['unit']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item['qty']} ${item['unit']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
                const Text('Available', style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInwardTab(ColorScheme cs) {
    return _EmptyState(icon: Icons.add_business_rounded, message: 'No inward records for this month');
  }

  Widget _buildConsumptionTab(ColorScheme cs) {
    return _EmptyState(icon: Icons.outbox_rounded, message: 'No consumption logged today');
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
