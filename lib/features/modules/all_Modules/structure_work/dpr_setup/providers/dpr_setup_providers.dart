import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../isar/assembly_card_isar.dart';
import '../services/dpr_setup_service.dart';

final dprSetupServiceProvider = Provider((ref) => DPRSetupService());

final assemblyCardsProvider = StateNotifierProvider.family<AssemblyCardNotifier, List<AssemblyCardIsar>, String>((ref, siteId) {
  final service = ref.watch(dprSetupServiceProvider);
  return AssemblyCardNotifier(service, siteId);
});

class AssemblyCardNotifier extends StateNotifier<List<AssemblyCardIsar>> {
  final DPRSetupService _service;
  final String siteId;

  AssemblyCardNotifier(this._service, this.siteId) : super([]) {
    loadCards();
  }

  Future<void> loadCards() async {
    state = await _service.getLocalAssemblyCards(siteId);
  }

  Future<void> addCard(AssemblyCardIsar card) async {
    // Enforce single card: Delete all existing cards for this site first
    final existing = await _service.getLocalAssemblyCards(siteId);
    for (final ec in existing) {
      await _service.deleteAssemblyCardLocal(ec.isarId);
    }
    await _service.saveAssemblyCardLocal(card);
    await loadCards();
  }

  Future<void> updateCard(AssemblyCardIsar card) async {
    await _service.saveAssemblyCardLocal(card);
    await loadCards();
  }

  Future<void> deleteCard(int id) async {
    await _service.deleteAssemblyCardLocal(id);
    await loadCards();
  }
}
