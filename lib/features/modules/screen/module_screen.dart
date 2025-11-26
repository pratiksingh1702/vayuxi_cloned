import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({super.key});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  int _currentIndex = 0;

  // Define your module items
  final List<ModuleItem> _moduleItems = [
    ModuleItem(
      label: "Site Details",
      icon: Icons.location_city,
      routeName: "/site-list/site",
      color: Colors.blue,
    ),
    ModuleItem(
      label: "Rate",
      icon: Icons.attach_money,
      routeName: "/site-list/rate",
      color: Colors.green,
    ),
      ModuleItem(
      label: "DPRS",
      icon: Icons.phonelink_setup,
      routeName: "/site-list/addMoc",
      color: Colors.green,
    ),

    ModuleItem(
      label: "Manpower Details",
      icon: Icons.group,
      routeName: "/manpower",
      color: Colors.orange,
    ),
    ModuleItem(
      label: "Create Team",
      icon: Icons.group_add,
      routeName: "/site-list/team",
      color: Colors.teal,
    ),
    ModuleItem(
      label: "DPR Report",
      icon: Icons.description,
      routeName: "/site-list/dpr",
      color: Colors.purple,
    ),
    ModuleItem(
      label: "Attendance",
      icon: Icons.check_circle,
      routeName: "/site-list/attendance",
      color: Colors.red,
    ),
    ModuleItem(
      label: "Add Expense",
      icon: Icons.receipt_long,
      routeName: "/site-list/expense",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "ISETUP",
      icon: Icons.receipt_long,
      routeName: "/site-list/inv-setup",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "DPR SHEETS",
      icon: Icons.analytics,
      routeName: "/site-list/dprReport",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Summary Analysis",
      icon: Icons.bar_chart,
      routeName: "/summary",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      label: "Salary",
      icon: Icons.payments,
      routeName: "/salary",
      color: Colors.brown,
    ),
    ModuleItem(
      label: "Profile",
      icon: Icons.person,
      routeName: "/profile",
      color: Colors.cyan,
    ),
    ModuleItem(
      label: "Upgrade 2.0",
      icon: Icons.upgrade,
      routeName: "upgrade",
      color: Colors.pink,
    ),
  ];

  // Group modules for each tab - UPDATED to match new labels
  List<ModuleItem> get _currentModules {
    switch (_currentIndex) {
      case 0: // Daily Entry
        return _moduleItems
            .where((m) => [
          "Attendance",
          "DPR Report",
          "Add Expense",
        ].contains(m.label))
            .toList();
      case 1: // Setup
        return _moduleItems
            .where((m) => [
          "Site Details",
          "Manpower Details",
          "Create Team",
          "Rate",
          "DPRS",
          "ISETUP"
        ].contains(m.label))
            .toList();
      case 2: // Report
        return _moduleItems
            .where((m) => [
          "Summary Analysis",
          "Salary",
          "DPR SHEETS"
        ].contains(m.label))
            .toList();
      case 3: // More
        return _moduleItems
            .where((m) => [
          "Profile",
          "Upgrade 2.0",
        ].contains(m.label))
            .toList();
      default:
        return [];
    }
  }

  // Header title per tab
  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return "Daily Entry";
      case 1:
        return "Set Up";
      case 2:
        return "Report";
      case 3:
        return "More";
      default:
        return "Modules";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _currentTitle),
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔹 Grid of Modules
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _currentModules.isEmpty
                    ? const Center(
                  child: Text(
                    "No modules available",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : GridView.builder(
                  itemCount: _currentModules.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = _currentModules[index];
                    return GestureDetector(
                      onTap: () => context.push(item.routeName),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),

                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 32,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            label: 'Daily Entry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// 🔹 Module model
class ModuleItem {
  final String label;
  final IconData icon;
  final String routeName;
  final Color color;

  ModuleItem({
    required this.label,
    required this.icon,
    required this.routeName,
    this.color = Colors.blue,
  });
}