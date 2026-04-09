import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/afd.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/work_type.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';

// Mechanical imports
import '../../../../../core/router/routes.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/date_picker.dart';
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
  final String name;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  const DprWorkScreen({
    required this.siteId,
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

  // Multi-select team filter
  Set<String> _selectedTeamIds = {};

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
      _fetchTeams();
      _fetchDataBasedOnType();
    });
  }

  Future<void> _fetchTeams() async {
    final workType = ref.read(typeProvider);
    if (workType == WorkType.mechanical) {
      await ref.read(teamProvider.notifier).fetchMechanicalCombined(siteId: widget.siteId);
    } else if (workType == WorkType.insulation) {
      await ref.read(teamProvider.notifier).fetchInsulationCombined(siteId: widget.siteId);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  Future<void> _showBeautifulDatePicker(
      BuildContext context, {
        required bool isStartDate,
      }) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        title: isStartDate ? "Select Start Date" : "Select End Date",
        primaryColor: Colors.blue,      // use your AppColors if available
        accentColor: Colors.blueAccent, // use your AppColors if available
        backgroundColor: Colors.white,  // use your AppColors if available
      ),
    );

    if (selected == null) return;

    setState(() {
      if (isStartDate) {
        _selectedStartDate = selected;
        // reset end date if invalid
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(selected)) {
          _selectedEndDate = null;
        }

        // ✅ IMPORTANT: when picking range, remove single-date mode
        selectedDate = null;
      } else {
        _selectedEndDate = selected;

        // ✅ IMPORTANT: when picking range, remove single-date mode
        selectedDate = null;
      }
    });
  }

  void _fetchDataBasedOnType() {
    final workType = ref.read(typeProvider);

    if (workType == WorkType.mechanical) {
      ref.read(dprProvider.notifier).fetchSiteDprWork(
        siteId: widget.siteId,
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
      final result = await InsulationDprApi.fetchSiteInsulationDprV2(
        siteId: widget.siteId,
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

  Future<void> pickDate() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        title: "Select Date",
        primaryColor: Colors.blue,
        accentColor: Colors.blueAccent,
        backgroundColor: Colors.white,
      ),
    );

    if (selected == null) return;

    setState(() {
      selectedDate = selected;

      // ✅ when using single date filter, clear range
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
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
  bool _matchesDate(DateTime date) {
    // 🔥 DO NOT convert to local
    final dprDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

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

    if (selectedDate != null) {
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );

      return dprDate == selected;
    }

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

  Widget _buildTeamFilter() {
    final teamState = ref.watch(teamProvider);
    if (teamState.teams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            "Filter by Teams",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: teamState.teams.length,
            itemBuilder: (context, index) {
              final team = teamState.teams[index];
              final isSelected = _selectedTeamIds.contains(team.id);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    team.teamName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTeamIds.add(team.id);
                      } else {
                        _selectedTeamIds.remove(team.id);
                      }
                    });
                  },
                  selectedColor: Colors.blue,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  Future<void> _deleteDpr(dynamic dpr) async {
    final workType = ref.read(typeProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Work"),
        content: const Text(
          "Are you sure you want to delete this work?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (workType == WorkType.mechanical) {
        await ref.read(dprProvider.notifier).deleteDpr(dpr.id);

        // 🔥 REMOVE LOCALLY IN PROVIDER
        ref.read(dprProvider.notifier).removeLocalDpr(dpr.id);

      } else {
        // await InsulationDprApi.deleteInsulationDpr(dpr.id);

        // 🔥 REMOVE LOCALLY FROM LIST
        setState(() {
          insulationList.removeWhere((item) => item.id == dpr.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("DPR deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workType = ref.watch(typeProvider);
    final team=ref.read(currentTeamProvider);

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

        print("🔍 Total DPRs received: ${list.length}");
        print("🎯 Selected Team IDs: $_selectedTeamIds");

        filteredList = list.where((dpr) {
          final matchesDate = _matchesDate(dpr.date);
          final cleanTeamId = dpr.teamId.trim();
          final matchesTeam = _selectedTeamIds.isEmpty ||
              _selectedTeamIds.any((id) => id.trim() == cleanTeamId);

          // 🔥 Debug each item
          print("""
📌 DPR CHECK:
- Date: ${dpr.date}
- TeamId (raw): '${dpr.teamId}'
- TeamId (clean): '$cleanTeamId'
- Matches Date: $matchesDate
- Matches Team: $matchesTeam
- FINAL RESULT: ${matchesDate && matchesTeam}
""");

          return matchesDate && matchesTeam;
        }).toList();

        print("✅ Filtered DPR count: ${filteredList.length}");
      }
    } else {
      isLoading = isLoadingInsulation;
      error = insulationError;
      filteredList = insulationList.where((dpr) {
        final matchesDate = _matchesDate(dpr.date);
        final cleanTeamId = (dpr.teamId ?? "").trim();
        final matchesTeam = _selectedTeamIds.isEmpty || (dpr.teamId != null && _selectedTeamIds.any((id) => id.trim() == cleanTeamId));
        return matchesDate && matchesTeam;
      }).toList();
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "Work Descriptions",
      ),
      body: BottomButtonWrapper(
        child: Column(
          children: [
            // Date Picker Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ✅ FROM date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "From",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedStartDate != null
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: _selectedStartDate != null ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedStartDate != null
                                            ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
                                            : "Select start date",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedStartDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedStartDate != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ✅ TO date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "To",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedEndDate != null
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: _selectedEndDate != null ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedEndDate != null
                                            ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                            : "Select end date",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedEndDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedEndDate != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ clear filter icon (cross) — keep this like you want
                      if (selectedDate != null || (_selectedStartDate != null && _selectedEndDate != null))
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            onTap: clearDateFilter,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ✅ quick action buttons row (single date + date range)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.event_available),
                          label: const Text("Single Date"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickDateRange,
                          icon: const Icon(Icons.date_range),
                          label: const Text("Date Range"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Team Filter Section
            _buildTeamFilter(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
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

                // if (error != null) {
                //   return Center(
                //     child: Column(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         const Icon(Icons.error_outline, color: Colors.red, size: 48),
                //         const SizedBox(height: 16),
                //         Text(
                //           'Error: $error',
                //           style: const TextStyle(color: Colors.red),
                //           textAlign: TextAlign.center,
                //         ),
                //         const SizedBox(height: 16),
                //         ElevatedButton(
                //           onPressed: _fetchDataBasedOnType,
                //           child: const Text('Retry'),
                //         ),
                //       ],
                //     ),
                //   );
                // }

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

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [ 
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('MMM dd').format(
                                    DateTime(
                                      (workType == WorkType.mechanical
                                          ? (dpr as DprModel).date
                                          : (dpr as InsulationDprModel).date)
                                          .year,
                                      (workType == WorkType.mechanical
                                          ? (dpr as DprModel).date
                                          : (dpr as InsulationDprModel).date)
                                          .month,
                                      (workType == WorkType.mechanical
                                          ? (dpr as DprModel).date
                                          : (dpr as InsulationDprModel).date)
                                          .day,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteDpr(dpr),
                            ),
                          ],
                        ),

                        onTap: () {
                          if (workType == WorkType.mechanical) {
                            context.push(Routes.dprDescription, extra: dpr as DprModel);
                          } else {
                            context.push(Routes.dprInsuDescription, extra: dpr as InsulationDprModel);
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