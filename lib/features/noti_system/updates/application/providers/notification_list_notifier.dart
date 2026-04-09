import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import 'notification_providers.dart';

class NotificationListState {
  const NotificationListState({
    required this.notifications,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.currentPage = 0,
  });

  final List<NotificationModel> notifications;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final int currentPage;

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    int? currentPage,
  }) =>
      NotificationListState(
        notifications: notifications ?? this.notifications,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
        currentPage: currentPage ?? this.currentPage,
      );
}

class NotificationListNotifier
    extends AsyncNotifier<NotificationListState> {
  @override
  Future<NotificationListState> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    final items = await repo.fetchNotifications();
    return NotificationListState(notifications: items);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final repo = ref.read(notificationRepositoryProvider);
    final nextPage = current.currentPage + 1;
    final more = await repo.fetchNotifications(page: nextPage);

    state = AsyncData(current.copyWith(
      notifications: [...current.notifications, ...more],
      isLoadingMore: false,
      hasReachedEnd: more.isEmpty,
      currentPage: nextPage,
    ));
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      notifications: current.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    ));
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      notifications: current.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}