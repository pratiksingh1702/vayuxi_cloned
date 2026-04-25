import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/router/access_control_provider.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/language/service/lang_providers.dart';
import 'package:untitled2/features/language/service/translator.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/features/tour/domain/tour_controller.dart';
import 'package:untitled2/features/tour/domain/tour_events.dart';
import 'package:untitled2/features/tour/domain/tour_presistent.dart';
import 'package:untitled2/features/tour/domain/tour_registery.dart';
import 'package:untitled2/features/tour/registry/site_registry.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'widgets/access_overlay.dart';

class ModuleItem {
  final String labelKey;
  final IconData icon;
  final Color iconColor;
  final String routeName;
  final bool isEmpty;

  ModuleItem({
    required this.labelKey,
    required this.icon,
    required this.iconColor,
    required this.routeName,
    this.isEmpty = false,
  });
}

class ModuleScreenV2 extends ConsumerStatefulWidget {
  final int initialIndex;
  const ModuleScreenV2({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ModuleScreenV2> createState() => _ModuleScreenV2State();
}

class _ModuleScreenV2State extends ConsumerState<ModuleScreenV2> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final Map<String, bool> _pressedMap = {};
  
  bool _showQuickSettings = false;
  bool _dummyToggle1 = true;
  bool _dummyToggle2 = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Access & State variables (Kept from original) ──────────────────────────
  AccessState? _overlayType;
  bool _overlayLoading = false;
  bool _checkInProgress = false;
  VoidCallback? _pendingAction;
  bool _tourChecked = false;
  bool _tourStartPending = false;
  TourCheckpoint? _checkpoint;
  BuildContext? _showcaseContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tourChecked = false;
  }

  // ── Business Logic (Kept unchanged from original) ─────────────────────────

  Future<bool> _checkAccess({
    required VoidCallback onAllowed,
    VoidCallback? previewSwitch,
  }) async {
    if (_checkInProgress) return false;
    _checkInProgress = true;
    if (previewSwitch != null) setState(previewSwitch);
    setState(() => _overlayLoading = true);
    try {
      await ref.read(accessControlProvider.notifier).evaluate();
      final asyncValue = ref.read(accessControlProvider);
      setState(() => _overlayLoading = false);
      _checkInProgress = false;
      final result = asyncValue.valueOrNull;
      if (result == null) return false;
      if (result.state == AccessState.allowed) return true;
      if (result.state == AccessState.noSubscription) {
        if (mounted) context.push('/subscription');
        return false;
      }
      _storePendingAndShowOverlay(result.state, onAllowed);
      return false;
    } catch (e) {
      setState(() => _overlayLoading = false);
      _checkInProgress = false;
      return false;
    }
  }

  void _storePendingAndShowOverlay(AccessState gate, VoidCallback onAllowed) {
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
      _checkInProgress = false;
    });
  }

  Future<void> _onUnlocked() async {
    if (_overlayLoading) return;
    setState(() => _overlayLoading = true);
    try {
      await ref.read(accessControlProvider.notifier).evaluate();
      final asyncValue = ref.read(accessControlProvider);
      setState(() => _overlayLoading = false);
      final result = asyncValue.valueOrNull;
      if (result == null) {
        _hideOverlay();
        return;
      }
      if (result.state == AccessState.allowed) {
        final action = _pendingAction;
        setState(() {
          _overlayType = null;
          _pendingAction = null;
          _tourChecked = false;
        });
        action?.call();
      } else if (result.state == AccessState.noSubscription) {
        setState(() {
          _overlayType = null;
          _pendingAction = null;
        });
        if (mounted) context.push('/subscription');
      } else {
        setState(() => _overlayType = result.state);
      }
    } catch (e) {
      setState(() => _overlayLoading = false);
      _hideOverlay();
    }
  }

  Future<void> _maybeStartShowcase(BuildContext showcaseContext) async {
    if (_tourChecked || _tourStartPending || !mounted || _overlayLoading || _overlayType != null) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    _tourStartPending = true;
    _tourChecked = true;
    final persistence = TourPersistence();
    if (await persistence.isCompleted()) {
      _tourStartPending = false;
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 90));

    final sc = ShowCaseWidget.of(showcaseContext);
    if (sc == null || !mounted) {
      _tourStartPending = false;
      return;
    }

    if (!await persistence.isSetupClicked()) {
      setState(() => _checkpoint = null);
      sc.startShowCase([TourRegistry.setupBottomNavKey]);
      _tourStartPending = false;
      return;
    }
    if (!await persistence.isSiteDone()) {
      _tourStartPending = false;
      return;
    }
    if (!await persistence.isRateDone()) {
      setState(() => _checkpoint = TourCheckpoint.rate);
      sc.startShowCase([TourRegistry.rateModuleKey]);
      _tourStartPending = false;
      return;
    }
    if (!await persistence.isManpowerDone()) {
      setState(() => _checkpoint = TourCheckpoint.manpower);
      sc.startShowCase([TourRegistry.manpowerModuleKey]);
      _tourStartPending = false;
      return;
    }
    if (!await persistence.isTeamDone()) {
      setState(() => _checkpoint = TourCheckpoint.team);
      sc.startShowCase([TourRegistry.teamModuleKey]);
      _tourStartPending = false;
      return;
    }
    if (!await persistence.isDprDone()) {
      setState(() => _checkpoint = TourCheckpoint.dpr);
      sc.startShowCase([TourRegistry.dprModuleKey]);
      _tourStartPending = false;
      return;
    }
    await persistence.markCompleted();
    _tourStartPending = false;
  }

  // ── Module Data ────────────────────────────────────────────────────────────
  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(labelKey: 'attendance_card', icon: Icons.how_to_reg_rounded, iconColor: Colors.green, routeName: "/site-list/attendance"),
    ModuleItem(labelKey: 'daily_progress_card', icon: Icons.description_rounded, iconColor: Colors.indigo, routeName: "/site-list/dpr"),
    ModuleItem(labelKey: 'expense_card', icon: Icons.receipt_long_rounded, iconColor: Colors.orange, routeName: "/site-list/add-exp"),
    ModuleItem(labelKey: 'inventory_entry_card', icon: Icons.inventory_2_rounded, iconColor: Colors.teal, routeName: "/site-list/inv-entry"),
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(labelKey: 'site_details_card', icon: Icons.location_city_rounded, iconColor: Colors.cyan, routeName: "/site"),
    ModuleItem(labelKey: 'rate_card', icon: Icons.currency_rupee_rounded, iconColor: Colors.amber, routeName: "/site-list/rate"),
    ModuleItem(labelKey: 'manpower_details_card', icon: Icons.engineering_rounded, iconColor: Colors.deepOrange, routeName: "/manpower"),
    ModuleItem(labelKey: 'create_team_card', icon: Icons.groups_rounded, iconColor: Colors.purple, routeName: "/site-list/team"),
    ModuleItem(labelKey: 'dpr_setup_card', icon: Icons.settings_suggest_rounded, iconColor: Colors.blueGrey, routeName: "/site-list/addMoc"),
    ModuleItem(labelKey: 'inventory_setup_card', icon: Icons.warehouse_rounded, iconColor: Colors.brown, routeName: "/site-list/inv-setup"),
  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(labelKey: 'summary_analysis_card', icon: Icons.analytics_rounded, iconColor: Colors.blue, routeName: "/summary"),
    ModuleItem(labelKey: 'salary_slip_card', icon: Icons.payments_rounded, iconColor: Colors.lightGreen, routeName: "/salary"),
    ModuleItem(labelKey: 'dpr_sheets_card', icon: Icons.table_chart_rounded, iconColor: Colors.deepPurple, routeName: "/site-list/dprReport"),
    ModuleItem(labelKey: 'expense_sheet_card', icon: Icons.request_quote_rounded, iconColor: Colors.redAccent, routeName: "/site-list/expense"),
    ModuleItem(labelKey: 'attendance_sheet_card', icon: Icons.fact_check_rounded, iconColor: Colors.lime, routeName: "/site-list/att-sheet"),
    ModuleItem(labelKey: 'inventory_summary_card', icon: Icons.assessment_rounded, iconColor: Colors.pink, routeName: "/site-list/inv-Report"),
  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(labelKey: 'profile_card', icon: Icons.account_circle_rounded, iconColor: Colors.deepPurpleAccent, routeName: "/profile"),
    ModuleItem(labelKey: 'subscription_card', icon: Icons.workspace_premium_rounded, iconColor: Colors.amberAccent, routeName: "/subscription"),
    ModuleItem(labelKey: 'upcoming_update_card', icon: Icons.new_releases_rounded, iconColor: Colors.lightBlue, routeName: "/upcoming-update"),
    ModuleItem(labelKey: 'theme_card', icon: Icons.palette_rounded, iconColor: Colors.pinkAccent, routeName: "/theme"),
    ModuleItem(labelKey: 'language_card', icon: Icons.translate_rounded, iconColor: Colors.cyanAccent, routeName: "/language"),
    ModuleItem(labelKey: 'help_card', icon: Icons.support_agent_rounded, iconColor: Colors.greenAccent, routeName: "/help"),
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

  void _onSiteChanged(SiteModel? newSite) {
    ref.read(siteDropdownValueProvider.notifier).state = newSite;
    if (newSite != null) {
      ref.read(teamProvider.notifier).fetchTeams(type: newSite.type, siteId: newSite.id);
    }
  }

  void _onTeamChanged(TeamModel? newTeam) {
    ref.read(teamDropdownValueProvider.notifier).state = newTeam;
  }

  // ── Navigation Handlers ────────────────────────────────────────────────────
  Future<void> _handleModuleTap(ModuleItem item) async {
    if (item.isEmpty) return;
    ref.read(moduleScreenSyncProvider.notifier).syncDropdownToGlobal();
    if (_currentIndex == 0 || _currentIndex == 3) {
      _navigateToModule(item);
      return;
    }
    void navigate() => _navigateToModule(item);
    final ok = await _checkAccess(onAllowed: navigate);
    if (ok) navigate();
  }

  Future<void> _navigateToModule(ModuleItem item) async {
    if (item.routeName == '/site') {
      await ref.read(tourControllerProvider.notifier).onEvent(TourEvents.siteModuleTapped);
    }
    final selectedSite = ref.read(siteDropdownValueProvider);
    final selectedTeam = ref.read(teamDropdownValueProvider);
    await context.push(item.routeName, extra: {
      'selectedSite': selectedSite,
      'selectedTeam': selectedTeam,
    });
    setState(() => _tourChecked = false);
  }

  Future<void> _handleAiAnalysisTap() async {
    final selectedSite = ref.read(siteDropdownValueProvider);
    final selectedTeam = ref.read(teamDropdownValueProvider);
    void navigate() => context.push("/analysis", extra: {
      'selectedSite': selectedSite,
      'selectedTeam': selectedTeam,
    });
    final ok = await _checkAccess(onAllowed: navigate);
    if (ok) navigate();
  }

  Future<void> _handleBottomNavTap(int index) async {
    void switchTab() => setState(() => _currentIndex = index);
    final ok = await _checkAccess(
      onAllowed: switchTab,
      previewSwitch: () => _currentIndex = index,
    );
    if (ok) switchTab();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _pageBackgroundColor(ColorScheme cs, bool isDark) => isDark ? cs.surface : cs.surfaceContainerLowest;
  Color _panelColor(ColorScheme cs, bool isDark) => isDark ? cs.surfaceContainerHigh : cs.surface;
  Color _moduleCardBorderColor(ColorScheme cs, bool isDark) => isDark ? cs.outline.withOpacity(0.35) : cs.outlineVariant.withOpacity(0.55);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final siteState = ref.watch(siteProvider);

    final homeModuleAsync = ref.watch(languageModuleProvider('home'));
    return homeModuleAsync.when(
      loading: () => _buildLoadingState(),
      error: (e, _) => _buildLoadingState(),
      data: (homeData) {
        final t = Translator(homeData);
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: _pageBackgroundColor(cs, isDark),
          body: ShowCaseWidget(
            builder: (showcaseContext) {
              _showcaseContext = showcaseContext;
              _maybeStartShowcase(showcaseContext);
              return GestureDetector(
                onTap: () {
                  if (_showQuickSettings) setState(() => _showQuickSettings = false);
                },
                child: Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          _buildContextualHeader(t),
                          const SizedBox(height: 12),
                          _buildDropdownRow(),
                          const SizedBox(height: 10),
                          _buildActivityCard(),
                          const SizedBox(height: 12),
                          _buildModuleCard(t),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                      left: 12,
                      right: 12,
                      child: _buildFloatingNavBar(showcaseContext, t),
                    ),
                    if (_showQuickSettings)
                      Positioned(
                        bottom: 84 + MediaQuery.of(context).padding.bottom,
                        left: 20,
                        child: _buildQuickSettingsMenu(cs, isDark),
                      ),
                    if (_overlayLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    if (!_overlayLoading && _overlayType != null && _overlayType != AccessState.noSubscription)
                      Positioned.fill(
                        child: AccessOverlay(
                          type: _overlayType!,
                          onUnlocked: _onUnlocked,
                          onDismiss: _hideOverlay,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Part 2: Contextual Header ──────────────────────────────────────────────
  Widget _buildContextualHeader(Translator t) {
    final cs = Theme.of(context).colorScheme;
    final type = ref.watch(typeProvider);
    
    String eyebrow = "";
    if (type == 'mechanical_work') eyebrow = "MECHANICAL WORK";
    else if (type == 'insulation_work') eyebrow = "INSULATION WORK";

    String title = "";
    switch (_currentIndex) {
      case 0: title = t.t('daily_entry_title'); break;
      case 1: title = t.t('setup_title'); break;
      case 2: title = t.t('report_title'); break;
      case 3: title = t.t('more_title'); break;
    }

    final now = DateTime.now();
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = "${days[now.weekday-1]}, ${now.day} ${months[now.month-1]}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Builder(
            builder: (innerContext) {
              return GestureDetector(
                onTap: () => Scaffold.of(innerContext).openDrawer(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.4), width: 0.8),
                  ),
                  child: Icon(Icons.menu_rounded, size: 22, color: cs.onSurfaceVariant),
                ),
              );
            }
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow.isNotEmpty)
                  Text(eyebrow, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: cs.primary)),
                Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.1)),
                Text(dateStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_currentModules.where((m) => !m.isEmpty).length} modules",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  // ── Part 3: Dropdowns ──────────────────────────────────────────────────────
  Widget _buildDropdownRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildCustomDropdown(label: "SITE")),
          const SizedBox(width: 10),
          Expanded(child: _buildCustomDropdown(label: "TEAM")),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({required String label}) {
    final cs = Theme.of(context).colorScheme;
    final isSite = label == "SITE";
    final allSites = ref.watch(siteProvider).sites;
    final selectedSite = ref.watch(siteDropdownValueProvider);
    final teamState = ref.watch(teamProvider);
    final selectedTeam = ref.watch(teamDropdownValueProvider);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6, left: 14,
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: cs.primary)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 10, right: 4),
            child: DropdownButtonHideUnderline(
              child: isSite 
                ? DropdownButton<SiteModel>(
                    value: selectedSite,
                    isExpanded: true,
                    hint: const Text("Select Site", style: TextStyle(fontSize: 13)),
                    items: allSites.map((s) => DropdownMenuItem(value: s, child: Text(s.siteName, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: _onSiteChanged,
                  )
                : DropdownButton<TeamModel>(
                    value: selectedTeam,
                    isExpanded: true,
                    hint: const Text("Select Team", style: TextStyle(fontSize: 13)),
                    items: teamState.teams.map((t) => DropdownMenuItem(value: t, child: Text(t.teamName, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: _onTeamChanged,
                  ),
            ),
          )
        ],
      ),
    );
  }

  // ── Part 4: Activity Card ──────────────────────────────────────────────────
  Widget _buildActivityCard() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.45), width: 0.8),
        ),
        child: Column(
          children: [
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.9), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("Recent Activity", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: cs.onSurfaceVariant)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.35), width: 0.8),
                ),
                child: const Text("● Live", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
              )
            ]),
            const SizedBox(height: 8),
            _buildActivityRow(icon: Icons.receipt_long_rounded, title: 'Expense entry added', time: '2 min ago', isRecent: true),
            const SizedBox(height: 6),
            _buildActivityRow(icon: Icons.how_to_reg_rounded, title: 'Attendance submitted', time: 'Today 9:30 AM', isRecent: false),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({required IconData icon, required String title, required String time, required bool isRecent}) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: cs.onSurfaceVariant),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
          Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant)),
        ]
      )),
      if (isRecent) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
    ]);
  }

  // ── Part 5: Module Card ─────────────────────────────────────────────────────
  Widget _buildModuleCard(Translator t) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            // Swipe Right -> Previous Tab
            if (_currentIndex > 0) _handleSwipe(_currentIndex - 1);
          } else if (details.primaryVelocity! < -500) {
            // Swipe Left -> Next Tab
            if (_currentIndex < 3) _handleSwipe(_currentIndex + 1);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerLow : cs.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _moduleCardBorderColor(cs, isDark), width: 0.8),
            boxShadow: isDark ? [] : [BoxShadow(color: cs.shadow.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTabLabel(t),
              const SizedBox(height: 16),
              _buildIconGrid(t),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSwipe(int newIndex) {
    if (newIndex == 0 || newIndex == 3) {
      _hideOverlay();
      setState(() => _currentIndex = newIndex);
    } else {
      if (_overlayType != null) return;
      _handleBottomNavTap(newIndex);
    }
  }

  Widget _buildCardTabLabel(Translator t) {
    final cs = Theme.of(context).colorScheme;
    String currentTabName = "";
    switch (_currentIndex) {
      case 0: currentTabName = t.t('daily_entry_title'); break;
      case 1: currentTabName = t.t('setup_title'); break;
      case 2: currentTabName = t.t('report_title'); break;
      case 3: currentTabName = t.t('more_title'); break;
    }

    return Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(currentTabName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
      const Spacer(),
      Row(children: List.generate(4, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(left: 4),
        width: i == _currentIndex ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: i == _currentIndex ? cs.primary : cs.outlineVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ))),
    ]);
  }

  Widget _buildIconGrid(Translator t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 4;
        return Wrap(
          spacing: 0,
          runSpacing: 24,
          alignment: WrapAlignment.start,
          children: _currentModules
            .where((m) => !m.isEmpty)
            .map((item) => _buildModuleIconItem(item, itemWidth, t))
            .toList(),
        );
      }
    );
  }

  Widget _buildModuleIconItem(ModuleItem item, double width, Translator t) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = SizedBox(
      width: width,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedMap[item.routeName] = true),
        onTapUp: (_) => setState(() => _pressedMap[item.routeName] = false),
        onTapCancel: () => setState(() => _pressedMap[item.routeName] = false),
        onTap: _overlayType != null ? null : () => _handleModuleTap(item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressedMap[item.routeName] == true ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Color.lerp(item.iconColor.withOpacity(0.13), isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow, 0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.iconColor.withOpacity(isDark ? 0.22 : 0.18), width: 0.8),
                ),
                child: Icon(item.icon, size: 24, color: Color.lerp(item.iconColor, cs.onSurface, isDark ? 0.08 : 0.15)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.t(item.labelKey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.85), height: 1.3),
            ),
          ],
        ),
      ),
    );

    // Showcase wrapping
    if (_currentIndex == 1 && item.routeName == '/site') {
      content = Showcase(key: SiteRegistry.siteModuleCardKey, description: "Click to add site details", child: content);
    } else if (_checkpoint == TourCheckpoint.rate && item.routeName == '/site-list/rate') {
      content = Showcase(key: TourRegistry.rateModuleKey, description: "Click to add rate details", child: content);
    } else if (_checkpoint == TourCheckpoint.manpower && item.routeName == '/manpower') {
      content = Showcase(key: TourRegistry.manpowerModuleKey, description: "Click to add manpower details", child: content);
    } else if (_checkpoint == TourCheckpoint.team && item.routeName == '/site-list/team') {
      content = Showcase(key: TourRegistry.teamModuleKey, description: "Click to add team details", child: content);
    } else if (_checkpoint == TourCheckpoint.dpr && item.routeName == '/site-list/addMoc') {
      content = Showcase(key: TourRegistry.dprModuleKey, description: "Click to add DPR details", child: content);
    }

    return content;
  }

  // ── Part 6: Floating NavBar ────────────────────────────────────────────────
  Widget _buildFloatingNavBar(BuildContext showcaseContext, Translator t) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh.withOpacity(0.75) : cs.surface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
            boxShadow: [BoxShadow(color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _buildMenuButton(),
              const SizedBox(width: 8),
              Expanded(child: _buildTabPills(showcaseContext)),
              const SizedBox(width: 8),
              _buildAiButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _showQuickSettings = !_showQuickSettings),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        ),
        child: Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildQuickSettingsMenu(ColorScheme cs, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          alignment: Alignment.bottomLeft,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh.withOpacity(0.85) : cs.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickSettingRow("Compact Mode", _dummyToggle1, (val) => setState(() => _dummyToggle1 = val)),
                const Divider(height: 16, thickness: 0.5),
                _buildQuickSettingRow("Show Labels", _dummyToggle2, (val) => setState(() => _dummyToggle2 = val)),
                const Divider(height: 16, thickness: 0.5),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded, size: 18, color: cs.error),
                  title: Text("Log Out", style: TextStyle(fontSize: 13, color: cs.error, fontWeight: FontWeight.w600)),
                  onTap: () => context.go('/workCategory'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSettingRow(String label, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        SizedBox(
          height: 24,
          child: Switch.adaptive(
            value: value, 
            onChanged: onChanged,
            activeColor: cs.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _navLine(double width) {
    final cs = Theme.of(context).colorScheme;
    return Container(width: width, height: 1.8, decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.7), borderRadius: BorderRadius.circular(1)));
  }

  Widget _buildTabPills(BuildContext showcaseContext) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25), width: 0.6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final pillWidth = (totalWidth - 24) / 4; // 4px spacing * 6 (edges + gaps)
          
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                left: 4 + (_currentIndex * (pillWidth + 5.3)),
                top: 4,
                bottom: 4,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabPill(label: 'Daily', index: 0, sc: null),
                  _buildTabPill(label: 'Setup', index: 1, sc: showcaseContext),
                  _buildTabPill(label: 'Reports', index: 2, sc: null),
                  _buildTabPill(label: 'More', index: 3, sc: null),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTabPill({required String label, required int index, BuildContext? sc}) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _currentIndex == index;
    Widget pill = Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0 || index == 3) {
            _hideOverlay();
            setState(() => _currentIndex = index);
          } else {
            if (_overlayType != null) return;
            _handleBottomNavTap(index);
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11, 
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600, 
                color: isActive ? Colors.white : cs.onSurfaceVariant.withOpacity(0.65)
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );

    if (index == 1 && sc != null) {
      pill = Showcase(
        key: TourRegistry.setupBottomNavKey,
        description: "Tap Setup to configure Site, Rate, Manpower, Team etc ⚙️",
        disposeOnTap: true,
        onTargetClick: () async {
          await ref.read(tourPersistenceProvider).markSetupClicked();
          await _handleBottomNavTap(1);
          setState(() => _tourChecked = false);
        },
        child: pill,
      );
    }
    return pill;
  }

  Widget _buildAiButton() {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _overlayType != null ? null : _handleAiAnalysisTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Space for shadow pulse
            child: Container(
              width: 44, height: 44,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.12 + (_pulseAnimation.value * 0.1)), 
                    blurRadius: 8 + (_pulseAnimation.value * 6), 
                    spreadRadius: _pulseAnimation.value * 2
                  )
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/adaptive-icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Part 7: Loading State ──────────────────────────────────────────────────
  Widget _buildLoadingState() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _pageBackgroundColor(cs, isDark),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerImage(height: 10, width: 100, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerImage(height: 26, width: 180, borderRadius: 8),
                  SizedBox(height: 4),
                  ShimmerImage(height: 10, width: 120, borderRadius: 6),
                ]
              )),
              const ShimmerImage(height: 28, width: 80, borderRadius: 14),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: const [
              Expanded(child: ShimmerImage(height: 54, width: double.infinity, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(child: ShimmerImage(height: 54, width: double.infinity, borderRadius: 14)),
            ]),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _panelColor(cs, isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _moduleCardBorderColor(cs, isDark), width: 0.8),
              ),
              child: Column(children: [
                Row(children: const [
                  ShimmerImage(height: 6, width: 6, borderRadius: 3),
                  SizedBox(width: 6),
                  ShimmerImage(height: 10, width: 100, borderRadius: 5),
                  Spacer(),
                  ShimmerImage(height: 20, width: 48, borderRadius: 10),
                ]),
                const SizedBox(height: 10),
                _buildActivityRowShimmer(),
                const SizedBox(height: 6),
                _buildActivityRowShimmer(),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _panelColor(cs, isDark),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _moduleCardBorderColor(cs, isDark), width: 0.8),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(children: [
                  Row(children: [
                    const ShimmerImage(height: 18, width: 4, borderRadius: 2),
                    const SizedBox(width: 8),
                    const ShimmerImage(height: 14, width: 100, borderRadius: 6),
                    const Spacer(),
                    Row(children: List.generate(4, (i) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ShimmerImage(height: 6, width: i == 0 ? 16 : 6, borderRadius: 3),
                      )
                    )),
                  ]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 20,
                      alignment: WrapAlignment.spaceAround,
                      children: List.generate(8, (i) =>
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 64) / 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              ShimmerImage(height: 52, width: 52, borderRadius: 16),
                              SizedBox(height: 6),
                              ShimmerImage(height: 10, width: 44, borderRadius: 5),
                            ],
                          ),
                        )
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _buildActivityRowShimmer() {
    return Row(children: [
      const ShimmerImage(height: 26, width: 26, borderRadius: 8),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        ShimmerImage(height: 11, width: double.infinity, borderRadius: 5),
        SizedBox(height: 4),
        ShimmerImage(height: 9, width: 80, borderRadius: 4),
      ])),
    ]);
  }
}
