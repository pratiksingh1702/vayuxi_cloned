// providers/moc_provider.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moc.dart';

// MOC State

// Local Storage Service for MOCs


class MOCLocalStorage {
  static const String key = "user_mocs";

  static Future<List<MOC>> loadUserMOCs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw == null) return [];

    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => MOC.fromJson(e)).toList();
  }

  static Future<void> saveUserMOCs(List<MOC> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }
}

// Mock Data Generator for MOCs
class MockMOCData {
  static final List<MOC> mockList=
    [
      MOC(
        id: "SS",
        name: "SS",
        imageUrl: "assets/stepper/image.png",
        createdAt: DateTime.now(),

        isPredefined: true, // Mark as predefined mock data
      ),
      MOC(
        id: "MS",
        name: "MS",
        imageUrl: "assets/stepper/ms.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "MSPT",
        name: "MSPT",
        imageUrl: "assets/stepper/mspt.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "GLR",
        name: "GLR",
        imageUrl: "assets/stepper/glr.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "HDPE",
        name: "HDPE",
        imageUrl: "assets/stepper/hdpe.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "PPFRP_1",
        name: "PPFRP",
        imageUrl: "assets/stepper/ppfrp.png",
        createdAt: DateTime.now(),
        isPredefined: true,
      ),
      MOC(
        id: "Rubber_Lined",
        name: "Rubber Lined",
        imageUrl: "assets/stepper/rubber.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "HDPE_FRP",
        name: "HDPE FRP",
        imageUrl: "assets/stepper/hdpefrp.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "PVDF",
        name: "PVDF",
        imageUrl: "assets/stepper/pvdf.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "Graphite",
        name: "Graphite",
        imageUrl: "assets/stepper/graphte.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "CS",
        name: "CS",
        imageUrl: "assets/stepper/cs.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "Aluminium",
        name: "Aluminium",
        imageUrl: "assets/stepper/aluminium.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "FRP_1",
        name: "FRP",
        imageUrl: "assets/stepper/frp.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "Duplex",
        name: "Duplex",
        imageUrl: "assets/stepper/duplex.png",
        createdAt: DateTime.now(),
        isPredefined: true,
      ),
      MOC(
        id: "PTFE",
        name: "PTFE",
        imageUrl: "assets/stepper/ptfe.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "Hastelloy",
        name: "Hastelloy",
        imageUrl: "assets/stepper/hastely.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "PP",
        name: "PP",
        imageUrl: "assets/stepper/pp.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "SS316",
        name: "SS316",
        imageUrl: "assets/stepper/ss316.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "SS304",
        name: "SS304",
        imageUrl: "assets/stepper/ss304.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "PPFRP_2",
        name: "PPFRP",
        imageUrl: "assets/stepper/ppfrp2.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
      MOC(
        id: "FRP_2",
        name: "FRP",
        imageUrl: "assets/stepper/frp2.png",
        createdAt: DateTime.now(),

        isPredefined: true,
      ),
    ];
  }




class MOCState {
  final List<MOC> userMOCs;
  final List<MOC> mockMOCs;
  final MOC? selectedMOC;
  final bool isLoading;
  final String? error;

  const MOCState({
    this.userMOCs = const [],
    this.mockMOCs = const [],
    this.selectedMOC,
    this.isLoading = false,
    this.error,
  });

  List<MOC> get all => [...mockMOCs, ...userMOCs]; // ALWAYS COMBINED

  MOCState copyWith({
    List<MOC>? userMOCs,
    List<MOC>? mockMOCs,
    MOC? selectedMOC,
    bool? isLoading,
    String? error,
  }) {
    return MOCState(
      userMOCs: userMOCs ?? this.userMOCs,
      mockMOCs: mockMOCs ?? this.mockMOCs,
      selectedMOC: selectedMOC ?? this.selectedMOC,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MOCNotifier extends StateNotifier<MOCState> {
  MOCNotifier() : super(const MOCState());

  Future<void> loadMOCs() async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await MOCLocalStorage.loadUserMOCs();
      final mock = MockMOCData.mockList;

      state = state.copyWith(
        userMOCs: user,
        mockMOCs: mock,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        mockMOCs: MockMOCData.mockList,
        isLoading: false,
        error: "Failed to load: $e",
      );
    }
  }

  void select(MOC moc) {
    state = state.copyWith(selectedMOC: moc);
  }

  Future<void> add(MOC moc) async {
    final updated = [...state.userMOCs, moc.copyWith(isPredefined: false)];

    state = state.copyWith(userMOCs: updated);
    await MOCLocalStorage.saveUserMOCs(updated);
  }

  Future<void> update(MOC moc) async {
    if (moc.isPredefined) {
      final updatedMock =
      state.mockMOCs.map((m) => m.id == moc.id ? moc : m).toList();
      state = state.copyWith(mockMOCs: updatedMock);
    } else {
      final updatedUser =
      state.userMOCs.map((m) => m.id == moc.id ? moc : m).toList();
      state = state.copyWith(userMOCs: updatedUser);
      await MOCLocalStorage.saveUserMOCs(updatedUser);
    }
  }

  Future<void> delete(String id) async {
    final moc = getById(id);
    if (moc == null || moc.isPredefined) {
      throw Exception("Cannot delete predefined MOC.");
    }

    final updated = state.userMOCs.where((m) => m.id != id).toList();
    state = state.copyWith(userMOCs: updated);
    await MOCLocalStorage.saveUserMOCs(updated);
  }

  MOC? getById(String id) {
    try {
      return state.all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<MOC> search(String term) {
    if (term.isEmpty) return state.all;
    return state.all
        .where((m) => m.name.toLowerCase().contains(term.toLowerCase()))
        .toList();
  }
}

// Providers
final mocProvider =
StateNotifierProvider<MOCNotifier, MOCState>((ref) => MOCNotifier());

final mocListProvider = Provider<List<MOC>>(
      (ref) => ref.watch(mocProvider).all,
);

final selectedMOCProvider = Provider<MOC?>((ref) {
  return ref.watch(mocProvider).selectedMOC;
});


final userMOCsProvider = Provider<List<MOC>>((ref) {
  return ref.watch(mocProvider).userMOCs;
});

final predefinedMOCsProvider = Provider<List<MOC>>((ref) {
  return ref.watch(mocProvider).mockMOCs;
});