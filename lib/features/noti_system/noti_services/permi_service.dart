import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check and request notification permission
  Future<PermissionStatus> checkAndRequestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      return await Permission.notification.request();
    }

    return status;
  }

  // Check current permission status
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    return await Permission.notification.status;
  }

  // Open app settings for permission management
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Check if permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}