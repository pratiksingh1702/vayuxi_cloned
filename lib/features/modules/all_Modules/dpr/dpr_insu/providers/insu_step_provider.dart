// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../model/insu_step_date.dart';
//
// // State provider for managing insulation step data
// final insulationStepProvider = StateNotifierProvider<InsulationStepNotifier, InsulationStepData>(
//       (ref) => InsulationStepNotifier(),
// );
//
// class InsulationStepNotifier extends StateNotifier<InsulationStepData> {
//   InsulationStepNotifier()
//       : super(InsulationStepData(
//     floor: '',
//     layerType: '',
//     layers: [],
//     cladding: Cladding(name: '', thickness: ''),
//   ));
//
//   void setFloor(String floor) {
//     state = state.copyWith(floor: floor);
//   }
//
//   void setLayerType(String type) {
//     int count = 1;
//     if (type == 'double') count = 2;
//     if (type == 'triple') count = 3;
//
//     final layers = List<LaggingMaterial>.generate(
//       count,
//           (index) => LaggingMaterial(name: '', thickness: ''),
//     );
//
//     state = state.copyWith(layerType: type, layers: layers);
//   }
//
//   void updateLayer(int index, LaggingMaterial material) {
//     final updatedLayers = List<LaggingMaterial>.from(state.layers);
//     updatedLayers[index] = material;
//     state = state.copyWith(layers: updatedLayers);
//   }
//
//   void setCladding(Cladding cladding) {
//     state = state.copyWith(cladding: cladding);
//   }
//
//   void reset() {
//     state = InsulationStepData(
//       floor: '',
//       layerType: '',
//       layers: [],
//       cladding: Cladding(name: '', thickness: ''),
//     );
//   }
// }
//
// // Provider for current step
// final currentStepProvider = StateProvider<int>((ref) => 1);