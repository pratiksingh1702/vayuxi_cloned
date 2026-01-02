import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';
import '../service/manpowerService.dart';
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
  Future<void> _confirmLeftManpower(
      BuildContext context,
      ManpowerModel manpower,
      ) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark Manpower as Left"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Optional: Mention reason for leaving",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Reason (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // ❌ Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          // ⏭ Skip
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Skip"),
          ),

          // ✅ Submit
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Mark Left"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _markManpowerLeft(
        manpower.id!,
        reasonController.text.trim(),
      );
    }
  }
  Future<void> _markManpowerLeft(String id, String reason) async {
    final type = ref.read(typeProvider);
    if (type == null) return;

    final data = {
      "reason": reason.isEmpty ? "Not specified" : reason,
    };

    await ref
        .read(manpowerProvider.notifier)
        .leftManpower(id, data, type);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Manpower marked as left")),
    );
  }


  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);

    return Scaffold(


      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "View Manpower Details"),
          ];
        },

        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
                button: RoundedButton
                  (text: "View Sheet",
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: () async {
                      await exportToExcel(manpowerState
                                              .manpowerList
                                              .map((m) => m.toJson())
                                              .toList());
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "✅ Excel saved in Downloads folder")));
                    }))
          ],

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
                          manpower.fullName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          manpower.employeeCode ?? "",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ✏️ Edit
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                context.push('/edit-manpower', extra: manpower);
                              },
                            ),

                            // 🚪 Mark Left
                            IconButton(
                              icon: const Icon(Icons.person_off, color: Colors.orange),
                              onPressed: () {
                                _confirmLeftManpower(context, manpower);
                              },
                            ),

                            // 🗑 Delete
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDelete(context, manpower.id!);
                              },
                            ),
                          ],
                        ),


                      ),
                    );
                  },
                ),
              ),

              // Footer Buttons
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //       horizontal: 16, vertical: 14),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: const BorderRadius.vertical(
              //         top: Radius.circular(24)),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black12.withOpacity(0.1),
              //         blurRadius: 12,
              //         offset: const Offset(0, -4),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     children: [
              //       // Add Manpower Button
              //       SizedBox(
              //         width: double.infinity,
              //         child: ElevatedButton.icon(
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: Colors.blue.shade700,
              //             padding:
              //             const EdgeInsets.symmetric(vertical: 16),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(30),
              //             ),
              //           ),
              //           icon: const Icon(Icons.add_circle,
              //               color: Colors.white),
              //           label: const Text(
              //             "Add Manpower Details",
              //             style: TextStyle(
              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w600,
              //               color: Colors.white
              //             ),
              //           ),
              //           onPressed: () {
              //             context.push('/manpower/addDetails');
              //           },
              //         ),
              //       ),
              //       const SizedBox(height: 12),
              //
              //       // Row of Buttons
              //       Row(
              //         children: [
              //           Expanded(
              //             child: OutlinedButton.icon(
              //               style: OutlinedButton.styleFrom(
              //                 padding: const EdgeInsets.symmetric(
              //                     vertical: 14),
              //                 side: const BorderSide(
              //                     color: Colors.black54),
              //                 shape: RoundedRectangleBorder(
              //                   borderRadius: BorderRadius.circular(30),
              //                 ),
              //               ),
              //               icon: const Icon(Icons.arrow_back),
              //               label: const Text("Back"),
              //               onPressed: () => Navigator.pop(context),
              //             ),
              //           ),
              //           const SizedBox(width: 12),
              //           Expanded(
              //             child: ElevatedButton.icon(
              //               style: ElevatedButton.styleFrom(
              //                 backgroundColor: Colors.teal,
              //                 padding: const EdgeInsets.symmetric(
              //                     vertical: 14),
              //                 shape: RoundedRectangleBorder(
              //                   borderRadius: BorderRadius.circular(30),
              //                 ),
              //               ),
              //               icon: const Icon(Icons.table_chart,
              //                   color: Colors.white),
              //               label: const Text("View Sheet",style: TextStyle(
              //                 color: Colors.white
              //               ),),
              //               onPressed: () async {
              //                 await exportToExcel(manpowerState
              //                     .manpowerList
              //                     .map((m) => m.toJson())
              //                     .toList());
              //                 ScaffoldMessenger.of(context)
              //                     .showSnackBar(const SnackBar(
              //                     content: Text(
              //                         "✅ Excel saved in Downloads folder")));
              //               },
              //             ),
              //           ),
              //
              //
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _confirmDelete(BuildContext context, String manpowerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Manpower"),
        content: const Text(
          "Are you sure you want to delete this manpower?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteManpower(context, manpowerId);
    }
  }
  Future<void> _deleteManpower(BuildContext context, String manpowerId) async {
    final res = await ManpowerAPI.deleteManpower(manpowerId);

    if (res['success'] == true) {
      // 🔥 REFRESH LIST
      final type = ref.read(typeProvider);
      ref.read(manpowerProvider.notifier).fetchManpower(type!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower deleted")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Delete failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


}
