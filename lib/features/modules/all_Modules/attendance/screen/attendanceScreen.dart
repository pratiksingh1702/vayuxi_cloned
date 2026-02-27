// FULL UI REWRITE — EXACT MATCH TO PROVIDED SCREENSHOT
// Functionality remains unchanged. Only UI layout/styling changed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../model/attModel.dart';
import '../offline/repo/att_offline_provider.dart';
import '../offline/repo/att_sync.dart';
import '../provider/AttendanceProvider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool allPresent = false;
  bool allAbsent = false;
  bool _draftInitialized = false;

  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  bool _isFirstOTEntry = true; // Track if this is the first OT entry
  double? _firstOTValue; // Store the first OT value
  bool _isEditMode = false; // Track edit mode for non-today dates

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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadManpower();
    });
  }


  @override
  void dispose() {
    // Reset edit mode when leaving screen
    _isEditMode = false;
    super.dispose();
  }

  Future<void> _loadManpower() async {
    setState(() => isLoading = true);
    final type = ref.read(typeProvider);
final siteId = ref.read(selectedSiteIdProvider)!;

    ref.invalidate(manpowerSyncControllerProvider((type: type!)));
    final repo = ref.read(attendanceRepositoryProvider);
    await repo.syncManpowerFromApi(type!);
    await ref.read(teamProvider.notifier).fetchTeams(type: type, siteId: siteId);

    setState(() {
      isLoading = false;
      _isFirstOTEntry = true; // Reset on new data load
      _firstOTValue = null;

      // IMPORTANT: Do NOT disable edit mode when loading new date
      // Edit mode should persist until user explicitly turns it off
    });
  }

  // Check if selected date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if current date is editable (always true for today, requires edit mode for other dates)
  bool get _isEditable => _isToday(_selectedDate) || _isEditMode;

  Future<void> _selectDate(BuildContext context) async {
    // Allow date selection ONLY when edit mode is ON for non-today dates
    if (!_isToday(_selectedDate) && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Click 'Edit' to modify attendance for ${_formatDate(_selectedDate)}"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadManpower();
    }
  }
  Future<void> _toggleAllPresent() async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    setState(() {
      allPresent = true;
      allAbsent = false;
    });

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;

    notifier.state = [
      for (final emp in list)
        emp.copyWith(status: "present", totalHours: 8)
    ];
  }

  Future<void> _toggleAllAbsent() async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    setState(() {
      allPresent = false;
      allAbsent = true;
    });

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;

    notifier.state = [
      for (final emp in list)
        emp.copyWith(status: "absent", totalHours: 0, ot: 0)
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
        const SnackBar(
          content: Text("Please enable edit mode to make changes"),
          backgroundColor: Colors.orange,
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
        const SnackBar(
          content: Text("Edit mode disabled"),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleOTChange(int index, double newOTValue) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;
    final emp = list[index];

    /// rule → if absent or < 8h → OT must be 0
    if (emp.status == "absent" || emp.totalHours < 8) {
      newOTValue = 0;
    }

    /// ⭐ FIRST ENTRY → ASK
    if (_isFirstOTEntry && newOTValue > 0) {
      _isFirstOTEntry = false;
      _firstOTValue = newOTValue;

      _showOTConfirmationDialog(newOTValue,index);
      return;
    }

    /// normal single update
    notifier.state = [
      for (int i = 0; i < list.length; i++)
        if (i == index)
          list[i].copyWith(ot: newOTValue)
        else
          list[i]
    ];
  }

  void _showOTConfirmationDialog(double otValue,int index) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ don't allow tap outside
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
                // 🔥 Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled,
                    size: 36,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 Title
                const Text(
                  "Apply Overtime?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // 🔥 Message
                Text(
                  "Apply $otValue hours OT to all eligible employees?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
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
                          Navigator.pop(context);
                          _applyOTToAll(otValue,index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Apply"
                          ,style: TextStyle(
                              color: Colors.white
                          ),),
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


  void _applyOTToAll(double otValue, int changedIndex) {
    if (!_isEditable) return;

    final notifier = ref.read(attendanceDraftProvider.notifier);
    final list = notifier.state;

    notifier.state = [
      for (int i = 0; i < list.length; i++)
        if (i == changedIndex)
          list[i].copyWith(ot: otValue)
        else if (list[i].status == "present" && list[i].totalHours >= 8)
          list[i].copyWith(ot: otValue)
        else
          list[i]
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$otValue hours OT applied'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (!_isEditable) {
      if (!_isToday(_selectedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enable edit mode to save attendance"),
            backgroundColor: Colors.orange,
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

      // FIX: DateTime constructor uses 1-based months, no need to subtract 1
      final isoDate = DateTime.utc(year, month, day).toIso8601String();

      // Debug: Verify date conversion
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
      final siteId = ref.read(selectedSiteIdProvider);

      // Since we're getting "Attendance already exists", always try update first
      print(
        '🔄 Trying to update attendance records (since records already exist)',
      );
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

        /// if network → DO NOTHING
        if (msg.contains("internet") ||
            msg.contains("connection") ||
            msg.contains("timeout")) {
          print("🌐 Network issue → queued by interceptor");
          return;
        }

        /// real server reason → try create
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance saved successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // IMPORTANT: Do NOT disable edit mode after saving
      // Edit mode should persist until user explicitly turns it off

      // Reset OT tracking for next operation
      _isFirstOTEntry = true;
      _firstOTValue = null;

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
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";
  Future<void> _updateLocal({
    required AttendanceModel emp,
    required String status,
    required double hours,
    required double ot,
  }) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final type = ref.read(typeProvider)!;
    final siteId = ref.read(selectedSiteIdProvider)!;

    await repo.upsertLocalAttendance(
      siteId: siteId,
      type: type,
      dateKey: repo.formatDateKey(_selectedDate),
      manpowerId: emp.manpower.id!,
      status: status,
      totalHours: hours,
      ot: ot,
      company: emp.company,
    );
    ref.invalidate(
      attendanceOfflineProvider((
      siteId: siteId,
      type: type,
      date: _selectedDate,
      )),
    );

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
    final lang=ref.watch(dailyEntryTranslationHelperProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: CustomAppBar(title: lang.recordAttendanceTitle),

      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Save",
              color: _isEditable ? Colors.blue : Colors.grey,
              textColor: Colors.white,
              width: 200,
              onPressed: _submitAttendance,
            ),
          ),
        ],
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : attendanceState.when(
          data: (attendanceList){
            if (!_draftInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(attendanceDraftProvider.notifier).state =
                    attendanceList.map((e) => e.copyWith()).toList();
              });

              _draftInitialized = true;
            }

            final draft = ref.watch(attendanceDraftProvider);

            return Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Name and Date Row
                // Updated date display section - Only show box and calendar icon in edit mode

// Replace the date selector section (around line 431-470) with this:

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
                    // Date selector - Only show box/icon in edit mode
                    GestureDetector(
                      onTap: _isEditMode ? () => _selectDate(context) : null,
                      child: _isEditMode
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      )
                          : Text(
                        _formatDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Edit Mode Button and Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit Button (always shown)
                    GestureDetector(
                      onTap: _toggleEditMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isEditMode ? Colors.blue.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isEditMode ? Colors.blue.shade700 : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isEditMode ? Icons.edit_off : Icons.edit,
                              size: 16,
                              color: _isEditMode ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isEditMode ? "Editing" : "Edit",
                              style: TextStyle(
                                color: _isEditMode ? Colors.blue.shade700 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons (All Present / All Absent)
                    Row(
                      children: [
                        // All Absent Button
                        GestureDetector(
                          onTap: _toggleAllAbsent,
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
                        // All Present Button
                        GestureDetector(
                          onTap: _toggleAllPresent,
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
                  child: ListView.builder(
                    itemCount: draft.length,
                    itemBuilder: (context, i) {
                      final emp =draft[i];
                      return AttendanceCard(
                        name: emp.manpower.fullName ?? "Unnamed",
                        status: emp.status,
                        totalHours: emp.totalHours,
                        otValue: emp.ot,
                        absentOptions: absentOptions,
                        otOptions: otOptions,
                        isEditMode: _isEditable, // Pass editable state to card
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

                          final notifier = ref.read(attendanceDraftProvider.notifier);
                          final list = notifier.state;

                          notifier.state = [
                            for (int j = 0; j < list.length; j++)
                              if (j == i)
                                list[j].copyWith(status: st, totalHours: hours)
                              else
                                list[j]
                          ];
                        }
                        ,
                        onOtChange: (v) => _handleOTChange(i, v),
                      );
                    },
                  ),
                ),
              ],
            ),
          );},

          error: (e, s) => Center(child: Text("Error: $e")),
          loading: () => const Center(child: CircularProgressIndicator()),
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
    _hours = widget.totalHours;
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
        _hours = widget.totalHours;
        _otHours = widget.otValue;
      });
    }
  }

  double get _totalHours => _present ? _hours + _otHours : 0;

  void toggleAttendance() {
    if (!widget.isEditMode) return;

    setState(() {
      _present = !_present;
      // If marking absent, set hours to 0 and OT to 0
      if (!_present) {
        _hours = 0;
        _otHours = 0;
      }
    });

    widget.onAbsentChange(_present ? "P" : "A");
    // Also trigger OT change if marking absent
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
    final effectiveOTValue = _present ? _otHours : 0.0;
    Color cardColor = _present ? Colors.green.shade50 : Colors.red.shade50;

    return InkWell(
      onTap: widget.isEditMode ? toggleAttendance : null,
      borderRadius: BorderRadius.circular(10),
      splashColor: widget.isEditMode
          ? (_present ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
          : null,
      highlightColor: widget.isEditMode
          ? (_present ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
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
              color: Colors.grey.shade100,
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
                  Container(
                    child: Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
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
                  ),
                  const SizedBox(height: 4),
                  // Total hours indicator (Present hours + OT hours)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _present
                            ? "${_totalHours.toStringAsFixed(1)}h"
                            : "0 hours",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// PRESENT/ABSENT + HOURS + OT
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // P/A Button
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _buildPAButton(),
                    ),
                    const SizedBox(width: 8),
                    // Hours Dropdown
                    _buildHoursDropdown(),
                  ],
                ),
                const SizedBox(height: 8),
                // OT Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _present
                            ? Colors.orange.withOpacity(0.9)
                            : Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _present
                            ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                            : null,
                      ),
                      child: Text(
                        "OT",
                        style: TextStyle(
                          color: _present ? Colors.white : Colors.grey,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          color: active
              ? (value ? Colors.green : Colors.red)
              : Colors.transparent,
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
    // If absent, only show 0 as option
    final hoursOptions = _present
        ? widget.absentOptions.where((e) => e["value"] is double).toList()
        : [{"value": 0.0, "label": "0h"}];

    return MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _present ? Colors.blue.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _present ? Colors.blue.shade100 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: hoursOptions.any((e) => e["value"] == _hours)
                ? _hours
                : hoursOptions.first["value"],

            iconSize: 16,
            isDense: true,
            items: hoursOptions
                .map(
                  (e) => DropdownMenuItem<double>(
                value: e["value"],
                child: Text(
                  e["label"].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _present ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            )
                .toList(),
            onChanged: widget.isEditMode && _present
                ? (v) {
              if (v != null) {
                setState(() => _hours = v);
                widget.onAbsentChange(v);
              }
            }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildOTDropdown(double effectiveOTValue) {
    // If absent, only show 0 as option
    final otOptions = _present
        ? widget.otOptions
        : [{"value": 0.0, "label": "0h"}];

    return MouseRegion(
      cursor: widget.isEditMode
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _present ? Colors.orange.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _present ? Colors.orange.shade100 : Colors.grey.shade300,
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
                    color: _present ? Colors.black : Colors.grey,
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