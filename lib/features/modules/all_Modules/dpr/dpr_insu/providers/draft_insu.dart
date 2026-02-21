import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/dpr_model_insu.dart';

final insulationDraftProvider =
StateNotifierProvider<InsulationDraftNotifier, List<InsulationDprModel>>(
        (ref) => InsulationDraftNotifier());

class InsulationDraftNotifier
    extends StateNotifier<List<InsulationDprModel>> {
  InsulationDraftNotifier() : super([]);

  void saveDraft(InsulationDprModel draft) {
    state = [
      ...state.where((d) => d.id != draft.id),
      draft,
    ];
  }

  void removeDraft(String id) {
    state = state.where((d) => d.id != id).toList();
  }

  InsulationDprModel? getDraft(String id) {
    return state.firstWhere(
          (d) => d.id == id,
      orElse: () =>InsulationDprModel.empty(),
    );
  }
}
