// lib/features/modules/all_Modules/dpr/screens/widgets/delete_mode_mixin.dart

import 'package:flutter/material.dart';

mixin DeleteModeMixin<T> {
  bool isDeleteMode = false;
  final Set<T> selectedIds = {};

  void toggleDeleteMode() {
    isDeleteMode = !isDeleteMode;
    if (!isDeleteMode) {
      selectedIds.clear();
    }
  }

  void toggleSelection(T id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  bool isSelected(T id) => selectedIds.contains(id);

  void selectAll(List<T> allIds) {
    selectedIds.clear();
    selectedIds.addAll(allIds);
  }

  void deselectAll() {
    selectedIds.clear();
  }

  bool areAllSelected(List<T> allIds) {
    if (allIds.isEmpty) return false;
    return selectedIds.length == allIds.length;
  }

  String selectAllLabel(List<T> allIds) {
    return areAllSelected(allIds) ? 'Deselect All' : 'Select All';
  }

  void handleSelectAllToggle(List<T> allIds) {
    if (areAllSelected(allIds)) {
      deselectAll();
    } else {
      selectAll(allIds);
    }
  }
}
