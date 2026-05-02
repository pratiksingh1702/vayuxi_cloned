import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/typeProvider/work_type.dart';

final typeProvider = StateNotifierProvider<TypeNotifier, String?>((ref) {
  return TypeNotifier();
});

class TypeNotifier extends StateNotifier<String?> {
  TypeNotifier() : super(null);

  void setType(String type) {
    state = type;
  }
}

final workTypeProvider = Provider<WorkType?>((ref) {
  return WorkType.fromApiValue(ref.watch(typeProvider));
});
