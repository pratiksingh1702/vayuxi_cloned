import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../noti_services/noti_service.dart';
import '../noti_services/permi_service.dart';

// Service Providers
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

// State Providers
final notificationPermissionStateProvider = StateProvider<PermissionStatus>((ref) {
  return PermissionStatus.denied;
});

final scheduledNotificationsProvider = StateProvider<List<ScheduledNotification>>((ref) {
  return [];
});

// Notification State Provider
final notificationsStateProvider = StateNotifierProvider<NotificationsStateNotifier, NotificationsState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationsStateNotifier(notificationService);
});

// Models
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isActive;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.isActive = true,
  });

  ScheduledNotification copyWith({
    int? id,
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? isActive,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedTime {
    final time = DateTime(0, 0, 0, hour, minute);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// State Management
class NotificationsState {
  final bool isLoading;
  final List<ScheduledNotification> scheduledNotifications;
  final PermissionStatus permissionStatus;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.scheduledNotifications = const [],
    this.permissionStatus = PermissionStatus.denied,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<ScheduledNotification>? scheduledNotifications,
    PermissionStatus? permissionStatus,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      scheduledNotifications: scheduledNotifications ?? this.scheduledNotifications,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      error: error ?? this.error,
    );
  }
}

class NotificationsStateNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _notificationService;

  NotificationsStateNotifier(this._notificationService) : super(const NotificationsState());

  // Load all scheduled notifications
  Future<void> loadScheduledNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      // In a real app, you might load from local storage
      // For now, we'll return empty and populate via scheduling
      state = state.copyWith(
        isLoading: false,
        scheduledNotifications: [],
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $error',
      );
    }
  }

  // Schedule a new daily notification
  Future<bool> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      final success = await _notificationService.scheduleDailyNotification(
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );

      if (success) {
        // Add to local state
        final newNotification = ScheduledNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
        );

        state = state.copyWith(
          scheduledNotifications: [
            ...state.scheduledNotifications,
            newNotification,
          ],
        );
      }

      return success;
    } catch (error) {
      state = state.copyWith(error: 'Failed to schedule notification: $error');
      return false;
    }
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);

      state = state.copyWith(
        scheduledNotifications: state.scheduledNotifications
            .where((notification) => notification.id != id)
            .toList(),
      );
    } catch (error) {
      state = state.copyWith(error: 'Failed to cancel notification: $error');
    }
  }

  // Send instant notification
  Future<void> sendInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationService.sendInstantNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (error) {
      state = state.copyWith(error: 'Failed to send notification: $error');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Update permission status
  void updatePermissionStatus(PermissionStatus status) {
    state = state.copyWith(permissionStatus: status);
  }
}