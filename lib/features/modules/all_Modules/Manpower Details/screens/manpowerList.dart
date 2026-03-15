import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/offline/repo/att_sync.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../attendance/offline/repo/att_offline_provider.dart';
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
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedManpowerIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final type = ref.read(typeProvider);
      if (type != null && type.isNotEmpty) {
        ref.invalidate(manpowerSyncControllerProvider((type: type!)));
        // ref.read(manpowerProvider.notifier).fetchManpower(type);
      } else {
        debugPrint("❌ Type not set in typeProvider");
      }
    });
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedManpowerIds.clear();
      }
    });
  }

  /// Toggle individual manpower selection
  void _toggleManpowerSelection(String manpowerId) {
    setState(() {
      if (_selectedManpowerIds.contains(manpowerId)) {
        _selectedManpowerIds.remove(manpowerId);
      } else {
        _selectedManpowerIds.add(manpowerId);
      }
    });
  }

  /// Select all manpower
  void _selectAllManpower(List<ManpowerModel> manpowerList) {
    setState(() {
      for (var manpower in manpowerList) {
        if (manpower.id != null) {
          _selectedManpowerIds.add(manpower.id!);
        }
      }
    });
  }

  /// Delete selected manpower
  Future<void> _deleteSelectedManpower() async {
    if (_selectedManpowerIds.isEmpty) {
  AppToast.show('No manpower selected');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Manpower'),
        content: Text(
          'Are you sure you want to delete ${_selectedManpowerIds.length} selected manpower records?\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(attendanceRepositoryProvider);

      for (final id in _selectedManpowerIds) {
        await repo.deleteManpowerLocal(id);
      }
      final result = await ManpowerAPI.bulkDeleteManpower(
        _selectedManpowerIds.toList(),
      );

      if (result['success'] == true) {
        // Refresh manpower list
        final type = ref.read(typeProvider);





        if (mounted) {
         AppToast.success('Successfully deleted ${_selectedManpowerIds.length} manpower records');
        }

        setState(() {
          _selectedManpowerIds.clear();
          _isSelectionMode = false;
        });
      } else {
        if (mounted) {
         AppToast.error(result['message'] ?? 'Failed to delete manpower');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');

      if (mounted) {
       AppToast.error('Bulk delete failed: ${e.toString()}');
      }
    }
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

    await ref.read(manpowerProvider.notifier).leftManpower(id, data, type);

   AppToast.info("✅ Manpower marked as left");
  }

  @override
  @override
  Widget build(BuildContext context) {
    final type = ref.read(typeProvider)!;


    final manpowerAsync = ref.watch(
      manpowerOfflineProvider(( type: type)),
    );
    final syncState =
    ref.watch(manpowerSyncControllerProvider((type: type)));


    return Scaffold(
      drawer: const CustomDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: _isSelectionMode
                  ? '${_selectedManpowerIds.length} Selected'
                  : "View Manpower Details",
            ),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: "View Sheet",
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: () async {
                  final list = manpowerAsync.value ?? [];

                  await exportToExcel(
                    list.map((m) => m.toJson()).toList(),
                  );

               AppToast.success("✅ Excel saved in Downloads folder");
                },
              ),
            ),
          ],
          child: manpowerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),

            error: (e, s) => Center(child: Text("Error: $e")),

            data: (manpowerList) {
              if (manpowerList.isEmpty) {
                if (syncState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return const Center(
                  child: Text(
                    "No manpower found",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                );
              }


              return Column(
                children: [
                  /// TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isSelectionMode) ...[
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSelectionMode,
                        ),
                        TextButton(
                          onPressed: () => _selectAllManpower(manpowerList),
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete'),
                          onPressed: _selectedManpowerIds.isEmpty
                              ? null
                              : _deleteSelectedManpower,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: manpowerList.isEmpty
                              ? null
                              : _toggleSelectionMode,
                        ),
                      ],
                    ],
                  ),

                  /// LIST
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: manpowerList.length,
                      itemBuilder: (context, index) {
                        final manpower = manpowerList[index];
                        final isSelected =
                        _selectedManpowerIds.contains(manpower.id);

                        return _buildManpowerTile(manpower, isSelected);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildManpowerTile(ManpowerModel manpower, bool isSelected) {
    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              onTap: _isSelectionMode
                  ? () => _toggleManpowerSelection(manpower.id!)
                  : null,
              leading: const Icon(
                Icons.person_2_outlined,
                color: Colors.blue,
              ),
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
              trailing: _isSelectionMode
                  ? null
                  : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✏️ Edit
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      print(const JsonEncoder.withIndent('  ').convert(manpower.toJson()));
                      context.push('/edit-manpower', extra: manpower);
                    },
                  ),

                  // 🚪 Mark Left
                  IconButton(
                    icon: const Icon(
                      Icons.person_off,
                      color: Colors.orange,
                    ),
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
          ),
        ),

        // Selection checkbox overlay
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleManpowerSelection(manpower.id!),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.white,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
                    : null,
              ),
            ),
          ),
      ],
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

    final repo = ref.read(attendanceRepositoryProvider);

    /// 1️⃣ DELETE LOCALLY FIRST (instant UI update)
    await repo.deleteManpowerLocal(manpowerId);

    try {

      /// 2️⃣ DELETE ON SERVER
      final res = await ManpowerAPI.deleteManpower(manpowerId);

      if (res['success'] != true) {
        throw Exception("Server delete failed");
      }

    } catch (e) {

      /// 3️⃣ OPTIONAL: rollback if server fails
      debugPrint("Server delete failed: $e");

    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Manpower deleted")),
    );
  }
}