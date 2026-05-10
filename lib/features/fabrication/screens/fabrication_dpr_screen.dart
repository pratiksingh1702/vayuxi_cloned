import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../boq_common/models/boq_model.dart';
import '../models/fabrication_model.dart';

class FabricationDprScreen extends ConsumerWidget {
  final String siteId;
  const FabricationDprScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock BOQ items for fabrication
    final boqItems = [
      CommonBoqItem(id: 'B1', siteId: siteId, description: 'Column C1-C10', totalQuantity: 10, unit: 'Nos', category: 'Fabrication'),
      CommonBoqItem(id: 'B2', siteId: siteId, description: 'Main Rafter R1', totalQuantity: 15, unit: 'Nos', category: 'Fabrication'),
      CommonBoqItem(id: 'B3', siteId: siteId, description: 'Purlins P1-P50', totalQuantity: 50, unit: 'Nos', category: 'Fabrication'),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Fabrication DPR'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: boqItems.length,
        itemBuilder: (context, index) {
          final item = boqItems[index];
          return _BoqItemCard(item: item);
        },
      ),
    );
  }
}

class _BoqItemCard extends StatelessWidget {
  final CommonBoqItem item;
  const _BoqItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FabricationStepperScreen(boqItem: item)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: ${item.totalQuantity} ${item.unit}', style: TextStyle(color: colorScheme.primary)),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: 0.4, borderRadius: BorderRadius.all(Radius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fabrication Stepper Screen ───────────────────────────────────────────────
class FabricationStepperScreen extends StatefulWidget {
  final CommonBoqItem boqItem;
  const FabricationStepperScreen({super.key, required this.boqItem});

  @override
  State<FabricationStepperScreen> createState() => _FabricationStepperScreenState();
}

class _FabricationStepperScreenState extends State<FabricationStepperScreen> {
  int _currentStageIndex = 1; // Start at Dispatch (Index 1)
  final _assemblyMarkController = TextEditingController();
  final Map<FabStage, double> _quantities = {
    FabStage.boq: 10.0,
    FabStage.dispatch: 0.0,
    FabStage.unload: 0.0,
    FabStage.shift: 0.0,
    FabStage.erect: 0.0,
    FabStage.align: 0.0,
    FabStage.inspect: 0.0,
  };

  @override
  void dispose() {
    _assemblyMarkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _quantities[FabStage.boq] = widget.boqItem.totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentStage = FabStage.values[_currentStageIndex];

    return Scaffold(
      appBar: CustomAppBar(title: 'Update Progress: ${widget.boqItem.description}'),
      body: Column(
        children: [
          _buildStageIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentStage.displayName.toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update quantity for this stage',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 48),
                  _buildQuantityInput(colorScheme, currentStage),
                  const SizedBox(height: 24),
                  _buildAssemblyMarkInput(colorScheme),
                  const SizedBox(height: 48),
                  _buildValidationMessage(currentStage),
                ],
              ),
            ),
          ),
          _buildBottomNav(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      color: Colors.blue.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: FabStage.values.map((stage) {
          final isCompleted = stage.index < _currentStageIndex;
          final isCurrent = stage.index == _currentStageIndex;
          return Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isCurrent ? Colors.blue : (isCompleted ? Colors.green : Colors.grey.shade300),
                child: isCompleted 
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('${stage.index + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text(stage.displayName, style: TextStyle(fontSize: 8, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuantityInput(ColorScheme cs, FabStage stage) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: () => _updateQty(-1), icon: const Icon(Icons.remove)),
          Expanded(
            child: Text(
              '${_quantities[stage]}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(onPressed: () => _updateQty(1), icon: const Icon(Icons.add)),
        ],
      ),
    );
  }

  void _updateQty(double delta) {
    final stage = FabStage.values[_currentStageIndex];
    setState(() {
      _quantities[stage] = (_quantities[stage]! + delta).clamp(0, _quantities[stage.previous]!);
    });
  }


  Widget _buildAssemblyMarkInput(ColorScheme cs) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _assemblyMarkController,
        decoration: InputDecoration(
          labelText: 'Assembly Mark',
          hintText: 'Enter Mark (e.g. C1, R1)',
          prefixIcon: const Icon(Icons.tag_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildValidationMessage(FabStage stage) {
    final prevStage = stage.previous;
    return Text(
      'Maximum allowed: ${_quantities[prevStage]} ${widget.boqItem.unit} (from ${prevStage.displayName})',
      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
    );
  }

  Widget _buildBottomNav(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStageIndex > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStageIndex--),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('PREVIOUS'),
              ),
            ),
          if (_currentStageIndex > 1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStageIndex < FabStage.values.length - 1) {
                  setState(() => _currentStageIndex++);
                } else {
                  context.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: Text(_currentStageIndex < FabStage.values.length - 1 ? 'NEXT STAGE' : 'FINISH'),
            ),
          ),
        ],
      ),
    );
  }
}
