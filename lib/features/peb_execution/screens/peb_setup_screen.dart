import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/custom_dropdown.dart';
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
  bool _orderDirty = false;
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
      _orderDirty = false;
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
      _orderDirty = false;
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

  void _reorderItems(int oldIndex, int newIndex) {
    final setup = _setup;
    if (setup == null) return;
    final items = List<PebSetupItem>.from(setup.items);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() {
      _setup = PebSetup(
        id: setup.id,
        section: setup.section,
        allowUnassignedDprFallback: setup.allowUnassignedDprFallback,
        items: items,
      );
      _orderDirty = true;
    });
  }

  Future<void> _saveOrder() async {
    final setup = _setup;
    if (setup == null || setup.items.isEmpty || !_orderDirty) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.reorderSetupItems(
        widget.siteId,
        widget.executionType,
        setup.items,
      );
      if (updated != null) {
        _setup = updated;
      } else {
        await _load();
      }
      _orderDirty = false;
      AppToast.success('Stage sequence saved');
    } catch (error) {
      AppToast.error('Failed to save stage sequence');
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
            final file = await _pickAndCropSetupImage('Crop DPR Setup Image');
            if (file == null) return;
            setSheetState(() => uploading = true);
            try {
              final urls =
                  await _service.uploadSetupImages(widget.siteId, [file]);
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
                        color: Colors.white,
                        padding: const EdgeInsets.all(14),
                        child: Image(
                          image: pebWorkImageProvider(
                              previewItem, widget.executionType),
                          fit: BoxFit.contain,
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
        uom: 'MT',
        remarks: remarks.text.trim(),
        targetQty: 0,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.siteName,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _saving ? null : _reset,
                          icon: const Icon(Icons.restore_rounded),
                          tooltip: 'Reset Default Setup',
                          color: cs.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.executionType == PebExecutionType.erection)
                      _trackingLevelCard(cs),
                    const SizedBox(height: 16),
                    _sequenceToolbar(cs),
                    const SizedBox(height: 10),
                    _itemsReorderList(cs),
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

  Widget _sequenceToolbar(ColorScheme cs) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(cs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.swap_vert_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Stage Sequence',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Drag stages to set the DPR Entry and Work Assignment order.',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _saving || !_orderDirty ? null : _saveOrder,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Order'),
          ),
        ],
      ),
    );
  }

  Widget _trackingLevelCard(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _boxDecoration(cs),
      child: CustomDropdownField<String>(
        label: 'Erection Tracking Level',
        value: _trackingLevel,
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

  Widget _itemsReorderList(ColorScheme cs) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: _saving ? (_, __) {} : _reorderItems,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
          child: child,
        ),
      ),
      itemBuilder: (context, index) => _orderedItemCard(
        key: ValueKey(items[index].id),
        item: items[index],
        index: index,
        cs: cs,
      ),
    );
  }

  Widget _orderedItemCard({
    required Key key,
    required PebSetupItem item,
    required int index,
    required ColorScheme cs,
  }) {
    final isUploading = _uploadingItemId == item.id;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _orderDirty
              ? cs.primary.withValues(alpha: 0.22)
              : cs.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 34,
                height: 58,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.drag_indicator_rounded,
                    color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 66,
                height: 58,
                child: Container(
                  color: cs.surfaceContainerLow,
                  padding: const EdgeInsets.all(6),
                  child: Image(
                    image: pebWorkImageProvider(item, widget.executionType),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => pebWorkImageFallback(
                      item,
                      widget.executionType,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.remarks.trim().isNotEmpty
                        ? item.remarks
                        : '${item.uom} • Target ${item.targetQty.toStringAsFixed(item.targetQty == item.targetQty.roundToDouble() ? 0 : 2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Replace image',
              onPressed:
                  _saving || isUploading ? null : () => _replaceItemImage(item),
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.photo_camera_rounded, color: cs.primary),
            ),
            IconButton(
              tooltip: 'Edit stage',
              onPressed: _saving ? null : () => _openItemForm(item),
              icon: Icon(Icons.edit_rounded, color: cs.primary),
            ),
            IconButton(
              tooltip: 'Delete stage',
              onPressed: _saving ? null : () => _deleteItem(item),
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replaceItemImage(PebSetupItem item) async {
    final file = await _pickAndCropSetupImage('Crop ${item.name} Image');
    if (file == null) return;
    setState(() => _uploadingItemId = item.id);
    try {
      final urls = await _service.uploadSetupImages(widget.siteId, [file]);
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

  Future<PlatformFile?> _pickAndCropSetupImage(String cropTitle) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final source = picked.files.first;
    final sourcePath = source.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      AppToast.error('Unable to read selected image');
      return null;
    }

    try {
      final cs = Theme.of(context).colorScheme;
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: cs.primary,
            toolbarWidgetColor: cs.onPrimary,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor: cs.onPrimary.withValues(alpha: 0.45),
            cropFrameColor: cs.primary,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: cs.primary,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: cropTitle,
            minimumAspectRatio: 0.1,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
            viewwMode: WebViewMode.mode_1,
          ),
        ],
      );

      if (cropped == null) return null;
      final croppedFile = File(cropped.path);
      final size = await croppedFile.length();
      return PlatformFile(
        name: cropped.path.split(Platform.pathSeparator).last,
        size: size,
        path: cropped.path,
      );
    } catch (_) {
      AppToast.error('Failed to crop image');
      return null;
    }
  }

  BoxDecoration _boxDecoration(ColorScheme cs) {
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
