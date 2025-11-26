// core/api/base_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/syncNotifierProvider.dart';


/// Extend this instead of StateNotifier<T>
/// so all notifiers auto-refresh after sync.
abstract class BaseNotifier<T> extends StateNotifier<T> {
  final Ref ref;

  BaseNotifier(this.ref, T state) : super(state) {
    // 👂 Listen for global sync events
    ref.listen<int>(syncNotifierProvider, (_, __) {
      onSync(); // will call your re-fetch logic
    });
  }

  /// Each child notifier implements its own refresh logic
  Future<void> onSync();
}
