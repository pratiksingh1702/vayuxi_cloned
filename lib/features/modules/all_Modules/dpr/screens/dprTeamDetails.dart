import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import '../../../../../core/utlis/widgets/afd.dart';
import '../models/dprModel.dart';

import 'package:intl/intl.dart';

import '../providers/dpr.dart';
import 'dprDetails.dart';

class DprWorkScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String name;
  final Widget Function(BuildContext context, DprModel dpr)? pageBuilder;

  const DprWorkScreen({
    required this.siteId,
    required this.teamId,
    required this.name,
    this.pageBuilder,
    super.key,
  });

  @override
  ConsumerState<DprWorkScreen> createState() => _DprWorkScreenState();
}

class _DprWorkScreenState extends ConsumerState<DprWorkScreen> {
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dprProvider.notifier).fetchDprWork(
        siteId: widget.siteId,
        teamId: widget.teamId,
      );
    });

  }

  void clearDateFilter() {
    setState(() {
      selectedDate = '';
    });
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isNotEmpty
          ? DateTime.parse(selectedDate)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dprState = ref.watch(dprProvider);

    List<DprModel> filteredList = [];
    if (dprState.data != null) {
      filteredList = (dprState.data as List<DprModel>)
          .where((dpr) {
        if (selectedDate.isEmpty) return true;
        final dprDate = DateFormat('yyyy-MM-dd').format(dpr.createdAt);
        return dprDate == selectedDate;
      })
          .toList();
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
                          selectedDate.isEmpty
                              ? 'Select Date'
                              : selectedDate,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  if (selectedDate.isNotEmpty)
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


                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final dpr = filteredList[index];
                    return SelectCard(
                      icon: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 32,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dpr.location ?? 'No Location',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Size: ${dpr.size ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      label: dpr.dprName,
                      onTap: () {
                        if (widget.pageBuilder != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => widget.pageBuilder!(context, dpr),
                            ),
                          );
                        } else {
                          // ✅ DEFAULT behavior (unchanged)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DprDetailScreen(
                                dpr: dpr,
                                teamName: widget.name,
                              ),
                            ),
                          );
                        }
                      },

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
