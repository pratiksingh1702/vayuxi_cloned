// FULL UI REWRITE — EXACT MATCH TO PROVIDED SCREENSHOT
// Functionality remains unchanged. Only UI layout/styling changed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../provider/AttendanceProvider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({
    super.key,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool allPresent = false;
  bool allAbsent = false;
  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  bool _isFirstOTEntry = true; // Track if this is the first OT entry
  double? _firstOTValue; // Store the first OT value
  bool _isEditMode = false; // Track edit mode
  bool _isFirstTimeCurrentDate = true; // Track if it's first time for current date

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
    _selectedDate = _selectedDate;
    _loadManpower();
  }

  Future<void> _loadManpower() async {
    setState(() => isLoading = true);
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);

    await ref
        .read(attendanceNotifierProvider.notifier)
        .fetchManpower(type!, siteId!, _selectedDate);

    setState(() {
      isLoading = false;
      _isFirstOTEntry = true; // Reset on new data load
      _firstOTValue = null;

      // AUTO-ENABLE EDIT MODE: Only for first time on current date
      final isCurrentDate = _isToday(_selectedDate);
      if (_isFirstTimeCurrentDate && isCurrentDate) {
        _isEditMode = true;
        _isFirstTimeCurrentDate = false; // Mark that we've used the first-time privilege
      } else {
        _isEditMode = false; // Disable edit mode for date changes or non-current dates
      }
    });
  }

  // Check if selected date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadManpower();

      // Show message if trying to edit past date without clicking edit
      if (!_isToday(picked)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Click 'Edit' to modify attendance for selected date"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    }
  }

  void _toggleAllPresent() {
    if (!_isEditMode) {
      _showEditModeRequiredMessage();
      return;
    }

    setState(() {
      allPresent = true;
      allAbsent = false;
    });

    final attendanceList = ref.read(attendanceNotifierProvider).value ?? [];
    for (int i = 0; i < attendanceList.length; i++) {
      ref.read(attendanceNotifierProvider.notifier).updateEmployee(
          i,
          attendanceList[i].copyWith(
            totalHours: 8.0,
            status: "present",
          ));
    }
  }

  void _toggleAllAbsent() {
    if (!_isEditMode) {
      _showEditModeRequiredMessage();
      return;
    }

    setState(() {
      allPresent = false;
      allAbsent = true;
    });

    final attendanceList = ref.read(attendanceNotifierProvider).value ?? [];
    for (int i = 0; i < attendanceList.length; i++) {
      ref.read(attendanceNotifierProvider.notifier).updateEmployee(
          i,
          attendanceList[i].copyWith(
            totalHours: 0.0,
            status: "absent",
          ));
    }
  }

  void _showEditModeRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enable edit mode to make changes"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // New method to handle OT logic
  void _handleOTChange(int index, double newOTValue) {
    if (!_isEditMode) {
      _showEditModeRequiredMessage();
      return;
    }

    final attendanceList = ref.read(attendanceNotifierProvider).value ?? [];
    final employee = attendanceList[index];

    // Check conditions for zero OT
    if (employee.status == "absent" || employee.totalHours < 8.0) {
      // If absent or worked less than 8 hours, OT should be 0
      ref.read(attendanceNotifierProvider.notifier).updateEmployee(
          index, employee.copyWith(ot: 0.0));
      return;
    }

    // If this is the first OT entry and employee is eligible for OT
    if (_isFirstOTEntry && newOTValue > 0) {
      _firstOTValue = newOTValue;
      _isFirstOTEntry = false;

      // Show confirmation snackbar
      _showOTConfirmationSnackbar(newOTValue);
    }

    // Update the specific employee's OT
    ref.read(attendanceNotifierProvider.notifier).updateEmployee(
        index, employee.copyWith(ot: newOTValue));
  }

  void _showOTConfirmationSnackbar(double otValue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                'Apply $otValue hours OT to all employees?',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Apply to All',
          textColor: Colors.white,
          onPressed: () {
            _applyOTToAll(otValue);
          },
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ),

    );
  }

  void _applyOTToAll(double otValue) {
    if (!_isEditMode) return;

    final attendanceList = ref.read(attendanceNotifierProvider).value ?? [];

    for (int i = 0; i < attendanceList.length; i++) {
      final employee = attendanceList[i];

      // Only apply OT to employees who are present AND worked 8+ hours
      if (employee.status == "present" && employee.totalHours >= 8.0) {
        ref.read(attendanceNotifierProvider.notifier).updateEmployee(
            i, employee.copyWith(ot: otValue));
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$otValue hours OT applied to all eligible employees'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (!_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable edit mode to save attendance"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final state = ref.read(attendanceNotifierProvider);
      final type = ref.read(typeProvider);
      final attendanceList = state.value ?? [];

      if (attendanceList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No attendance data to save"), behavior: SnackBarBehavior.floating,),
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
      print('🔄 Trying to update attendance records (since records already exist)');
      try {
        await ref.read(attendanceNotifierProvider.notifier).updateMultipleAttendance(
          payload: payload,
          type: type!,
          siteId: siteId!,
          date: currentDate,
        );
        print('✅ Successfully updated attendance records');
      } catch (updateError) {
        print('⚠️ Update failed, trying create: $updateError');

        // If update fails, try create
        await ref.read(attendanceNotifierProvider.notifier).postMultipleAttendance(
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

      // Optionally disable edit mode after successful save
      setState(() {
        _isEditMode = false;
      });

    } catch (e) {
      print('❌ Submission error: $e');

      String errorMessage = "Error saving attendance";
      if (e.toString().contains("Attendance already exists")) {
        errorMessage = "Attendance for this date already exists. Please update instead.";
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    if (_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Edit mode enabled - You can now modify attendance"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Edit mode disabled"),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceNotifierProvider);
    final site = ref.read(currentSiteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: CustomAppBar(title: "Record Attendance"),

      body: CornerClippedScreenSimple(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : attendanceState.when(
          data: (attendanceList) => Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    // Make date clickable
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Edit Mode Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _toggleEditMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isEditMode ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isEditMode ? Colors.blue.shade700 : Colors.grey.shade600),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isEditMode ? Icons.edit_off : Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isEditMode ? "Editing" : "Edit",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _toggleAllPresent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: allPresent ? Colors.green : Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              "All Present",
                              style: TextStyle(
                                color: allPresent ? Colors.white : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                // Info message for first-time current date editing
                if (_isEditMode && _isToday(_selectedDate) && _isFirstTimeCurrentDate)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "First-time editing for today's date enabled automatically",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Attendance List
                Expanded(
                  child: ListView.builder(
                    itemCount: attendanceList.length,
                    itemBuilder: (context, i) {
                      final emp = attendanceList[i];
                      return AttendanceCard(
                        name: emp.manpower.fullName ?? "Unnamed",
                        status: emp.status,
                        totalHours: emp.totalHours,
                        otValue: emp.ot,
                        absentOptions: absentOptions,
                        otOptions: otOptions,
                        isEditMode: _isEditMode, // Pass edit mode to card
                        onAbsentChange: (v) {
                          if (!_isEditMode) {
                            _showEditModeRequiredMessage();
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

                          ref
                              .read(attendanceNotifierProvider.notifier)
                              .updateEmployee(i, emp.copyWith(
                            totalHours: hours,
                            status: st,
                          ));
                        },
                        onOtChange: (v) => _handleOTChange(i, v),
                      );
                    },
                  ),
                ),

                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoundedButton(
                        text: "Back",
                        color: Colors.white,
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context),
                      ),
                      RoundedButton(
                        text: "Save Attendance",
                        color: _isEditMode ? Colors.blue : Colors.grey,
                        textColor: Colors.white,
                        width: 200,
                        onPressed: _submitAttendance,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

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

  @override
  void initState() {
    super.initState();
    _present = widget.status != "absent";
    _hours = widget.totalHours;
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status || oldWidget.totalHours != widget.totalHours) {
      setState(() {
        _present = widget.status != "absent";
        _hours = widget.totalHours;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOTValue = (widget.status == "absent" || widget.totalHours < 8.0)
        ? 0.0
        : widget.otValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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

          const SizedBox(height: 12),

          /// PRESENT/ABSENT + HOURS
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    _buildPAButton(),
                    const SizedBox(width: 5),
                    _buildHoursDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "OT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildOTDropdown(effectiveOTValue),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPAButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
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
      onTap: widget.isEditMode ? () {
        setState(() => _present = value);
        widget.onAbsentChange(value ? "P" : "A");
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? (value ? Colors.green : Colors.red)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : (value ? Colors.green : Colors.red),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHoursDropdown() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _hours,
          items: widget.absentOptions
              .where((e) => e["value"] is double)
              .map((e) => DropdownMenuItem<double>(
            value: e["value"],
            child: Text(e["label"].toString()),
          ))
              .toList(),
          onChanged: widget.isEditMode ? (v) {
            if (v != null) {
              setState(() => _hours = v);
              widget.onAbsentChange(v);
            }
          } : null,
        ),
      ),
    );
  }

  Widget _buildOTDropdown(double effectiveOTValue) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: effectiveOTValue,
          items: widget.otOptions
              .map((e) => DropdownMenuItem<double>(
            value: e["value"],
            child: Text(e["label"].toString()),
          ))
              .toList(),
          onChanged: widget.isEditMode ? (v) {
            if (v != null) {
              widget.onOtChange(v);
            }
          } : null,
        ),
      ),
    );
  }
}