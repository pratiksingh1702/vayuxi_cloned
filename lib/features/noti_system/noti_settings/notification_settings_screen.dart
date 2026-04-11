import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
import 'package:untitled2/features/noti_system/noti_services/noti_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const int morningId = 73001;
  static const int eveningId = 193001;

  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String morningEnabledKey = 'morning_enabled';
  static const String morningHourKey = 'morning_hour';
  static const String morningMinuteKey = 'morning_minute';
  static const String eveningEnabledKey = 'evening_enabled';
  static const String eveningHourKey = 'evening_hour';
  static const String eveningMinuteKey = 'evening_minute';
  static const String customRemindersKey = 'custom_reminders_v1';

  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _morningEnabled = true;
  bool _eveningEnabled = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 19, minute: 30);
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  List<_CustomReminder> _customReminders = const [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionStatus = await Permission.notification.status;

    final rawCustom = prefs.getString(customRemindersKey);
    final custom = _decodeCustomReminders(rawCustom);

    setState(() {
      _notificationsEnabled = prefs.getBool(notificationsEnabledKey) ?? true;
      _morningEnabled = prefs.getBool(morningEnabledKey) ?? true;
      _eveningEnabled = prefs.getBool(eveningEnabledKey) ?? true;
      _morningTime = TimeOfDay(
        hour: prefs.getInt(morningHourKey) ?? 7,
        minute: prefs.getInt(morningMinuteKey) ?? 30,
      );
      _eveningTime = TimeOfDay(
        hour: prefs.getInt(eveningHourKey) ?? 19,
        minute: prefs.getInt(eveningMinuteKey) ?? 30,
      );
      _customReminders = custom;
      _permissionStatus = permissionStatus;
      _isLoading = false;
    });

    await _applyAllSchedules();
  }

  Future<void> _saveMainSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, _notificationsEnabled);
    await prefs.setBool(morningEnabledKey, _morningEnabled);
    await prefs.setBool(eveningEnabledKey, _eveningEnabled);
    await prefs.setInt(morningHourKey, _morningTime.hour);
    await prefs.setInt(morningMinuteKey, _morningTime.minute);
    await prefs.setInt(eveningHourKey, _eveningTime.hour);
    await prefs.setInt(eveningMinuteKey, _eveningTime.minute);
  }

  Future<void> _saveCustomReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      customRemindersKey,
      jsonEncode(_customReminders.map((e) => e.toJson()).toList()),
    );
  }

  List<_CustomReminder> _decodeCustomReminders(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_CustomReminder.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    setState(() => _permissionStatus = status);

    if (status.isGranted) {
      await _applyAllSchedules();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission granted.')),
      );
    }
  }

  Future<void> _applyAllSchedules() async {
    if (!_notificationsEnabled || !_permissionStatus.isGranted) {
      await _notificationService.cancelAllNotifications();
      return;
    }

    if (_morningEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: morningId,
        title: 'Morning Reminder',
        body: 'Takes 1 min - update today\'s attendance.',
        hour: _morningTime.hour,
        minute: _morningTime.minute,
      );
    } else {
      await _notificationService.cancelNotification(morningId);
    }

    if (_eveningEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: eveningId,
        title: 'Evening Reminder',
        body: 'Quick close: attendance, expenses, inventory and work update.',
        hour: _eveningTime.hour,
        minute: _eveningTime.minute,
      );
    } else {
      await _notificationService.cancelNotification(eveningId);
    }

    for (final reminder in _customReminders) {
      if (!reminder.enabled) {
        await _notificationService.cancelNotification(reminder.id);
        continue;
      }

      await _notificationService.scheduleDailyNotification(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }
  }

  Future<void> _pickTime({required bool isMorning}) async {
    final initial = isMorning ? _morningTime : _eveningTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF174A94),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isMorning) {
        _morningTime = picked;
      } else {
        _eveningTime = picked;
      }
    });

    await _saveMainSettings();
    await _applyAllSchedules();
  }

  Future<void> _addOrEditCustomReminder({
    _CustomReminder? existing,
    int? index,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    TimeOfDay selectedTime = TimeOfDay(
      hour: existing?.hour ?? 9,
      minute: existing?.minute ?? 0,
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Add Custom Reminder' : 'Edit Reminder',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF132847),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked == null) return;
                      setModalState(() => selectedTime = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD9EF)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Time: ${_formatTime(selectedTime)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty ||
                                bodyController.text.trim().isEmpty) {
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final updated = _CustomReminder(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: titleController.text.trim(),
      body: bodyController.text.trim(),
      hour: selectedTime.hour,
      minute: selectedTime.minute,
      enabled: existing?.enabled ?? true,
    );

    setState(() {
      final list = [..._customReminders];
      if (index != null) {
        list[index] = updated;
      } else {
        list.add(updated);
      }
      _customReminders = list;
    });

    await _saveCustomReminders();
    await _applyAllSchedules();
  }

  Future<void> _toggleCustom(int index, bool value) async {
    final updated = [..._customReminders];
    updated[index] = updated[index].copyWith(enabled: value);
    setState(() => _customReminders = updated);
    await _saveCustomReminders();
    await _applyAllSchedules();
  }

  Future<void> _deleteCustom(int index) async {
    final reminder = _customReminders[index];
    final updated = [..._customReminders]..removeAt(index);
    setState(() => _customReminders = updated);
    await _notificationService.cancelNotification(reminder.id);
    await _saveCustomReminders();
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.sendInstantNotification(
      title: 'Test Notification',
      body: 'Your premium notification settings are active.',
      channelId: 'immediate_notifications',
      channelName: 'Instant Notifications',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent.')),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: PremiumAppBar(
        title: 'Notification Settings',
        showDrawerButton: false,
        subtitle: const Text('Personalize reminders and alerts'),
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F8FF), Color(0xFFE8F1FF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              _SectionCard(
                title: 'Global Control',
                icon: Icons.notifications_rounded,
                children: [
                  _SettingSwitchTile(
                    title: 'Enable Notifications',
                    subtitle: _permissionStatus.isGranted
                        ? 'Notifications are allowed on this device.'
                        : 'Permission required to show notifications.',
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await _saveMainSettings();
                      await _applyAllSchedules();
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!_permissionStatus.isGranted)
                    ElevatedButton.icon(
                      onPressed: _requestPermission,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Allow Notification Permission'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Send Test Notification'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Daily Reminders',
                icon: Icons.wb_sunny_rounded,
                children: [
                  _TimeSettingTile(
                    title: 'Morning Reminder',
                    subtitle: 'Attendance quick update',
                    timeLabel: _formatTime(_morningTime),
                    enabled: _morningEnabled,
                    onToggle: (value) async {
                      setState(() => _morningEnabled = value);
                      await _saveMainSettings();
                      await _applyAllSchedules();
                    },
                    onPickTime: () => _pickTime(isMorning: true),
                  ),
                  const SizedBox(height: 10),
                  _TimeSettingTile(
                    title: 'Evening Reminder',
                    subtitle: 'Daily close and update checklist',
                    timeLabel: _formatTime(_eveningTime),
                    enabled: _eveningEnabled,
                    onToggle: (value) async {
                      setState(() => _eveningEnabled = value);
                      await _saveMainSettings();
                      await _applyAllSchedules();
                    },
                    onPickTime: () => _pickTime(isMorning: false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Custom Reminders',
                icon: Icons.edit_calendar_rounded,
                trailing: IconButton(
                  onPressed: () => _addOrEditCustomReminder(),
                  icon: const Icon(Icons.add_circle_rounded,
                      color: Color(0xFF1A4E96)),
                ),
                children: [
                  if (_customReminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No custom reminders yet. Add one to get started.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5C708E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ...List.generate(_customReminders.length, (index) {
                      final reminder = _customReminders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CustomReminderCard(
                          reminder: reminder,
                          onToggle: (value) => _toggleCustom(index, value),
                          onEdit: () => _addOrEditCustomReminder(
                              existing: reminder, index: index),
                          onDelete: () => _deleteCustom(index),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A4E96), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF223A5F),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD4E1F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF213755),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D7191),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TimeSettingTile extends StatelessWidget {
  const _TimeSettingTile({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.enabled,
    required this.onToggle,
    required this.onPickTime,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD4E1F5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF213755),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5D7191),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: enabled ? onPickTime : null,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: enabled ? Colors.white : const Color(0xFFF1F4F9),
                border: Border.all(color: const Color(0xFFCCD9EE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: Color(0xFF3A5F95)),
                  const SizedBox(width: 8),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? const Color(0xFF1D3B67)
                          : const Color(0xFF8796AE),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: enabled
                        ? const Color(0xFF1A4E96)
                        : const Color(0xFF9AA7BC),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomReminder {
  const _CustomReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.enabled,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool enabled;

  _CustomReminder copyWith({
    int? id,
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return _CustomReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  factory _CustomReminder.fromJson(Map<String, dynamic> json) {
    return _CustomReminder(
      id: (json['id'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: json['title']?.toString() ?? 'Custom Reminder',
      body: json['body']?.toString() ?? '',
      hour: (json['hour'] as num?)?.toInt() ?? 9,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _CustomReminderCard extends StatelessWidget {
  const _CustomReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _CustomReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD4E1F5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 18, color: Color(0xFF2E5A9A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF213755),
                  ),
                ),
              ),
              Switch.adaptive(
                value: reminder.enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  reminder.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D7191),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4E96).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reminder.formattedTime,
                  style: const TextStyle(
                    color: Color(0xFF1A4E96),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: const Color(0xFF2E5A9A),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: const Color(0xFFB44242),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
