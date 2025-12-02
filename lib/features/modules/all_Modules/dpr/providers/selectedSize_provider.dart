// providers/size_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the selected size state
final selectedSizeProvider = StateProvider<String?>((ref) => null);