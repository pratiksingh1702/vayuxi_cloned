import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../rate/data/rate_file_uplaod_model.dart' hide UploadStatus;
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import '../../../../tour/definitions/setup_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../models/boq_model.dart';
import '../providers/boq_provider.dart';


// ─────────────────────────────────────────────────────────────────────────────
// BOQ ADD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class BoqAddScreen extends ConsumerStatefulWidget {
  final String siteId;
  const BoqAddScreen({super.key, required this.siteId});

  @override
  ConsumerState<BoqAddScreen> createState() => _BoqAddScreenState();
}

class _BoqAddScreenState extends ConsumerState<BoqAddScreen> with ScreenOwnedTourMixin<BoqAddScreen> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final GlobalKey _modeTourKey = GlobalKey(debugLabel: 'boq_mode_picker');
  String? _lastShowcasedTourStepId;
  String _entryMode = 'excel';

  void _syncBoqPickerTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}_picker',
      title: 'BOQ Upload',
      description: 'Choose how BOQ data should be added.',
      icon: Icons.table_rows_rounded,
      steps: [
        const AppTourStep(
          id: 'boq_picker_intro',
          title: 'BOQ Upload',
          body:
              'Use this screen to add BOQ data from Excel or by typing the details manually.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'boq_picker_mode',
          title: 'Choose Add Method',
          body:
              'Select Upload Excel when you have a BOQ sheet. Select Manual Entry when you want to create BOQ totals or items directly.',
          targetKey: _modeTourKey,
          progressLabel: 'Method',
        ),
      ],
    );

    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.boqUploadId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(typeProvider);
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncBoqPickerTour(showcaseContext);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you like to add BOQ?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              _tourTarget(
                _modeTourKey,
                Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.upload_file_outlined,
                        title: 'Upload Excel',
                        subtitle: 'Import from .xlsx / .xls',
                        selected: _entryMode == 'excel',
                        onTap: () => setState(() => _entryMode = 'excel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.edit_note_outlined,
                        title: 'Manual Entry',
                        subtitle: 'Fill form manually',
                        selected: _entryMode == 'manual',
                        onTap: () => setState(() => _entryMode = 'manual'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_entryMode == 'excel')
                _ExcelUploadSection(
                  siteId: widget.siteId,
                  preselectedType: selectedType,
                )
              else
                _ManualEntrySection(
                  siteId: widget.siteId,
                  preselectedType: selectedType,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE STATE
//
// API (Phase 3) accepts:
//   timeline.startDate           → "2026-03-20"      (required)
//   timeline.endDate             → "2026-04-20"      (required)
//   timeline.distributionMethod  → "equal"|"weighted"|"custom"  (required)
//   timeline.workingDays         → ["monday",...]    (optional, default Mon-Sat)
//   timeline.holidays            → ["2026-03-26"...] (optional)
//
// For upload (multipart): timeline is sent as a JSON *string*
// For manual (JSON body): timeline is sent as a JSON *object*
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineState {
  bool enabled;
  DateTime? startDate;
  DateTime? endDate;
  String distributionMethod;
  List<String> workingDays;
  List<DateTime> holidays;

  _TimelineState({
    this.enabled = false,
    this.startDate,
    this.endDate,
    this.distributionMethod = 'equal',
    List<String>? workingDays,
    List<DateTime>? holidays,
  })  : workingDays = workingDays ??
      ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
        holidays = holidays ?? [];

  /// Returns the timeline as a Map for JSON body requests (manual BOQ).
  Map<String, dynamic>? toApiPayload() {
    if (!enabled || startDate == null || endDate == null) return null;
    final payload = <String, dynamic>{
      'startDate': DateFormat('yyyy-MM-dd').format(startDate!),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate!),
      'distributionMethod': distributionMethod,
      'workingDays': workingDays,
    };
    if (holidays.isNotEmpty) {
      payload['holidays'] =
          holidays.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    }
    return payload;
  }

  /// Returns the timeline as a JSON *string* for multipart/form-data upload.
  String? toApiJsonString() {
    final payload = toApiPayload();
    if (payload == null) return null;
    return jsonEncode(payload);
  }

  bool get isValid =>
      !enabled ||
          (startDate != null &&
              endDate != null &&
              endDate!.isAfter(startDate!));
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE SECTION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineSection extends StatefulWidget {
  final _TimelineState state;
  final VoidCallback onChanged;

  const _TimelineSection({
    required this.state,
    required this.onChanged,
  });

  @override
  State<_TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<_TimelineSection> {
  static const _days = [
    ('Mon', 'monday'),
    ('Tue', 'tuesday'),
    ('Wed', 'wednesday'),
    ('Thu', 'thursday'),
    ('Fri', 'friday'),
    ('Sat', 'saturday'),
    ('Sun', 'sunday'),
  ];

  static const _methods = [
    (
    value: 'equal',
    label: 'Equal Distribution',
    desc: 'Work spread evenly across all working days',
    icon: Icons.balance_outlined,
    ),
    (
    value: 'weighted',
    label: 'Weighted (Front-loaded)',
    desc: 'Earlier days get slightly more target quantity',
    icon: Icons.trending_down_outlined,
    ),
    (
    value: 'custom',
    label: 'Custom',
    desc: 'Set per-day targets manually after creation',
    icon: Icons.tune_outlined,
    ),
  ];

  void _mutate(void Function() fn) {
    setState(fn);
    widget.onChanged();
  }

  Future<void> _pickDate(bool isStart) async {
    final s = widget.state;
    final now = DateTime.now();
    final initial = isStart
        ? (s.startDate ?? now)
        : (s.endDate ?? now.add(const Duration(days: 30)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563EB),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    _mutate(() {
      if (isStart) {
        s.startDate = picked;
        if (s.endDate != null && !s.endDate!.isAfter(picked)) {
          s.endDate = picked.add(const Duration(days: 30));
        }
      } else {
        s.endDate = picked;
      }
    });
  }

  Future<void> _addHoliday() async {
    final s = widget.state;
    final picked = await showDatePicker(
      context: context,
      initialDate: s.startDate ?? DateTime.now(),
      firstDate: s.startDate ?? DateTime(2020),
      lastDate: s.endDate ?? DateTime(2030),
      helpText: 'Select Holiday Date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEF4444),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (s.holidays.any((h) =>
    h.year == picked.year &&
        h.month == picked.month &&
        h.day == picked.day)) return; // duplicate
    _mutate(() => s.holidays.add(picked));
  }

  int _workingDayCount() {
    final s = widget.state;
    if (s.startDate == null || s.endDate == null) return 0;
    const dayMap = {
      1: 'monday', 2: 'tuesday', 3: 'wednesday',
      4: 'thursday', 5: 'friday', 6: 'saturday', 7: 'sunday',
    };
    final holidaySet = s.holidays
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet();
    int count = 0;
    var cur = s.startDate!;
    while (!cur.isAfter(s.endDate!)) {
      final key = '${cur.year}-${cur.month}-${cur.day}';
      if (s.workingDays.contains(dayMap[cur.weekday]) &&
          !holidaySet.contains(key)) count++;
      cur = cur.add(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dateError = s.startDate != null &&
        s.endDate != null &&
        !s.endDate!.isAfter(s.startDate!);
    final fmt = DateFormat('d MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toggle header ────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: s.enabled
                ? const Color(0xFF2563EB).withOpacity(0.06)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.enabled
                  ? const Color(0xFF2563EB).withOpacity(0.35)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: s.enabled
                      ? const Color(0xFF2563EB).withOpacity(0.12)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: s.enabled
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Timeline  (optional)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827)),
                    ),
                    Text(
                      s.enabled
                          ? 'DPR entries will auto-update daily progress'
                          : 'Track BOQ progress against daily targets',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: s.enabled,
                onChanged: (v) => _mutate(() => s.enabled = v),
                activeColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ),

        // ── Expanded content ─────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: s.enabled
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date pickers ──────────────────────────────────────────
                _boqFieldLabel('Start Date & End Date *'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerTile(
                        label: 'Start Date',
                        date: s.startDate,
                        hint: 'Pick start',
                        isError: false,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: s.startDate != null && s.endDate != null
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    Expanded(
                      child: _DatePickerTile(
                        label: 'End Date',
                        date: s.endDate,
                        hint: 'Pick end',
                        isError: dateError,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),

                // ── Duration badge ────────────────────────────────────────
                if (s.startDate != null && s.endDate != null && !dateError) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Text(
                          '${_workingDayCount()} working days  •  '
                              '${DateFormat("d MMM").format(s.startDate!)} – '
                              '${DateFormat("d MMM yyyy").format(s.endDate!)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],

                if (dateError) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text('End date must be after start date',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFEF4444))),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                // ── Distribution method ───────────────────────────────────
                _boqFieldLabel('Distribution Method'),
                const SizedBox(height: 10),
                ..._methods.map((m) {
                  final isSelected = s.distributionMethod == m.value;
                  return GestureDetector(
                    onTap: () =>
                        _mutate(() => s.distributionMethod = m.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB).withOpacity(0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                size: 11, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            m.icon,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  m.desc,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // ── Working days ──────────────────────────────────────────
                _boqFieldLabel('Working Days'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((d) {
                    final isSelected = s.workingDays.contains(d.$2);
                    return GestureDetector(
                      onTap: () {
                        _mutate(() {
                          if (isSelected) {
                            if (s.workingDays.length > 1) {
                              s.workingDays.remove(d.$2);
                            }
                          } else {
                            s.workingDays.add(d.$2);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Holidays ──────────────────────────────────────────────
                Row(
                  children: [
                    _boqFieldLabel('Holidays (optional)'),
                    const Spacer(),
                    if (s.startDate != null && s.endDate != null)
                      GestureDetector(
                        onTap: _addHoliday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 14, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text('Add',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (s.holidays.isEmpty)
                  Text(
                    s.startDate == null
                        ? 'Set start & end dates first to add holidays'
                        : 'No holidays added — tap Add to mark a holiday',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: s.holidays.map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy_outlined,
                                size: 13, color: Color(0xFFEF4444)),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat('d MMM').format(h),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626)),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _mutate(() => s.holidays.remove(h)),
                              child: const Icon(Icons.close,
                                  size: 13, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String hint;
  final bool isError;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.hint,
    required this.isError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _boqFieldLabel(label),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isError
                    ? const Color(0xFFEF4444)
                    : date != null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: date != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: isError
                      ? const Color(0xFFEF4444)
                      : date != null
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null ? fmt.format(date!) : hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: date != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isError
                          ? const Color(0xFFEF4444)
                          : date != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// MODE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXCEL UPLOAD SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ExcelUploadSection extends ConsumerStatefulWidget {
  final String siteId;
  final String? preselectedType;
  const _ExcelUploadSection({required this.siteId, this.preselectedType});

  @override
  ConsumerState<_ExcelUploadSection> createState() =>
      _ExcelUploadSectionState();
}

class _ExcelUploadSectionState extends ConsumerState<_ExcelUploadSection> with ScreenOwnedTourMixin<_ExcelUploadSection> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final GlobalKey _typeTourKey = GlobalKey(debugLabel: 'boq_excel_type');
  final GlobalKey _nameTourKey = GlobalKey(debugLabel: 'boq_excel_name');
  final GlobalKey _fileTourKey = GlobalKey(debugLabel: 'boq_excel_file');
  final GlobalKey _timelineTourKey =
      GlobalKey(debugLabel: 'boq_excel_timeline');
  final GlobalKey _uploadTourKey = GlobalKey(debugLabel: 'boq_excel_upload');
  String? _lastShowcasedTourStepId;
  PlatformFile? _pickedFile;
  String _type = 'mechanical_work';
  final _nameController = TextEditingController();
  final _timeline = _TimelineState();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) _type = widget.preselectedType!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      _showSnack('Please select an Excel file first');
      return;
    }
    if (!_timeline.isValid) {
      _showSnack('End date must be after start date');
      return;
    }
    await ref.read(uploadBoqProvider.notifier).uploadExcel(
      siteId: widget.siteId,
      file: _pickedFile!,
      type: _type,
      boqName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      // Upload uses multipart: pass JSON string
      timelineJsonString: _timeline.toApiJsonString(),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _syncExcelTour(BuildContext showcaseContext, UploadStatus status) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}_excel',
      title: 'Upload BOQ Excel',
      description: 'Learn how to upload BOQ from Excel.',
      icon: Icons.upload_file_rounded,
      steps: [
        const AppTourStep(
          id: 'boq_excel_intro',
          title: 'Upload BOQ Excel',
          body:
              'Use this option when your BOQ is already prepared in an Excel file.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'boq_excel_type',
          title: 'BOQ Type',
          body:
              'Choose Mechanical or Insulation so the app reads the Excel columns in the correct format.',
          targetKey: _typeTourKey,
          progressLabel: 'Type',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_excel_name',
          title: 'BOQ Name',
          body:
              'You can give this BOQ a clear name. If you leave it blank, the file name can be used.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_excel_file',
          title: 'Excel File',
          body:
              'Tap here to select the .xlsx or .xls BOQ file from your device.',
          targetKey: _fileTourKey,
          progressLabel: 'File',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_excel_timeline',
          title: 'Timeline',
          body:
              'Turn this on if you want the BOQ quantity to be planned across dates for daily progress tracking.',
          targetKey: _timelineTourKey,
          progressLabel: 'Timeline',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_excel_upload',
          title: 'Upload BOQ',
          body:
              'Tap this button after selecting the file. The app will upload and check the BOQ data.',
          targetKey: _uploadTourKey,
          progressLabel: 'Upload',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );

    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || status == UploadStatus.uploading) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.boqUploadId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadBoqProvider);
    ref.watch(appTourControllerProvider);

    ref.listen(uploadBoqProvider, (prev, next) {
      if (next.status == UploadStatus.success) {
        _showSnack('✅ BOQ uploaded successfully!');
        ref.read(boqListParamsProvider.notifier).state =
            BoqListParams(siteId: widget.siteId);
        ref.read(uploadBoqProvider.notifier).reset();
        setState(() => _pickedFile = null);
      } else if (next.status == UploadStatus.error) {
        _showSnack('❌ ${next.errorMessage ?? 'Upload failed'}');
      }
    });

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncExcelTour(showcaseContext, uploadState.status);
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tourTarget(
          _typeTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boqFieldLabel('BOQ Type'),
              const SizedBox(height: 8),
              _TypeToggle(
                  selected: _type,
                  onChanged: (t) => setState(() => _type = t)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _tourTarget(
          _nameTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boqFieldLabel('BOQ Name (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _boqInputDecoration(
                    'Auto-generated from filename if left empty'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _tourTarget(
          _fileTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boqFieldLabel('Excel File'),
              const SizedBox(height: 8),
              _FilePicker(file: _pickedFile, onPick: _pickFile),
              const SizedBox(height: 12),
              _TemplateHint(type: _type),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Timeline ──────────────────────────────────────────────────────
        _tourTarget(
          _timelineTourKey,
          _TimelineSection(
            state: _timeline,
            onChanged: () => setState(() {}),
          ),
        ),

        const SizedBox(height: 24),

        _tourTarget(
          _uploadTourKey,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              uploadState.status == UploadStatus.uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: uploadState.status == UploadStatus.uploading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                uploadState.status == UploadStatus.uploading
                    ? 'Uploading...'
                    : 'Upload BOQ',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        if (uploadState.status == UploadStatus.success &&
            uploadState.summary != null)
          _UploadSummaryCard(summary: uploadState.summary!),
      ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILE PICKER WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onPick;
  const _FilePicker({this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? const Color(0xFF059669)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: file != null
                    ? const Color(0xFF059669).withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                file != null
                    ? Icons.insert_drive_file_outlined
                    : Icons.upload_file_outlined,
                color: file != null
                    ? const Color(0xFF059669)
                    : const Color(0xFF6B7280),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file != null ? file!.name : 'Tap to select file',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: file != null
                            ? const Color(0xFF111827)
                            : const Color(0xFF6B7280)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  file != null
                      ? Text(
                      '${(file!.size / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)))
                      : const Text('.xlsx or .xls format',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TemplateHint extends StatelessWidget {
  final String type;
  const _TemplateHint({required this.type});

  @override
  Widget build(BuildContext context) {
    final isMech = type == 'mechanical_work';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMech
                  ? 'Columns: Sr No, Material Name, Size (Inch), Quantity (Nos), Length (Meter), Inch Dia, Inch Mtr, Remarks'
                  : 'Columns: Sr. No., Material Name, Size, Size UOM, Qty, Layer, Legging Material 1/2/3, Thickness 1/2/3, Cladding Material, Cladding SWG, User RMT, User Area, Remarks',
              style:
              const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSummaryCard extends StatelessWidget {
  final BoqUploadSummary summary;
  const _UploadSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
          SizedBox(width: 6),
          Text('Upload Summary',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                  fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        _SummaryRow('Total Rows', '${summary.totalRows}'),
        _SummaryRow('Valid', '${summary.validRows}',
            color: const Color(0xFF059669)),
        if (summary.invalidRows > 0)
          _SummaryRow('Invalid', '${summary.invalidRows}',
              color: const Color(0xFFEF4444)),
        _SummaryRow('Matched Materials', '${summary.matchedMaterials}'),
        if (summary.customMaterials > 0)
          _SummaryRow('Custom Materials', '${summary.customMaterials}',
              color: const Color(0xFFF59E0B)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF374151))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANUAL ENTRY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ManualEntrySection extends ConsumerStatefulWidget {
  final String siteId;
  final String? preselectedType;
  const _ManualEntrySection({required this.siteId, this.preselectedType});

  @override
  ConsumerState<_ManualEntrySection> createState() =>
      _ManualEntrySectionState();
}

class _ManualEntrySectionState extends ConsumerState<_ManualEntrySection> with ScreenOwnedTourMixin<_ManualEntrySection> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final GlobalKey _typeTourKey = GlobalKey(debugLabel: 'boq_manual_type');
  final GlobalKey _nameTourKey = GlobalKey(debugLabel: 'boq_manual_name');
  final GlobalKey _modeTourKey = GlobalKey(debugLabel: 'boq_manual_mode');
  final GlobalKey _detailsTourKey = GlobalKey(debugLabel: 'boq_manual_details');
  final GlobalKey _timelineTourKey =
      GlobalKey(debugLabel: 'boq_manual_timeline');
  final GlobalKey _submitTourKey = GlobalKey(debugLabel: 'boq_manual_submit');
  String? _lastShowcasedTourStepId;
  String _type = 'mechanical_work';
  final _nameController = TextEditingController();
  final _inchDiaController = TextEditingController();
  final _inchMtrController = TextEditingController();
  final _rmtController = TextEditingController();
  final _areaController = TextEditingController();
  final List<_MechItemRow> _mechItems = [_MechItemRow()];
  final List<_InsuItemRow> _insuItems = [_InsuItemRow()];
  bool _useDirectTotals = true;
  final _timeline = _TimelineState();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) _type = widget.preselectedType!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inchDiaController.dispose();
    _inchMtrController.dispose();
    _rmtController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final boqName = _nameController.text.trim();
    if (boqName.isEmpty) {
      _showSnack('Please enter a BOQ name');
      return;
    }
    if (!_timeline.isValid) {
      _showSnack('End date must be after start date');
      return;
    }
    // Manual endpoint receives timeline as JSON object (Map), not string
    final timelinePayload = _timeline.toApiPayload();

    if (_type == 'mechanical_work') {
      if (_useDirectTotals) {
        final inchDia = double.tryParse(_inchDiaController.text);
        final inchMtr = double.tryParse(_inchMtrController.text);
        if (inchDia == null && inchMtr == null) {
          _showSnack('Enter at least one of Inch Dia or Inch Mtr');
          return;
        }
        await ref.read(uploadBoqProvider.notifier).createManualMechanical(
          siteId: widget.siteId,
          boqName: boqName,
          directTotalInchDia: inchDia,
          directTotalInchMtr: inchMtr,
          timeline: timelinePayload,
        );
      } else {
        final items = _mechItems
            .where((r) => r.materialController.text.isNotEmpty)
            .map((r) => r.toJson())
            .toList();
        if (items.isEmpty) {
          _showSnack('Add at least one item');
          return;
        }
        await ref.read(uploadBoqProvider.notifier).createManualMechanical(
          siteId: widget.siteId,
          boqName: boqName,
          items: items,
          timeline: timelinePayload,
        );
      }
    } else {
      if (_useDirectTotals) {
        final rmt = double.tryParse(_rmtController.text);
        final area = double.tryParse(_areaController.text);
        if (rmt == null && area == null) {
          _showSnack('Enter at least one of RMT or Area');
          return;
        }
        await ref.read(uploadBoqProvider.notifier).createManualInsulation(
          siteId: widget.siteId,
          boqName: boqName,
          directTotalRMT: rmt,
          directTotalArea: area,
          timeline: timelinePayload,
        );
      } else {
        final items = _insuItems
            .where((r) => r.materialController.text.isNotEmpty)
            .map((r) => r.toJson())
            .toList();
        if (items.isEmpty) {
          _showSnack('Add at least one item');
          return;
        }
        await ref.read(uploadBoqProvider.notifier).createManualInsulation(
          siteId: widget.siteId,
          boqName: boqName,
          items: items,
          timeline: timelinePayload,
        );
      }
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _syncManualTour(BuildContext showcaseContext, UploadStatus status) {
    final detailMode = _useDirectTotals ? 'quick' : 'items';
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}_manual_${_type}_$detailMode',
      title: 'Manual BOQ Entry',
      description: 'Learn how to create BOQ manually.',
      icon: Icons.edit_note_rounded,
      steps: [
        const AppTourStep(
          id: 'boq_manual_intro',
          title: 'Manual BOQ Entry',
          body:
              'Use this option when you want to create BOQ data by typing totals or item rows.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'boq_manual_type',
          title: 'BOQ Type',
          body:
              'Choose Mechanical or Insulation so the form asks for the right quantities.',
          targetKey: _typeTourKey,
          progressLabel: 'Type',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_manual_name',
          title: 'BOQ Name',
          body: 'Give this BOQ a clear name so it is easy to find later.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_manual_mode',
          title: 'Entry Method',
          body:
              'Use Quick Totals for total quantity only. Use Item by Item when you want detailed BOQ rows.',
          targetKey: _modeTourKey,
          progressLabel: 'Method',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_manual_details',
          title: _useDirectTotals ? 'Quantity Totals' : 'Item Rows',
          body: _useDirectTotals
              ? 'Enter the total quantity values for this BOQ. These totals become the planned BOQ quantity.'
              : 'Add each BOQ item here with material, size, quantity, and calculated values.',
          targetKey: _detailsTourKey,
          progressLabel: 'Details',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_manual_timeline',
          title: 'Timeline',
          body:
              'Turn this on if you want the BOQ quantity planned across dates for daily progress tracking.',
          targetKey: _timelineTourKey,
          progressLabel: 'Timeline',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'boq_manual_submit',
          title: 'Create BOQ',
          body:
              'Tap this button when the BOQ details are ready. The app will save this BOQ for the selected site.',
          targetKey: _submitTourKey,
          progressLabel: 'Create',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );

    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || status == UploadStatus.uploading) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.boqUploadId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadBoqProvider);

    ref.listen(uploadBoqProvider, (prev, next) {
      if (next.status == UploadStatus.success) {
        _showSnack('✅ BOQ created successfully!');
        ref.read(boqListParamsProvider.notifier).state =
            BoqListParams(siteId: widget.siteId);
        ref.read(uploadBoqProvider.notifier).reset();
        _nameController.clear();
      } else if (next.status == UploadStatus.error) {
        _showSnack('❌ ${next.errorMessage ?? 'Creation failed'}');
      }
    });

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncManualTour(showcaseContext, uploadState.status);
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tourTarget(
          _typeTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boqFieldLabel('BOQ Type'),
              const SizedBox(height: 8),
              _TypeToggle(
                  selected: _type,
                  onChanged: (t) => setState(() => _type = t)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _tourTarget(
          _nameTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boqFieldLabel('BOQ Name *'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration:
                    _boqInputDecoration('e.g. Mechanical Piping Phase 1'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _tourTarget(
          _modeTourKey,
          Row(children: [
            Expanded(
              child: _SegmentButton(
                label: 'Quick (Totals)',
                icon: Icons.flash_on_outlined,
                selected: _useDirectTotals,
                onTap: () => setState(() => _useDirectTotals = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentButton(
                label: 'Item by Item',
                icon: Icons.list_outlined,
                selected: !_useDirectTotals,
                onTap: () => setState(() => _useDirectTotals = false),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _tourTarget(
          _detailsTourKey,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        if (_useDirectTotals) ...[
          if (_type == 'mechanical_work') ...[
            _boqFieldLabel('Total Inch Dia'),
            const SizedBox(height: 6),
            TextField(
                controller: _inchDiaController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _boqInputDecoration('e.g. 3610')),
            const SizedBox(height: 12),
            _boqFieldLabel('Total Inch Mtr'),
            const SizedBox(height: 6),
            TextField(
                controller: _inchMtrController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _boqInputDecoration('e.g. 2460')),
          ] else ...[
            _boqFieldLabel('Total RMT'),
            const SizedBox(height: 6),
            TextField(
                controller: _rmtController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _boqInputDecoration('Running Meter Total')),
            const SizedBox(height: 12),
            _boqFieldLabel('Total Area (m²)'),
            const SizedBox(height: 6),
            TextField(
                controller: _areaController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _boqInputDecoration('Area in m²')),
          ],
        ] else ...[
          if (_type == 'mechanical_work')
            _MechanicalItemsEditor(
              items: _mechItems,
              onAdd: () => setState(() => _mechItems.add(_MechItemRow())),
              onRemove: (i) => setState(() => _mechItems.removeAt(i)),
            )
          else
            _InsulationItemsEditor(
              items: _insuItems,
              onAdd: () => setState(() => _insuItems.add(_InsuItemRow())),
              onRemove: (i) => setState(() => _insuItems.removeAt(i)),
            ),
        ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Timeline ──────────────────────────────────────────────────────
        _tourTarget(
          _timelineTourKey,
          _TimelineSection(
            state: _timeline,
            onChanged: () => setState(() {}),
          ),
        ),

        const SizedBox(height: 24),

        _tourTarget(
          _submitTourKey,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              uploadState.status == UploadStatus.uploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: uploadState.status == UploadStatus.uploading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(
                uploadState.status == UploadStatus.uploading
                    ? 'Creating...'
                    : 'Create BOQ',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MECHANICAL ITEMS EDITOR
// ─────────────────────────────────────────────────────────────────────────────

class _MechItemRow {
  final materialController = TextEditingController();
  final sizeController = TextEditingController();
  final qtyController = TextEditingController();
  final lengthController = TextEditingController();
  final inchDiaController = TextEditingController();
  final inchMtrController = TextEditingController();

  Map<String, dynamic> toJson() => {
    'materialName': materialController.text.trim(),
    if (sizeController.text.isNotEmpty)
      'size': double.tryParse(sizeController.text) ?? 0,
    if (qtyController.text.isNotEmpty)
      'quantity': double.tryParse(qtyController.text),
    if (lengthController.text.isNotEmpty)
      'length': double.tryParse(lengthController.text),
    if (inchDiaController.text.isNotEmpty)
      'userProvidedInchDia': double.tryParse(inchDiaController.text),
    if (inchMtrController.text.isNotEmpty)
      'userProvidedInchMtr': double.tryParse(inchMtrController.text),
  };
}

class _MechanicalItemsEditor extends StatelessWidget {
  final List<_MechItemRow> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _MechanicalItemsEditor(
      {required this.items, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((e) => _MechItemCard(
            index: e.key,
            row: e.value,
            onRemove: items.length > 1 ? () => onRemove(e.key) : null)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Row'),
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB))),
        ),
      ],
    );
  }
}

class _MechItemCard extends StatelessWidget {
  final int index;
  final _MechItemRow row;
  final VoidCallback? onRemove;
  const _MechItemCard(
      {required this.index, required this.row, this.onRemove});

  static const _mechMaterials = [
    'Pipe Erection / Fittings', 'Joints Welding / Fitting',
    'Elbow 90 Joint / Fitting', 'Flange Joints / Fitting',
    'Tee Joints / Fitting', 'Reducer Joints / Fitting',
    'Valve Fitting', 'Blind Fabrication And Fitting',
    'U Clamp Fitting', 'Support Fabrication And Erection',
    'Miter Fabrication', 'Plate Cutting', 'Plate Welding',
    'Shoe Support Fabrication And Erection',
    'Pipe Dismantling', 'Pipe Hole Cutting',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Item ${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  fontSize: 13)),
          const Spacer(),
          if (onRemove != null)
            GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 10),
        Autocomplete<String>(
          optionsBuilder: (v) => v.text.isEmpty
              ? _mechMaterials
              : _mechMaterials.where(
                  (m) => m.toLowerCase().contains(v.text.toLowerCase())),
          onSelected: (val) => row.materialController.text = val,
          fieldViewBuilder: (ctx, ctrl, fn, onSub) {
            row.materialController.text = ctrl.text;
            return TextField(
                controller: ctrl,
                focusNode: fn,
                decoration: _boqInputDecoration('Material Name *'));
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.sizeController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Size (inch)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: row.qtyController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Qty (Nos)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: row.lengthController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Length (m)'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.inchDiaController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Inch Dia (opt)'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: row.inchMtrController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Inch Mtr (opt)'))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INSULATION ITEMS EDITOR
// ─────────────────────────────────────────────────────────────────────────────

class _InsuItemRow {
  final materialController = TextEditingController();
  final sizeController = TextEditingController();
  final qtyController = TextEditingController();
  String sizeUom = 'inch';
  String layer = 'single';
  final legging1MatController = TextEditingController();
  final legging1ThkController = TextEditingController();
  final legging2MatController = TextEditingController();
  final legging2ThkController = TextEditingController();
  final legging3MatController = TextEditingController();
  final legging3ThkController = TextEditingController();
  final claddingMatController = TextEditingController();
  final claddingSwgController = TextEditingController();
  final userRmtController = TextEditingController();
  final userAreaController = TextEditingController();

  Map<String, dynamic> toJson() => {
    'materialName': materialController.text.trim(),
    'size': double.tryParse(sizeController.text) ?? 0,
    'sizeUom': sizeUom,
    'qty': double.tryParse(qtyController.text) ?? 0,
    'layer': layer,
    'legging_material_1': legging1MatController.text.trim(),
    'legging_thickness_1': double.tryParse(legging1ThkController.text) ?? 0,
    if (layer != 'single') ...{
      'legging_material_2': legging2MatController.text.trim(),
      'legging_thickness_2':
      double.tryParse(legging2ThkController.text) ?? 0,
    },
    if (layer == 'triple') ...{
      'legging_material_3': legging3MatController.text.trim(),
      'legging_thickness_3':
      double.tryParse(legging3ThkController.text) ?? 0,
    },
    'cladding_material': claddingMatController.text.trim(),
    'cladding_swg': int.tryParse(claddingSwgController.text) ?? 24,
    if (userRmtController.text.isNotEmpty)
      'userProvidedRMT': double.tryParse(userRmtController.text),
    if (userAreaController.text.isNotEmpty)
      'userProvidedArea': double.tryParse(userAreaController.text),
  };
}

class _InsulationItemsEditor extends StatelessWidget {
  final List<_InsuItemRow> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _InsulationItemsEditor(
      {required this.items, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((e) => _InsuItemCard(
            index: e.key,
            row: e.value,
            onRemove: items.length > 1 ? () => onRemove(e.key) : null)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Row'),
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0891B2),
              side: const BorderSide(color: Color(0xFF0891B2))),
        ),
      ],
    );
  }
}

class _InsuItemCard extends StatefulWidget {
  final int index;
  final _InsuItemRow row;
  final VoidCallback? onRemove;
  const _InsuItemCard(
      {required this.index, required this.row, this.onRemove});

  @override
  State<_InsuItemCard> createState() => _InsuItemCardState();
}

class _InsuItemCardState extends State<_InsuItemCard> {
  static const _insuMaterials = [
    'PIPE', 'ELBOW 90°', 'ELBOW 45°', 'TEE', 'REDUCER', 'CAP',
    'INSULATED FLANGE PAIR (REMOVABLE)',
    'INSULATED FLANGE VALVE (FIXED)',
    'INSULATED WELDED VALVE (FIXED)',
  ];

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Item ${widget.index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151))),
          const Spacer(),
          if (widget.onRemove != null)
            GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 10),
        Autocomplete<String>(
          optionsBuilder: (v) => v.text.isEmpty
              ? _insuMaterials
              : _insuMaterials.where(
                  (m) => m.toLowerCase().contains(v.text.toLowerCase())),
          onSelected: (val) => row.materialController.text = val,
          fieldViewBuilder: (ctx, ctrl, fn, onSub) {
            row.materialController.text = ctrl.text;
            return TextField(
                controller: ctrl,
                focusNode: fn,
                decoration: _boqInputDecoration('Material Name *'));
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.sizeController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Size'))),
          const SizedBox(width: 8),
          Expanded(
              child: DropdownButtonFormField<String>(
                value: row.sizeUom,
                decoration: _boqInputDecoration('UOM'),
                items: ['inch', 'mm']
                    .map((u) =>
                    DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => row.sizeUom = v ?? 'inch'),
              )),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: row.qtyController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Qty'))),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: row.layer,
          decoration: _boqInputDecoration('Layer'),
          items: ['single', 'double', 'triple']
              .map((l) =>
              DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) =>
              setState(() => row.layer = v ?? 'single'),
        ),
        const SizedBox(height: 8),
        _boqFieldLabel('Layer 1'),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.legging1MatController,
                  decoration: _boqInputDecoration('Material'))),
          const SizedBox(width: 8),
          SizedBox(
              width: 90,
              child: TextField(
                  controller: row.legging1ThkController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Thk mm'))),
        ]),
        if (row.layer != 'single') ...[
          const SizedBox(height: 8),
          _boqFieldLabel('Layer 2'),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: row.legging2MatController,
                    decoration: _boqInputDecoration('Material'))),
            const SizedBox(width: 8),
            SizedBox(
                width: 90,
                child: TextField(
                    controller: row.legging2ThkController,
                    keyboardType: TextInputType.number,
                    decoration: _boqInputDecoration('Thk mm'))),
          ]),
        ],
        if (row.layer == 'triple') ...[
          const SizedBox(height: 8),
          _boqFieldLabel('Layer 3'),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: row.legging3MatController,
                    decoration: _boqInputDecoration('Material'))),
            const SizedBox(width: 8),
            SizedBox(
                width: 90,
                child: TextField(
                    controller: row.legging3ThkController,
                    keyboardType: TextInputType.number,
                    decoration: _boqInputDecoration('Thk mm'))),
          ]),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.claddingMatController,
                  decoration: _boqInputDecoration('Cladding Material'))),
          const SizedBox(width: 8),
          SizedBox(
              width: 90,
              child: TextField(
                  controller: row.claddingSwgController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('SWG'))),
        ]),
        const SizedBox(height: 8),
        _boqFieldLabel('User Pre-Calculated (optional)'),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: row.userRmtController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('RMT'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: row.userAreaController,
                  keyboardType: TextInputType.number,
                  decoration: _boqInputDecoration('Area (m²)'))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    _TypeBtn(
        label: 'Mechanical',
        icon: Icons.plumbing_outlined,
        value: 'mechanical_work',
        selected: selected,
        color: const Color(0xFF7C3AED),
        onTap: onChanged),
    const SizedBox(width: 10),
    _TypeBtn(
        label: 'Insulation',
        icon: Icons.layers_outlined,
        value: 'insulation_piping',
        selected: selected,
        color: const Color(0xFF0891B2),
        onTap: onChanged),
  ]);
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final Color color;
  final void Function(String) onTap;
  const _TypeBtn(
      {required this.label,
        required this.icon,
        required this.value,
        required this.selected,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? color : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? color
                        : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton(
      {required this.label,
        required this.icon,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

Widget _boqFieldLabel(String label) => Text(label,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151)));

InputDecoration _boqInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle:
  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
  filled: true,
  fillColor: Colors.white,
  contentPadding:
  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      const BorderSide(color: Color(0xFF2563EB), width: 2)),
);
