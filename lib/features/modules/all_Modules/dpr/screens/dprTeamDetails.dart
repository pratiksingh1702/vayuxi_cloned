import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dprModel.dart';

import 'package:intl/intl.dart';

import '../providers/dpr.dart';
import 'dprDetails.dart';

class DprWorkScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String name;

  const DprWorkScreen({
    required this.siteId,
    required this.teamId,
    required this.name,
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
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dprProvider.notifier).fetchDprWork(
                siteId: widget.siteId,
                teamId: widget.teamId,
              );
            },
          ),
        ],
      ),
      body: Column(
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

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final dpr = filteredList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(dpr.dprName),
                      subtitle: Text('Location: ${dpr.location} | Size: ${dpr.size}'),
                      // In your existing DprWorkScreen, update the onTap in ListTile:
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DprDetailScreen(
                              dpr: dpr,
                              teamName: widget.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),

          // Add & Back Buttons
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to stepper/add DPR
                  },
                  child: const Text('Add Description'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
