import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A horizontal scrolling date picker for quick navigation between days.
/// Used primarily in Multi-Entry mode for Attendance and DPR.
class TimelineDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Set<DateTime> completedDates;

  const TimelineDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.completedDates = const {},
  });

  @override
  State<TimelineDatePicker> createState() => _TimelineDatePickerState();
}

class _TimelineDatePickerState extends State<TimelineDatePicker> {
  late ScrollController _scrollController;
  final List<DateTime> _dates = [];
  final double _itemWidth = 34.0; // Ultra compact

  @override
  void initState() {
    super.initState();
    _generateDates();
    _scrollController = ScrollController();
    
    // Auto-scroll to selected date after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _generateDates() {
    final today = DateTime.now();
    // Show 31 days (15 back, 15 forward)
    final start = today.subtract(const Duration(days: 15));
    for (int i = 0; i <= 30; i++) {
      _dates.add(start.add(Duration(days: i)));
    }
  }

  void _scrollToSelected() {
    final index = _dates.indexWhere((d) => _isSameDay(d, widget.selectedDate));
    if (index != -1 && _scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = (index * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  void didUpdateWidget(TimelineDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48, // Ultra compact
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = _isSameDay(date, widget.selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                final isCompleted = widget.completedDates.any((d) => _isSameDay(d, date));

                return GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: Container(
                    width: _itemWidth - 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday && !isSelected
                          ? Border.all(color: cs.primary.withOpacity(0.3), width: 1)
                          : isSelected 
                            ? null 
                            : Border.all(color: cs.outlineVariant.withOpacity(0.1), width: 0.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date).substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white70 : cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.white : cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        
                        // Green checkmark for completion
                        if (isCompleted)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 10,
                              color: isSelected ? Colors.white : Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
