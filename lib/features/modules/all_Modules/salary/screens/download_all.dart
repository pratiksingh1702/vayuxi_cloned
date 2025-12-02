import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

class SelectRangeScreen extends StatefulWidget {
  const SelectRangeScreen({super.key});

  @override
  State<SelectRangeScreen> createState() => _SelectRangeScreenState();
}

class _SelectRangeScreenState extends State<SelectRangeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Helper function to format DateTime to string
  String _formatDate(DateTime? date) {
    if (date == null) return "Input Text";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Download All"),
      body: CornerClippedScreenSimple(
        child: Column(
          children: [
        
        
            // ---------------- TO / FROM INPUTS ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("From", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  textField(_formatDate(_rangeStart)),
        
                  const SizedBox(height: 15),
        
                  const Text("To", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  textField(_formatDate(_rangeEnd)),
                ],
              ),
            ),
        
            const SizedBox(height: 20),
        
            // ---------------- CALENDAR ----------------
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) => false,
                    onRangeSelected: (start, end, focusedDay) {
                      setState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      rangeHighlightColor: Colors.blue.shade100,
                      rangeStartDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        
            // ---------------- BOTTOM BUTTONS ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Back Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Back",
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
        
                  const SizedBox(width: 16),
        
                  // Download button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rangeStart != null && _rangeEnd != null
                          ? () {
                        // Add your download logic here
                        print("Download from ${_formatDate(_rangeStart)} to ${_formatDate(_rangeEnd)}");
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Download",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- UI Helper TextField ----------
  Widget textField(String text) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: text == "Input Text" ? Colors.black54 : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          Icon(Icons.calendar_today, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}