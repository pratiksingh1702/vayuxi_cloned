import '../actions/api_action.dart';
import '../actions/callback_action.dart';
import '../actions/external_link_action.dart';
import '../actions/navigate_action.dart';
import '../models/notification_media.dart';
import '../models/notification_model.dart';
import '../models/notification_priority.dart';
import '../models/notification_type.dart';

final mockNotifications = <NotificationModel>[
  NotificationModel(
    id: 'notif_001',
    type: NotificationType.update,
    title: 'App Update Available',
    description: 'Version 3.2.0 brings performance improvements and new features. Update now for the best experience.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    priority: NotificationPriority.high,
    isRead: false,
    actions: [
      NavigateAction(label: 'Update Now', route: '/settings/update', isPrimary: true),
      CallbackAction(label: 'Remind Later', handlerKey: 'snooze_update', payload: {'hours': 24}),
    ],
  ),
  NotificationModel(
    id: 'notif_002',
    type: NotificationType.promo,
    title: 'Exclusive Offer Just for You',
    description: 'Get 30% off on your next purchase. Limited time offer — expires in 48 hours.',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    priority: NotificationPriority.medium,
    isRead: false,
    media: const NotificationMedia(
      url: 'https://picsum.photos/seed/promo/800/400',
      type: NotificationMediaType.image,
      altText: 'Promotional banner',
    ),
    actions: [
      ExternalLinkAction(label: 'Claim Offer', url: 'https://example.com/offer', isPrimary: true),
    ],
  ),
  NotificationModel(
    id: 'notif_003',
    type: NotificationType.alert,
    title: 'Security Alert',
    description: 'A new sign-in was detected from Mumbai, India. If this was you, no action needed.',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    priority: NotificationPriority.high,
    isRead: false,
    actions: [
      NavigateAction(label: 'Review Activity', route: '/security/activity', isPrimary: true),
      ApiAction(label: 'Secure Account', endpoint: '/api/account/lock', isPrimary: false),
    ],
  ),
  NotificationModel(
    id: 'notif_004',
    type: NotificationType.transaction,
    title: 'Payment Successful',
    description: '₹2,499 was debited for Order #84729. Your order has been confirmed.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    priority: NotificationPriority.low,
    isRead: true,
    actions: [
      NavigateAction(label: 'View Order', route: '/orders/84729', params: {'orderId': '84729'}, isPrimary: true),
    ],
  ),
  NotificationModel(
    id: 'notif_005',
    type: NotificationType.system,
    title: 'Scheduled Maintenance',
    description: 'The app will be unavailable on Sunday, 2 AM–4 AM IST for scheduled maintenance.',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    priority: NotificationPriority.medium,
    isRead: true,
  ),
];