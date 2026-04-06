import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

enum AppToastType { success, info, error }

class AppToast {
  static void show(
      String message, {
        AppToastType type = AppToastType.info,
      }) {
    final bg = switch (type) {
      AppToastType.success => Colors.green.shade600,
      AppToastType.info => Colors.blue.shade600,
      AppToastType.error => Colors.red.shade600,

    };

    final icon = switch (type) {
      AppToastType.success => Icons.check_circle,
      AppToastType.info => Icons.info,
      AppToastType.error => Icons.error,
    };

    BotToast.showCustomNotification(
      duration: const Duration(seconds: 3),
      dismissDirections: [
        DismissDirection.horizontal,
        DismissDirection.down,
      ],
      align: Alignment.bottomCenter,
      toastBuilder: (cancelFunc) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          child: GestureDetector(
            onTap: cancelFunc, // ✅ tap to dismiss
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                      color: Colors.black26,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: cancelFunc, // ✅ close button dismiss
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void success(String msg) => show(msg, type: AppToastType.success);
  static void info(String msg) => show(msg, type: AppToastType.info);
  static void error(String msg) => show(msg, type: AppToastType.error);
}
