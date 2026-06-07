import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';

import '../models/peb_execution_models.dart';
import '../services/peb_execution_service.dart';
import '../utils/peb_work_images.dart';

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
  String _uploadingItemId = '';
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
    final images = List<String>.from(item?.images ?? const []);
    var uploading = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          Future<void> pickImages() async {
            final picked = await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.image,
              withData: true,
            );
            if (picked == null || picked.files.isEmpty) return;
            setSheetState(() => uploading = true);
            try {
              final urls =
                  await _service.uploadSetupImages(widget.siteId, picked.files);
              if (urls.isNotEmpty) {
                images
                  ..clear()
                  ..addAll(urls);
              }
            } catch (_) {
              AppToast.error('Failed to upload image');
            } finally {
              setSheetState(() => uploading = false);
            }
          }

          final previewItem = PebSetupItem(
            id: item?.id ?? '',
            name: name.text.trim().isEmpty ? item?.name ?? '' : name.text,
            uom: uom.text,
            targetQty: num.tryParse(qty.text.trim())?.toDouble() ?? 0,
            remarks: remarks.text,
            images: images,
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item == null ? 'Add DPR Item' : 'Edit DPR Item',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        padding: EdgeInsets.all(
                            pebWorkImageIsCustom(previewItem) ? 0 : 18),
                        child: Image(
                          image: pebWorkImageProvider(
                              previewItem, widget.executionType),
                          fit: pebWorkImageIsCustom(previewItem)
                              ? BoxFit.cover
                              : BoxFit.contain,
                          errorBuilder: (_, __, ___) => pebWorkImageFallback(
                            previewItem,
                            widget.executionType,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: uploading ? null : pickImages,
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label:
                        Text(images.isEmpty ? 'Upload Image' : 'Replace Image'),
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
                      onPressed: uploading ? null : () => context.pop(true),
                      child: Text(item == null ? 'Add Item' : 'Update Item'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
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
        images: images.isEmpty ? null : images,
        imageUserSpecific: images.isNotEmpty,
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
                    _itemsGrid(cs),
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
        initialValue: _trackingLevel,
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

  Widget _itemsGrid(ColorScheme cs) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth >= 720 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: crossAxisCount == 1 ? 1.18 : 1.02,
        ),
        itemBuilder: (context, index) => _itemCard(items[index], cs),
      );
    });
  }

  Future<void> _replaceItemImage(PebSetupItem item) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    setState(() => _uploadingItemId = item.id);
    try {
      final urls =
          await _service.uploadSetupImages(widget.siteId, picked.files);
      if (urls.isEmpty) return;
      await _service.saveSetupItem(
        widget.siteId,
        widget.executionType,
        itemId: item.id,
        name: item.name,
        uom: item.uom,
        remarks: item.remarks,
        targetQty: item.targetQty,
        images: urls,
        imageUserSpecific: true,
      );
      await _load();
      AppToast.success('Image updated');
    } catch (_) {
      AppToast.error('Failed to update image');
    } finally {
      if (mounted) setState(() => _uploadingItemId = '');
    }
  }

  Widget _itemCard(PebSetupItem item, ColorScheme cs) {
    final isUploading = _uploadingItemId == item.id;
    final hasCustomImage = pebWorkImageIsCustom(item);
    return Container(
      decoration: _boxDecoration(cs),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: cs.surfaceContainerLow,
                  padding: EdgeInsets.all(hasCustomImage ? 0 : 20),
                  child: Image(
                    image: pebWorkImageProvider(item, widget.executionType),
                    fit: hasCustomImage ? BoxFit.cover : BoxFit.contain,
                    errorBuilder: (_, __, ___) => pebWorkImageFallback(
                      item,
                      widget.executionType,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black
                              .withValues(alpha: hasCustomImage ? 0.45 : 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: _saving || isUploading
                        ? null
                        : () => _replaceItemImage(item),
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_rounded, size: 18),
                    label: Text(item.images.isEmpty ? 'Upload' : 'Edit'),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoChip(label: 'UOM', value: item.uom),
                    const SizedBox(width: 8),
                    _InfoChip(label: 'Target', value: '${item.targetQty}'),
                  ],
                ),
                if (item.remarks.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.remarks,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _openItemForm(item),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _saving ? null : () => _deleteItem(item),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(ColorScheme cs) {
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
