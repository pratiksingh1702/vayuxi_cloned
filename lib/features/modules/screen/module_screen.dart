import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamService.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';

import '../../../core/utlis/widgets/sidebar.dart';
import '../all_Modules/site_Details/providers/siteProvider.dart';
import '../all_Modules/site_Details/providers/site_current_provider.dart';
import '../all_Modules/team/provider/teamProvider.dart';
import 'craosule_banner.dart';
import 'device_id.dart';
import 'device_id_helper.dart';

class ModuleScreen extends ConsumerStatefulWidget {
  const ModuleScreen({super.key});

  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  int _currentIndex = 0;
  SiteModel? _selectedSite;
  TeamModel? _selectedTeam;

  // Define modules by category with image paths
  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(
      label: "Attendance",
      imagePath: "assets/images/icons/attendance.webp",
      routeName: "/site-list/attendance",
      color: Colors.red,
    ),
    ModuleItem(
      label: "Daily Progress",
      imagePath: "assets/images/icons/dpr.webp",
      routeName: "/site-list/dpr",
      color: Colors.purple,
    ),
    ModuleItem(
      label: "Expense",
      imagePath: "assets/images/icons/expense_daily.webp",
      routeName: "/site-list/add-exp",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Inventory Entry",
      imagePath: "assets/images/icons/inventory_entry.webp",
      routeName: "/site-list/inv-entry",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "",
      imagePath: "",
      routeName: "",
      color: Colors.transparent,
      isEmpty: true,
    ),
    ModuleItem(
      label: "",
      imagePath: "",
      routeName: "",
      color: Colors.transparent,
      isEmpty: true,
    ),
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(
      label: "Site Details",
      imagePath: "assets/images/icons/site_details.webp",
      routeName: "/site",
      color: Colors.blue,
    ),
    ModuleItem(
      label: "Rate",
      imagePath: "assets/images/icons/rate.webp",
      routeName: "/site-list/rate",
      color: Colors.green,
    ),
    ModuleItem(
      label: "Manpower Details",
      imagePath: "assets/images/icons/manpower_setup.webp",
      routeName: "/manpower",
      color: Colors.orange,
    ),
    ModuleItem(
      label: "Create Team",
      imagePath: "assets/images/icons/add_team.webp",
      routeName: "/site-list/team",
      color: Colors.teal,
    ),
    ModuleItem(
      label: "Dpr Set Up",
      imagePath: "assets/images/icons/dpr_setup.webp",
      routeName: "/site-list/addMoc",
      color: Colors.green,
    ),
    ModuleItem(
      label: "Inventory Setup",
      imagePath: "assets/images/icons/inventory_setup.webp",
      routeName: "/site-list/inv-setup",
      color: Colors.indigo,
    ),
  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(
      label: "Summary & Analysis",
      imagePath: "assets/images/icons/summary_analysis.webp",
      routeName: "/summary",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      label: "Salary Slip",
      imagePath: "assets/images/icons/salary_slip.webp",
      routeName: "/salary",
      color: Colors.brown,
    ),
    ModuleItem(
      label: "DPR SHEETS",
      imagePath: "assets/images/icons/dpr_report.webp",
      routeName: "/site-list/dprReport",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Expense Report",
      imagePath: "assets/images/icons/expense_sheet.webp",
      routeName: "/site-list/expense",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Attendance Sheet",
      imagePath: "assets/images/icons/attendance_sheet.webp",
      routeName: "/site-list/att-sheet",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      label: "Inventory Report",
      imagePath: "assets/images/icons/inventory_summary.webp",
      routeName: "/site-list/inv-Report",
      color: Colors.deepPurple,
    ),
  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(
      label: "Profile",
      imagePath: "assets/images/icons/profile.webp",
      routeName: "/profile",
      color: Colors.cyan,
    ),
    ModuleItem(
      label: "Subscription",
      imagePath: "assets/images/icons/subscription.webp",
      routeName: "/subscription",
      color: Colors.amber,
    ),
    ModuleItem(
      label: "Upcoming Update",
      imagePath: "assets/images/icons/updates.webp",
      routeName: "/upcoming-update",
      color: Colors.green,
    ),
    ModuleItem(
      label: "Theme",
      imagePath: "assets/images/icons/theme.webp",
      routeName: "/theme",
      color: Colors.purple,
    ),
    ModuleItem(
      label: "Language",
      imagePath: "assets/images/icons/language.webp",
      routeName: "/language",
      color: Colors.blue,
    ),
    ModuleItem(
      label: "Help",
      imagePath: "assets/images/icons/help.webp",
      routeName: "/help",
      color: Colors.orange,
    ),
  ];

  List<ModuleItem> get _currentModules {
    switch (_currentIndex) {
      case 0:
        return _dailyEntryModules;
      case 1:
        return _setupModules;
      case 2:
        return _reportModules;
      case 3:
        return _moreModules;
      default:
        return [];
    }
  }

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("[INIT] Fetching sites");
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  void _onSiteChanged(SiteModel? newSite) {
    setState(() {
      _selectedSite = newSite;
      _selectedTeam = null;
    });

    if (newSite != null) {
      ref.read(teamProvider.notifier).getTeams(newSite.type, newSite.id);
    }
  }

  void _onTeamChanged(TeamModel? newTeam) {
    setState(() {
      _selectedTeam = newTeam;
    });
  }

  Future<bool> _checkDeviceVerification() async {
    final id = await DevicePrefs.getDeviceId();
    return id != null && id.isNotEmpty;
  }

  Future<void> _handleModuleTap(ModuleItem item) async {
    if (item.isEmpty) return;

    ref.read(moduleScreenSyncProvider.notifier).syncDropdownToGlobal();

    if (_currentIndex == 0) {
      _navigateToModule(item);
      return;
    }

    final isDeviceVerified = await _checkDeviceVerification();

    if (!isDeviceVerified) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device not verified. Please verify first to access this feature."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceOtpScreen(
              redirectRoute: item.routeName,
              redirectExtraData: {
                'selectedSite': _selectedSite,
                'selectedTeam': _selectedTeam,
              },
            ),
          ),
        );
      }
    } else {
      _navigateToModule(item);
    }
  }

  void _navigateToModule(ModuleItem item) {
    final extraData = {
      'selectedSite': _selectedSite,
      'selectedTeam': _selectedTeam,
    };
    context.push(item.routeName, extra: extraData);
  }

  Future<void> _handleAiAnalysisTap() async {
    final isDeviceVerified = await _checkDeviceVerification();

    if (!isDeviceVerified) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device not verified. Please verify first to access AI Analysis."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceOtpScreen(
              redirectRoute: "/analysis",
              redirectExtraData: {
                'selectedSite': _selectedSite,
                'selectedTeam': _selectedTeam,
              },
            ),
          ),
        );
      }
    } else {
      final extraData = {
        'selectedSite': _selectedSite,
        'selectedTeam': _selectedTeam,
      };
      context.push("/analysis", extra: extraData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteProvider);
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: _currentTitle),
      body: Stack(
        children: [
          CornerClippedScreenSimple(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 🔹 FIXED HEIGHT HEADER SECTION (Daily Entry only)
                  SizedBox(
                    child: _currentIndex == 0
                        ? Column(
                      children: [
                        const SizedBox(height: 10),
                        // Ad Banner
                        AdBannerCarousel(
                          height: 130,
                          imageUrls: [
                            'assets/images/b1.webp',
                            'assets/images/b4.webp',
                            'assets/images/b2.webp',
                            'assets/images/b3.webp',
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Dropdowns
                        Row(
                          children: [
                            Expanded(child: _buildSiteDropdown(siteState)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildTeamDropdown(teamState)),
                          ],
                        ),
                        const SizedBox(height: 1),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),

                  // 🔹 GRID SECTION WITH CONSISTENT PADDING
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: _currentModules.isEmpty
                          ? const Center(
                        child: Text(
                          "No modules available",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                          : GridView.builder(
                        itemCount: _currentModules.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = _currentModules[index];

                          if (item.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () => _handleModuleTap(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon area
                                  SizedBox(
                                    height: 90,
                                    width: 90,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        item.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Label
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      item.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B1B1B),
                                      ),
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
          ),
          // AI Analysis Button
          Positioned(
            right: 1,
            bottom: -1,
            child: GestureDetector(
              onTap: _handleAiAnalysisTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Color(0xFFBBD9FF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Ready to listen you !",
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: Image.asset("assets/images/img.png", fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Daily Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setup'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), label: 'More'),
        ],
      ),
    );
  }



  Future<void> _handleBottomNavTap(int index) async {
    if (index == 0) {
      setState(() => _currentIndex = index);
      return;
    }

    final isDeviceVerified = await _checkDeviceVerification();

    if (!isDeviceVerified) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device not verified. Please verify first to access this section."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 900),
          ),
        );

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceOtpScreen(
              redirectRoute: null,
              redirectExtraData: {
                'selectedSite': _selectedSite,
                'selectedTeam': _selectedTeam,
                'targetTabIndex': index,
              },
            ),
          ),
        );

        if (result != null && result is int && mounted) {
          setState(() => _currentIndex = result);
        }
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Widget _buildSiteDropdown(SiteState siteState) {
    final uniqueSites = siteState.sites.fold(<String, SiteModel>{}, (map, site) {
      map[site.id] = site;
      return map;
    }).values.toList();

    final noneSite = SiteModel(
      id: "none",
      siteName: "None",
      address: '',
      contactPerson: '',
      gstNo: '',
      phoneNumber: '',
      emailId: '',
      documentDate: '',
      documentNumber: '',
      isDeleted: false,
      company: '',
      type: '',
      createdAt: '',
      updatedAt: '',
    );

    final dropdownList = [noneSite, ...uniqueSites];
    final currentSelectedSite = _selectedSite != null
        ? dropdownList.firstWhere((site) => site.id == _selectedSite!.id, orElse: () => noneSite)
        : noneSite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButton<SiteModel>(
          value: currentSelectedSite,
          isExpanded: true,
          underline: const SizedBox(),
          items: dropdownList.map((site) {
            return DropdownMenuItem<SiteModel>(
              value: site,
              child: Text(
                site.siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (SiteModel? newSite) {
            if (newSite == null || newSite.id == "none") {
              _onSiteChanged(null);
              ref.read(siteDropdownValueProvider.notifier).state = null;
              ref.read(selectedSiteIdProvider.notifier).state = null;
            } else {
              _onSiteChanged(newSite);
              ref.read(siteDropdownValueProvider.notifier).state = newSite;
              ref.read(selectedSiteIdProvider.notifier).state = newSite.id;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTeamDropdown(AsyncValue<List<TeamModel>> teamState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: teamState.when(
          data: (teams) {
            final noneTeam = TeamModel(
              id: "none",
              teamName: "None",
              teamMemberIds: [],
              company: '',
              isDeleted: false,
              type: '',
            );

            final dropdownTeams = [noneTeam, ...teams];
            final currentSelectedTeam = _selectedTeam != null
                ? dropdownTeams.firstWhere((team) => team.id == _selectedTeam!.id, orElse: () => noneTeam)
                : noneTeam;

            return DropdownButton<TeamModel>(
              value: currentSelectedTeam,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('Select Team'),
              items: dropdownTeams.map((team) {
                return DropdownMenuItem<TeamModel>(
                  value: team,
                  child: Text(
                    team.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: _selectedSite != null
                  ? (TeamModel? newTeam) {
                if (newTeam == null || newTeam.id == "none") {
                  _onTeamChanged(null);
                  ref.read(selectedTeamIdProvider.notifier).state = null;
                } else {
                  _onTeamChanged(newTeam);
                  ref.read(selectedTeamIdProvider.notifier).state = newTeam.id;
                }
              }
                  : null,
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text("Select Site First")),
          ),
          error: (error, stack) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Error loading teams'),
          ),
        ),
      ),
    );
  }
}

class ModuleItem {
  final String label;
  final String imagePath;
  final String routeName;
  final Color color;
  final bool isEmpty;

  ModuleItem({
    required this.label,
    required this.imagePath,
    required this.routeName,
    this.color = Colors.blue,
    this.isEmpty = false,
  });
}