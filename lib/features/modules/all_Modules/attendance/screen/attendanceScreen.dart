import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/attendance_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import 'package:untitled2/features/tour/widgets/no_cutout_tour_target.dart';
import '../../../../../core/router/routes.dart';
import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';

import '../../../../../typeProvider/type_provider.dart';
import '../../../screen/module_preferences.dart';
import '../../../../../core/utlis/widgets/timeline_date_picker.dart';
import '../../../../../core/utlis/widgets/timeline_calendar_dialog.dart';
import '../../../screen/device_id.dart';
import '../model/attModel.dart';
import '../offline/repo/att_offline_provider.dart';
import '../offline/repo/att_sync.dart';
import '../provider/AttendanceProvider.dart';
import 'package:untitled2/features/modules/screen/workflow/domain/workflow_controller.dart';
import '../../../../../core/utlis/widgets/timeline_date_picker.dart';

enum AttendanceSortOption {
  nameAsc,
  nameDesc,
  designationAsc,
  designationDesc,
  hoursHighToLow,
  hoursLowToHigh,
  otHighToLow,
  otLowToHigh,
  latestFirst
}

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with ScreenOwnedTourMixin<AttendanceScreen> {
  bool allPresent = false;
  bool allAbsent = false;
  final ScrollController _scrollController = ScrollController();
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _timelineTourKey =
      GlobalKey(debugLabel: 'attendance_tour_timeline');
  final GlobalKey _siteDateTourKey =
      GlobalKey(debugLabel: 'attendance_tour_site_date');
  final GlobalKey _searchFilterTourKey =
      GlobalKey(debugLabel: 'attendance_tour_search_filter');
  final GlobalKey _editTourKey = GlobalKey(debugLabel: 'attendance_tour_edit');
  final GlobalKey _bulkActionsTourKey =
      GlobalKey(debugLabel: 'attendance_tour_bulk_actions');
  final GlobalKey _workerCardTourKey =
      GlobalKey(debugLabel: 'attendance_tour_worker_card');
  final GlobalKey _workerStatusTourKey =
      GlobalKey(debugLabel: 'attendance_tour_worker_status');
  final GlobalKey _workerHoursTourKey =
      GlobalKey(debugLabel: 'attendance_tour_worker_hours');
  final GlobalKey _workerOtTourKey =
      GlobalKey(debugLabel: 'attendance_tour_worker_ot');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'attendance_tour_save');

  // ✅ Track which date the draft was loaded for (replaces _draftInitialized bool)
  DateTime? _draftLoadedForDate;

  bool isLoading = false;
  bool _entryModeLoaded = false;
  bool _isMultipleEntry = false;
  Set<DateTime> _completedDates = {};
  final Map<String, List<AttendanceModel>> _multiEntryDrafts = {};
  final Set<String> _dirtyMultiEntryDates = {};
  String? _activeMultiEntryDateKey;

  // ✅ Always normalize to midnight to avoid provider cache misses
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isFirstOTEntry = true;
  double? _firstOTValue;
  bool _isEditMode = false;

  final List<Map<String, dynamic>> absentOptions = [
    {"label": "P", "value": "P"},
    {"label": "A", "value": "A"},
    ...List.generate(17, (i) {
      final val = i * 0.5;
      return {"label": val.toString(), "value": val};
    }),
  ];

  final List<Map<String, dynamic>> otOptions = List.generate(33, (i) {
    final val = i * 0.5;
    return {"label": val.toString(), "value": val};
  });

  // Filter & Sort State
  AttendanceSortOption _currentSort = AttendanceSortOption.latestFirst;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _filterStatus = {};
  Set<String> _filterDesignation = {};
  double? _filterHoursMin;
  double? _filterHoursMax;
  double? _filterOTMin;
  double? _filterOTMax;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final multi = await ModulePreferences.isMultipleEntry();
      if (!mounted) return;

      setState(() {
        _isMultipleEntry = multi;
        _entryModeLoaded = true;
      });

      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      if (type != null && siteId != null) {
        // Fetch teams first, then load manpower
        await ref
            .read(teamProvider.notifier)
            .fetchTeams(type: type, siteId: siteId);
        if (multi) {
          await _initializeMultiEntrySession(type: type, siteId: siteId);
        } else {
          _loadManpower();
        }
      }

      if (multi) {
        _fetchCompletedDates();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _fetchCompletedDates() async {
    final siteId = ref.read(selectedSiteIdProvider);
    final type = ref.read(typeProvider);
    if (siteId == null || type == null) return;

    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 180));
    final dateKeys = List.generate(365, (i) {
      final date = start.add(Duration(days: i));
      return ref.read(attendanceRepositoryProvider).formatDateKey(date);
    });

    final repo = ref.read(attendanceRepositoryProvider);
    final completedKeys = await repo.getCompletedDateKeys(
      siteId: siteId,
      type: type,
      dateKeys: dateKeys,
    );

    if (mounted) {
      setState(() {
        _completedDates = completedKeys.map((k) {
          final d = DateTime.parse(k);
          return DateTime(d.year, d.month, d.day);
        }).toSet();
      });
    }
  }

  String _attendanceDateKey(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String _displayDateFromKey(String dateKey) {
    final date = DateTime.parse(dateKey);
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  List<AttendanceModel> _cloneAttendanceList(List<AttendanceModel> list) {
    return list.map((e) => e.copyWith()).toList();
  }

  Future<void> _initializeMultiEntrySession({
    required String type,
    required String siteId,
  }) async {
    setState(() => isLoading = true);
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      if (await repo.isOnline()) {
        await repo.syncManpowerBySite(siteId: siteId, type: type);
      }
    } catch (e) {
      print("⚠️ Multi-entry manpower sync failed, using cached data: $e");
    }

    await _loadMultiEntryDate(_selectedDate, preserveCurrent: false);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMultiEntryDate(
    DateTime date, {
    bool preserveCurrent = true,
  }) async {
    if (preserveCurrent) {
      _cacheCurrentMultiEntryDraft(persistLocal: true);
    }

    final siteId = ref.read(selectedSiteIdProvider);
    final type = ref.read(typeProvider);
    if (siteId == null || type == null) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = _attendanceDateKey(normalizedDate);
    final repo = ref.read(attendanceRepositoryProvider);

    List<AttendanceModel>? rows = _multiEntryDrafts[dateKey];

    if (rows == null) {
      await repo.ensureAttendanceForSite(
        siteId: siteId,
        type: type,
        dateKey: dateKey,
      );
      rows = await repo
          .watchAttendance(
            siteId: siteId,
            type: type,
            dateKey: dateKey,
          )
          .first;
      _multiEntryDrafts[dateKey] = _cloneAttendanceList(rows);
    }

    if (!mounted) return;
    setState(() {
      _selectedDate = normalizedDate;
      _activeMultiEntryDateKey = dateKey;
      _draftLoadedForDate = normalizedDate;
    });
    ref.read(attendanceDraftProvider.notifier).state =
        _cloneAttendanceList(_multiEntryDrafts[dateKey] ?? const []);
  }

  void _cacheCurrentMultiEntryDraft({bool persistLocal = false}) {
    if (!_isMultipleEntry) return;
    final dateKey =
        _activeMultiEntryDateKey ?? _attendanceDateKey(_selectedDate);
    final draft = ref.read(attendanceDraftProvider);
    if (draft.isEmpty) return;

    final cloned = _cloneAttendanceList(draft);
    _multiEntryDrafts[dateKey] = cloned;

    if (persistLocal && _dirtyMultiEntryDates.contains(dateKey)) {
      unawaited(_persistMultiEntryDraftLocally(dateKey, cloned));
    }
  }

  void _markCurrentMultiEntryDateDirty() {
    if (!_isMultipleEntry) return;
    final dateKey =
        _activeMultiEntryDateKey ?? _attendanceDateKey(_selectedDate);
    _dirtyMultiEntryDates.add(dateKey);
    _cacheCurrentMultiEntryDraft();
    setState(() {
      _completedDates.add(
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      );
    });
  }

  Future<void> _persistMultiEntryDraftLocally(
    String dateKey,
    List<AttendanceModel> rows,
  ) async {
    final siteId = ref.read(selectedSiteIdProvider);
    final type = ref.read(typeProvider);
    if (siteId == null || type == null) return;

    final repo = ref.read(attendanceRepositoryProvider);
    for (final row in rows) {
      final manpowerId = row.manpower.id;
      if (manpowerId == null || manpowerId.isEmpty) continue;
      await repo.upsertLocalAttendance(
        siteId: siteId,
        type: type,
        dateKey: dateKey,
        manpowerId: manpowerId,
        status: row.status,
        totalHours: row.totalHours,
        ot: row.ot,
        company: row.company,
      );
    }
  }

  @override
  void dispose() {
    _isEditMode = false;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _filterStatus.isNotEmpty ||
      _filterDesignation.isNotEmpty ||
      _filterHoursMin != null ||
      _filterHoursMax != null ||
      _filterOTMin != null ||
      _filterOTMax != null ||
      _currentSort != AttendanceSortOption.latestFirst;

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          final draft = ref.read(attendanceDraftProvider);
          final designations = draft
              .map((e) => e.manpower.designation ?? 'N/A')
              .toSet()
              .toList()
            ..sort();

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _currentSort = AttendanceSortOption.latestFirst;
                            _filterStatus = {};
                            _filterDesignation = {};
                            _filterHoursMin = null;
                            _filterHoursMax = null;
                            _filterOTMin = null;
                            _filterOTMax = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Sorting
                  _buildFilterLabel('Sort By'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Latest First',
                        selected:
                            _currentSort == AttendanceSortOption.latestFirst,
                        onSelected: (val) {
                          setSheetState(() =>
                              _currentSort = AttendanceSortOption.latestFirst);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Name (A-Z)',
                        selected: _currentSort == AttendanceSortOption.nameAsc,
                        onSelected: (val) {
                          setSheetState(() =>
                              _currentSort = AttendanceSortOption.nameAsc);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Name (Z-A)',
                        selected: _currentSort == AttendanceSortOption.nameDesc,
                        onSelected: (val) {
                          setSheetState(() =>
                              _currentSort = AttendanceSortOption.nameDesc);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Hours (High-Low)',
                        selected:
                            _currentSort == AttendanceSortOption.hoursHighToLow,
                        onSelected: (val) {
                          setSheetState(() => _currentSort =
                              AttendanceSortOption.hoursHighToLow);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'OT (High-Low)',
                        selected:
                            _currentSort == AttendanceSortOption.otHighToLow,
                        onSelected: (val) {
                          setSheetState(() =>
                              _currentSort = AttendanceSortOption.otHighToLow);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status
                  _buildFilterLabel('Attendance Status'),
                  Wrap(
                    spacing: 8,
                    children: ['Present', 'Absent', 'Half Day'].map((status) {
                      return _buildFilterChip(
                        label: status,
                        selected: _filterStatus.contains(status),
                        onSelected: (val) {
                          setSheetState(() {
                            if (val) {
                              _filterStatus.add(status);
                            } else {
                              _filterStatus.remove(status);
                            }
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Designation
                  if (designations.isNotEmpty) ...[
                    _buildFilterLabel('Designation'),
                    Wrap(
                      spacing: 8,
                      children: designations.map((des) {
                        return _buildFilterChip(
                          label: des,
                          selected: _filterDesignation.contains(des),
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                _filterDesignation.add(des);
                              } else {
                                _filterDesignation.remove(des);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Shift Hours Range
                  _buildFilterLabel(
                      'Shift Hours: ${_filterHoursMin?.toStringAsFixed(1) ?? "0"} - ${_filterHoursMax?.toStringAsFixed(1) ?? "12"}h'),
                  _buildSliderRange(
                    min: 0,
                    max: 12,
                    values: RangeValues(
                        _filterHoursMin ?? 0, _filterHoursMax ?? 12),
                    onChanged: (values) {
                      setSheetState(() {
                        _filterHoursMin = values.start;
                        _filterHoursMax = values.end;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),

                  // OT Range
                  _buildFilterLabel(
                      'OT Hours: ${_filterOTMin?.toStringAsFixed(1) ?? "0"} - ${_filterOTMax?.toStringAsFixed(1) ?? "8"}h'),
                  _buildSliderRange(
                    min: 0,
                    max: 8,
                    values: RangeValues(_filterOTMin ?? 0, _filterOTMax ?? 8),
                    onChanged: (values) {
                      setSheetState(() {
                        _filterOTMin = values.start;
                        _filterOTMax = values.end;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? colorScheme.primary : colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildSliderRange({
    required double min,
    required double max,
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return RangeSlider(
      values: values,
      min: min,
      max: max,
      divisions: (max - min) * 2 > 0 ? ((max - min) * 2).toInt() : 1,
      labels: RangeLabels(
        values.start.toStringAsFixed(1),
        values.end.toStringAsFixed(1),
      ),
      activeColor: colorScheme.primary,
      inactiveColor: colorScheme.primaryContainer,
      onChanged: onChanged,
    );
  }

  Future<void> _reloadAll() async {
    print("🔄 FULL RELOAD START");

    final type = ref.read(typeProvider)!;
    final siteId = ref.read(selectedSiteIdProvider)!;

    try {
      // 1️⃣ Reload teams
      await ref.read(teamProvider.notifier).fetchTeams(
            type: type,
            siteId: siteId,
          );

      // 2️⃣ Reload manpower
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.syncManpowerFromApi(type);

      // 3️⃣ Force attendance provider rebuild
      ref.invalidate(attendanceOfflineProvider);

      // 4️⃣ Force refresh counter (extra safety)
      ref.read(attendanceRefreshProvider.notifier).state++;

      print("✅ FULL RELOAD DONE");
    } catch (e) {
      print("❌ Reload failed: $e");
    }
  }

  Future<void> _loadManpower() async {
    setState(() => isLoading = true);

    print("88888888888888888888888888888888888888888888888888888888");

    final type = ref.read(typeProvider);
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      await repo.syncManpowerFromApi(type!);
      print("✅ Manpower synced from API");
    } catch (e) {
      final error = extractBackendError(e);
      AppToast.error(error);
      if (isDeviceAuthError(e)) {
        print("🔐 Device not authorized → opening OTP screen");

        final result = await context.push<bool>(
          Routes.deviceOtp, // you MUST add this route
        );
        // 🔥 After OTP success → retry
        if (result == true) {
          print("✅ Device authorized → reloading full screen");

          await _reloadAll();

          if (mounted) {
            setState(() {}); // force rebuild UI
          }

          return;
        }

        setState(() => isLoading = false);
        return;
      }

      print("⚠️ Failed to sync manpower, using offline data: $e");
    }

    // 🔥 Always refresh UI regardless of API success/failure
    ref.read(attendanceRefreshProvider.notifier).state++;

    setState(() {
      isLoading = false;
      _isFirstOTEntry = true;
      _firstOTValue = null;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get _isEditable =>
      _isMultipleEntry || _isToday(_selectedDate) || _isEditMode;

  Future<void> _selectDate(BuildContext context) async {
    if (!_isToday(_selectedDate) && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Click 'Edit' to modify attendance for ${_formatDate(_selectedDate)}"),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picked = await TimelineCalendarDialog.show(
      context: context,
      initialDate: _selectedDate,
      completedDates: _completedDates,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        // ✅ Strip time component
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _draftLoadedForDate = null; // force reload for new date
      });
      // ✅ Clear stale draft immediately
      ref.read(attendanceDraftProvider.notifier).state = [];
      _loadManpower();
    }
  }

  void _onTimelineDateSelected(DateTime date) {
    if (_isSameDay(date, _selectedDate)) return;

    if (_isMultipleEntry) {
      _loadMultiEntryDate(date);
      return;
    }

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _draftLoadedForDate = null;
    });
    ref.read(attendanceDraftProvider.notifier).state = [];
    _loadManpower();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _toggleAllPresent(List<AttendanceModel> listToUpdate) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    setState(() {
      allPresent = true;
      allAbsent = false;
    });

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final fullList = notifier.state;
    final idsToUpdate = listToUpdate.map((e) => e.manpower.id).toSet();

    notifier.state = [
      for (final emp in fullList)
        if (idsToUpdate.contains(emp.manpower.id))
          emp.copyWith(
            status: "present",
            totalHours: double.tryParse(emp.manpower.totalHour ?? "") ?? 8.0,
          )
        else
          emp
    ];
    _markCurrentMultiEntryDateDirty();
  }

  Future<void> _toggleAllAbsent(List<AttendanceModel> listToUpdate) async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    setState(() {
      allPresent = false;
      allAbsent = true;
    });

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final fullList = notifier.state;
    final idsToUpdate = listToUpdate.map((e) => e.manpower.id).toSet();

    notifier.state = [
      for (final emp in fullList)
        if (idsToUpdate.contains(emp.manpower.id))
          emp.copyWith(status: "absent", totalHours: 0, ot: 0)
        else
          emp
    ];
    _markCurrentMultiEntryDateDirty();
  }

  void _showEditRequiredMessage() {
    if (_isToday(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can edit today's attendance directly"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enable edit mode to make changes"),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    if (_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isToday(_selectedDate)
              ? "Edit mode enabled - You can now modify today's attendance and change date"
              : "Edit mode enabled - You can now modify attendance for ${_formatDate(_selectedDate)}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Edit mode disabled"),
          backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleOTChange(String manpowerId, double newOTValue) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;
    final emp = list.firstWhere((e) => e.manpower.id == manpowerId);

    // rule → if absent or < 8h → OT must be 0
    if (emp.status == "absent" || emp.totalHours < 8) {
      newOTValue = 0;
    }

    // FIRST ENTRY → ASK
    if (_isFirstOTEntry && newOTValue > 0) {
      _isFirstOTEntry = false;
      _firstOTValue = newOTValue;
      _showOTConfirmationDialogForId(newOTValue, manpowerId);
      return;
    }

    // normal single update
    notifier.state = [
      for (final item in list)
        if (item.manpower.id == manpowerId)
          item.copyWith(ot: newOTValue)
        else
          item
    ];
    _markCurrentMultiEntryDateDirty();
  }

  void _showOTConfirmationDialogForId(double otValue, String manpowerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apply Overtime?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Apply $otValue hours OT to all eligible employees?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                          _applyOTToAllForId(otValue, manpowerId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Apply",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyOTToAllForId(double otValue, String changedId) {
    if (!_isEditable) return;

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;

    notifier.state = [
      for (final item in list)
        if (item.manpower.id == changedId)
          item.copyWith(ot: otValue)
        else if (item.status == "present")
          () {
            final totalHourRaw = item.manpower.totalHour;
            final totalHour = double.tryParse(totalHourRaw ?? "") ?? 0;

            // fallback to 8 if not defined
            final maxOT = totalHour > 0 ? totalHour : 8.0;

            final safeOT = otValue.clamp(0, maxOT).toDouble();
            return item.copyWith(ot: safeOT);
          }()
        else
          item
    ];
    _markCurrentMultiEntryDateDirty();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$otValue hours OT applied (adjusted per employee)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_isMultipleEntry) {
      await _submitMultiEntryAttendance();
      return;
    }

    if (!_isEditable) {
      if (!_isToday(_selectedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enable edit mode to save attendance"),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      setState(() => isLoading = true);

      final attendanceList = ref.read(attendanceDraftProvider);
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      if (attendanceList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No attendance data to save"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final currentDate = _formatDate(_selectedDate); // DD/MM/YYYY
      final parts = currentDate.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final isoDate = DateTime.utc(year, month, day).toIso8601String();

      print('📅 Date conversion check:');
      print('   Selected: $_selectedDate');
      print('   Formatted: $currentDate');
      print('   ISO: $isoDate');

      final payload = attendanceList.map((emp) {
        return {
          "manpowerId": emp.manpower.id,
          "date": isoDate,
          "status": emp.status,
          "totalHours": emp.totalHours,
          "ot": emp.ot,
        };
      }).toList();

      print('📤 Sending ${payload.length} records to API');

      try {
        await ref
            .read(attendanceNotifierProvider.notifier)
            .updateMultipleAttendance(
              payload: payload,
              type: type!,
              siteId: siteId!,
              date: currentDate,
            );
        print('✅ Successfully updated attendance records');
      } catch (updateError) {
        final msg = updateError.toString().toLowerCase();

        if (msg.contains("internet") ||
            msg.contains("connection") ||
            msg.contains("timeout")) {
          print("🌐 Network issue → queued by interceptor");
          return;
        }

        print('⚠️ Update failed for real, trying create');

        await ref
            .read(attendanceNotifierProvider.notifier)
            .postMultipleAttendance(
              payload: payload,
              type: type!,
              siteId: siteId!,
            );
        print('✅ Successfully created attendance records');
      }

      // ✅ API succeeded — show success first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance saved successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _isFirstOTEntry = true;
      _firstOTValue = null;

      if (mounted) {
        final wf = ref.read(workflowControllerProvider);
        if (wf.isActive) {
          await ref.read(workflowControllerProvider.notifier).advance(context);
        } else {
          final isMultiple = await ModulePreferences.isMultipleEntry();
          if (!isMultiple) {
            context.pop();
          }
        }
      }

      // ✅ Sync confirmed data from API back into Isar
      final repo = ref.read(attendanceRepositoryProvider);
      final dateKey = repo.formatDateKey(_selectedDate);
      final team = ref.read(currentTeamProvider);

      try {
        await repo.syncAttendanceForDate(
          siteId: siteId!,
          type: type!,
          dateKey: dateKey,
        );

        // ✅ After sync, refresh completed dates to show tick
        final isMultiple = await ModulePreferences.isMultipleEntry();
        if (isMultiple) {
          _fetchCompletedDates();
        }

        // ✅ Read fresh confirmed data from Isar and rebuild draft — no flash
        final fresh = await repo
            .watchAttendance(
              siteId: siteId,
              type: type,
              dateKey: dateKey,
              teamMemberIds: team!.teamMemberIds,
            )
            .first;

        if (mounted) {
          ref.read(attendanceDraftProvider.notifier).state = fresh;
          // ✅ Prevent build() from overwriting with stale stream data
          _draftLoadedForDate = _selectedDate;
        }
      } catch (syncError, s) {
        print(s);
        // Sync failed — draft stays as-is (what user saved), not a critical error
        print("⚠️ Post-save sync failed: $syncError");
      }
    } catch (e) {
      print('❌ Submission error: $e');

      String errorMessage = "Error saving attendance";
      if (e.toString().contains("Attendance already exists")) {
        errorMessage =
            "Attendance for this date already exists. Please update instead.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _submitMultiEntryAttendance() async {
    _cacheCurrentMultiEntryDraft(persistLocal: true);

    if (_dirtyMultiEntryDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No pending attendance drafts to save"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);
      if (type == null || siteId == null) return;

      final repo = ref.read(attendanceRepositoryProvider);
      final datesToSave = _dirtyMultiEntryDates.toList()..sort();

      for (final dateKey in datesToSave) {
        final attendanceList = _multiEntryDrafts[dateKey] ?? const [];
        if (attendanceList.isEmpty) continue;

        final date = DateTime.parse(dateKey);
        final isoDate =
            DateTime.utc(date.year, date.month, date.day).toIso8601String();

        final payload = attendanceList.map((emp) {
          return {
            "manpowerId": emp.manpower.id,
            "date": isoDate,
            "status": emp.status,
            "totalHours": emp.totalHours,
            "ot": emp.ot,
          };
        }).toList();

        final displayDate = _displayDateFromKey(dateKey);

        try {
          await ref
              .read(attendanceNotifierProvider.notifier)
              .updateMultipleAttendance(
                payload: payload,
                type: type,
                siteId: siteId,
                date: displayDate,
              );
        } catch (updateError) {
          final msg = updateError.toString().toLowerCase();
          if (msg.contains("internet") ||
              msg.contains("connection") ||
              msg.contains("timeout")) {
            rethrow;
          }

          await ref
              .read(attendanceNotifierProvider.notifier)
              .postMultipleAttendance(
                payload: payload,
                type: type,
                siteId: siteId,
              );
        }

        try {
          await repo.syncAttendanceForDate(
            siteId: siteId,
            type: type,
            dateKey: dateKey,
          );
        } catch (syncError) {
          print(
              "⚠️ Multi-entry post-save sync failed for $dateKey: $syncError");
        }
      }

      _dirtyMultiEntryDates.clear();
      await _fetchCompletedDates();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Attendance saved for ${datesToSave.length} date${datesToSave.length == 1 ? '' : 's'}",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Multi-entry submission error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving multi-entry attendance"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";
  List<Map<String, dynamic>> buildOTOptions({
    required double? maxAllowedHours,
  }) {
    // fallback to 8 if not provided or invalid
    final maxOT = (maxAllowedHours != null && maxAllowedHours > 0)
        ? maxAllowedHours
        : 8.0;

    final steps = (maxOT * 2).floor(); // 0.5 steps

    return List.generate(steps + 1, (i) {
      final val = i * 0.5;
      return {
        "label": val.toString(),
        "value": val,
      };
    });
  }

  void _syncAttendanceTour(
    BuildContext showcaseContext, {
    required bool includeTimeline,
    required bool includeWorkerControls,
  }) {
    final definition = _buildAttendanceTour(
      includeTimeline: includeTimeline,
      includeWorkerControls: includeWorkerControls,
    );

    bindScreenOwnedTour(
        tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || isLoading) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);

      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: AttendanceModuleTours.attendanceId,
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
      // No-cutout tour overlay handles target presentation.
    });
  }

  AppTourDefinition _buildAttendanceTour({
    required bool includeTimeline,
    required bool includeWorkerControls,
  }) {
    final variant = [
      if (includeTimeline) 'timeline',
      if (includeWorkerControls) 'worker' else 'basic',
    ].join('_');

    return AppTourDefinition(
      id: '${AttendanceModuleTours.attendanceId}_$variant',
      title: 'Attendance',
      description: 'Learn how to mark and save attendance.',
      icon: Icons.how_to_reg_rounded,
      steps: [
        const AppTourStep(
          id: 'attendance_intro',
          title: 'Attendance',
          body:
              'Use this screen to mark who came to work and how many hours they worked.',
          progressLabel: 'Attendance intro',
          useSpotlight: false,
        ),
        if (includeTimeline)
          AppTourStep(
            id: 'attendance_timeline',
            title: 'Pick a Date',
            body:
                'Use this timeline to move between dates when multiple entry mode is on.',
            targetKey: _timelineTourKey,
            progressLabel: 'Date timeline',
          ),
        AppTourStep(
          id: 'attendance_site_date',
          title: 'Site and Date',
          body:
              'Check the site name and date before marking attendance for workers.',
          targetKey: _siteDateTourKey,
          progressLabel: 'Site and date',
        ),
        AppTourStep(
          id: 'attendance_search_filter',
          title: 'Find Workers',
          body:
              'Search by employee name or code, and use filters to narrow the list.',
          targetKey: _searchFilterTourKey,
          progressLabel: 'Search and filter',
        ),
        AppTourStep(
          id: 'attendance_edit',
          title: 'Edit Mode',
          body:
              'Tap Edit when you need to change attendance, especially for older dates.',
          targetKey: _editTourKey,
          progressLabel: 'Edit mode',
        ),
        AppTourStep(
          id: 'attendance_bulk_actions',
          title: 'Mark Everyone Quickly',
          body:
              'Use All Absent or All Present to update the visible worker list in one tap.',
          targetKey: _bulkActionsTourKey,
          progressLabel: 'Bulk actions',
        ),
        if (includeWorkerControls) ...[
          AppTourStep(
            id: 'attendance_worker_card',
            title: 'Worker Card',
            body:
                'Each card is one worker. You can mark attendance, hours, and overtime here.',
            targetKey: _workerCardTourKey,
            progressLabel: 'Worker card',
          ),
          AppTourStep(
            id: 'attendance_worker_status',
            title: 'Present or Absent',
            body: 'Use P for present and A for absent for this worker.',
            targetKey: _workerStatusTourKey,
            progressLabel: 'P/A status',
          ),
          AppTourStep(
            id: 'attendance_worker_hours',
            title: 'Worked Hours',
            body:
                'Use this dropdown to set how many regular hours the worker completed.',
            targetKey: _workerHoursTourKey,
            progressLabel: 'Worked hours',
          ),
          AppTourStep(
            id: 'attendance_worker_ot',
            title: 'Overtime',
            body: 'Use OT to add extra hours when the worker did overtime.',
            targetKey: _workerOtTourKey,
            progressLabel: 'Overtime',
          ),
        ],
        AppTourStep(
          id: 'attendance_save',
          title: 'Save Attendance',
          body: 'Tap Save when the attendance details are ready to submit.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
          tooltipBottomOffset: 96,
        ),
      ],
    );
  }

  Widget _buildAttendanceTourTarget({
    required GlobalKey key,
    required Widget child,
    EdgeInsets targetPadding = const EdgeInsets.all(6),
  }) {
    return NoCutoutTourTarget(targetKey: key, child: child);
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: colorScheme.outlineVariant.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionChip({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : colorScheme.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? accent : colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? accent : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider)!;
    final siteId = ref.watch(selectedSiteIdProvider)!;

    final attendanceState = !_entryModeLoaded
        ? const AsyncValue<List<AttendanceModel>>.loading()
        : _isMultipleEntry
            ? AsyncValue<List<AttendanceModel>>.data(
                ref.watch(attendanceDraftProvider),
              )
            : ref.watch(
                attendanceOfflineProvider((
                  siteId: siteId,
                  type: type,
                  date: _selectedDate,
                )),
              );

    final site = ref.read(currentSiteProvider);
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(appTourControllerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(title: lang.recordAttendanceTitle),
      body: ShowCaseWidget(
        builder: (showcaseContext) {
          return BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: _buildAttendanceTourTarget(
                  key: _saveTourKey,
                  targetPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: RoundedButton(
                    text: _isMultipleEntry ? "Save All" : "Save",
                    color: _isEditable
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    textColor: colorScheme.onPrimary,
                    width: 200,
                    onPressed: _submitAttendance,
                  ),
                ),
              ),
            ],
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceState.when(
                    data: (attendanceList) {
                      // ✅ Only initialize single-entry draft when date changes.
                      // Multi-entry owns its date-wise draft cache separately.
                      if (!_isMultipleEntry &&
                          _draftLoadedForDate != _selectedDate &&
                          attendanceList.isNotEmpty) {
                        _draftLoadedForDate = _selectedDate;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          ref.read(attendanceDraftProvider.notifier).state =
                              attendanceList.map((e) => e.copyWith()).toList();
                        });
                      }

                      final draft = ref.watch(attendanceDraftProvider);

                      // Apply Filtering
                      var filteredList = draft.where((emp) {
                        // Search
                        if (_searchQuery.isNotEmpty &&
                            !(emp.manpower.fullName ?? '')
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) &&
                            !(emp.manpower.employeeCode ?? '')
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase())) {
                          return false;
                        }

                        // Status
                        if (_filterStatus.isNotEmpty) {
                          String status =
                              emp.status == 'present' ? 'Present' : 'Absent';
                          if (emp.totalHours > 0 && emp.totalHours < 8) {
                            status = 'Half Day';
                          }
                          if (!_filterStatus.contains(status)) return false;
                        }

                        // Designation
                        if (_filterDesignation.isNotEmpty &&
                            !_filterDesignation
                                .contains(emp.manpower.designation ?? 'N/A')) {
                          return false;
                        }

                        // Hours Range
                        if (_filterHoursMin != null &&
                            emp.totalHours < _filterHoursMin!) return false;
                        if (_filterHoursMax != null &&
                            emp.totalHours > _filterHoursMax!) return false;

                        // OT Range
                        if (_filterOTMin != null && emp.ot < _filterOTMin!) {
                          return false;
                        }
                        if (_filterOTMax != null && emp.ot > _filterOTMax!) {
                          return false;
                        }

                        return true;
                      }).toList();

                      // Apply Sorting
                      filteredList.sort((a, b) {
                        switch (_currentSort) {
                          case AttendanceSortOption.nameAsc:
                            return (a.manpower.fullName ?? '')
                                .compareTo(b.manpower.fullName ?? '');
                          case AttendanceSortOption.nameDesc:
                            return (b.manpower.fullName ?? '')
                                .compareTo(a.manpower.fullName ?? '');
                          case AttendanceSortOption.designationAsc:
                            return (a.manpower.designation ?? '')
                                .compareTo(b.manpower.designation ?? '');
                          case AttendanceSortOption.designationDesc:
                            return (b.manpower.designation ?? '')
                                .compareTo(a.manpower.designation ?? '');
                          case AttendanceSortOption.hoursHighToLow:
                            return b.totalHours.compareTo(a.totalHours);
                          case AttendanceSortOption.hoursLowToHigh:
                            return a.totalHours.compareTo(b.totalHours);
                          case AttendanceSortOption.otHighToLow:
                            return b.ot.compareTo(a.ot);
                          case AttendanceSortOption.otLowToHigh:
                            return a.ot.compareTo(b.ot);
                          case AttendanceSortOption.latestFirst:
                            return b.createdAt.compareTo(a.createdAt);
                        }
                      });

                      _syncAttendanceTour(
                        showcaseContext,
                        includeTimeline: _isMultipleEntry,
                        includeWorkerControls: filteredList.isNotEmpty,
                      );

                      final presentCount =
                          draft.where((e) => e.status == 'present').length;
                      final absentCount =
                          draft.where((e) => e.status != 'present').length;
                      final otTotal =
                          draft.fold<double>(0, (sum, e) => sum + e.ot);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isMultipleEntry) ...[
                              _buildAttendanceTourTarget(
                                key: _timelineTourKey,
                                targetPadding: const EdgeInsets.all(8),
                                child: TimelineDatePicker(
                                  selectedDate: _selectedDate,
                                  onDateSelected: _onTimelineDateSelected,
                                  completedDates: _completedDates,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Site Name and Date Row
                            _buildAttendanceTourTarget(
                              key: _siteDateTourKey,
                              targetPadding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.how_to_reg_rounded,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            site!.siteName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${draft.length} workers',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isEditMode
                                          ? () => _selectDate(context)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isEditMode
                                              ? colorScheme.primary
                                                  .withOpacity(0.08)
                                              : colorScheme.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _isEditMode
                                                ? colorScheme.primary
                                                    .withOpacity(0.25)
                                                : colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: _isEditMode
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(_selectedDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _isEditMode
                                                    ? colorScheme.primary
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                _buildSummaryTile(
                                  label: 'Present',
                                  value: '$presentCount',
                                  icon: Icons.check_circle_outline_rounded,
                                  accent: const Color(0xFF168A4A),
                                ),
                                const SizedBox(width: 8),
                                _buildSummaryTile(
                                  label: 'Absent',
                                  value: '$absentCount',
                                  icon: Icons.cancel_outlined,
                                  accent: const Color(0xFFC2413A),
                                ),
                                const SizedBox(width: 8),
                                _buildSummaryTile(
                                  label: 'OT Hours',
                                  value: otTotal.toStringAsFixed(1),
                                  icon: Icons.access_time_rounded,
                                  accent: colorScheme.primary,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Search and Filter Row
                            _buildAttendanceTourTarget(
                              key: _searchFilterTourKey,
                              targetPadding: const EdgeInsets.all(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                              colorScheme.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: colorScheme.outlineVariant
                                                  .withOpacity(0.5)),
                                        ),
                                        child: TextField(
                                          controller: _searchController,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: 'Search employee...',
                                            prefixIcon: Icon(Icons.search,
                                                color: colorScheme.primary,
                                                size: 20),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 14),
                                            suffixIcon: _searchQuery.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.clear,
                                                        size: 18),
                                                    onPressed: () =>
                                                        _searchController
                                                            .clear(),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: _showFilterSortBottomSheet,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: hasActiveFilters
                                              ? colorScheme.primary
                                              : colorScheme.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: hasActiveFilters
                                                ? colorScheme.primary
                                                : colorScheme.outlineVariant
                                                    .withOpacity(0.5),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.tune,
                                          color: hasActiveFilters
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Edit Mode Button and Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!_isMultipleEntry)
                                  _buildAttendanceTourTarget(
                                    key: _editTourKey,
                                    targetPadding: const EdgeInsets.all(6),
                                    child: _buildCompactActionChip(
                                      label: _isEditMode ? 'Editing' : 'Edit',
                                      icon: _isEditMode
                                          ? Icons.edit_off_rounded
                                          : Icons.edit_rounded,
                                      accent: colorScheme.primary,
                                      selected: _isEditMode,
                                      onTap: _toggleEditMode,
                                    ),
                                  )
                                else
                                  Text(
                                    '${_dirtyMultiEntryDates.length} draft date${_dirtyMultiEntryDates.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),

                                // All Present / All Absent
                                _buildAttendanceTourTarget(
                                  key: _bulkActionsTourKey,
                                  targetPadding: const EdgeInsets.all(6),
                                  child: Row(
                                    children: [
                                      _buildCompactActionChip(
                                        label: 'All Absent',
                                        icon: Icons.cancel_outlined,
                                        accent: const Color(0xFFC2413A),
                                        selected: allAbsent,
                                        onTap: () =>
                                            _toggleAllAbsent(filteredList),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCompactActionChip(
                                        label: 'All Present',
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        accent: const Color(0xFF168A4A),
                                        selected: allPresent,
                                        onTap: () =>
                                            _toggleAllPresent(filteredList),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Attendance List
                            Expanded(
                              child: CustomScrollbar(
                                controller: _scrollController,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, i) {
                                    final emp = filteredList[i];
                                    final totalHours = double.tryParse(
                                            emp.manpower.totalHour ?? "") ??
                                        0;

                                    final otOptions = buildOTOptions(
                                      maxAllowedHours: totalHours,
                                    );
                                    return AttendanceCard(
                                      key: ValueKey(emp.manpower.id),
                                      name: emp.manpower.fullName ?? "Unnamed",
                                      maxAllowedHours: totalHours,
                                      status: emp.status,
                                      totalHours: emp.totalHours,
                                      otValue: emp.ot,
                                      absentOptions: absentOptions,
                                      otOptions: otOptions,
                                      isEditMode: _isEditable,
                                      cardTourKey:
                                          i == 0 ? _workerCardTourKey : null,
                                      statusTourKey:
                                          i == 0 ? _workerStatusTourKey : null,
                                      hoursTourKey:
                                          i == 0 ? _workerHoursTourKey : null,
                                      otTourKey:
                                          i == 0 ? _workerOtTourKey : null,
                                      onAbsentChange: (v) {
                                        if (!_isEditable) {
                                          _showEditRequiredMessage();
                                          return;
                                        }

                                        double hours = 0;
                                        String st = "absent";

                                        if (v == "P") {
                                          hours = 8;
                                          st = "present";
                                        } else if (v is double && v > 0) {
                                          hours = v;
                                          st = "present";
                                        }

                                        final notifier = ref.read(
                                            attendanceDraftProvider.notifier);
                                        final list = notifier.state;

                                        notifier.state = [
                                          for (final item in list)
                                            if (item.manpower.id ==
                                                emp.manpower.id)
                                              item.copyWith(
                                                  status: st, totalHours: hours)
                                            else
                                              item
                                        ];
                                        _markCurrentMultiEntryDateDirty();
                                      },
                                      onOtChange: (v) {
                                        if (!_isEditable) {
                                          _showEditRequiredMessage();
                                          return;
                                        }

                                        final notifier = ref.read(
                                            attendanceDraftProvider.notifier);
                                        final list = notifier.state;

                                        // rule → if absent or < 8h → OT must be 0
                                        double newOTValue = v;
                                        if (emp.status == "absent" ||
                                            emp.totalHours < 8) {
                                          newOTValue = 0;
                                        }

                                        // FIRST ENTRY → ASK
                                        if (_isFirstOTEntry && newOTValue > 0) {
                                          _isFirstOTEntry = false;
                                          _firstOTValue = newOTValue;
                                          // Need to find original index for existing dialog logic
                                          // OR update dialog to use ID.
                                          // For now, I'll update the state directly if dialog is too complex to refactor here.
                                          // Wait, I should probably keep the dialog logic.
                                          _showOTConfirmationDialogForId(
                                              newOTValue, emp.manpower.id!);
                                          return;
                                        }

                                        notifier.state = [
                                          for (final item in list)
                                            if (item.manpower.id ==
                                                emp.manpower.id)
                                              item.copyWith(ot: newOTValue)
                                            else
                                              item
                                        ];
                                        _markCurrentMultiEntryDateDirty();
                                      },
                                    );
                                  },
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    error: (e, s) {
                      print(e);
                      return Text("$e");
                    },
                    loading: () => const ShimmerList(
                      type: ShimmerListType.tile,
                      itemCount: 8,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class AttendanceCard extends StatefulWidget {
  final String name;
  final String status;
  final double totalHours;
  final double otValue;
  final List<Map<String, dynamic>> absentOptions;
  final List<Map<String, dynamic>> otOptions;
  final Function(dynamic) onAbsentChange;
  final Function(double) onOtChange;
  final bool isEditMode;
  final double maxAllowedHours;
  final GlobalKey? cardTourKey;
  final GlobalKey? statusTourKey;
  final GlobalKey? hoursTourKey;
  final GlobalKey? otTourKey;

  const AttendanceCard({
    super.key,
    required this.name,
    required this.status,
    required this.totalHours,
    required this.otValue,
    required this.absentOptions,
    required this.otOptions,
    required this.onAbsentChange,
    required this.onOtChange,
    required this.isEditMode,
    required this.maxAllowedHours,
    this.cardTourKey,
    this.statusTourKey,
    this.hoursTourKey,
    this.otTourKey,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  late bool _present;
  late double _hours;
  late double _otHours;

  @override
  void initState() {
    super.initState();
    _present = widget.status != "absent";

    final hasRecordedAttendance =
        widget.status == "present" || widget.status == "absent";

    if (hasRecordedAttendance &&
        widget.totalHours > 0 &&
        widget.totalHours != widget.maxAllowedHours) {
      _hours = widget.totalHours;
    } else {
      _hours = widget.maxAllowedHours > 0 ? widget.maxAllowedHours : 8.0;
    }

    _otHours = widget.otValue;
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.totalHours != widget.totalHours ||
        oldWidget.otValue != widget.otValue) {
      setState(() {
        _present = widget.status != "absent";

        final hasRecordedAttendance =
            widget.status == "present" || widget.status == "absent";

        if (hasRecordedAttendance &&
            widget.totalHours > 0 &&
            widget.totalHours != widget.maxAllowedHours) {
          _hours = widget.totalHours;
        } else {
          _hours = widget.maxAllowedHours > 0 ? widget.maxAllowedHours : 8.0;
        }

        _otHours = widget.otValue;
      });
    }
  }

  double get _totalHours => _present ? _hours + _otHours : 0;

  void toggleAttendance() {
    if (!widget.isEditMode) return;

    setState(() {
      _present = !_present;
      if (!_present) {
        _hours = 0;
        _otHours = 0;
      }
    });

    widget.onAbsentChange(_present ? "P" : "A");
    if (!_present) {
      widget.onOtChange(0);
    }
  }

  void setPresent(bool value) {
    if (!widget.isEditMode) return;

    setState(() {
      _present = value;
      if (!_present) {
        _hours = 0;
        _otHours = 0;
      }
    });

    widget.onAbsentChange(value ? "P" : "A");
    if (!value) widget.onOtChange(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOTValue = _present ? _otHours : 0.0;
    final statusColor =
        _present ? const Color(0xFF168A4A) : const Color(0xFFC2413A);

    final card = InkWell(
      onTap: widget.isEditMode ? toggleAttendance : null,
      borderRadius: BorderRadius.circular(12),
      splashColor:
          widget.isEditMode ? colorScheme.primary.withOpacity(0.08) : null,
      highlightColor:
          widget.isEditMode ? colorScheme.primary.withOpacity(0.04) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withOpacity(0.20),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _present
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _present ? "Present" : "Absent",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _present
                            ? "${_totalHours.toStringAsFixed(1)}h"
                            : "0 hours",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.7),
                        ),
                      ),
                      child: _buildPAButton(),
                    ),
                    const SizedBox(width: 8),
                    _buildHoursDropdown(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        "OT",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildOTDropdown(effectiveOTValue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return _wrapTourTarget(
      key: widget.cardTourKey,
      child: card,
    );
  }

  Widget _wrapTourTarget({
    required GlobalKey? key,
    required Widget child,
    EdgeInsets targetPadding = const EdgeInsets.all(6),
  }) {
    if (key == null) return child;
    return NoCutoutTourTarget(targetKey: key, child: child);
  }

  Widget _buildPAButton() {
    final button = Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _segment("P", true),
          _segment("A", false),
        ],
      ),
    );
    return _wrapTourTarget(
      key: widget.statusTourKey,
      targetPadding: const EdgeInsets.all(4),
      child: button,
    );
  }

  Widget _segment(String label, bool value) {
    final active = _present == value;
    final accent = value ? const Color(0xFF168A4A) : const Color(0xFFC2413A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isEditMode ? () => setPresent(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : accent.withOpacity(0.65),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: active ? 13 : 10,
          ),
        ),
      ),
    );
  }

  Widget _buildHoursDropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    final maxAllowedHours =
        widget.maxAllowedHours > 0 ? widget.maxAllowedHours : 8.0;
    print("⏱ HOURS DROPDOWN --------------------");
    print("👤 ${widget.name}");
    print("📊 maxAllowedHours: $maxAllowedHours");
    print("📊 current _hours: $_hours");

    final hoursOptions = _present
        ? List.generate((maxAllowedHours * 2).floor() + 1, (i) {
            final val = i * 0.5;
            return {"label": "${val.toString()}h", "value": val};
          })
        : [
            {"value": 0.0, "label": "0h"}
          ];

    final defaultValue = _present ? _hours : 0.0;
    print("📋 hoursOptions:");
    for (var e in hoursOptions) {
      print("   ${e["value"]}");
    }
    print("🔑 defaultValue: $defaultValue");

    final dropdown = MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.8),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: defaultValue,
            iconSize: 16,
            isDense: true,
            items: hoursOptions
                .map(
                  (e) => DropdownMenuItem<double>(
                    value: e["value"] as double,
                    child: Text(
                      e["label"].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _present
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.isEditMode && _present
                ? (v) {
                    if (v != null) {
                      setState(() => _hours = v);

                      // 🔥 IMPORTANT: reset OT if exceeds limit
                      if (_otHours > maxAllowedHours - v) {
                        _otHours = 0;
                        widget.onOtChange(0);
                      }

                      widget.onAbsentChange(v);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
    return _wrapTourTarget(
      key: widget.hoursTourKey,
      targetPadding: const EdgeInsets.all(4),
      child: dropdown,
    );
  }

  List<Map<String, dynamic>> buildOTOptions({
    required double maxAllowedHours,
    required double workedHours,
  }) {
    final maxOT = (maxAllowedHours - workedHours).clamp(0, 24);

    final steps = (maxOT * 2).floor(); // 0.5 steps

    return List.generate(steps + 1, (i) {
      final val = i * 0.5;
      return {
        "label": val.toString(),
        "value": val,
      };
    });
  }

  Widget _buildOTDropdown(double effectiveOTValue) {
    final colorScheme = Theme.of(context).colorScheme;
    final otOptions = _present
        ? widget.otOptions
        : [
            {"value": 0.0, "label": "0h"}
          ];

    final dropdown = MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.8),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: otOptions.any((e) => e["value"] == effectiveOTValue)
                ? effectiveOTValue
                : otOptions.first["value"],
            iconSize: 16,
            isDense: true,
            items: otOptions
                .map(
                  (e) => DropdownMenuItem<double>(
                    value: e["value"],
                    child: Text(
                      e["label"].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _present
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.isEditMode && _present
                ? (v) {
                    if (v != null) {
                      setState(() => _otHours = v);
                      widget.onOtChange(v);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
    return _wrapTourTarget(
      key: widget.otTourKey,
      targetPadding: const EdgeInsets.all(4),
      child: dropdown,
    );
  }
}
