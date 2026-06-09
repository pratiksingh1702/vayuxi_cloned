import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
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
          mainAxisExtent: crossAxisCount == 1 ? 214 : 206,
        ),
        itemBuilder: (context, index) => _itemCard(items[index], cs),
      );
    });
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

  Widget _itemCard(PebSetupItem item, ColorScheme cs) {
    final isUploading = _uploadingItemId == item.id;
    final hasCustomImage = pebWorkImageIsCustom(item);
    return LayoutBuilder(builder: (context, constraints) {
      final imageWidth =
          constraints.maxWidth < 390 ? constraints.maxWidth * 0.32 : 118.0;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration(cs),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Expanded(
                  child: SizedBox(
                    width: imageWidth.clamp(100.0, 122.0),
                    child: _SetupImageTile(
                      item: item,
                      executionType: widget.executionType,
                      hasCustomImage: hasCustomImage,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: imageWidth.clamp(100.0, 122.0),
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: _saving || isUploading
                        ? null
                        : () => _replaceItemImage(item),
                    icon: isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined, size: 16),
                    label: Text(
                      item.images.isEmpty ? 'Upload' : 'Change',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'More actions',
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') _openItemForm(item);
                          if (value == 'delete') _deleteItem(item);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit details'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: !_saving,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  Icon(Icons.delete_outline, color: cs.error),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.remarks.trim().isNotEmpty)
                    Text(
                      item.remarks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      'No remarks added',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _SetupInlineMeta(
                        label: 'UOM',
                        value: item.uom,
                        cs: cs,
                      ),
                      _SetupInlineMeta(
                        label: 'Target',
                        value: '${item.targetQty}',
                        cs: cs,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _openItemForm(item),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
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

class _SetupImageTile extends StatelessWidget {
  final PebSetupItem item;
  final PebExecutionType executionType;
  final bool hasCustomImage;

  const _SetupImageTile({
    required this.item,
    required this.executionType,
    required this.hasCustomImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        padding: EdgeInsets.all(hasCustomImage ? 8 : 14),
        child: Center(
          child: Image(
            image: pebWorkImageProvider(item, executionType),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => pebWorkImageFallback(
              item,
              executionType,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupInlineMeta extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _SetupInlineMeta({
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          height: 1.1,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
