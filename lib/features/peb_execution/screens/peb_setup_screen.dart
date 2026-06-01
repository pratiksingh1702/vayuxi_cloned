import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';

import '../models/peb_execution_models.dart';
import '../services/peb_execution_service.dart';

class PebSetupScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final PebExecutionType executionType;

  const PebSetupScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
  });

  @override
  State<PebSetupScreen> createState() => _PebSetupScreenState();
}

class _PebSetupScreenState extends State<PebSetupScreen> {
  final _service = PebExecutionService();
  PebSetup? _setup;
  bool _loading = true;
  bool _saving = false;
  String _trackingLevel = 'advanced';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _setup = await _service.getSetup(widget.siteId, widget.executionType);
    } catch (error) {
      AppToast.error('Failed to load DPR setup');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    try {
      _setup = await _service.resetSetup(
        widget.siteId,
        widget.executionType,
        trackingLevel: _trackingLevel,
      );
      AppToast.success('DPR setup reset successfully');
    } catch (error) {
      AppToast.error('Failed to reset setup');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteItem(PebSetupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Delete ${item.name} from this DPR setup?'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _service.deleteSetupItem(
          widget.siteId, widget.executionType, item.id);
      await _load();
      AppToast.success('Item deleted');
    } catch (error) {
      AppToast.error('Failed to delete item');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openItemForm([PebSetupItem? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final uom = TextEditingController(text: item?.uom ?? 'MT');
    final qty = TextEditingController(text: (item?.targetQty ?? 0).toString());
    final remarks = TextEditingController(text: item?.remarks ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item == null ? 'Add DPR Item' : 'Edit DPR Item',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration:
                    const InputDecoration(labelText: 'Item / Stage name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: uom,
                      decoration: const InputDecoration(labelText: 'UOM'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Target Qty'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarks,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.pop(true),
                  child: Text(item == null ? 'Add Item' : 'Update Item'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (saved != true) return;
    if (name.text.trim().isEmpty) {
      AppToast.error('Item name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.saveSetupItem(
        widget.siteId,
        widget.executionType,
        itemId: item?.id,
        name: name.text.trim(),
        uom: uom.text.trim().isEmpty ? 'MT' : uom.text.trim(),
        remarks: remarks.text.trim(),
        targetQty: num.tryParse(qty.text.trim()) ?? 0,
      );
      await _load();
      AppToast.success('Setup saved');
    } catch (error) {
      AppToast.error('Failed to save item');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: cs.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          CustomSliverAppBar(title: '${widget.executionType.title} DPR Setup'),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.siteName,
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (widget.executionType == PebExecutionType.erection)
                      _trackingLevelCard(cs),
                    _actions(cs),
                    const SizedBox(height: 16),
                    ...(_setup?.items ?? []).map((item) => _itemTile(item, cs)),
                    if ((_setup?.items ?? []).isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: Text('No setup items found')),
                      ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _openItemForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _trackingLevelCard(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(cs),
      child: DropdownButtonFormField<String>(
        value: _trackingLevel,
        decoration: const InputDecoration(labelText: 'Erection Tracking Level'),
        items: const [
          DropdownMenuItem(value: 'basic', child: Text('Level 1 - Basic')),
          DropdownMenuItem(
              value: 'semi_structured',
              child: Text('Level 2 - Semi Structured')),
          DropdownMenuItem(
              value: 'advanced', child: Text('Level 3 - Advanced')),
        ],
        onChanged: (value) =>
            setState(() => _trackingLevel = value ?? 'advanced'),
      ),
    );
  }

  Widget _actions(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Default Setup'),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(PebSetupItem item, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(cs),
      child: Row(
        children: [
          Container(width: 4, height: 42, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('UOM: ${item.uom}   Target: ${item.targetQty}',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => _openItemForm(item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _saving ? null : () => _deleteItem(item),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(ColorScheme cs) {
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.outlineVariant),
    );
  }
}
