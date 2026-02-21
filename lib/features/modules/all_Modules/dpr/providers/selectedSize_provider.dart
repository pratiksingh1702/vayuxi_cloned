import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedSizeProvider = StateProvider<String?>((ref) => null);

// NEW: unit provider
final selectedUnitProvider = StateProvider<String>((ref) => 'mm');
