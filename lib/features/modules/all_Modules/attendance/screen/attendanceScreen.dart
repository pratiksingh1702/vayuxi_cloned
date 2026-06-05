import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
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

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool allPresent = false;
  bool allAbsent = false;
  final ScrollController _scrollController = ScrollController();

  // ✅ Track which date the draft was loaded for (replaces _draftInitialized bool)
  DateTime? _draftLoadedForDate;

  bool isLoading = false;
  bool _isMultipleEntry = false;
  Set<DateTime> _completedDates = {};

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
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);
      
      if (type != null && siteId != null) {
        // Fetch teams first, then load manpower
        await ref
            .read(teamProvider.notifier)
            .fetchTeams(type: type, siteId: siteId);
        _loadManpower();
      }
      
      _initMultiMode();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _initMultiMode() async {
    final multi = await ModulePreferences.isMultipleEntry();
    if (mounted) {
      setState(() => _isMultipleEntry = multi);
      if (multi) {
        _fetchCompletedDates();
      }
    }
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
          final designations =
              draft.map((e) => e.manpower.designation ?? 'N/A').toSet().toList()
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
                          setSheetState(() => _currentSort =
                              AttendanceSortOption.latestFirst);
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
                          setSheetState(() => _currentSort =
                              AttendanceSortOption.otHighToLow);
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
                    values: RangeValues(_filterHoursMin ?? 0, _filterHoursMax ?? 12),
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

  bool get _isEditable => _isToday(_selectedDate) || _isEditMode;

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$otValue hours OT applied (adjusted per employee)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitAttendance() async {
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

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider)!;
    final siteId = ref.watch(selectedSiteIdProvider)!;

    final attendanceState = ref.watch(
      attendanceOfflineProvider((
        siteId: siteId,
        type: type,
        date: _selectedDate,
      )),
    );

    final site = ref.read(currentSiteProvider);
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(title: lang.recordAttendanceTitle),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Save",
              color: _isEditable
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              textColor: colorScheme.onPrimary,
              width: 200,
              onPressed: _submitAttendance,
            ),
          ),
        ],
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : attendanceState.when(
                data: (attendanceList) {
                  // ✅ Only initialize draft when date changes, not on every stream emit
                  if (_draftLoadedForDate != _selectedDate &&
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

                  return Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isMultipleEntry) ...[
                          TimelineDatePicker(
                            selectedDate: _selectedDate,
                            onDateSelected: _onTimelineDateSelected,
                            completedDates: _completedDates,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Site Name and Date Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: Text(
                                site!.siteName,
                                maxLines: 1,
                                overflow: TextOverflow.values.first,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Date selector — only tappable in edit mode
                            GestureDetector(
                              onTap: _isEditMode
                                  ? () => _selectDate(context)
                                  : null,
                              child: _isEditMode
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(_selectedDate),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      _formatDate(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),


                        // Search and Filter Row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
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
                                          color: colorScheme.primary, size: 20),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 18),
                                              onPressed: () =>
                                                  _searchController.clear(),
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
                                    borderRadius: BorderRadius.circular(12),
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

                        const SizedBox(height: 8),

                        // Edit Mode Button and Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Edit Button
                            GestureDetector(
                              onTap: _toggleEditMode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isEditMode
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isEditMode
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isEditMode ? Icons.edit_off : Icons.edit,
                                      size: 16,
                                      color: _isEditMode
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isEditMode ? "Editing" : "Edit",
                                      style: TextStyle(
                                        color: _isEditMode
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // All Present / All Absent
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleAllAbsent(filteredList),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: allAbsent
                                          ? Colors.red
                                          : Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.red),
                                    ),
                                    child: Text(
                                      "All Absent",
                                      style: TextStyle(
                                        color: allAbsent
                                            ? Colors.white
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _toggleAllPresent(filteredList),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: allPresent
                                          ? Colors.green
                                          : Colors.green.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Text(
                                      "All Present",
                                      style: TextStyle(
                                        color: allPresent
                                            ? Colors.white
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Attendance List
                        Expanded(
                          child: CustomScrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
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

                                    final notifier = ref
                                        .read(attendanceDraftProvider.notifier);
                                    final list = notifier.state;

                                    notifier.state = [
                                      for (final item in list)
                                        if (item.manpower.id == emp.manpower.id)
                                          item.copyWith(
                                              status: st, totalHours: hours)
                                        else
                                          item
                                    ];
                                  },
                                  onOtChange: (v) {
                                    if (!_isEditable) {
                                      _showEditRequiredMessage();
                                      return;
                                    }

                                    final notifier = ref
                                        .read(attendanceDraftProvider.notifier);
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
                                        if (item.manpower.id == emp.manpower.id)
                                          item.copyWith(ot: newOTValue)
                                        else
                                          item
                                    ];
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
    final overlayBase = _present ? Colors.green : Colors.red;
    final cardColor = Color.alphaBlend(
      overlayBase
          .withOpacity(colorScheme.brightness == Brightness.dark ? 0.18 : 0.10),
      colorScheme.surface,
    );

    return InkWell(
      onTap: widget.isEditMode ? toggleAttendance : null,
      borderRadius: BorderRadius.circular(10),
      splashColor: widget.isEditMode
          ? (_present
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2))
          : null,
      highlightColor: widget.isEditMode
          ? (_present
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _present ? Colors.green : Colors.red,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                        constraints: const BoxConstraints(maxWidth: 140),
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
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _present
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _present
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _present ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: _present ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _present ? "Present" : "Absent",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _present ? Colors.green : Colors.red,
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
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8.0),
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
                        color: _present
                            ? colorScheme.tertiary
                            : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _present
                            ? [
                                BoxShadow(
                                  color: colorScheme.tertiary.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        "OT",
                        style: TextStyle(
                          color: _present
                              ? colorScheme.onTertiary
                              : colorScheme.onSurfaceVariant,
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
  }

  Widget _buildPAButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _segment("P", true),
          _segment("A", false),
        ],
      ),
    );
  }

  Widget _segment(String label, bool value) {
    final active = _present == value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isEditMode ? () => setPresent(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              active ? (value ? Colors.green : Colors.red) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : value
                    ? Colors.green.withOpacity(0.6)
                    : Colors.red.withOpacity(0.6),
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

    return MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _present
              ? colorScheme.tertiaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _present
                ? colorScheme.tertiary.withOpacity(0.25)
                : colorScheme.outlineVariant,
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

    return MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _present
              ? colorScheme.tertiaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _present
                ? colorScheme.tertiary.withOpacity(0.25)
                : colorScheme.outlineVariant,
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
  }
}
