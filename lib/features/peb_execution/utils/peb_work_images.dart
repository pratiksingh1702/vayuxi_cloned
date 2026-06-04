import 'package:flutter/material.dart';

import '../models/peb_execution_models.dart';

String pebWorkImageFor(PebSetupItem item, PebExecutionType type) {
  if (item.images.isNotEmpty) return item.images.first;

  final name = item.name.trim().toLowerCase();
  final asset = switch (name) {
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
