import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import '../../../../../core/utlis/widgets/afd.dart';
import '../models/dprModel.dart';

import 'package:intl/intl.dart';

import '../providers/dpr.dart';
import 'add_description.dart';
import 'dprDetails.dart';

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
    this.selectedEndDate,this.selectedStartDate,

    super.key,
  });

  @override
  ConsumerState<DprWorkScreen> createState() => _DprWorkScreenState();
}

class _DprWorkScreenState extends ConsumerState<DprWorkScreen> {
  DateTime? selectedDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _selectedStartDate = widget.selectedStartDate;
      _selectedEndDate = widget.selectedEndDate;
      ref.read(dprProvider.notifier).fetchDprWork(
        siteId: widget.siteId,
        teamId: widget.teamId,
      );
    });

  }

  void clearDateFilter() {
    setState(() {
      selectedDate = null;
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
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final dprState = ref.watch(dprProvider);
    List<DprModel> filteredList = [];
    if (dprState.data != null) {
      final list = dprState.data as List<DprModel>;

      filteredList = list.where((dpr) {
        final dprDate = DateTime(
          dpr.createdAt.year,
          dpr.createdAt.month,
          dpr.createdAt.day,
        );

        // 🔥 PRIORITY 1: RANGE FILTER
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

        // 🔥 PRIORITY 2: SINGLE DATE FILTER
        if (selectedDate != null) {
          final selected = DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
          );

          return dprDate == selected;
        }

        // 🔥 PRIORITY 3: NO FILTER
        return true;
      }).toList();
    }


    return Scaffold(
      appBar: CustomAppBar(
        title: "Work Descriptions",

      ),
      body: BottomButtonWrapper(
        child: Column(
          children: [
            // Date Picker
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          _selectedStartDate != null && _selectedEndDate != null
                              ? '${DateFormat('yyyy-MM-dd').format(_selectedStartDate!)}'
                              ' → ${DateFormat('yyyy-MM-dd').format(_selectedEndDate!)}'
                              : selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                              : 'Select Date',
                          style: const TextStyle(fontSize: 16),
                        ),


                      ),
                    ),
                  ),
        if (selectedDate != null)
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: clearDateFilter,
    ),

                ],
              ),
            ),

            // Loading / Error / List
            Expanded(
              child: Builder(builder: (_) {
                if (dprState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (dprState.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${dprState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'No data found',
                      style: const TextStyle(fontSize: 16),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description,
                            color: Colors.blue.shade700,
                            size: 22,
                          ),
                        ),

                        // 🔹 MAIN NAME
                        title: Text(
                          dpr.dprName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 🔹 SMALL INFO TEXT
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: ${dpr.size ?? 'N/A'}  •  '
                                'MOC: ${dpr.moc ?? 'N/A'}  •  '
                                'Floor: ${dpr.location ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),

                        onTap: () {
                          print("❤️❤️❤️❤️❤️❤️❤️ ${dpr.id}");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddDescriptionScreen(work: dpr),
                            ),
                          );
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
