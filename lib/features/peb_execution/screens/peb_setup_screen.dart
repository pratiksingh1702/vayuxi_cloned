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

  Widget _itemsGrid(ColorScheme cs) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth >= 1000
          ? 4
          : (constraints.maxWidth >= 600 ? 3 : 2);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 282,
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
    
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image header (full-width, 160px tall) ──────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image(
                    image: pebWorkImageProvider(item, widget.executionType),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => pebWorkImageFallback(
                      item,
                      widget.executionType,
                    ),
                  ),
                ),
              ),
              // Camera button — top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _saving || isUploading
                      ? null
                      : () => _replaceItemImage(item),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Center(
                      child: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Data section ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage name under the image
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Remark pill on the left
                    GestureDetector(
                      onTap: () => _openItemForm(item),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 95),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          item.remarks.trim().isNotEmpty
                              ? item.remarks
                              : 'Add Remark',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Actions (Edit/Delete) on the right
                    _actionBtn(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: cs.primary,
                      onTap: () => _openItemForm(item),
                    ),
                    const SizedBox(width: 4),
                    _actionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: cs.error,
                      onTap: () => _deleteItem(item),
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

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
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
