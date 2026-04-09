import 'dart:async';

import '../datasources/mock_notification_data.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

class LocalNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _store = List.from(mockNotifications);
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  @override
  Future<List<NotificationModel>> fetchNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate network
    final start = page * limit;
    if (start >= _store.length) return [];
    return _store.sublist(start, (start + limit).clamp(0, _store.length));
  }

  @override
  Future<void> markAsRead(String id) async {
    final idx = _store.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _store[idx] = _store[idx].copyWith(isRead: true);
    _controller.add(List.from(_store));
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _store.length; i++) {
      _store[i] = _store[i].copyWith(isRead: true);
    }
    _controller.add(List.from(_store));
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    _store.insert(0, notification);
    _controller.add(List.from(_store));
  }

  @override
  Future<void> clearNotifications() async {
    _store.clear();
    _controller.add([]);
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() => _controller.stream;

  void dispose() => _controller.close();
}