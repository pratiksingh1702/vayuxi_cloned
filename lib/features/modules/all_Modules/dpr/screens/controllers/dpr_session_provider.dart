// dpr_session_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DprSessionState {
  final bool isEditMode;
  final DateTime selectedDate;

 DprSessionState({
    this.isEditMode = false,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DprSessionState copyWith({bool? isEditMode, DateTime? selectedDate}) {
    return DprSessionState(
      isEditMode: isEditMode ?? this.isEditMode,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DprSessionNotifier extends StateNotifier<DprSessionState> {
  DprSessionNotifier() : super(DprSessionState());

  void setEditMode(bool value, {DateTime? date}) {
    if (!value) {
      // Edit mode OFF → reset date to today
      final now = DateTime.now();
      state = DprSessionState(
        isEditMode: false,
        selectedDate: DateTime(now.year, now.month, now.day),
      );
    } else {
      state = state.copyWith(
        isEditMode: true,
        selectedDate: date ?? state.selectedDate,
      );
    }
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

final dprSessionProvider =
StateNotifierProvider<DprSessionNotifier, DprSessionState>(
      (ref) => DprSessionNotifier(),
);