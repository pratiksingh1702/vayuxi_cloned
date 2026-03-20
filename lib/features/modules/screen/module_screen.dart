// features/modules/screen/module_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FIXES vs previous version:
//   1. Overlay now covers the AppBar — Scaffold is wrapped in a Stack so the
//      Positioned.fill overlay sits above everything including the AppBar.
//   2. _checkInProgress is reset in _storePendingAndShowOverlay so plan taps
//      and subsequent checks are never permanently blocked.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
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

import '../../../core/router/access_control_provider.dart';
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
import 'device_id_helper.dart';
import 'widgets/access_overlay.dart';

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

  // ── Overlay state ──────────────────────────────────────────────────────────
  AccessState? _overlayType;
  bool _overlayLoading = false;
  bool _checkInProgress = false;
  VoidCallback? _pendingAction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tourChecked = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCESS CHECK
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _checkAccess({
    bool deviceOnly = false,
    required VoidCallback onAllowed,
    VoidCallback? previewSwitch,
  }) async {
    if (_checkInProgress) return false;
    _checkInProgress = true;

    if (previewSwitch != null) {
      setState(previewSwitch);
    }

    if (deviceOnly) {
      final deviceId = await DevicePrefs.getDeviceId();
      final ok = deviceId != null && deviceId.isNotEmpty;
      _checkInProgress = false;
      if (!ok) {
        _storePendingAndShowOverlay(AccessState.deviceNotVerified, onAllowed);
        return false;
      }
      return true;
    }

    setState(() => _overlayLoading = true);

    try {
      ref.invalidate(accessControlProvider);
      final result = await ref.read(accessControlProvider.future);
      setState(() => _overlayLoading = false);
      _checkInProgress = false; // ✅ reset before showing overlay

      if (result.state == AccessState.allowed) return true;

      _storePendingAndShowOverlay(result.state, onAllowed);
      return false;
    } catch (_) {
      setState(() => _overlayLoading = false);
      _checkInProgress = false;
      return false;
    }
  }

  void _storePendingAndShowOverlay(AccessState gate, VoidCallback onAllowed) {
    // ✅ FIX: _checkInProgress must be false before setState so that taps
    // inside the overlay (plan select, OTP) are never blocked.
    _checkInProgress = false;
    setState(() {
      _pendingAction = onAllowed;
      _overlayType = gate;
    });
  }

  void _hideOverlay() {
    setState(() {
      _overlayType = null;
      _pendingAction = null;
      _checkInProgress = false; // safety reset
    });
  }

  Future<void> _onUnlocked() async {
    setState(() => _overlayLoading = true);
    ref.invalidate(accessControlProvider);
    try {
      final result = await ref.read(accessControlProvider.future);
      setState(() => _overlayLoading = false);

      if (result.state == AccessState.allowed) {
        final action = _pendingAction;
        setState(() {
          _overlayType = null;
          _pendingAction = null;
        });
        action?.call();
      } else {
        setState(() => _overlayType = result.state);
      }
    } catch (_) {
      setState(() => _overlayLoading = false);
      _hideOverlay();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOUR (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _maybeStartShowcase(BuildContext showcaseContext) async {
    if (_tourChecked) return;
    _tourChecked = true;
    final persistence = TourPersistence();
    if (await persistence.isCompleted()) return;
    await Future.delayed(const Duration(milliseconds: 200));
    final sc = ShowCaseWidget.of(showcaseContext);
    if (sc == null) return;

    if (!await persistence.isSetupClicked()) {
      setState(() => _checkpoint = null);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.setupBottomNavKey]);
      return;
    }
    if (!await persistence.isSiteDone()) {
      setState(() => _checkpoint = TourCheckpoint.site);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.siteModuleKey]);
      return;
    }
    if (!await persistence.isRateDone()) {
      setState(() => _checkpoint = TourCheckpoint.rate);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.rateModuleKey]);
      return;
    }
    if (!await persistence.isManpowerDone()) {
      setState(() => _checkpoint = TourCheckpoint.manpower);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.manpowerModuleKey]);
      return;
    }
    if (!await persistence.isTeamDone()) {
      setState(() => _checkpoint = TourCheckpoint.team);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.teamModuleKey]);
      return;
    }
    if (!await persistence.isDprDone()) {
      setState(() => _checkpoint = TourCheckpoint.dpr);
      await Future.delayed(const Duration(milliseconds: 200));
      sc.startShowCase([TourRegistry.dprModuleKey]);
      return;
    }
    await persistence.markCompleted();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODULE DATA (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(labelKey: 'attendance_card', imagePath: "assets/images/icons/attendance.webp", routeName: "/site-list/attendance", color: Colors.red),
    ModuleItem(labelKey: 'daily_progress_card', imagePath: "assets/images/icons/dpr.webp", routeName: "/site-list/dpr", color: Colors.purple),
    ModuleItem(labelKey: 'expense_card', imagePath: "assets/images/icons/expense_daily.webp", routeName: "/site-list/add-exp", color: Colors.indigo),
    ModuleItem(labelKey: 'inventory_entry_card', imagePath: "assets/images/icons/inventory_entry.webp", routeName: "/site-list/inv-entry", color: Colors.indigo),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(labelKey: 'site_details_card', imagePath: "assets/images/icons/site_details.webp", routeName: "/site", color: Colors.blue),
    ModuleItem(labelKey: 'rate_card', imagePath: "assets/images/icons/rate.webp", routeName: "/site-list/rate", color: Colors.green),
    ModuleItem(labelKey: 'manpower_details_card', imagePath: "assets/images/icons/manpower_setup.webp", routeName: "/manpower", color: Colors.orange),
    ModuleItem(labelKey: 'create_team_card', imagePath: "assets/images/icons/add_team.webp", routeName: "/site-list/team", color: Colors.teal),
    ModuleItem(labelKey: 'dpr_setup_card', imagePath: "assets/images/icons/dpr_setup.webp", routeName: "/site-list/addMoc", color: Colors.green),
    ModuleItem(labelKey: 'inventory_setup_card', imagePath: "assets/images/icons/inventory_setup.webp", routeName: "/site-list/inv-setup", color: Colors.indigo),
  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(labelKey: 'summary_analysis_card', imagePath: "assets/images/icons/summary_analysis.webp", routeName: "/summary", color: Colors.deepPurple),
    ModuleItem(labelKey: 'salary_slip_card', imagePath: "assets/images/icons/salary_slip.webp", routeName: "/salary", color: Colors.brown),
    ModuleItem(labelKey: 'dpr_sheets_card', imagePath: "assets/images/icons/dpr_report.webp", routeName: "/site-list/dprReport", color: Colors.indigo),
    ModuleItem(labelKey: 'expense_sheet_card', imagePath: "assets/images/icons/expense_sheet.webp", routeName: "/site-list/expense", color: Colors.indigo),
    ModuleItem(labelKey: 'attendance_sheet_card', imagePath: "assets/images/icons/attendance_sheet.webp", routeName: "/site-list/att-sheet", color: Colors.deepPurple),
    ModuleItem(labelKey: 'inventory_summary_card', imagePath: "assets/images/icons/inventory_summary.webp", routeName: "/site-list/inv-Report", color: Colors.deepPurple),
  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(labelKey: 'profile_card', imagePath: "assets/images/icons/profile.webp", routeName: "/profile", color: Colors.cyan),
    ModuleItem(labelKey: 'subscription_card', imagePath: "assets/images/icons/subscription.webp", routeName: "/subscription", color: Colors.amber),
    ModuleItem(labelKey: 'upcoming_update_card', imagePath: "assets/images/icons/updates.webp", routeName: "/upcoming-update", color: Colors.green),
    ModuleItem(labelKey: 'theme_card', imagePath: "assets/images/icons/theme.webp", routeName: "/theme", color: Colors.purple),
    ModuleItem(labelKey: 'language_card', imagePath: "assets/images/icons/language.webp", routeName: "/language", color: Colors.blue),
    ModuleItem(labelKey: 'help_card', imagePath: "assets/images/icons/help.webp", routeName: "/help", color: Colors.orange),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  void _onSiteChanged(SiteModel? newSite) {
    setState(() { _selectedSite = newSite; _selectedTeam = null; });
    if (newSite != null) {
      ref.read(teamProvider.notifier).fetchTeams(type: newSite.type, siteId: newSite.id);
    }
  }

  void _onTeamChanged(TeamModel? newTeam) => setState(() => _selectedTeam = newTeam);

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleModuleTap(ModuleItem item) async {
    if (item.isEmpty) return;
    ref.read(moduleScreenSyncProvider.notifier).syncDropdownToGlobal();

    if (_currentIndex == 3) { _navigateToModule(item); return; }

    void navigate() => _navigateToModule(item);

    if (_currentIndex == 0) {
      final ok = await _checkAccess(deviceOnly: true, onAllowed: navigate);
      if (ok) navigate();
      return;
    }

    final ok = await _checkAccess(deviceOnly: false, onAllowed: navigate);
    if (ok) navigate();
  }

  Future<void> _navigateToModule(ModuleItem item) async {
    await context.push(item.routeName, extra: {
      'selectedSite': _selectedSite,
      'selectedTeam': _selectedTeam,
    });
    setState(() => _tourChecked = false);
  }

  Future<void> _handleAiAnalysisTap() async {
    void navigate() => context.push("/analysis", extra: {
      'selectedSite': _selectedSite,
      'selectedTeam': _selectedTeam,
    });
    final ok = await _checkAccess(deviceOnly: false, onAllowed: navigate);
    if (ok) navigate();
  }

  Future<void> _handleBottomNavTap(int index) async {
    void switchTab() => setState(() => _currentIndex = index);
    final ok = await _checkAccess(
      deviceOnly: false,
      onAllowed: switchTab,
      previewSwitch: () => _currentIndex = index,
    );
    if (ok) switchTab();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteProvider);
    final teamState = ref.watch(teamProvider);
    final homeModuleAsync = ref.watch(languageModuleProvider('home'));
    final tHelper = ref.watch(homeTranslationHelperProvider);

    return homeModuleAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (homeData) {
        final t = Translator(homeData);

        String currentTitle() {
          switch (_currentIndex) {
            case 0: return t.t('daily_entry_title');
            case 1: return t.t('setup_title');
            case 2: return t.t('report_title');
            case 3: return t.t('more_title');
            default: return '';
          }
        }

        return ShowCaseWidget(
          builder: (showcaseContext) {
            _showcaseContext = showcaseContext;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeStartShowcase(showcaseContext);
            });

            // ── FIX: wrap the entire Scaffold in a Stack so the overlay
            //    can sit above the AppBar as well as the body. ──────────────
            return Stack(
              children: [
                // ── The real Scaffold ─────────────────────────────────────
                Scaffold(
                  drawer: const CustomDrawer(),
                  appBar: CustomAppBar(title: currentTitle()),
                  body: Stack(
                    children: [
                      CornerClippedScreenSimple(
                        child: SafeArea(
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              if (_currentIndex == 0)
                                Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    AdBannerCarousel(
                                      height: 130,
                                      imageUrls: const [
                                        'assets/images/b1.webp',
                                        'assets/images/b4.webp',
                                        'assets/images/b2.webp',
                                        'assets/images/b3.webp',
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Expanded(child: _buildSiteDropdown(siteState)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildTeamDropdown(teamState)),
                                    ]),
                                    const SizedBox(height: 1),
                                  ],
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: _currentModules.isEmpty
                                      ? const Center(child: Text("No modules available", style: TextStyle(fontSize: 16, color: Colors.grey)))
                                      : GridView.builder(
                                    physics: _overlayType != null ? const NeverScrollableScrollPhysics() : null,
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
                                        return Container(decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(20)));
                                      }

                                      Widget card = GestureDetector(
                                        onTap: _overlayType != null ? null : () => _handleModuleTap(item),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 1)],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: 90, width: 90,
                                                child: Container(padding: const EdgeInsets.all(12), child: Image.asset(item.imagePath, fit: BoxFit.contain)),
                                              ),
                                              const SizedBox(height: 8),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(t.t(item.labelKey), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B1B1B))),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                      // Tour wrappers (unchanged)
                                      final bool isSetupTab = _currentIndex == 1;
                                      if (_checkpoint == TourCheckpoint.site && isSetupTab && item.routeName == "/site") {
                                        card = Showcase(key: TourRegistry.siteModuleKey, description: "Add your Site here ✅", disposeOnTap: true,
                                            onTargetClick: () async { await ref.read(tourPersistenceProvider).markSiteDone(); setState(() => _tourChecked = false); }, child: card);
                                      } else if (_checkpoint == TourCheckpoint.rate && isSetupTab && item.routeName == "/site-list/rate") {
                                        card = Showcase(key: TourRegistry.rateModuleKey, description: "Now add Rate here 💰", disposeOnTap: true,
                                            onTargetClick: () async { await ref.read(tourPersistenceProvider).markRateDone(); setState(() => _tourChecked = false); }, child: card);
                                      } else if (_checkpoint == TourCheckpoint.manpower && isSetupTab && item.routeName == "/manpower") {
                                        card = Showcase(key: TourRegistry.manpowerModuleKey, description: "Now add Manpower 👷", disposeOnTap: true,
                                            onTargetClick: () async { await ref.read(tourPersistenceProvider).markManpowerDone(); setState(() => _tourChecked = false); }, child: card);
                                      } else if (_checkpoint == TourCheckpoint.team && isSetupTab && item.routeName == "/site-list/team") {
                                        card = Showcase(key: TourRegistry.teamModuleKey, description: "Finally create your Team 👥", disposeOnTap: true,
                                            onTargetClick: () async { await ref.read(tourPersistenceProvider).markTeamDone(); setState(() => _tourChecked = false); }, child: card);
                                      } else if (_checkpoint == TourCheckpoint.dpr && isSetupTab && item.routeName == "/site-list/addMoc") {
                                        card = Showcase(key: TourRegistry.dprModuleKey, description: "Now configure DPR settings 📋", disposeOnTap: true,
                                            onTargetClick: () async { await ref.read(tourPersistenceProvider).markDprDone(); setState(() => _tourChecked = false); }, child: card);
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

                      // AI FAB
                      Positioned(
                        right: 1, bottom: -1,
                        child: GestureDetector(
                          onTap: _overlayType != null ? null : _handleAiAnalysisTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFFBBD9FF)),
                                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
                                ),
                                child: const Text("Ready to listen you !", style: TextStyle(fontSize: 10, color: Colors.black87)),
                              ),
                              const SizedBox(width: 2),
                              SizedBox(height: 55, width: 55, child: Image.asset("assets/images/img.png", fit: BoxFit.contain)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      if (index == 0 || index == 3) {
                        _hideOverlay();
                        setState(() => _currentIndex = index);
                      } else {
                        if (_overlayType != null) return;
                        _handleBottomNavTap(index);
                      }
                    },
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Colors.grey,
                    selectedLabelStyle: const TextStyle(color: Colors.black),
                    unselectedLabelStyle: const TextStyle(color: Colors.black),
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(icon: const Icon(Icons.edit_note_outlined), label: tHelper.bottomNavDailyEntry),
                      BottomNavigationBarItem(
                        icon: Showcase(
                          key: TourRegistry.setupBottomNavKey,
                          description: "Tap Setup to configure Site, Rate, Manpower, Team etc ⚙️",
                          disposeOnTap: true,
                          onTargetClick: () async {
                            await ref.read(tourPersistenceProvider).markSetupClicked();
                            await _handleBottomNavTap(1);
                            setState(() => _tourChecked = false);
                          },
                          child: const Icon(Icons.settings_outlined),
                        ),
                        label: t.t('bottom_nav_setup'),
                      ),
                      BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_outlined), label: t.t('bottom_nav_report')),
                      BottomNavigationBarItem(icon: const Icon(Icons.more_horiz_outlined), label: t.t('bottom_nav_more')),
                    ],
                  ),
                ),

                // ── OVERLAY — sits above the entire Scaffold including AppBar ──
                // Spinner while checking
                if (_overlayLoading)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: Colors.black.withOpacity(0.48),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                    ),
                  ),

                // Gate card overlay
                if (!_overlayLoading && _overlayType != null)
                  Positioned.fill(
                    child: AccessOverlay(
                      type: _overlayType!,
                      onDismiss: _hideOverlay,
                      onUnlocked: _onUnlocked,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DROPDOWNS (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSiteDropdown(SiteState siteState) {
    final uniqueSites = siteState.sites.fold<Map<String, SiteModel>>({}, (map, site) { map[site.id] = site; return map; }).values.toList();
    final noneSite = SiteModel(id: "none", siteName: "None", address: '', contactPerson: '', gstNo: '', phoneNumber: '', emailId: '', documentDate: '', documentNumber: '', isDeleted: false, company: '', type: '', createdAt: '', updatedAt: '', shippingAddress: '');
    final dropdownList = [noneSite, ...uniqueSites];
    final currentSelectedSite = _selectedSite != null ? dropdownList.firstWhere((s) => s.id == _selectedSite!.id, orElse: () => noneSite) : noneSite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: DropdownButton<SiteModel>(
          value: currentSelectedSite, isExpanded: true, underline: const SizedBox(),
          items: dropdownList.map((site) => DropdownMenuItem<SiteModel>(value: site, child: Text(site.siteName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)))).toList(),
          onChanged: (SiteModel? newSite) {
            if (newSite == null || newSite.id == "none") { _onSiteChanged(null); ref.read(siteDropdownValueProvider.notifier).state = null; ref.read(selectedSiteIdProvider.notifier).state = null; }
            else { _onSiteChanged(newSite); ref.read(siteDropdownValueProvider.notifier).state = newSite; ref.read(selectedSiteIdProvider.notifier).state = newSite.id; }
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Builder(builder: (context) {
          if (teamState.isLoading && !teamState.hasData) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: Text("Loading teams...")));
          if (!teamState.hasData && teamState.error != null) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Error loading teams"));
          final uniqueTeams = teamState.teams.fold<Map<String, TeamModel>>({}, (map, team) { map[team.id] = team; return map; }).values.toList();
          final noneTeam = TeamModel(id: "none", teamName: "None", teamMemberIds: const [], company: '', isDeleted: false, type: '');
          final dropdownList = [noneTeam, ...uniqueTeams];
          final currentSelectedTeam = _selectedTeam != null ? dropdownList.firstWhere((t) => t.id == _selectedTeam!.id, orElse: () => noneTeam) : noneTeam;
          return DropdownButton<TeamModel>(
            value: currentSelectedTeam, isExpanded: true, underline: const SizedBox(),
            items: dropdownList.map((team) => DropdownMenuItem<TeamModel>(value: team, child: Text(team.teamName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)))).toList(),
            onChanged: (TeamModel? newTeam) {
              if (newTeam == null || newTeam.id == "none") { _onTeamChanged(null); ref.read(teamDropdownValueProvider.notifier).state = null; ref.read(selectedTeamIdProvider.notifier).state = ""; }
              else { _onTeamChanged(newTeam); ref.read(teamDropdownValueProvider.notifier).state = newTeam; ref.read(selectedTeamIdProvider.notifier).state = newTeam.id; }
            },
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

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