import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/router/app_router.dart';
import '../../data/repositories/local_notification_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/services/action_dispatcher.dart';
import '../../domain/services/action_handler_registry.dart';
import 'notification_list_notifier.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => LocalNotificationRepository(),
);

final notificationListProvider =
    AsyncNotifierProvider<NotificationListNotifier, NotificationListState>(
  NotificationListNotifier.new,
);

final actionHandlerRegistryProvider = Provider<ActionHandlerRegistry>(
  (ref) => ActionHandlerRegistry.instance,
);

// Wire in your GoRouter instance from your main router provider
final actionDispatcherProvider = Provider<ActionDispatcher>((ref) {
  final registry = ref.read(actionHandlerRegistryProvider);
  final router = ref.read(appRouterProvider);
  return ActionDispatcher(router: router, registry: registry);
});

final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationListProvider);
  return state.maybeWhen(
    data: (s) => s.notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
