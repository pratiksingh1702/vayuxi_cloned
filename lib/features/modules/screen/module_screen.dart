import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamService.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';

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

// Define modules by category from the start
  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(
      label: "Attendance",
      icon: Icons.check_circle,
      routeName: "/site-list/attendance",
      color: Colors.red,
    ),
    ModuleItem(
      label: "Daily Progress",
      icon: Icons.description,
      routeName: "/site-list/dpr",
      color: Colors.purple,
    ),
    ModuleItem(
      label: "Expense",
      icon: Icons.receipt_long,
      routeName: "/site-list/add-exp",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Inventory Entry",
      icon: Icons.receipt_long,
      routeName: "/site-list/inv-entry",
      color: Colors.indigo,
    )
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(
      label: "Site Details",
      icon: Icons.location_city,
      routeName: "/site",
      color: Colors.blue,
    ),
    ModuleItem(
      label: "Rate",
      icon: Icons.attach_money,
      routeName: "/site-list/rate",
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
      label: "Dpr Set Up",
      icon: Icons.phonelink_setup,
      routeName: "/site-list/addMoc",
      color: Colors.green,
    ),
    ModuleItem(
      label: "Inventory Setup",
      icon: Icons.receipt_long,
      routeName: "/site-list/inv-setup",
      color: Colors.indigo,
    ),


  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(
      label: "Summary & Analysis",
      icon: Icons.bar_chart,
      routeName: "/summary",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      label: "Salary Slip",
      icon: Icons.payments,
      routeName: "/salary",
      color: Colors.brown,
    ),
    ModuleItem(
      label: "DPR SHEETS",
      icon: Icons.analytics,
      routeName: "/site-list/dprReport",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Expense Report",
      icon: Icons.receipt_long,
      routeName: "/site-list/expense",
      color: Colors.indigo,
    ),
    ModuleItem(
      label: "Attendance Sheet",
      icon: Icons.bar_chart,
      routeName: "/site-list/att-sheet",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      label: "Inventory Report",
      icon: Icons.bar_chart,
      routeName: "/site-list/inv-Report",
      color: Colors.deepPurple,
    ),

  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(
      label: "Profile",
      icon: Icons.person,
      routeName: "/profile",
      color: Colors.cyan,
    ),
    ModuleItem(
      label: "Subscription",
      icon: Icons.subscriptions,
      routeName: "/subscription",
      color: Colors.amber,
    ),
    ModuleItem(
      label: "Upcoming Update",
      icon: Icons.update,
      routeName: "/upcoming-update",
      color: Colors.green,
    ),
    ModuleItem(
      label: "Theme",
      icon: Icons.palette,
      routeName: "/theme",
      color: Colors.purple,
    ),
    ModuleItem(
      label: "Language",
      icon: Icons.language,
      routeName: "/language",
      color: Colors.blue,
    ),
    ModuleItem(
      label: "Help",
      icon: Icons.help,
      routeName: "/help",
      color: Colors.orange,
    ),
  ];

  List<ModuleItem> get _currentModules {
    switch (_currentIndex) {
      case 0: return _dailyEntryModules;
      case 1: return _setupModules;
      case 2: return _reportModules;
      case 3: return _moreModules;
      default: return [];
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
  void initState() {
    super.initState();
    // Fetch sites when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  void _onSiteChanged(SiteModel? newSite) {
    setState(() {
      _selectedSite = newSite;
      _selectedTeam = null; // Reset team when site changes
    });

    if (newSite != null) {
      // Fetch teams for the selected site
      ref.read(teamProvider.notifier).getTeams(newSite.type, newSite.id);
    }
  }

  void _onTeamChanged(TeamModel? newTeam) {
    setState(() {
      _selectedTeam = newTeam;
    });
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteProvider);
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      appBar: CustomAppBar(title: _currentTitle),
      body: Stack(
        children: [
          CornerClippedScreenSimple(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 🔹 Site and Team Dropdowns (Only for Daily Entry tab)
                if (_currentIndex == 0) ...<Widget>[
                  const SizedBox(height: 10),

// 🔹 Ad Banner Carousel
                  AdBannerCarousel(
                    imageUrls: [
                      'assets/images/b1.webp',
                      'assets/images/b4.webp',
                      'assets/images/b2.webp',
                      'assets/images/b3.webp',
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildSiteDropdown(siteState)),
                      const SizedBox(height: 12),
                      Expanded(child: _buildTeamDropdown(teamState)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
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
                          onTap: () async {
                            final blockedModules = ["Rate", "Dpr Set Up", "Manpower Details"];

                            if (blockedModules.contains(item.label)) {
                              final id = await DevicePrefs.getDeviceId();

                              if (id == null || id.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Device not verified. Please verify first."),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeviceOtpScreen(
                                        redirectRoute: item.routeName,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            // Pass site and team data to the target route
                            final extraData = {
                              'selectedSite': _selectedSite,
                              'selectedTeam': _selectedTeam,
                            };

                            context.push(item.routeName, extra: extraData);
                          },
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
        ),
          Positioned(
            right: 16,
            bottom: 10, // keep above bottom nav
            child: GestureDetector(
              onTap: () {
                final extraData = {
                  'selectedSite': _selectedSite,
                  'selectedTeam': _selectedTeam,
                };
                context.push("/analysis", extra: extraData);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Color(0xFFBBD9FF)),
                    ),
                    child: const Text(
                      "Ask me anything !",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // Sticker Image
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: Image.asset(
                      "assets/images/img.png", // your sticker image
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          )
    ],

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

  Widget _buildSiteDropdown(SiteState siteState) {
    // Remove duplicates by using a Set based on site ID
    final uniqueSites = siteState.sites.fold(<String, SiteModel>{}, (map, site) {
      map[site.id] = site;
      return map;
    }).values.toList();

    // Add "None" option manually
    final noneSite = SiteModel(
      id: "none",
      siteName: "None", address: '', contactPerson: '', gstNo: '', phoneNumber: '', emailId: '', documentDate: '', documentNumber: '', isDeleted: false, company: '', type: '', createdAt: '', updatedAt: '',
    );

    final dropdownList = [noneSite, ...uniqueSites];

    // Determine current selection
    final currentSelectedSite = _selectedSite != null
        ? dropdownList.firstWhere(
          (site) => site.id == _selectedSite!.id,
      orElse: () => noneSite,
    )
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
              ref.read(selectedSiteIdProvider.notifier).state = null;
            } else {
              _onSiteChanged(newSite);
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
            // Create NONE item
            final noneTeam = TeamModel(
              id: "none",
              teamName: "None", teamMemberIds: [], company: '', isDeleted: false, type: '',
            );

            final dropdownTeams = [noneTeam, ...teams];

            // Fix selected value
            final currentSelectedTeam = _selectedTeam != null
                ? dropdownTeams.firstWhere(
                  (team) => team.id == _selectedTeam!.id,
              orElse: () => noneTeam,
            )
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
                  // NONE selected
                  _onTeamChanged(null);
                  ref.read(selectedTeamIdProvider.notifier).state = null;
                } else {
                  // Real team
                  _onTeamChanged(newTeam);
                  ref.read(selectedTeamIdProvider.notifier).state =
                      newTeam.id;
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