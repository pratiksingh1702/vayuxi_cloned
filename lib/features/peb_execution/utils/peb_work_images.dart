import 'package:flutter/material.dart';

import '../models/peb_execution_models.dart';

String pebWorkImageFor(PebSetupItem item, PebExecutionType type) {
  if (item.images.isNotEmpty) return item.images.first;

  final name = item.name.trim().toLowerCase();
  final asset = switch (name) {
    'unloading' when type == PebExecutionType.erection =>
      'e-images/unloading work.png',
    'shifting' when type == PebExecutionType.erection =>
      'e-images/shifting work.png',
    'erection' when type == PebExecutionType.erection =>
      'e-images/ERECTION.png',
    'alignment' when type == PebExecutionType.erection =>
      'e-images/ALIGNMENT.png',
    'bolt tightening' when type == PebExecutionType.erection =>
      'e-images/BOLT TIGHTENING.png',
    'patch-up & finishing' ||
    'patch up & finishing' ||
    'patchup' ||
    'touch up and finishing' when type == PebExecutionType.erection =>
      'e-images/TOUCH UP AND FINISHING.png',
    'qc clearance' when type == PebExecutionType.erection =>
      'e-images/QC CLEARANCE.png',
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

  return asset;
}

bool pebWorkImageIsCustom(PebSetupItem item) => item.images.isNotEmpty;

ImageProvider pebWorkImageProvider(PebSetupItem item, PebExecutionType type) {
  final image = pebWorkImageFor(item, type);
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return NetworkImage(image);
  }
  return AssetImage(image);
}
