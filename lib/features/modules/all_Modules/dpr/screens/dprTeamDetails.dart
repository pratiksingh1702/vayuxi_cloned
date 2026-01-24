import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/afd.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/work_type.dart';

// Mechanical imports
import '../../../../../typeProvider/type_provider.dart';
import '../dpr_insu/screens/testing.dart';
import '../dpr_insu/service/insulation_dpr_service.dart';
import '../models/dprModel.dart';
import '../providers/dpr.dart';
import 'add_description.dart';

// Insulation imports
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/dpr_model_insu.dart';


class DprWorkScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String name;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  const DprWorkScreen({
    required this.siteId,
    required this.teamId,
    required this.name,
    this.selectedEndDate,
    this.selectedStartDate,
    super.key,
  });

  @override
  ConsumerState<DprWorkScreen> createState() => _DprWorkScreenState();
}

class _DprWorkScreenState extends ConsumerState<DprWorkScreen> {
  DateTime? selectedDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Insulation-specific state
  List<InsulationDprModel> insulationList = [];
  bool isLoadingInsulation = false;
  String? insulationError;

  // Timer for debouncing (optional)
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _selectedStartDate = widget.selectedStartDate;
      _selectedEndDate = widget.selectedEndDate;
      _fetchDataBasedOnType();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _fetchDataBasedOnType() {
    final workType = ref.read(typeProvider);

    if (workType == WorkType.mechanical) {
      ref.read(dprProvider.notifier).fetchDprWork(
        siteId: widget.siteId,
        teamId: widget.teamId,
      );
    } else if (workType == WorkType.insulation) {
      _fetchInsulationData();
    }
  }

  Future<void> _fetchInsulationData() async {
    if (isLoadingInsulation) return;

    setState(() {
      isLoadingInsulation = true;
      insulationError = null;
    });

    try {
      final result = await InsulationDprApi.fetchInsulationDprList(
        siteId: widget.siteId,
        teamId: widget.teamId,
      );

      setState(() {
        insulationList = result;
      });
    } catch (e) {
      setState(() {
        insulationError = e.toString();
      });
    } finally {
      setState(() {
        isLoadingInsulation = false;
      });
    }
  }

  void clearDateFilter() {
    setState(() {
      selectedDate = null;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _selectedStartDate = null;
        _selectedEndDate = null;
      });
    }
  }

  void pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        _selectedStartDate = pickedRange.start;
        _selectedEndDate = pickedRange.end;
        selectedDate = null;
      });
    }
  }

  // Generic date matching helper
  bool _matchesDate(DateTime createdAt) {
    final dprDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    // Priority 1: Range filter
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final start = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
      );
      final end = DateTime(
        _selectedEndDate!.year,
        _selectedEndDate!.month,
        _selectedEndDate!.day,
      );
      return !dprDate.isBefore(start) && !dprDate.isAfter(end);
    }

    // Priority 2: Single date filter
    if (selectedDate != null) {
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      return dprDate == selected;
    }

    // Priority 3: No filter
    return true;
  }

  // Build subtitle based on work type
  String _buildSubtitle(dynamic dpr, String workType) {
    if (workType == WorkType.mechanical) {
      final mechanicalDpr = dpr as DprModel;
      return 'Size: ${mechanicalDpr.size ?? 'N/A'}  •  '
          'MOC: ${mechanicalDpr.moc ?? 'N/A'}  •  '
          'Floor: ${mechanicalDpr.location ?? 'N/A'}';
    } else {
      final insulationDpr = dpr as InsulationDprModel;
      return 'Layer: ${insulationDpr.layer}  •  '
          'Size: ${insulationDpr.size}  •  '
          'Location: ${insulationDpr.location}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final workType = ref.watch(typeProvider);

    // Fail fast if no work type is selected
    if (workType == null || !WorkType.isValid(workType)) {
      return Scaffold(
        appBar: CustomAppBar(
          title: "Work Descriptions",
        ),
        body: Center(
          child: Text(
            'Please select a work type first',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Get the appropriate data
    final dprState = ref.watch(dprProvider);
    List<dynamic> filteredList = [];
    bool isLoading = false;
    String? error;

    if (workType == WorkType.mechanical) {
      isLoading = dprState.isLoading;
      error = dprState.error;

      if (dprState.data != null) {
        final list = dprState.data as List<DprModel>;
        filteredList = list.where((dpr) => _matchesDate(dpr.createdAt)).toList();
      }
    } else {
      isLoading = isLoadingInsulation;
      error = insulationError;
      filteredList = insulationList.where((dpr) => _matchesDate(dpr.createdAt)).toList();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "${workType == WorkType.mechanical ? 'Mechanical' : 'Insulation'} Work Descriptions",

      ),
      body: BottomButtonWrapper(
        child: Column(
          children: [
            // Date Picker Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              _selectedStartDate != null && _selectedEndDate != null
                                  ? '${DateFormat('yyyy-MM-dd').format(_selectedStartDate!)} → ${DateFormat('yyyy-MM-dd').format(_selectedEndDate!)}'
                                  : selectedDate != null
                                  ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                  : 'Select Date',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: pickDateRange,
                        tooltip: 'Select Date Range',
                      ),
                      if (selectedDate != null || (_selectedStartDate != null && _selectedEndDate != null))
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: clearDateFilter,
                          tooltip: 'Clear Filter',
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    workType == WorkType.mechanical ? 'Mechanical Works' : 'Insulation Works',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Loading / Error / List
            Expanded(
              child: Builder(builder: (_) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDataBasedOnType,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list_alt_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No ${workType == WorkType.mechanical ? 'mechanical' : 'insulation'} works found',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (selectedDate != null || (_selectedStartDate != null && _selectedEndDate != null))
                          OutlinedButton(
                            onPressed: clearDateFilter,
                            child: const Text('Clear Date Filter'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final dpr = filteredList[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: workType == WorkType.mechanical
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            workType == WorkType.mechanical
                                ? Icons.build
                                : Icons.thermostat_auto,
                            color: workType == WorkType.mechanical
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                            size: 22,
                          ),
                        ),

                        // Title based on work type
                        title: Text(
                          workType == WorkType.mechanical
                              ? (dpr as DprModel).dprName
                              : (dpr as InsulationDprModel).workDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Subtitle based on work type
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _buildSubtitle(dpr, workType),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMM dd').format(
                                workType == WorkType.mechanical
                                    ? (dpr as DprModel).createdAt
                                    : (dpr as InsulationDprModel).createdAt,
                              ),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),

                        onTap: () {
                          if (workType == WorkType.mechanical) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDescriptionScreen(
                                  work: dpr as DprModel,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddInsulationDescriptionScreen(
                                  work: dpr as InsulationDprModel,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}