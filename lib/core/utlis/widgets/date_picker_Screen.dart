import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRangeSelectionScreen extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDatesSelected;

  const DateRangeSelectionScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDatesSelected,
  });

  @override
  State<DateRangeSelectionScreen> createState() =>
      _DateRangeSelectionScreenState();
}

class _DateRangeSelectionScreenState extends State<DateRangeSelectionScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    if (_startDate != null) {
      _focusedDay = _startDate!;
    }
  }

  void _clearSelection() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _selectToday() {
    final today = DateTime.now();
    setState(() {
      _startDate = today;
      _endDate = today;
      _focusedDay = today;
    });
  }

  void _selectLast7Days() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    setState(() {
      _startDate = sevenDaysAgo;
      _endDate = today;
      _focusedDay = today;
    });
  }

  void _selectLast30Days() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 29));
    setState(() {
      _startDate = thirtyDaysAgo;
      _endDate = today;
      _focusedDay = today;
    });
  }

  void _selectThisMonth() {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    setState(() {
      _startDate = firstDayOfMonth;
      _endDate = today;
      _focusedDay = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date Range'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface.withOpacity(0),
        foregroundColor: cs.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
        ],
      ),
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Quick Selection Buttons
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickButton(
                    label: 'Today',
                    icon: Icons.today,
                    onTap: _selectToday,
                    isActive: _startDate != null &&
                        _endDate != null &&
                        _startDate!.day == DateTime.now().day &&
                        _endDate!.day == DateTime.now().day,
                  ),
                  const SizedBox(width: 8),
                  _QuickButton(
                    label: 'Last 7 Days',
                    icon: Icons.calendar_view_week,
                    onTap: _selectLast7Days,
                  ),
                  const SizedBox(width: 8),
                  _QuickButton(
                    label: 'Last 30 Days',
                    icon: Icons.calendar_view_month,
                    onTap: _selectLast30Days,
                  ),
                  const SizedBox(width: 8),
                  _QuickButton(
                    label: 'This Month',
                    icon: Icons.date_range,
                    onTap: _selectThisMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selected Dates Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DateDisplay(
                    label: 'From',
                    date: _startDate,
                    isSelected: _startDate != null,
                  ),
                  Icon(Icons.arrow_forward, color: cs.onSurfaceVariant),
                  _DateDisplay(
                    label: 'To',
                    date: _endDate,
                    isSelected: _endDate != null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? cs.surfaceContainer : cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  rangeStartDay: _startDate,
                  rangeEndDay: _endDate,
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  selectedDayPredicate: (day) => false,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      if (_startDate == null ||
                          (_startDate != null && _endDate != null)) {
                        _startDate = selectedDay;
                        _endDate = null;
                      } else if (selectedDay.isAfter(_startDate!)) {
                        _endDate = selectedDay;
                      } else {
                        _endDate = _startDate;
                        _startDate = selectedDay;
                      }
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    rangeStartDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    withinRangeDecoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    defaultDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    weekendDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    outsideDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    disabledDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: cs.primary,
                      size: 24,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: cs.primary,
                      size: 24,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: cs.outlineVariant, width: 0.5),
                      ),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    weekendStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              widget.onDatesSelected(_startDate!, _endDate!);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: cs.surfaceContainerHighest,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isActive ? cs.primaryContainer : cs.surfaceContainerLowest,
        foregroundColor: isActive ? cs.primary : cs.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DateDisplay extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isSelected;

  const _DateDisplay({
    required this.label,
    required this.date,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date!)
                    : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
