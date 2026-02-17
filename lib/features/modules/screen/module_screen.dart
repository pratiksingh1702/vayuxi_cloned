import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/offline/state/team_State.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamService.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../core/utlis/widgets/sidebar.dart';
import '../../language/service/lang_providers.dart';
import '../../language/service/providers.dart';
import '../../language/service/translator.dart';
import '../../tour/domain/tour_controller.dart';
import '../../tour/domain/tour_presistent.dart';
import '../../tour/domain/tour_registery.dart';
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
  BuildContext? _showcaseContext;
  bool _tourChecked = false;
  TourCheckpoint? _checkpoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tourChecked = false;
  }



  Future<void> _maybeStartShowcase(BuildContext showcaseContext) async {
    if (_tourChecked) return;
    _tourChecked = true;

    final persistence = TourPersistence();

    // Tour completely done? stop.
    if (await persistence.isCompleted()) return;

    await Future.delayed(const Duration(milliseconds: 200));


    final sc = ShowCaseWidget.of(showcaseContext);
    if (sc == null) return;
    if (!await persistence.isSetupClicked()) {
      setState(() {
        _checkpoint = null;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.setupBottomNavKey]);
      return;
    }


    if (!await persistence.isSiteDone()) {
      setState(() {
        _checkpoint = TourCheckpoint.site;

      });
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.siteModuleKey]);
      return;
    }

    if (!await persistence.isRateDone()) {
      setState(() {
        _checkpoint = TourCheckpoint.rate;

      });
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.rateModuleKey]);

      return;
    }

    if (!await persistence.isManpowerDone()) {
      setState(() {
        _checkpoint = TourCheckpoint.manpower;

      });
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.manpowerModuleKey]);
      return;
    }

    if (!await persistence.isTeamDone()) {
      setState(() {
        _checkpoint = TourCheckpoint.team;

      });
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.teamModuleKey]);
      return;
    }
    if (!await persistence.isDprDone()) {
      setState(() {
        _checkpoint = TourCheckpoint.dpr;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.dprModuleKey]);
      return;
    }



    // ✅ everything done
    await persistence.markCompleted();
  }




  // Define modules by category with image paths
  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(
      labelKey: 'attendance_card',
      imagePath: "assets/images/icons/attendance.webp",
      routeName: "/site-list/attendance",
      color: Colors.red,
    ),
    ModuleItem(
      labelKey: 'daily_progress_card',
      imagePath: "assets/images/icons/dpr.webp",
      routeName: "/site-list/dpr",
      color: Colors.purple,
    ),
    ModuleItem(
      labelKey: 'expense_card',
      imagePath: "assets/images/icons/expense_daily.webp",
      routeName: "/site-list/add-exp",
      color: Colors.indigo,
    ),
    ModuleItem(
      labelKey: 'inventory_entry_card',
      imagePath: "assets/images/icons/inventory_entry.webp",
      routeName: "/site-list/inv-entry",
      color: Colors.indigo,
    ),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(
      labelKey: 'site_details_card',
      imagePath: "assets/images/icons/site_details.webp",
      routeName: "/site",
      color: Colors.blue,
    ),
    ModuleItem(
      labelKey: 'rate_card',
      imagePath: "assets/images/icons/rate.webp",
      routeName: "/site-list/rate",
      color: Colors.green,
    ),
    ModuleItem(
      labelKey: 'manpower_details_card',
      imagePath: "assets/images/icons/manpower_setup.webp",
      routeName: "/manpower",
      color: Colors.orange,
    ),
    ModuleItem(
      labelKey: 'create_team_card',
      imagePath: "assets/images/icons/add_team.webp",
      routeName: "/site-list/team",
      color: Colors.teal,
    ),
    ModuleItem(
      labelKey: 'dpr_setup_card',
      imagePath: "assets/images/icons/dpr_setup.webp",
      routeName: "/site-list/addMoc",
      color: Colors.green,
    ),
    ModuleItem(
      labelKey: 'inventory_setup_card',
      imagePath: "assets/images/icons/inventory_setup.webp",
      routeName: "/site-list/inv-setup",
      color: Colors.indigo,
    ),
  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(
      labelKey: 'summary_analysis_card',
      imagePath: "assets/images/icons/summary_analysis.webp",
      routeName: "/summary",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      labelKey: 'salary_slip_card',
      imagePath: "assets/images/icons/salary_slip.webp",
      routeName: "/salary",
      color: Colors.brown,
    ),
    ModuleItem(
      labelKey: 'dpr_sheets_card',
      imagePath: "assets/images/icons/dpr_report.webp",
      routeName: "/site-list/dprReport",
      color: Colors.indigo,
    ),
    ModuleItem(
      labelKey: 'expense_sheet_card',
      imagePath: "assets/images/icons/expense_sheet.webp",
      routeName: "/site-list/expense",
      color: Colors.indigo,
    ),
    ModuleItem(
      labelKey: 'attendance_sheet_card',
      imagePath: "assets/images/icons/attendance_sheet.webp",
      routeName: "/site-list/att-sheet",
      color: Colors.deepPurple,
    ),
    ModuleItem(
      labelKey: 'inventory_summary_card',
      imagePath: "assets/images/icons/inventory_summary.webp",
      routeName: "/site-list/inv-Report",
      color: Colors.deepPurple,
    ),
  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(
      labelKey: 'profile_card',
      imagePath: "assets/images/icons/profile.webp",
      routeName: "/profile",
      color: Colors.cyan,
    ),
    ModuleItem(
      labelKey: 'subscription_card',
      imagePath: "assets/images/icons/subscription.webp",
      routeName: "/subscription",
      color: Colors.amber,
    ),
    ModuleItem(
      labelKey: 'upcoming_update_card',
      imagePath: "assets/images/icons/updates.webp",
      routeName: "/upcoming-update",
      color: Colors.green,
    ),
    ModuleItem(
      labelKey: 'theme_card',
      imagePath: "assets/images/icons/theme.webp",
      routeName: "/theme",
      color: Colors.purple,
    ),
    ModuleItem(
      labelKey: 'language_card',
      imagePath: "assets/images/icons/language.webp",
      routeName: "/language",
      color: Colors.blue,
    ),
    ModuleItem(
      labelKey: 'help_card',
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
      ref
          .read(teamProvider.notifier)
          .fetchTeams(type: newSite.type, siteId: newSite.id);
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
            content: Text(
                "Device not verified. Please verify first to access this feature."),
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

  Future<void> _navigateToModule(ModuleItem item) async {
    final extraData = {
      'selectedSite': _selectedSite,
      'selectedTeam': _selectedTeam,
    };
    await context.push(item.routeName, extra: extraData);
    setState(() {
      _tourChecked = false;
    });

  }

  Future<void> _handleAiAnalysisTap() async {
    final isDeviceVerified = await _checkDeviceVerification();

    if (!isDeviceVerified) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Device not verified. Please verify first to access AI Analysis."),
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
    final homeModuleAsync = ref.watch(languageModuleProvider('home'));
    final tHelper = ref.watch(homeTranslationHelperProvider);

    return homeModuleAsync.when(
        loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) => Scaffold(
              body: Center(child: Text(e.toString())),
            ),
        data: (homeData) {
          final t = Translator(homeData);

          String currentTitle() {
            switch (_currentIndex) {
              case 0:
                return t.t('daily_entry_title');
              case 1:
                return t.t('setup_title');
              case 2:
                return t.t('report_title');
              case 3:
                return t.t('more_title');
              default:
                return '';
            }
          }

          return ShowCaseWidget(
            builder: (showcaseContext) {
              _showcaseContext = showcaseContext;
              _showcaseContext = showcaseContext;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _maybeStartShowcase(showcaseContext);
              });

              return Scaffold(
                drawer: const CustomDrawer(),
                appBar: CustomAppBar(title: currentTitle()),
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
                                      Expanded(
                                          child:
                                          _buildSiteDropdown(siteState)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child:
                                          _buildTeamDropdown(teamState)),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: _currentModules.isEmpty
                                    ? const Center(
                                  child: Text(
                                    "No modules available",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
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

                                    if (item.isEmpty) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                      );
                                    }

                                    final isSetupSiteCard =
                                    (_currentIndex == 1 && item.routeName == "/site"); // site details module

                                    Widget card = GestureDetector(
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
                                            SizedBox(
                                              height: 90,
                                              width: 90,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                child: Image.asset(item.imagePath, fit: BoxFit.contain),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                t.t(item.labelKey),
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

                                    final bool isSetupTab = _currentIndex == 1;
                                    final bool isDprCard =
                                        isSetupTab && item.routeName == "/site-list/addMoc";

                                    final bool isSiteCard = isSetupTab && item.routeName == "/site";
                                    final bool isRateCard = isSetupTab && item.routeName == "/site-list/rate";
                                    final bool isManpowerCard = isSetupTab && item.routeName == "/manpower";
                                    final bool isTeamCard = isSetupTab && item.routeName == "/site-list/team";

                                    if (_checkpoint == TourCheckpoint.site && isSiteCard) {
                                      card = Showcase(
                                        key: TourRegistry.siteModuleKey,
                                        description: "Add your Site here ✅",
                                        disposeOnTap: true,
                                        onTargetClick: () async {
                                          await ref.read(tourPersistenceProvider).markSiteDone();
                                          setState(() {
                                            _tourChecked = false; // allow next step
                                          });
                                        },
                                        child: card,
                                      );


                                  }else if (_checkpoint == TourCheckpoint.rate && isRateCard) {
                                      card = Showcase(
                                        key: TourRegistry.rateModuleKey,
                                        description: "Now add Rate here 💰",
                                        disposeOnTap: true,
                                        onTargetClick: () async {
                                          await ref.read(tourPersistenceProvider).markRateDone();
                                          setState(() {
                                            _tourChecked = false;
                                          });
                                        },
                                        child: card,
                                      );
                                    }
                                    else if (_checkpoint == TourCheckpoint.manpower && isManpowerCard) {
                                      card = Showcase(
                                        key: TourRegistry.manpowerModuleKey,
                                        description: "Now add Manpower 👷",
                                        disposeOnTap: true,
                                        onTargetClick: () async {
                                          await ref.read(tourPersistenceProvider).markManpowerDone();
                                          setState(() {
                                            _tourChecked = false;
                                          });
                                        },
                                        child: card,
                                      );
                                    }
                                    else if (_checkpoint == TourCheckpoint.team && isTeamCard) {
                                      card = Showcase(
                                        key: TourRegistry.teamModuleKey,
                                        description: "Finally create your Team 👥",
                                        disposeOnTap: true,
                                        onTargetClick: () async {
                                          await ref.read(tourPersistenceProvider).markTeamDone();
                                          setState(() {
                                            _tourChecked = false;
                                          });
                                        },
                                        child: card,
                                      );
                                    }else if (_checkpoint == TourCheckpoint.dpr && isDprCard) {
                                      card = Showcase(
                                        key: TourRegistry.dprModuleKey,
                                        description: "Now configure DPR settings 📋",
                                        disposeOnTap: true,
                                        onTargetClick: () async {
                                          await ref.read(tourPersistenceProvider).markDprDone();
                                          setState(() {
                                            _tourChecked = false;
                                          });
                                        },
                                        child: card,
                                      );
                                    }




                                    return card;

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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                                style:
                                TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 2),
                            SizedBox(
                              height: 55,
                              width: 55,
                              child: Image.asset("assets/images/img.png",
                                  fit: BoxFit.contain),
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
                  selectedItemColor: Colors.black,
                  unselectedItemColor: Colors.black,
                  selectedLabelStyle: const TextStyle(color: Colors.black),
                  unselectedLabelStyle: const TextStyle(color: Colors.black),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.edit_note_outlined),
                      label: tHelper.bottomNavDailyEntry,
                    ),
                    BottomNavigationBarItem(
                      icon: Showcase(
                        key: TourRegistry.setupBottomNavKey,
                        description: "Tap Setup to configure Site, Rate, Manpower, Team etc ⚙️",
                        disposeOnTap: true, // ✅ important
                        onTargetClick: () async {
                          await ref.read(tourPersistenceProvider).markSetupClicked();
                          await _handleBottomNavTap(1);
                          setState(() {
                            _tourChecked = false; // allow next step to trigger
                          });
                        },
                        child: const Icon(Icons.settings_outlined),
                      ),
                      label: t.t('bottom_nav_setup'),
                    ),

                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bar_chart_outlined),
                      label: t.t('bottom_nav_report'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.more_horiz_outlined),
                      label: t.t('bottom_nav_more'),
                    ),
                  ],
                ),
              );
            },
          );

        });
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
            content: Text(
                "Device not verified. Please verify first to access this section."),
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
    final uniqueSites = siteState.sites
        .fold(<String, SiteModel>{}, (map, site) {
          map[site.id] = site;
          return map;
        })
        .values
        .toList();

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
        shippingAddress: '');

    final dropdownList = [noneSite, ...uniqueSites];
    final currentSelectedSite = _selectedSite != null
        ? dropdownList.firstWhere((site) => site.id == _selectedSite!.id,
            orElse: () => noneSite)
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

  Widget _buildTeamDropdown(TeamState teamState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Builder(
          builder: (context) {
            // ✅ show loading ONLY if nothing cached yet
            if (teamState.isLoading && !teamState.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text("Loading teams...")),
              );
            }

            // ✅ hard error only if no cached data
            if (!teamState.hasData && teamState.error != null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("Error loading teams"),
              );
            }

            final teams = teamState.teams;

            final uniqueTeams = teams
                .fold<Map<String, TeamModel>>({}, (map, team) {
                  map[team.id] = team;
                  return map;
                })
                .values
                .toList();

            final noneTeam = TeamModel(
              id: "none",
              teamName: "None",
              teamMemberIds: const [],
              company: '',
              isDeleted: false,
              type: '',
            );

            final dropdownList = [noneTeam, ...uniqueTeams];

            final currentSelectedTeam = _selectedTeam != null
                ? dropdownList.firstWhere(
                    (team) => team.id == _selectedTeam!.id,
                    orElse: () => noneTeam,
                  )
                : noneTeam;

            return DropdownButton<TeamModel>(
              value: currentSelectedTeam,
              isExpanded: true,
              underline: const SizedBox(),
              items: dropdownList.map((team) {
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
              onChanged: (TeamModel? newTeam) {
                if (newTeam == null || newTeam.id == "none") {
                  _onTeamChanged(null);
                  ref.read(teamDropdownValueProvider.notifier).state = null;
                  ref.read(selectedTeamIdProvider.notifier).state = "";
                } else {
                  _onTeamChanged(newTeam);
                  ref.read(teamDropdownValueProvider.notifier).state = newTeam;
                  ref.read(selectedTeamIdProvider.notifier).state = newTeam.id;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class ModuleItem {
  final String labelKey;
  final String imagePath;
  final String routeName;
  final Color color;
  final bool isEmpty;

  ModuleItem({
    required this.labelKey,
    required this.imagePath,
    required this.routeName,
    this.color = Colors.blue,
    this.isEmpty = false,
  });
}
