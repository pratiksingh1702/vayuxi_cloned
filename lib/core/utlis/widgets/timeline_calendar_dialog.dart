import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class TimelineCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final Set<DateTime> completedDates;

  const TimelineCalendarDialog({
    super.key,
    required this.initialDate,
    required this.completedDates,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required Set<DateTime> completedDates,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => TimelineCalendarDialog(
        initialDate: initialDate,
        completedDates: completedDates,
      ),
    );
  }

  @override
  State<TimelineCalendarDialog> createState() => _TimelineCalendarDialogState();
}

class _TimelineCalendarDialogState extends State<TimelineCalendarDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  bool _isCompleted(DateTime day) {
    return widget.completedDates.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (_isCompleted(day)) {
                    return Positioned(
                      right: 1,
                      top: 1,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: const Text("SELECT"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
