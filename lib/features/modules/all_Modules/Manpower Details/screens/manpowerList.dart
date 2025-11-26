import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';
import '../util/ViewExcel.dart';

class ManpowerListScreen extends ConsumerStatefulWidget {
  const ManpowerListScreen({super.key});

  @override
  ConsumerState<ManpowerListScreen> createState() => _ManpowerListScreenState();
}

class _ManpowerListScreenState extends ConsumerState<ManpowerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final type = ref.read(typeProvider);
      if (type != null && type.isNotEmpty) {
        ref.read(manpowerProvider.notifier).fetchManpower(type);
      } else {
        debugPrint("❌ Type not set in typeProvider");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,


      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Employee List"),
          ];
        },

        body: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black,


            ),

            child: manpowerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : manpowerState.manpowerList.isEmpty
                ? const Center(
              child: Text(
                "No manpower found",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Employee List
                Expanded(
                  child: ListView.builder(
                    padding:  const EdgeInsets.symmetric(horizontal: 16),

                    itemCount: manpowerState.manpowerList.length,
                    itemBuilder: (context, index) {
                      final ManpowerModel manpower =
                      manpowerState.manpowerList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),

                        ),
                        child: ListTile(

                          leading: Icon(Icons.person_2_outlined,color: Colors.blue,),
                          title: Text(
                            manpower.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            manpower.employeeCode ?? "",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          trailing: IconButton(

                            onPressed: () {
                              context.push('/edit-manpower',
                                  extra: manpower);
                            },
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer Buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Add Manpower Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle,
                              color: Colors.white),
                          label: const Text(
                            "Add Manpower Details",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              color: Colors.white
                            ),
                          ),
                          onPressed: () {
                            context.push('/manpower/addDetails');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row of Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                side: const BorderSide(
                                    color: Colors.black54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Back"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.table_chart,
                                  color: Colors.white),
                              label: const Text("View Sheet",style: TextStyle(
                                color: Colors.white
                              ),),
                              onPressed: () async {
                                await exportToExcel(manpowerState
                                    .manpowerList
                                    .map((m) => m.toJson())
                                    .toList());
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                    content: Text(
                                        "✅ Excel saved in Downloads folder")));
                              },
                            ),
                          ),


                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
