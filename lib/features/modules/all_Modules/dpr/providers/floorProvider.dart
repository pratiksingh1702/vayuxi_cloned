// providers/floor_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/floorModel.dart';

// Floor State
class FloorState {
  final List<Floor> floorList;
  final Floor? selectedFloor;
  final bool isLoading;
  final String? error;
  final bool useMockData;

  const FloorState({
    this.floorList = const [],
    this.selectedFloor,
    this.isLoading = false,
    this.error,
    this.useMockData = false,
  });

  FloorState copyWith({
    List<Floor>? floorList,
    Floor? selectedFloor,
    bool? isLoading,
    String? error,
    bool? useMockData,
  }) {
    return FloorState(
      floorList: floorList ?? this.floorList,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      useMockData: useMockData ?? this.useMockData,
    );
  }
}

// Local Storage Service
class FloorLocalStorage {
  static const String _floorsKey = 'user_floors';
  static const String _useMockKey = 'use_mock_floors';

  // Save floors to local storage
  static Future<void> saveFloors(List<Floor> floors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final floorsJson = floors.map((floor) => floor.toJson()).toList();
      await prefs.setString(_floorsKey, json.encode(floorsJson));
    } catch (e) {
      throw Exception('Failed to save floors: $e');
    }
  }

  // Load floors from local storage
  static Future<List<Floor>> loadFloors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final floorsJson = prefs.getString(_floorsKey);

      if (floorsJson == null) return [];

      final List<dynamic> decoded = json.decode(floorsJson);
      return decoded.map((json) => Floor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load floors: $e');
    }
  }

  // Save mock data preference
  static Future<void> setUseMockData(bool useMock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useMockKey, useMock);
    } catch (e) {
      throw Exception('Failed to save preference: $e');
    }
  }

  // Load mock data preference
  static Future<bool> getUseMockData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useMockKey) ?? true; // Default to true (use mock)
    } catch (e) {
      return true; // Default to mock data on error
    }
  }

  // Clear all stored floors
  static Future<void> clearFloors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_floorsKey);
    } catch (e) {
      throw Exception('Failed to clear floors: $e');
    }
  }
}

// Mock Data Generator
class MockFloorData {
  static List<Floor> generateMockFloors() {
    return [
      Floor(
        id: "ground",
        name: "Ground",
        code: "ground",
        image: "assets/floor/groundfloor.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      Floor(
        id: "first",
        name: "First",
        code: "first",
        image: "assets/floor/firstfloor.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      Floor(
        id: "second",
        name: "Second",
        code: "second",
        image: "assets/floor/secondfloor.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      Floor(
        id: "third",
        name: "Third",
        code: "third",
        image: "assets/floor/thirdfloor.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      Floor(
        id: "fourth",
        name: "Fourth",
        code: "fourth",
        image: "assets/floor/fourthfloor.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      Floor(
        id: "terrace",
        name: "Terrace",
        code: "terrace",
        image: "assets/floor/terrace.png",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
    ];
  }
}

// Floor Notifier
class FloorNotifier extends StateNotifier<FloorState> {
  FloorNotifier() : super(const FloorState());

  // Load Floors - tries local storage first, then mock data if enabled
  Future<void> loadFloors() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final useMock = await FloorLocalStorage.getUseMockData();

      // Load both sources
      final localFloors = await FloorLocalStorage.loadFloors();
      final mockFloors = MockFloorData.generateMockFloors();

      List<Floor> finalList;

      if (useMock) {
        // Combine mock + local (unique by id)
        var finalMap = {
          for (var f in [...mockFloors, ...localFloors]) f.id: f
        };
        finalList = finalMap.values.toList();
      } else {
        // If no local data → fallback to combined
        if (localFloors.isEmpty) {
          var finalMap = {
            for (var f in [...mockFloors]) f.id: f
          };
          finalList = finalMap.values.toList();
        } else {
          finalList = localFloors;
        }
      }

      state = state.copyWith(
        floorList: finalList,
        isLoading: false,
        useMockData: useMock,
      );
    } catch (e) {
      // As a last resort, mock only
      final mockFloors = MockFloorData.generateMockFloors();

      state = state.copyWith(
        floorList: mockFloors,
        error: "Failed to load floors, fallback to mock: $e",
        isLoading: false,
        useMockData: true,
      );
    }
  }

  // Load mock floors
  Future<void> _loadMockFloors() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    final mockFloors = MockFloorData.generateMockFloors();
    state = state.copyWith(
      floorList: mockFloors,
      isLoading: false,
    );
  }

  // Switch between mock data and user data
  Future<void> toggleMockData(bool useMock) async {
    await FloorLocalStorage.setUseMockData(useMock);

    if (useMock) {
      await _loadMockFloors();
    } else {
      await loadFloors(); // This will load from local storage
    }

    state = state.copyWith(useMockData: useMock);
  }

  // Add new Floor and save to device
  Future<void> addFloor(Floor floor) async {
    try {
      final updatedList = [...state.floorList, floor];
      state = state.copyWith(floorList: updatedList);

      // Save to local storage if not using mock data
      if (!state.useMockData) {
        await FloorLocalStorage.saveFloors(updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to add floor: $e");
      rethrow;
    }
  }

  // Update existing Floor and save to device
  Future<void> updateFloor(Floor updatedFloor) async {
    try {
      final updatedList = state.floorList.map((floor) {
        return floor.id == updatedFloor.id ? updatedFloor : floor;
      }).toList();

      state = state.copyWith(floorList: updatedList);

      // If the updated Floor is currently selected, update it too
      if (state.selectedFloor?.id == updatedFloor.id) {
        state = state.copyWith(selectedFloor: updatedFloor);
      }

      // Save to local storage if not using mock data
      if (!state.useMockData) {
        await FloorLocalStorage.saveFloors(updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to update floor: $e");
      rethrow;
    }
  }

  // Delete Floor and save to device
  Future<void> deleteFloor(String floorId) async {
    try {
      final updatedList = state.floorList.where((floor) => floor.id != floorId).toList();
      state = state.copyWith(floorList: updatedList);

      // If the deleted Floor was selected, clear selection
      if (state.selectedFloor?.id == floorId) {
        state = state.copyWith(selectedFloor: null);
      }

      // Save to local storage if not using mock data
      if (!state.useMockData) {
        await FloorLocalStorage.saveFloors(updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to delete floor: $e");
      rethrow;
    }
  }

  // Import mock data and switch to user mode
  Future<void> importMockData() async {
    try {
      final mockFloors = MockFloorData.generateMockFloors();
      await FloorLocalStorage.saveFloors(mockFloors);
      await toggleMockData(false); // Switch to user data mode
    } catch (e) {
      state = state.copyWith(error: "Failed to import mock data: $e");
      rethrow;
    }
  }

  // Clear all user data and switch to mock data
  Future<void> clearUserData() async {
    try {
      await FloorLocalStorage.clearFloors();
      await toggleMockData(true); // Switch to mock data mode
    } catch (e) {
      state = state.copyWith(error: "Failed to clear data: $e");
      rethrow;
    }
  }

  // Select Floor
  void selectFloor(Floor floor) {
    state = state.copyWith(selectedFloor: floor);
  }

  // Select Floor by ID
  void selectFloorById(String floorId) {
    final floor = getFloorById(floorId);
    if (floor != null) {
      selectFloor(floor);
    }
  }

  // Select Floor by Code
  void selectFloorByCode(String floorCode) {
    final floor = getFloorByCode(floorCode);
    if (floor != null) {
      selectFloor(floor);
    }
  }

  // Clear selected Floor
  void clearSelectedFloor() {
    state = state.copyWith(selectedFloor: null);
  }

  // Get Floor by ID
  Floor? getFloorById(String id) {
    try {
      return state.floorList.firstWhere((floor) => floor.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get Floor by Code
  Floor? getFloorByCode(String code) {
    try {
      return state.floorList.firstWhere((floor) => floor.code == code);
    } catch (e) {
      return null;
    }
  }

  // Get Floor by name
  Floor? getFloorByName(String name) {
    try {
      return state.floorList.firstWhere((floor) => floor.name == name);
    } catch (e) {
      return null;
    }
  }

  // Filter Floors by search term
  List<Floor> searchFloors(String searchTerm) {
    if (searchTerm.isEmpty) return state.floorList;

    return state.floorList.where((floor) =>
    floor.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
        floor.code.toLowerCase().contains(searchTerm.toLowerCase()) ||
        floor.id.toLowerCase().contains(searchTerm.toLowerCase())
    ).toList();
  }

  // Get active Floors only
  List<Floor> get activeFloors {
    return state.floorList.where((floor) => floor.isActive).toList();
  }

  // Get floors ordered by typical building order
  List<Floor> get orderedFloors {
    final order = ['basement', 'ground', 'first', 'second', 'third', 'fourth', 'terrace', 'roof'];
    return List.from(state.floorList)
      ..sort((a, b) {
        final indexA = order.indexOf(a.code);
        final indexB = order.indexOf(b.code);
        return indexA.compareTo(indexB);
      });
  }
}

// Providers
final floorProvider = StateNotifierProvider<FloorNotifier, FloorState>((ref) {
  return FloorNotifier();
});

final selectedFloorProvider = Provider<Floor?>((ref) {
  return ref.watch(floorProvider).selectedFloor;
});

final floorListProvider = Provider<List<Floor>>((ref) {
  return ref.watch(floorProvider).floorList;
});

final activeFloorsProvider = Provider<List<Floor>>((ref) {
  return ref.watch(floorProvider.notifier).activeFloors;
});

final orderedFloorsProvider = Provider<List<Floor>>((ref) {
  return ref.watch(floorProvider.notifier).orderedFloors;
});

final useMockDataProvider = Provider<bool>((ref) {
  return ref.watch(floorProvider).useMockData;
});