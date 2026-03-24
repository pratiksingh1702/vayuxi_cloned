import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/boq_model.dart';

import '../providers/boq_provider.dart';


// ─────────────────────────────────────────────────────────────────────────────
// BOQ SETTINGS SCREEN
// Full notification preferences UI
// ─────────────────────────────────────────────────────────────────────────────

class BoqSettingsScreen extends ConsumerWidget {
  final String siteId;
  const BoqSettingsScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final statsAsync = ref.watch(notificationStatsProvider);

    return prefsAsync.when(
      loading: () =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 8),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(notificationPreferencesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (prefs) => _NotificationSettingsForm(
        prefs: prefs,
        siteId: siteId,
        statsAsync: statsAsync,
      ),
    );
  }
}

class _NotificationSettingsForm extends ConsumerStatefulWidget {
  final NotificationPreferences prefs;
  final String siteId;
  final AsyncValue<NotificationStats> statsAsync;

  const _NotificationSettingsForm({
    required this.prefs,
    required this.siteId,
    required this.statsAsync,
  });

  @override
  ConsumerState<_NotificationSettingsForm> createState() =>
      _NotificationSettingsFormState();
}

class _NotificationSettingsFormState
    extends ConsumerState<_NotificationSettingsForm> {
  // Mutable local copies of prefs
  late bool _enabled;
  late String _frequency;
  late String _time;
  late List<String> _weeklyDays;
  late int _monthlyDate;
  late String _templateMode;

  // Thresholds
  late double _onTrackMin;
  late double _onTrackMax;
  late double _behindThreshold;
  late double _criticalThreshold;
  late double _aheadThreshold;
  late double _excellentAheadThreshold;

  // Send conditions
  late bool _sendOnlyIfChanged;
  late bool _sendOnlyIfBehind;
  late bool _sendOnlyIfCritical;
  late double _minVariance;
  late bool _sendOnWeekends;
  late bool _sendOnHolidays;

  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFromPrefs(widget.prefs);
  }

  void _loadFromPrefs(NotificationPreferences prefs) {
    final g = prefs.globalSettings;
    _enabled = g.enabled;
    _frequency = g.schedule.frequency;
    _time = g.schedule.time;
    _timeController.text = _time;
    _weeklyDays = List.from(g.schedule.weeklyDays ?? []);
    _monthlyDate = g.schedule.monthlyDate ?? 1;
    _templateMode = g.templateSelection.mode;

    _onTrackMin = g.customThresholds.onTrackMin;
    _onTrackMax = g.customThresholds.onTrackMax;
    _behindThreshold = g.customThresholds.behindThreshold;
    _criticalThreshold = g.customThresholds.criticalBehindThreshold;
    _aheadThreshold = g.customThresholds.aheadThreshold;
    _excellentAheadThreshold = g.customThresholds.excellentAheadThreshold;

    _sendOnlyIfChanged = g.sendConditions.sendOnlyIfChanged;
    _sendOnlyIfBehind = g.sendConditions.sendOnlyIfBehind;
    _sendOnlyIfCritical = g.sendConditions.sendOnlyIfCritical;
    _minVariance = g.sendConditions.minimumVarianceToSend;
    _sendOnWeekends = g.sendConditions.sendOnWeekends;
    _sendOnHolidays = g.sendConditions.sendOnHolidays;
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'enabled': _enabled,
      'templateSelection': {
        'mode': _templateMode,
        'allowAutoSwitch': _templateMode == 'auto',
      },
      'schedule': {
        'frequency': _frequency,
        'time': _time,
        'timezone': 'Asia/Kolkata',
        if (_frequency == 'weekly' && _weeklyDays.isNotEmpty)
          'weeklyDays': _weeklyDays,
        if (_frequency == 'monthly') 'monthlyDate': _monthlyDate,
      },
      'customThresholds': {
        'onTrackMin': _onTrackMin,
        'onTrackMax': _onTrackMax,
        'behindThreshold': _behindThreshold,
        'criticalBehindThreshold': _criticalThreshold,
        'aheadThreshold': _aheadThreshold,
        'excellentAheadThreshold': _excellentAheadThreshold,
      },
      'sendConditions': {
        'sendOnlyIfChanged': _sendOnlyIfChanged,
        'sendOnlyIfBehind': _sendOnlyIfBehind,
        'sendOnlyIfCritical': _sendOnlyIfCritical,
        'minimumVarianceToSend': _minVariance,
        'sendOnWeekends': _sendOnWeekends,
        'sendOnHolidays': _sendOnHolidays,
      },
    };
  }

  Future<void> _save() async {
    await ref.read(savePrefsProvider.notifier).save(_buildPayload());
    ref.invalidate(notificationPreferencesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification preferences saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _sendTest() async {
    await ref.read(savePrefsProvider.notifier).sendTest();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Test notification sent via WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reset() async {
    await ref.read(boqApiServiceProvider).resetNotificationPreferences();
    ref.invalidate(notificationPreferencesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to defaults'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(savePrefsProvider);
    final isSaving = saveState is AsyncLoading;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats banner ────────────────────────────────────────────
              widget.statsAsync.whenOrNull(
                data: (stats) => _StatsBanner(stats: stats),
              ) ??
                  const SizedBox.shrink(),

              const SizedBox(height: 16),

              // ── Master toggle ───────────────────────────────────────────
              _SettingsCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Notifications',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF111827)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive BOQ progress updates on WhatsApp',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),

              if (_enabled) ...[
                const SizedBox(height: 16),

                // ── Schedule ──────────────────────────────────────────────
                _SectionHeader('Schedule', icon: Icons.schedule_outlined),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Frequency
                      _FieldLabel('Frequency'),
                      const SizedBox(height: 8),
                      _SegmentRow(
                        options: const [
                          ('Daily', 'daily'),
                          ('Weekly', 'weekly'),
                          ('Monthly', 'monthly'),
                        ],
                        selected: _frequency,
                        onChanged: (v) => setState(() => _frequency = v),
                      ),

                      const SizedBox(height: 14),

                      // Time
                      _FieldLabel('Notification Time'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final parts = _time.split(':');
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.tryParse(parts[0]) ?? 20,
                              minute: int.tryParse(parts[1]) ?? 30,
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _time =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              _timeController.text = _time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 18, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Text(
                                _time,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827)),
                              ),
                              const Spacer(),
                              const Text('Tap to change',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                      ),

                      // Weekly days
                      if (_frequency == 'weekly') ...[
                        const SizedBox(height: 14),
                        _FieldLabel('Send on days'),
                        const SizedBox(height: 8),
                        _WeekdayPicker(
                          selected: _weeklyDays,
                          onChanged: (days) =>
                              setState(() => _weeklyDays = days),
                        ),
                      ],

                      // Monthly date
                      if (_frequency == 'monthly') ...[
                        const SizedBox(height: 14),
                        _FieldLabel('Send on day of month'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Day $_monthlyDate',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 180,
                              child: Slider(
                                value: _monthlyDate.toDouble(),
                                min: 1,
                                max: 28,
                                divisions: 27,
                                label: '$_monthlyDate',
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (v) =>
                                    setState(() => _monthlyDate = v.toInt()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Template ──────────────────────────────────────────────
                _SectionHeader('Template Mode', icon: Icons.auto_awesome_outlined),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SegmentRow(
                        options: const [
                          ('Auto', 'auto'),
                          ('Single Site', 'single_site'),
                          ('Multi Site', 'multi_site'),
                        ],
                        selected: _templateMode,
                        onChanged: (v) => setState(() => _templateMode = v),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _templateModeDesc(_templateMode),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Thresholds ─────────────────────────────────────────────
                _SectionHeader('Status Thresholds (%)',
                    icon: Icons.tune_outlined),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    children: [
                      _ThresholdSlider(
                        label: 'On Track Min',
                        value: _onTrackMin,
                        min: -20,
                        max: 0,
                        color: const Color(0xFF059669),
                        onChanged: (v) =>
                            setState(() => _onTrackMin = v),
                      ),
                      _ThresholdSlider(
                        label: 'On Track Max',
                        value: _onTrackMax,
                        min: 0,
                        max: 20,
                        color: const Color(0xFF059669),
                        onChanged: (v) =>
                            setState(() => _onTrackMax = v),
                      ),
                      _ThresholdSlider(
                        label: 'Behind Threshold',
                        value: _behindThreshold,
                        min: -30,
                        max: -1,
                        color: const Color(0xFFF59E0B),
                        onChanged: (v) =>
                            setState(() => _behindThreshold = v),
                      ),
                      _ThresholdSlider(
                        label: 'Critical Behind',
                        value: _criticalThreshold,
                        min: -50,
                        max: -5,
                        color: const Color(0xFFEF4444),
                        onChanged: (v) =>
                            setState(() => _criticalThreshold = v),
                      ),
                      _ThresholdSlider(
                        label: 'Ahead Threshold',
                        value: _aheadThreshold,
                        min: 1,
                        max: 30,
                        color: const Color(0xFF2563EB),
                        onChanged: (v) =>
                            setState(() => _aheadThreshold = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Send conditions ────────────────────────────────────────
                _SectionHeader('Send Conditions',
                    icon: Icons.filter_list_outlined),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    children: [
                      _ConditionToggle(
                        label: 'Only if status changed',
                        subtitle: 'Skip if same as last notification',
                        value: _sendOnlyIfChanged,
                        onChanged: (v) =>
                            setState(() => _sendOnlyIfChanged = v),
                      ),
                      _ConditionToggle(
                        label: 'Only if behind schedule',
                        subtitle: 'Skip on-track and ahead notifications',
                        value: _sendOnlyIfBehind,
                        onChanged: (v) =>
                            setState(() => _sendOnlyIfBehind = v),
                      ),
                      _ConditionToggle(
                        label: 'Only critical alerts',
                        subtitle: 'Send only when critically behind',
                        value: _sendOnlyIfCritical,
                        onChanged: (v) =>
                            setState(() => _sendOnlyIfCritical = v),
                      ),
                      const Divider(height: 20),
                      _FieldLabel(
                          'Min Variance to Send: ${_minVariance.toStringAsFixed(0)}%'),
                      Slider(
                        value: _minVariance,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        label: '${_minVariance.toStringAsFixed(0)}%',
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) =>
                            setState(() => _minVariance = v),
                      ),
                      const Divider(height: 20),
                      _ConditionToggle(
                        label: 'Send on weekends',
                        value: _sendOnWeekends,
                        onChanged: (v) =>
                            setState(() => _sendOnWeekends = v),
                      ),
                      _ConditionToggle(
                        label: 'Send on holidays',
                        value: _sendOnHolidays,
                        onChanged: (v) =>
                            setState(() => _sendOnHolidays = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── History ───────────────────────────────────────────────
                _NotificationHistorySection(),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),

        // ── Floating action bar ─────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Test button
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _sendTest,
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset button
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _reset,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Save button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _save,
                    icon: isSaving
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Preferences',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _templateModeDesc(String mode) {
    switch (mode) {
      case 'single_site':
        return 'Always use single-site template regardless of site count';
      case 'multi_site':
        return 'Always use multi-site consolidated template';
      default:
        return 'System auto-picks best template based on your sites & BOQs';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION HISTORY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationHistorySection extends ConsumerWidget {
  const _NotificationHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Recent Notifications',
            icon: Icons.history_outlined),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB))),
          error: (e, _) => const SizedBox.shrink(),
          data: (history) {
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No notifications sent yet',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              );
            }
            return Column(
              children: history.take(5).map((h) => _HistoryItem(item: h)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final NotificationHistoryItem item;
  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == 'sent' || item.status == 'delivered'
        ? const Color(0xFF059669)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDate(item.sentAt ?? item.date),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
                if (item.snapshot != null)
                  Text(
                    'Progress: ${item.snapshot!.progressPercent.toStringAsFixed(1)}%'
                        ' | Variance: ${item.snapshot!.variance.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),
          Text(
            item.status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SETTINGS WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final NotificationStats stats;
  const _StatsBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              label: 'Sent',
              value: '${stats.totalSent}',
              icon: Icons.send),
          _StatItem(
              label: 'Delivered',
              value: '${stats.delivered}',
              icon: Icons.check),
          _StatItem(
              label: 'Failed',
              value: '${stats.failed}',
              icon: Icons.error_outline),
          _StatItem(
              label: 'Critical',
              value: '${stats.byStatus['critical'] ?? 0}',
              icon: Icons.warning_amber_outlined),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
      ],
    );
  }
}

Widget _FieldLabel(String label) => Text(
  label,
  style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151)),
);

class _SegmentRow extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final void Function(String) onChanged;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.$2;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$2),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt.$1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final List<String> selected;
  final void Function(List<String>) onChanged;

  const _WeekdayPicker(
      {required this.selected, required this.onChanged});

  static const _days = [
    ('M', 'monday'),
    ('T', 'tuesday'),
    ('W', 'wednesday'),
    ('T', 'thursday'),
    ('F', 'friday'),
    ('S', 'saturday'),
    ('S', 'sunday'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((d) {
        final isSelected = selected.contains(d.$2);
        return GestureDetector(
          onTap: () {
            final copy = List<String>.from(selected);
            isSelected ? copy.remove(d.$2) : copy.add(d.$2);
            onChanged(copy);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Center(
              child: Text(
                d.$1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color color;
  final void Function(double) onChanged;

  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min).abs()).toInt(),
              label: '${value.toStringAsFixed(0)}%',
              activeColor: color,
              inactiveColor: color.withOpacity(0.2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${value.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionToggle extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _ConditionToggle({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151))),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}