import 'package:flutter/material.dart';

import '../models/peb_execution_models.dart';

String? pebCustomWorkImageFor(PebSetupItem item) {
  for (final rawImage in item.images) {
    final image = rawImage.trim();
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
  }
  return null;
}

String pebDefaultWorkImageFor(PebSetupItem item, PebExecutionType type) {
  final name = item.name.trim().toLowerCase();
  return switch (name) {
    'unloading' when type == PebExecutionType.erection =>
      'erection-image/unloading.png',
    'shifting' when type == PebExecutionType.erection =>
      'erection-image/shifting.png',
    'erection' when type == PebExecutionType.erection =>
      'erection-image/erection.png',
    'alignment' when type == PebExecutionType.erection =>
      'erection-image/alignment.png',
    'bolt tightening' when type == PebExecutionType.erection =>
      'erection-image/bolt-tightning.png',
    'patch-up & finishing' ||
    'patch up & finishing' ||
    'patchup' ||
    'touch up and finishing' when type == PebExecutionType.erection =>
      'erection-image/Patch-up & Finishing.png',
    'qc clearance' when type == PebExecutionType.erection =>
      'erection-image/QC Clearance.png',
    'unloading' => 'assets/images/Unloading.png',
    'shifting' => 'assets/images/Shfiting.png',
    'cutting' => 'assets/images/Cutting.png',
    'fitup' || 'fit up' || 'fit' => 'assets/images/Fit.png',
    'grinding' ||
    'grinding & finishing' ||
    'grinding and finishing' =>
      'assets/images/Grinding.png',
    'welding' || 'mig welding' || 'weld visual' => 'assets/images/Welding.png',
    'dispatch' || 'loading' => 'assets/images/Dispatch.png',
    _ => type == PebExecutionType.erection
        ? 'assets/images/peb.png'
        : 'assets/images/peb.png',
  };
}

String pebWorkImageFor(PebSetupItem item, PebExecutionType type) {
  return pebCustomWorkImageFor(item) ?? pebDefaultWorkImageFor(item, type);
}

bool pebWorkImageIsCustom(PebSetupItem item) =>
    pebCustomWorkImageFor(item) != null;

ImageProvider pebWorkImageProvider(PebSetupItem item, PebExecutionType type) {
  final image = pebWorkImageFor(item, type);
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return NetworkImage(image);
  }
  return AssetImage(image);
}

Widget pebWorkImageFallback(
  PebSetupItem item,
  PebExecutionType type, {
  BoxFit fit = BoxFit.contain,
}) {
  return Image.asset(
    pebDefaultWorkImageFor(item, type),
    fit: fit,
    errorBuilder: (_, __, ___) => const Center(
      child: Icon(Icons.construction_rounded, size: 42),
    ),
  );
}
