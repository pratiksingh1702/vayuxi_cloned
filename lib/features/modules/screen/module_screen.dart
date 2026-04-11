// features/modules/screen/module_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGE IN THIS VERSION
// ─────────────────────────────────────────────────────────────────────────────
//
// When access check returns noSubscription → redirect to /subscription screen
// instead of showing the inline plan overlay.
//
// All other gates (needsOnboarding, deviceNotVerified) still use the overlay
// as before. Only noSubscription is redirected.
//
// WHY:
//   The subscription screen (/subscription) is the proper full-screen plan
//   selection experience with Hero animations and plan detail views.
//   The inline overlay plan cards are a secondary fallback that's no longer
//   needed for this gate since the dedicated screen handles it better.
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/offline/state/team_State.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamService.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../core/router/access_control_provider.dart';
import '../../../core/utlis/widgets/shimmer.dart';
import '../../../core/utlis/widgets/sidebar.dart';
import '../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../language/service/lang_providers.dart';
import '../../language/service/providers.dart';
import '../../language/service/translator.dart';
import '../../tour/domain/tour_controller.dart';
import '../../tour/domain/tour_events.dart';
import '../../tour/domain/tour_presistent.dart';
import '../../tour/domain/tour_registery.dart';
import '../../tour/registry/site_registry.dart';
import '../all_Modules/site_Details/providers/siteProvider.dart';
import '../all_Modules/site_Details/providers/site_current_provider.dart';
import '../all_Modules/team/provider/teamProvider.dart';
import 'craosule_banner.dart';
import 'widgets/access_overlay.dart';

class ModuleScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ModuleScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  late int _currentIndex;
  SiteModel? _selectedSite;
  TeamModel? _selectedTeam;
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  BuildContext? _showcaseContext;
  bool _tourChecked = false;
  bool _tourStartPending = false;
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
  //
  // noSubscription → navigates to /subscription (full screen experience)
  // needsOnboarding / deviceNotVerified → shows inline overlay as before
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _checkAccess({
    required VoidCallback onAllowed,
    VoidCallback? previewSwitch,
  }) async {
    if (_checkInProgress) {
      print(
          '🔒 [ModuleScreen] _checkAccess skipped — check already in progress');
      return false;
    }
    _checkInProgress = true;
    print('🔒 [ModuleScreen] _checkAccess started');

    if (previewSwitch != null) {
      setState(previewSwitch);
    }

    setState(() => _overlayLoading = true);

    try {
      await ref.read(accessControlProvider.notifier).evaluate();

      final asyncValue = ref.read(accessControlProvider);
      setState(() => _overlayLoading = false);
      _checkInProgress = false;

      final result = asyncValue.valueOrNull;

      if (result == null) {
        print('⚠️  [ModuleScreen] accessControlProvider returned null result');
        return false;
      }

      print('🔒 [ModuleScreen] Access result: ${result.state}');

      if (result.state == AccessState.allowed) {
        print('✅ [ModuleScreen] Access GRANTED');
        return true;
      }

      // ── noSubscription → redirect to subscription screen ─────────────────
      // Don't show inline plan overlay — use the dedicated subscription page.
      if (result.state == AccessState.noSubscription) {
        print(
            '🔒 [ModuleScreen] No subscription → redirecting to /subscription');
        if (mounted) context.push('/subscription');
        return false;
      }

      // ── Other gates (onboarding, device OTP) → show inline overlay ───────
      _storePendingAndShowOverlay(result.state, onAllowed);
      return false;
    } catch (e) {
      print('❌ [ModuleScreen] _checkAccess error: $e');
      setState(() => _overlayLoading = false);
      _checkInProgress = false;
      return false;
    }
  }

  void _storePendingAndShowOverlay(AccessState gate, VoidCallback onAllowed) {
    _checkInProgress = false;
    print('🎭 [ModuleScreen] Showing overlay gate: $gate');
    setState(() {
      _pendingAction = onAllowed;
      _overlayType = gate;
    });
  }

  void _hideOverlay() {
    print('🎭 [ModuleScreen] Hiding overlay');
    setState(() {
      _overlayType = null;
      _pendingAction = null;
      _checkInProgress = false;
    });
  }

  Future<void> _onUnlocked() async {
    print('🔓 [ModuleScreen] _onUnlocked called');

    if (_overlayLoading) {
      print('🔓 [ModuleScreen] _onUnlocked skipped — already loading');
      return;
    }

    setState(() => _overlayLoading = true);

    try {
      await ref.read(accessControlProvider.notifier).evaluate();

      final asyncValue = ref.read(accessControlProvider);
      setState(() => _overlayLoading = false);

      final result = asyncValue.valueOrNull;

      if (result == null) {
        print('⚠️  [ModuleScreen] _onUnlocked: null result after evaluate');
        _hideOverlay();
        return;
      }

      print('🔓 [ModuleScreen] _onUnlocked result: ${result.state}');

      if (result.state == AccessState.allowed) {
        print('✅ [ModuleScreen] All gates cleared — running pending action');
        final action = _pendingAction;
        setState(() {
          _overlayType = null;
          _pendingAction = null;
          _tourChecked = false;
        });
        action?.call();
      } else if (result.state == AccessState.noSubscription) {
        // Subscription gate appeared after completing another gate
        // (e.g. onboarding done but subscription still needed).
        // Redirect to subscription screen instead of showing overlay.
        print(
            '🔒 [ModuleScreen] _onUnlocked: noSubscription → redirecting to /subscription');
        setState(() {
          _overlayType = null;
          _pendingAction = null;
        });
        if (mounted) context.push('/subscription');
      } else {
        print('🔒 [ModuleScreen] Still blocked at: ${result.state}');
        setState(() => _overlayType = result.state);
      }
    } catch (e) {
      print('❌ [ModuleScreen] _onUnlocked error: $e');
      setState(() => _overlayLoading = false);
      _hideOverlay();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOUR (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _maybeStartShowcase(BuildContext showcaseContext) async {
    // ✅ Gate 1: Already checked or pending
    if (_tourChecked || _tourStartPending) {
      debugPrint('⏳ ModuleScreen showcase blocked: already checked/pending');
      return;
    }

    // ✅ Gate 2: Widget not mounted
    if (!mounted) {
      debugPrint('⏳ ModuleScreen showcase blocked: not mounted');
      return;
    }

    // ✅ Gate 3: Access locks still blocking (overlays or gates active)
    if (_overlayLoading) {
      debugPrint('⏳ ModuleScreen showcase blocked: overlay loading');
      return;
    }
    if (_overlayType != null) {
      debugPrint('⏳ ModuleScreen showcase blocked: access gate=$_overlayType');
      return;
    }

    // ✅ Gate 4: Route not current
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      debugPrint('⏳ ModuleScreen showcase blocked: route not current');
      return;
    }

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
      // ✅ Don't start site tour on module screen
      // Site tour will start automatically on /site route
      // via SiteRegistry activation when user navigates there
      debugPrint('ℹ️ Site tour not done, but will auto-start on /site page');
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

  // ─────────────────────────────────────────────────────────────────────────
  // MODULE DATA (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  final List<ModuleItem> _dailyEntryModules = [
    ModuleItem(
        labelKey: 'attendance_card',
        imagePath: "assets/images/icons/attendance.webp",
        routeName: "/site-list/attendance"),
    ModuleItem(
        labelKey: 'daily_progress_card',
        imagePath: "assets/images/icons/dpr.webp",
        routeName: "/site-list/dpr"),
    ModuleItem(
        labelKey: 'expense_card',
        imagePath: "assets/images/icons/expense_daily.webp",
        routeName: "/site-list/add-exp"),
    ModuleItem(
        labelKey: 'inventory_entry_card',
        imagePath: "assets/images/icons/inventory_entry.webp",
        routeName: "/site-list/inv-entry"),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
    ModuleItem(labelKey: '', imagePath: '', routeName: '', isEmpty: true),
  ];

  final List<ModuleItem> _setupModules = [
    ModuleItem(
        labelKey: 'site_details_card',
        imagePath: "assets/images/icons/site_details.webp",
        routeName: "/site"),
    ModuleItem(
        labelKey: 'rate_card',
        imagePath: "assets/images/icons/rate.webp",
        routeName: "/site-list/rate"),
    ModuleItem(
        labelKey: 'manpower_details_card',
        imagePath: "assets/images/icons/manpower_setup.webp",
        routeName: "/manpower"),
    ModuleItem(
        labelKey: 'create_team_card',
        imagePath: "assets/images/icons/add_team.webp",
        routeName: "/site-list/team"),
    ModuleItem(
        labelKey: 'dpr_setup_card',
        imagePath: "assets/images/icons/dpr_setup.webp",
        routeName: "/site-list/addMoc"),
    ModuleItem(
        labelKey: 'inventory_setup_card',
        imagePath: "assets/images/icons/inventory_setup.webp",
        routeName: "/site-list/inv-setup"),
    // ModuleItem(labelKey: 'boq_card', imagePath: "assets/images/icons/boq.webp", routeName: "/site-list/boq"),
  ];

  final List<ModuleItem> _reportModules = [
    ModuleItem(
        labelKey: 'summary_analysis_card',
        imagePath: "assets/images/icons/summary_analysis.webp",
        routeName: "/summary"),
    ModuleItem(
        labelKey: 'salary_slip_card',
        imagePath: "assets/images/icons/salary_slip.webp",
        routeName: "/salary"),
    ModuleItem(
        labelKey: 'dpr_sheets_card',
        imagePath: "assets/images/icons/dpr_report.webp",
        routeName: "/site-list/dprReport"),
    ModuleItem(
        labelKey: 'expense_sheet_card',
        imagePath: "assets/images/icons/expense_sheet.webp",
        routeName: "/site-list/expense"),
    ModuleItem(
        labelKey: 'attendance_sheet_card',
        imagePath: "assets/images/icons/attendance_sheet.webp",
        routeName: "/site-list/att-sheet"),
    ModuleItem(
        labelKey: 'inventory_summary_card',
        imagePath: "assets/images/icons/inventory_summary.webp",
        routeName: "/site-list/inv-Report"),
  ];

  final List<ModuleItem> _moreModules = [
    ModuleItem(
        labelKey: 'profile_card',
        imagePath: "assets/images/icons/profile.webp",
        routeName: "/profile"),
    ModuleItem(
        labelKey: 'subscription_card',
        imagePath: "assets/images/icons/subscription.webp",
        routeName: "/subscription"),
    ModuleItem(
        labelKey: 'upcoming_update_card',
        imagePath: "assets/images/icons/updates.webp",
        routeName: "/upcoming-update"),
    ModuleItem(
        labelKey: 'theme_card',
        imagePath: "assets/images/icons/theme.webp",
        routeName: "/theme"),
    ModuleItem(
        labelKey: 'language_card',
        imagePath: "assets/images/icons/language.webp",
        routeName: "/language"),
    ModuleItem(
        labelKey: 'help_card',
        imagePath: "assets/images/icons/help.webp",
        routeName: "/help"),
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

  void _onTeamChanged(TeamModel? newTeam) =>
      setState(() => _selectedTeam = newTeam);

  Color _pageBackgroundColor(ColorScheme cs, bool isDark) {
    return isDark ? cs.surface : cs.surfaceContainerLowest;
  }

  Color _panelColor(ColorScheme cs, bool isDark) {
    return isDark ? cs.surfaceContainerHigh : cs.surface;
  }

  Color _moduleCardColor(ColorScheme cs, bool isDark) {
    return isDark ? cs.surfaceContainer : cs.surfaceContainerLow;
  }

  Color _moduleCardBorderColor(ColorScheme cs, bool isDark) {
    return isDark
        ? cs.outline.withOpacity(0.42)
        : cs.outlineVariant.withOpacity(0.92);
  }

  List<BoxShadow> _moduleCardShadow(ColorScheme cs, bool isDark) {
    return [
      BoxShadow(
        color: cs.shadow.withOpacity(isDark ? 0.28 : 0.08),
        blurRadius: isDark ? 10 : 8,
        spreadRadius: isDark ? 0.6 : 0.8,
        offset: const Offset(0, 3),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION HANDLERS (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleModuleTap(ModuleItem item) async {
    if (item.isEmpty) return;
    ref.read(moduleScreenSyncProvider.notifier).syncDropdownToGlobal();

    if (_currentIndex == 3) {
      _navigateToModule(item);
      return;
    }
    if (_currentIndex == 0) {
      _navigateToModule(item);
      return;
    }

    void navigate() => _navigateToModule(item);
    final ok = await _checkAccess(onAllowed: navigate);
    if (ok) navigate();
  }

  Future<void> _navigateToModule(ModuleItem item) async {
    if (item.routeName == '/site') {
      await ref
          .read(tourControllerProvider.notifier)
          .onEvent(TourEvents.siteModuleTapped);
    }

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

  // ─────────────────────────────────────────────────────────────────────────
  // LOADING STATE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _pageBackgroundColor(colorScheme, isDark),
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: _currentIndex == 0
            ? 'Daily Entry'
            : _currentIndex == 1
                ? 'Setup'
                : _currentIndex == 2
                    ? 'Report'
                    : 'More',
      ),
      body: CornerClippedScreenSimple(
        child: SafeArea(
          child: Column(
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
              Row(
                children: [
                  Expanded(child: _buildDropdownLoadingBox()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdownLoadingBox()),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ShimmerList(
                  type: ShimmerListType.grid,
                  itemCount: 4,
                  crossAxisCount: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemSpacing: 16,
                  gridChildAspectRatio: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLoadingBox() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _panelColor(colorScheme, isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _moduleCardBorderColor(colorScheme, isDark),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.22 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const ShimmerImage(
          height: 52,
          width: double.infinity,
          borderRadius: 16,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final siteState = ref.watch(siteProvider);
    final teamState = ref.watch(teamProvider);
    final homeModuleAsync = ref.watch(languageModuleProvider('home'));
    final tHelper = ref.watch(homeTranslationHelperProvider);

    return homeModuleAsync.when(
      loading: () => _buildLoadingState(),
      error: (e, _) => _buildLoadingState(),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_overlayLoading || _overlayType != null) {
                _tourChecked = false;
                return;
              }
              _maybeStartShowcase(showcaseContext);
            });

            return Stack(
              children: [
                Scaffold(
                  backgroundColor: _pageBackgroundColor(colorScheme, isDark),
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
                                      Expanded(
                                          child: _buildSiteDropdown(siteState)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildTeamDropdown(teamState)),
                                    ]),
                                    const SizedBox(height: 1),
                                  ],
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  child: _currentModules.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.inventory_2_outlined,
                                                  size: 64,
                                                  color: colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.35)),
                                              const SizedBox(height: 16),
                                              Text(
                                                t.t("no_modules_available"),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                t.t("try_changing_tab"),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : CustomScrollbar(
                                          enabled: false,
                                          controller: _gridScrollController,
                                          child: GridView.builder(
                                            controller: _gridScrollController,
                                            physics: _overlayType != null
                                                ? const NeverScrollableScrollPhysics()
                                                : const AlwaysScrollableScrollPhysics(),
                                            itemCount: _currentModules.length,
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 16,
                                              crossAxisSpacing: 16,
                                              childAspectRatio: 1,
                                            ),
                                            itemBuilder: (context, index) {
                                              final item =
                                                  _currentModules[index];
                                              if (item.isEmpty) {
                                                return Container(
                                                    decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .surface
                                                            .withOpacity(0),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20)));
                                              }

                                              Widget card = GestureDetector(
                                                onTap: _overlayType != null
                                                    ? null
                                                    : () =>
                                                        _handleModuleTap(item),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _moduleCardColor(
                                                        colorScheme, isDark),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color:
                                                          _moduleCardBorderColor(
                                                              colorScheme,
                                                              isDark),
                                                    ),
                                                    boxShadow:
                                                        _moduleCardShadow(
                                                            colorScheme,
                                                            isDark),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        height: 90,
                                                        width: 90,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          child: Image.asset(
                                                              item.imagePath,
                                                              fit: BoxFit
                                                                  .contain),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8),
                                                        child: Text(
                                                          t.t(item.labelKey),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );

                                              final bool isSetupTab =
                                                  _currentIndex == 1;

                                              if (isSetupTab &&
                                                  item.routeName == '/site') {
                                                card = Showcase(
                                                  key: SiteRegistry
                                                      .siteModuleCardKey,
                                                  description:
                                                      'Tap Site Details to begin setup.',
                                                  child: card,
                                                );
                                              }

                                              if (_checkpoint ==
                                                      TourCheckpoint.rate &&
                                                  isSetupTab &&
                                                  item.routeName ==
                                                      "/site-list/rate") {
                                                card = Showcase(
                                                    key: TourRegistry
                                                        .rateModuleKey,
                                                    description:
                                                        "Now add Rate here 💰",
                                                    disposeOnTap: true,
                                                    onTargetClick: () async {
                                                      await ref
                                                          .read(
                                                              tourPersistenceProvider)
                                                          .markRateDone();
                                                      setState(() =>
                                                          _tourChecked = false);
                                                    },
                                                    child: card);
                                              } else if (_checkpoint ==
                                                      TourCheckpoint.manpower &&
                                                  isSetupTab &&
                                                  item.routeName ==
                                                      "/manpower") {
                                                card = Showcase(
                                                    key: TourRegistry
                                                        .manpowerModuleKey,
                                                    description:
                                                        "Now add Manpower 👷",
                                                    disposeOnTap: true,
                                                    onTargetClick: () async {
                                                      await ref
                                                          .read(
                                                              tourPersistenceProvider)
                                                          .markManpowerDone();
                                                      setState(() =>
                                                          _tourChecked = false);
                                                    },
                                                    child: card);
                                              } else if (_checkpoint ==
                                                      TourCheckpoint.team &&
                                                  isSetupTab &&
                                                  item.routeName ==
                                                      "/site-list/team") {
                                                card = Showcase(
                                                    key: TourRegistry
                                                        .teamModuleKey,
                                                    description:
                                                        "Finally create your Team 👥",
                                                    disposeOnTap: true,
                                                    onTargetClick: () async {
                                                      await ref
                                                          .read(
                                                              tourPersistenceProvider)
                                                          .markTeamDone();
                                                      setState(() =>
                                                          _tourChecked = false);
                                                    },
                                                    child: card);
                                              } else if (_checkpoint ==
                                                      TourCheckpoint.dpr &&
                                                  isSetupTab &&
                                                  item.routeName ==
                                                      "/site-list/addMoc") {
                                                card = Showcase(
                                                    key: TourRegistry
                                                        .dprModuleKey,
                                                    description:
                                                        "Now configure DPR settings 📋",
                                                    disposeOnTap: true,
                                                    onTargetClick: () async {
                                                      await ref
                                                          .read(
                                                              tourPersistenceProvider)
                                                          .markDprDone();
                                                      setState(() =>
                                                          _tourChecked = false);
                                                    },
                                                    child: card);
                                              }

                                              return card;
                                            },
                                          ),
                                        ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 1,
                        bottom: -1,
                        child: GestureDetector(
                          onTap: _overlayType != null
                              ? null
                              : _handleAiAnalysisTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _panelColor(colorScheme, isDark),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: _moduleCardBorderColor(
                                          colorScheme, isDark)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow
                                          .withOpacity(isDark ? 0.24 : 0.12),
                                      spreadRadius: 0,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Text(
                                  "Ready to listen you !",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface),
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
                    backgroundColor: _panelColor(colorScheme, isDark),
                    selectedItemColor: colorScheme.onSurface,
                    unselectedItemColor: colorScheme.onSurfaceVariant,
                    selectedLabelStyle: TextStyle(color: colorScheme.onSurface),
                    unselectedLabelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(
                          icon: const Icon(Icons.edit_note_outlined),
                          label: tHelper.bottomNavDailyEntry),
                      BottomNavigationBarItem(
                        icon: Showcase(
                          key: TourRegistry.setupBottomNavKey,
                          description:
                              "Tap Setup to configure Site, Rate, Manpower, Team etc ⚙️",
                          disposeOnTap: true,
                          onTargetClick: () async {
                            await ref
                                .read(tourPersistenceProvider)
                                .markSetupClicked();
                            await _handleBottomNavTap(1);
                            setState(() => _tourChecked = false);
                          },
                          child: const Icon(Icons.settings_outlined),
                        ),
                        label: t.t('bottom_nav_setup'),
                      ),
                      BottomNavigationBarItem(
                          icon: const Icon(Icons.bar_chart_outlined),
                          label: t.t('bottom_nav_report')),
                      BottomNavigationBarItem(
                          icon: const Icon(Icons.more_horiz_outlined),
                          label: t.t('bottom_nav_more')),
                    ],
                  ),
                ),

                // Spinner while evaluate() is running
                if (_overlayLoading)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: colorScheme.scrim.withOpacity(0.42),
                        child: const Center(
                          child: ShimmerCircle(size: 60),
                        ),
                      ),
                    ),
                  ),

                // Overlay only for onboarding and device OTP gates
                // noSubscription is handled by navigation to /subscription
                if (!_overlayLoading &&
                    _overlayType != null &&
                    _overlayType != AccessState.noSubscription)
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueSites = siteState.sites
        .fold<Map<String, SiteModel>>({}, (map, site) {
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
        ? dropdownList.firstWhere((s) => s.id == _selectedSite!.id,
            orElse: () => noneSite)
        : noneSite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
            color: _panelColor(colorScheme, isDark),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _moduleCardBorderColor(colorScheme, isDark)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isDark ? 0.22 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SiteModel>(
            value: currentSelectedSite,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: colorScheme.primary),
            items: dropdownList
                .map((site) => DropdownMenuItem<SiteModel>(
                    value: site,
                    child: Text(site.siteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ))))
                .toList(),
            onChanged: (SiteModel? newSite) {
              if (newSite == null || newSite.id == "none") {
                _onSiteChanged(null);
                ref.read(siteDropdownValueProvider.notifier).state = null;
                ref.read(selectedSiteIdProvider.notifier).state = null;

                // 🔥 Clear team dropdown when "None" is selected
                ref.read(teamDropdownValueProvider.notifier).state = null;
                ref.read(selectedTeamIdProvider.notifier).state = "";
                ref.read(selectedTeamProvider.notifier).clear();

                // 🔥 Set teams to empty list
                ref.read(teamProvider.notifier).state =
                    ref.read(teamProvider.notifier).state.copyWith(
                  teams: [],
                  hasData: false,
                );
              } else {
                _onSiteChanged(newSite);
                ref.read(siteDropdownValueProvider.notifier).state = newSite;
                ref.read(selectedSiteIdProvider.notifier).state = newSite.id;

                // 🔥 Fetch teams for the selected site
                final type = ref.read(typeProvider); // Get selected type
                final notifier = ref.read(teamProvider.notifier);

                if (type == "mechanical_work") {
                  notifier.fetchMechanicalCombined(siteId: newSite.id);
                } else if (type == "insulation_work") {
                  notifier.fetchInsulationCombined(siteId: newSite.id);
                } else {
                  notifier.fetchTeams(
                    type: type ?? "",
                    siteId: newSite.id,
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDropdown(TeamState teamState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
            color: _panelColor(colorScheme, isDark),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _moduleCardBorderColor(colorScheme, isDark)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isDark ? 0.22 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]),
        child: Builder(builder: (context) {
          if (teamState.isLoading && !teamState.hasData)
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text("Loading teams...",
                        style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant))));
          if (!teamState.hasData && teamState.error != null)
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("None",
                    style: TextStyle(
                        fontSize: 14, color: colorScheme.onSurfaceVariant)));
          final uniqueTeams = teamState.teams
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
              type: '');
          final dropdownList = [noneTeam, ...uniqueTeams];
          final currentSelectedTeam = _selectedTeam != null
              ? dropdownList.firstWhere((t) => t.id == _selectedTeam!.id,
                  orElse: () => noneTeam)
              : noneTeam;
          return DropdownButtonHideUnderline(
            child: DropdownButton<TeamModel>(
              value: currentSelectedTeam,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.primary),
              items: dropdownList
                  .map((team) => DropdownMenuItem<TeamModel>(
                      value: team,
                      child: Text(team.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ))))
                  .toList(),
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
            ),
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
  final bool isEmpty;

  ModuleItem({
    required this.labelKey,
    required this.imagePath,
    required this.routeName,
    this.isEmpty = false,
  });
}
