// FULL UI REWRITE — EXACT MATCH TO PROVIDED SCREENSHOT
// Functionality remains unchanged. Only UI layout/styling changed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../provider/AttendanceProvider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final DateTime? selectedDate; // Add this

  const AttendanceScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.selectedDate,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool allPresent = false;
  bool allAbsent = false;
  bool isLoading = false;
  late DateTime _selectedDate;

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
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _loadManpower();
  }

  Future<void> _loadManpower() async {
    setState(() => isLoading = true);
    final type = ref.read(typeProvider);

    await ref
        .read(attendanceNotifierProvider.notifier)
        .fetchManpower(type!, widget.siteId, _selectedDate);

    setState(() => isLoading = false);
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
    }
  }

  void _toggleAllPresent() {
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
          )
      );
    }
  }

  void _toggleAllAbsent() {
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
          )
      );
    }
  }

  Future<void> _submitAttendance() async {
    try {
      setState(() => isLoading = true);

      final state = ref.read(attendanceNotifierProvider);
      final type = ref.read(typeProvider);
      final attendanceList = state.value ?? [];

      if (attendanceList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No attendance data to save")),
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

      // Since we're getting "Attendance already exists", always try update first
      print('🔄 Trying to update attendance records (since records already exist)');
      try {
        await ref.read(attendanceNotifierProvider.notifier).updateMultipleAttendance(
          payload: payload,
          type: type!,
          siteId: widget.siteId,
          date: currentDate,
        );
        print('✅ Successfully updated attendance records');
      } catch (updateError) {
        print('⚠️ Update failed, trying create: $updateError');

        // If update fails, try create
        await ref.read(attendanceNotifierProvider.notifier).postMultipleAttendance(
          payload: payload,
          type: type!,
          siteId: widget.siteId,
        );
        print('✅ Successfully created attendance records');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance saved successfully"),
          backgroundColor: Colors.green,
        ),
      );

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
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: CustomAppBar(title: "Record Attendance"),

      body: isLoading
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
                  Text(
                    widget.siteName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

              const SizedBox(height: 10),

              // All Present / All Absent Buttons
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
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleAllAbsent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: allAbsent ? Colors.red : Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        "All Absent",
                        style: TextStyle(
                          color: allAbsent ? Colors.white : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
                      onAbsentChange: (v) {
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
                      onOtChange: (v) {
                        ref
                            .read(attendanceNotifierProvider.notifier)
                            .updateEmployee(i, emp.copyWith(ot: v));
                      },
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
                      color: Colors.blue,
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
    // Update local state when widget data changes from parent
    if (oldWidget.status != widget.status || oldWidget.totalHours != widget.totalHours) {
      setState(() {
        _present = widget.status != "absent";
        _hours = widget.totalHours;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildOTDropdown(),
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
      onTap: () {
        setState(() => _present = value);
        widget.onAbsentChange(value ? "P" : "A");
      },
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
          onChanged: (v) {
            if (v != null) {
              setState(() => _hours = v);
              widget.onAbsentChange(v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOTDropdown() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: widget.otValue,
          items: widget.otOptions
              .map((e) => DropdownMenuItem<double>(
            value: e["value"],
            child: Text(e["label"].toString()),
          ))
              .toList(),
          onChanged: (v) => v != null ? widget.onOtChange(v) : null,
        ),
      ),
    );
  }
}