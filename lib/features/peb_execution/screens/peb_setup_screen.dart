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
      final crossAxisCount = constraints.maxWidth >= 720 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: crossAxisCount == 1 ? 240 : 230,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const blueFill = Color(0xFFD0EAFD);
    const darkBlueFill = Color(0xFF1E3A5F);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Top space for name and corner blue box as remark
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openItemForm(item),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 78,
                      maxWidth: 110,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.7),
                      border: Border.all(color: cs.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.remarks.trim().isNotEmpty
                          ? item.remarks
                          : 'Remark',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSecondaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // LEFT COLUMN: Image & Actions
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 4, 7, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image(
                                  image: pebWorkImageProvider(item, widget.executionType),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => pebWorkImageFallback(
                                    item,
                                    widget.executionType,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Action row (Edit, Upload/Change Image, Delete)
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionIcon(
                                  Icons.edit_rounded,
                                  cs.primary,
                                  () => _openItemForm(item),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionIcon(
                                  isUploading ? null : Icons.photo_camera_outlined,
                                  Colors.green,
                                  _saving || isUploading ? () {} : () => _replaceItemImage(item),
                                  isUploading: isUploading,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionIcon(
                                  Icons.delete_outline_rounded,
                                  cs.error,
                                  () => _deleteItem(item),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT COLUMN: Fields
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(7, 4, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _blueBox(
                                  label: "UOM",
                                  value: item.uom,
                                  cs: cs,
                                  isDark: isDark,
                                  blueFill: blueFill,
                                  darkBlueFill: darkBlueFill,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _blueBox(
                                  label: "Target Qty",
                                  value: '${item.targetQty}',
                                  cs: cs,
                                  isDark: isDark,
                                  blueFill: blueFill,
                                  darkBlueFill: darkBlueFill,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData? icon, Color color, VoidCallback onPressed, {bool isUploading = false}) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: isUploading
              ? Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                )
              : Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _blueBox({
    required String label,
    required String value,
    required ColorScheme cs,
    required bool isDark,
    required Color blueFill,
    required Color darkBlueFill,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        Container(
          height: 26,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? darkBlueFill : blueFill,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
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
