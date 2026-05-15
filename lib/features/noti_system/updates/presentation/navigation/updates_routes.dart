import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/noti_system/noti_settings/notification_settings_screen.dart';
import 'package:untitled2/features/noti_system/updates/presentation/screens/notification_detail_screen.dart';
import 'package:untitled2/features/noti_system/updates/presentation/screens/notification_list_screen.dart';
import '../../data/models/notification_model.dart';

abstract class UpdatesRoutes {
  static const list = '/updates';
  static const detail = '/updates/detail';
  static const settings = '/updates/settings';

  static void goDetail(BuildContext context, NotificationModel notification) {
    context.push(detail, extra: notification);
  }

  static void goSettings(BuildContext context) {
    context.push(settings);
  }

  static List<GoRoute> routes = [
    GoRoute(
      path: list,
      builder: (_, __) => const NotificationListScreen(),
    ),
    GoRoute(
      path: settings,
      builder: (_, __) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: detail,
      pageBuilder: (context, state) {
        final notification = state.extra as NotificationModel;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 750),
          reverseTransitionDuration: const Duration(milliseconds: 550),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: child,
            );
          },
          child: NotificationDetailScreen(notification: notification),
        );
      },
    ),
  ];
}
