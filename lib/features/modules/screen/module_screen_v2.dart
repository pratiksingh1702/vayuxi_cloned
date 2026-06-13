import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/screens/theme_switcher.dart';
import 'package:untitled2/features/noti_system/updates/presentation/navigation/updates_routes.dart';
import 'package:untitled2/features/noti_system/updates/application/providers/notification_providers.dart';

import 'package:untitled2/core/router/access_control_provider.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/language/service/lang_providers.dart';
import 'package:untitled2/features/language/service/translator.dart';
// ignore: unused_import // reserved for locale-switch rebuild
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/typeProvider/work_type.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
// ignore: unused_import // reserved for placeholder routes
import 'package:untitled2/core/router/placeholders.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/definitions/module_screen_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import 'widgets/access_overlay.dart';
import 'module_preferences.dart';
import 'module_dashboard_service.dart';
import 'package:untitled2/features/modules/screen/workflow/domain/workflow_controller.dart';
// ignore: unused_import // reserved for workflow state types
import 'package:untitled2/features/modules/screen/workflow/domain/workflow_state.dart';
import 'package:untitled2/features/modules/screen/workflow/registry/workflow_registry.dart';
import 'package:untitled2/features/profile_page/provider/userProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/dpr_draft_repo.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/offline/repo/insu_dpr_draft_repo.dart';

extension WorkTypeExtension on WorkType {
  String get displayNameShort {
    switch (this) {
      case WorkType.mechanical:
        return 'Mechanical';
      case WorkType.insulation:
        return 'Insulation';
      case WorkType.structure:
        return 'Structural Erection';
      case WorkType.civil:
        return 'Civil';
      case WorkType.roofing:
        return 'Roofing';
      case WorkType.fabrication:
        return 'Structural Fabrication';
    }
  }
}

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

class _ModuleScreenV2State extends ConsumerState<ModuleScreenV2>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final Map<String, bool> _pressedMap = {};

  bool _showQuickSettings = false;

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
    _loadPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workflowControllerProvider.notifier).tryRestoreSession();
    });
  }

  Future<void> _loadPreferences() async {
    // We ignore the saved attachment preference to always start in "deattach" mode
    const isAttached = false;
    final isMultiple = await ModulePreferences.isMultipleEntry();
    if (mounted) {
      setState(() {
        _moduleCardAttached = isAttached;
        _moduleCardVisible = !isAttached;
        _multipleEntryMode = isMultiple;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  // ── Access & State variables (Kept from original) ──────────────────────────
  AccessState? _overlayType;
  bool _overlayLoading = false;
  bool _checkInProgress = false;
  VoidCallback? _pendingAction;
  String? _lastShowcasedTourStepId;
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final Map<String, GlobalKey> _moduleTourKeys = {};

  // NEW — module card attach/detach
  bool _moduleCardAttached = false;
  bool _moduleCardVisible = true;
  bool _multipleEntryMode = false;
  final ScrollController _scrollController = ScrollController();
  // ignore: unused_field
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  // ignore: unused_field
  Set<DateTime> _completedDates = {};

  // NEW — toast system
  String _toastMessage = '';
  bool _toastVisible = false;
  Timer? _toastTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _syncModuleTour(BuildContext showcaseContext, Translator t) {
    final currentTabTour = _buildCurrentTabTour(t);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _overlayLoading || _overlayType != null) return;
      if (currentTabTour.tabIndex != _currentIndex) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);

      if (tourState.status != AppTourStatus.running) {
        final startedWelcome = await tourController.maybeStartWelcome();
        if (!mounted) return;
        if (!startedWelcome) {
          await tourController.maybeStartRuntimeTour(
            currentTabTour,
            policyTourId: ModuleScreenTours.tabTourId(_currentIndex),
          );
        }
      }

      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      final stepKey = activeTour == null || step == null
          ? null
          : '${activeTour.id}:${step.id}';

      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }

      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  // ── Module Data ────────────────────────────────────────────────────────────
  List<ModuleItem> get _dailyEntryModules {
    final type = ref.watch(typeProvider);
    final base = [
      ModuleItem(
          labelKey: 'attendance_card',
          icon: Icons.how_to_reg_rounded,
          iconColor: Colors.green,
          routeName: "/site-list/attendance"),
      ModuleItem(
          labelKey: 'expense_card',
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.orange,
          routeName: "/site-list/add-exp"),
      ModuleItem(
          labelKey: 'inventory_entry_card',
          icon: Icons.inventory_2_rounded,
          iconColor: Colors.teal,
          routeName: "/site-list/inv-entry"),
    ];

    final dprModule = _getDprModule(type);
    final pmModule = (type == 'erection_work' ||
            type == WorkType.structure.apiValue ||
            type == 'fabrication_work' ||
            type == WorkType.fabrication.apiValue)
        ? ModuleItem(
            labelKey: 'P&M Entry',
            icon: Icons.precision_manufacturing_rounded,
            iconColor: const Color(0xFF7B3F00),
            routeName: "/site-list/structure-pm-entry")
        : null;
    return [
      base[0],
      dprModule,
      if (pmModule != null) pmModule,
      ...base.sublist(1),
    ];
  }

  ModuleItem _getDprModule(String? type) {
    if (type == 'mechanical_work' || type == WorkType.mechanical.apiValue) {
      return ModuleItem(
          labelKey: 'daily_progress_card',
          icon: Icons.description_rounded,
          iconColor: Colors.indigo,
          routeName: "/site-list/dpr");
    } else if (type == 'insulation_work' ||
        type == WorkType.insulation.apiValue) {
      return ModuleItem(
          labelKey: 'Insulation DPR',
          icon: Icons.layers_rounded,
          iconColor: Colors.indigo,
          routeName: "/site-list/dpr");
    } else if (type == 'structure_work' ||
        type == WorkType.structure.apiValue) {
      return ModuleItem(
          labelKey: 'Structure Erection DPR',
          icon: Icons.construction_rounded,
          iconColor: Colors.indigo,
          routeName: "/site-list/dpr");
    } else if (type == 'civil_work' || type == WorkType.civil.apiValue) {
      return ModuleItem(
          labelKey: 'Civil DPR',
          icon: Icons.foundation_rounded,
          iconColor: Colors.indigo,
          routeName: Routes.civilDpr);
    } else if (type == 'roofing_work' || type == WorkType.roofing.apiValue) {
      return ModuleItem(
          labelKey: 'Roofing DPR',
          icon: Icons.roofing_rounded,
          iconColor: Colors.indigo,
          routeName: Routes.roofingDpr);
    } else if (type == 'fabrication_work' ||
        type == WorkType.fabrication.apiValue) {
      return ModuleItem(
          labelKey: 'Structure Fabrication DPR',
          icon: Icons.factory_rounded,
          iconColor: Colors.indigo,
          routeName: Routes.fabricationDpr);
    }
    return ModuleItem(
        labelKey: 'daily_progress_card',
        icon: Icons.description_rounded,
        iconColor: Colors.indigo,
        routeName: "/site-list/dpr");
  }

  List<ModuleItem> get _setupModules {
    final type = ref.watch(typeProvider);
    final historyUploadModule = _getSatmaxHistoryUploadModule(type);

    final base = [
      ModuleItem(
          labelKey: 'site_details_card',
          icon: Icons.location_city_rounded,
          iconColor: Colors.cyan,
          routeName: "/site"),
      ModuleItem(
          labelKey: 'rate_card',
          icon: Icons.currency_rupee_rounded,
          iconColor: Colors.amber,
          routeName: "/site-list/rate"),
      ModuleItem(
          labelKey: 'manpower_details_card',
          icon: Icons.engineering_rounded,
          iconColor: Colors.deepOrange,
          routeName: "/manpower"),
      ModuleItem(
          labelKey: 'create_team_card',
          icon: Icons.groups_rounded,
          iconColor: Colors.purple,
          routeName: "/site-list/team"),
      ModuleItem(
          labelKey: 'inventory_setup_card',
          icon: Icons.warehouse_rounded,
          iconColor: Colors.brown,
          routeName: "/site-list/inv-setup"),
    ];

    final dprSetupModule = _getDprSetupModule(type);
    final secondaryModules = _getSecondaryModules(type);
    final workAssignmentModule = _getWorkAssignmentModule(type);
    final pmSetupModule = _getPmSetupModule(type);

    return [
      ...base,
      ...secondaryModules,
      if (historyUploadModule != null) historyUploadModule,
      dprSetupModule,
      if (workAssignmentModule != null) workAssignmentModule,
      if (pmSetupModule != null) pmSetupModule,
    ];
  }

  bool get _isSatmaxUser {
    return ref.watch(currentUserProvider)?.hasSatmaxMainFrameAccess ?? false;
  }

  ModuleItem? _getSatmaxHistoryUploadModule(String? type) {
    if (!_isSatmaxUser) return null;
    if (type == 'structure_work' || type == WorkType.structure.apiValue) {
      return ModuleItem(
          labelKey: 'History Upload',
          icon: Icons.history_edu_rounded,
          iconColor: const Color(0xFF7B3F00),
          routeName: "/site-list/structure-history-upload");
    }
    return null;
  }

  ModuleItem _getDprSetupModule(String? type) {
    if (type == 'mechanical_work' || type == WorkType.mechanical.apiValue) {
      return ModuleItem(
          labelKey: 'DPR Setup',
          icon: Icons.settings_suggest_rounded,
          iconColor: Colors.blueGrey,
          routeName: "/site-list/addMoc");
    } else if (type == 'insulation_work' ||
        type == WorkType.insulation.apiValue) {
      return ModuleItem(
          labelKey: 'Insulation DPR Setup',
          icon: Icons.settings_suggest_rounded,
          iconColor: Colors.blueGrey,
          routeName: "/site-list/addMoc");
    } else if (type == 'structure_work' ||
        type == WorkType.structure.apiValue) {
      return ModuleItem(
          labelKey: 'Structure Erection Setup',
          icon: Icons.architecture_rounded,
          iconColor: Colors.blueAccent,
          routeName: Routes.erectionSetup);
    } else if (type == 'civil_work' || type == WorkType.civil.apiValue) {
      return ModuleItem(
          labelKey: 'Civil DPR Setup',
          icon: Icons.foundation_rounded,
          iconColor: Colors.blueAccent,
          routeName: Routes.civilSetup);
    } else if (type == 'roofing_work' || type == WorkType.roofing.apiValue) {
      return ModuleItem(
          labelKey: 'Roofing DPR Setup',
          icon: Icons.roofing_rounded,
          iconColor: Colors.blueGrey,
          routeName: Routes.roofingSetup);
    } else if (type == 'fabrication_work' ||
        type == WorkType.fabrication.apiValue) {
      return ModuleItem(
          labelKey: 'Structure Fabrication Setup',
          icon: Icons.factory_rounded,
          iconColor: Colors.blueAccent,
          routeName: Routes.fabricationSetup);
    }
    return ModuleItem(
        labelKey: 'DPR Setup',
        icon: Icons.settings_suggest_rounded,
        iconColor: Colors.blueGrey,
        routeName: "/site-list/addMoc");
  }

  ModuleItem? _getWorkAssignmentModule(String? type) {
    if (type == 'structure_work' ||
        type == WorkType.structure.apiValue ||
        type == 'fabrication_work' ||
        type == WorkType.fabrication.apiValue) {
      return ModuleItem(
          labelKey: 'Work Assignment',
          icon: Icons.assignment_ind_rounded,
          iconColor: Colors.deepPurple,
          routeName: "/site-list/work-assignment");
    }
    return null;
  }

  ModuleItem? _getPmSetupModule(String? type) {
    if (type == 'structure_work' ||
        type == WorkType.structure.apiValue ||
        type == 'fabrication_work' ||
        type == WorkType.fabrication.apiValue) {
      return ModuleItem(
          labelKey: 'P&M Setup',
          icon: Icons.precision_manufacturing_rounded,
          iconColor: const Color(0xFF7B3F00),
          routeName: "/site-list/structure-pm-setup");
    }
    return null;
  }

  List<ModuleItem> _getSecondaryModules(String? type) {
    final boqModule = ModuleItem(
        labelKey: 'BOQ',
        icon: Icons.table_rows_rounded,
        iconColor: const Color(0xFF7B3F00),
        routeName: Routes.boqUpload);

    if (type == 'mechanical_work' ||
        type == WorkType.mechanical.apiValue ||
        type == 'insulation_work' ||
        type == WorkType.insulation.apiValue ||
        type == 'roofing_work' ||
        type == WorkType.roofing.apiValue) {
      return [];
    } else if (type == 'structure_work' ||
        type == WorkType.structure.apiValue) {
      return [boqModule];
    } else if (type == 'fabrication_work' ||
        type == WorkType.fabrication.apiValue) {
      return [boqModule];
    } else if (type == 'civil_work' || type == WorkType.civil.apiValue) {
      return [boqModule];
    }
    return [];
  }

  List<ModuleItem> get _reportModules {
    final type = ref.watch(typeProvider);
    final pmReportModule = (type == 'structure_work' ||
            type == WorkType.structure.apiValue ||
            type == 'erection_work' ||
            type == 'fabrication_work' ||
            type == WorkType.fabrication.apiValue)
        ? ModuleItem(
            labelKey: 'P&M Reports',
            icon: Icons.precision_manufacturing_rounded,
            iconColor: const Color(0xFF7B3F00),
            routeName: "/site-list/structure-pm-report")
        : null;

    return [
      ModuleItem(
          labelKey: 'summary_analysis_card',
          icon: Icons.analytics_rounded,
          iconColor: Colors.blue,
          routeName: "/summary"),
      ModuleItem(
          labelKey: 'salary_slip_card',
          icon: Icons.payments_rounded,
          iconColor: Colors.lightGreen,
          routeName: "/salary"),
      ModuleItem(
          labelKey: 'dpr_sheets_card',
          icon: Icons.table_chart_rounded,
          iconColor: Colors.deepPurple,
          routeName: "/site-list/dprReport"),
      if (pmReportModule != null) pmReportModule,
      ModuleItem(
          labelKey: 'expense_sheet_card',
          icon: Icons.request_quote_rounded,
          iconColor: Colors.redAccent,
          routeName: "/site-list/expense"),
      ModuleItem(
          labelKey: 'attendance_sheet_card',
          icon: Icons.fact_check_rounded,
          iconColor: Colors.lime,
          routeName: "/site-list/att-sheet"),
      ModuleItem(
          labelKey: 'inventory_summary_card',
          icon: Icons.assessment_rounded,
          iconColor: Colors.pink,
          routeName: "/site-list/inv-Report"),
    ];
  }

  final List<ModuleItem> _moreModules = [
    ModuleItem(
        labelKey: 'profile_card',
        icon: Icons.account_circle_rounded,
        iconColor: Colors.deepPurpleAccent,
        routeName: "/profile"),
    ModuleItem(
        labelKey: 'subscription_card',
        icon: Icons.workspace_premium_rounded,
        iconColor: Colors.amberAccent,
        routeName: "/subscription"),
    ModuleItem(
        labelKey: 'upcoming_update_card',
        icon: Icons.new_releases_rounded,
        iconColor: Colors.lightBlue,
        routeName: "/upcoming-update"),
    ModuleItem(
        labelKey: 'theme_card',
        icon: Icons.palette_rounded,
        iconColor: Colors.pinkAccent,
        routeName: "/theme"),
    ModuleItem(
        labelKey: 'language_card',
        icon: Icons.translate_rounded,
        iconColor: Colors.cyanAccent,
        routeName: "/language"),
    ModuleItem(
        labelKey: 'help_card',
        icon: Icons.support_agent_rounded,
        iconColor: Colors.greenAccent,
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

  AppTourDefinition _buildCurrentTabTour(Translator t) {
    final modules = _currentModules;
    final policyId = ModuleScreenTours.tabTourId(_currentIndex);
    final type = _safeTourPart(ref.watch(typeProvider) ?? 'default');
    final signature = _moduleListSignature(modules);

    return AppTourDefinition(
      id: '${policyId}_${type}_$signature',
      title: _tabTourTitle(_currentIndex),
      description: 'Explains the visible modules in this tab.',
      icon: _tabTourIcon(_currentIndex),
      tabIndex: _currentIndex,
      steps: [
        for (var i = 0; i < modules.length; i++)
          AppTourStep(
            id: 'module_${i}_${_safeTourPart(modules[i].routeName)}',
            title: _moduleTourTitle(modules[i], t),
            body: _moduleTourDescription(
              modules[i],
              _moduleTourTitle(modules[i], t),
            ),
            targetKey: _moduleTourTargetKey(modules[i], i),
            progressLabel: 'Module ${i + 1} of ${modules.length}',
          ),
      ],
    );
  }

  String _tabTourTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Daily Entry';
      case 1:
        return 'Setup';
      case 2:
        return 'Reports';
      case 3:
        return 'More';
      default:
        return 'Modules';
    }
  }

  IconData _tabTourIcon(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return Icons.edit_calendar_rounded;
      case 1:
        return Icons.tune_rounded;
      case 2:
        return Icons.bar_chart_rounded;
      case 3:
        return Icons.more_horiz_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  GlobalKey _moduleTourTargetKey(ModuleItem item, int index) {
    final key = _moduleTourKey(item, index);
    return _moduleTourKeys.putIfAbsent(
      key,
      () => GlobalKey(debugLabel: 'tour_$key'),
    );
  }

  String _moduleTourKey(ModuleItem item, int index) {
    final type = ref.watch(typeProvider) ?? 'default';
    return [
      'tab$_currentIndex',
      _safeTourPart(type),
      index.toString(),
      _safeTourPart(item.routeName),
      _safeTourPart(item.labelKey),
    ].join('_');
  }

  String _moduleListSignature(List<ModuleItem> modules) {
    return modules
        .asMap()
        .entries
        .map((entry) {
          final item = entry.value;
          return [
            entry.key.toString(),
            _safeTourPart(item.routeName),
            _safeTourPart(item.labelKey),
          ].join('_');
        })
        .join('__');
  }

  String _safeTourPart(String value) {
    final sanitized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'module' : sanitized;
  }

  String _moduleTourTitle(ModuleItem item, Translator t) {
    final translated = t.t(item.labelKey).trim();
    return translated.isEmpty ? item.labelKey : translated;
  }

  String _moduleTourDescription(ModuleItem item, String title) {
    final byRoute = <String, String>{
      '/site-list/attendance': 'Use this to mark who came to work today.',
      '/site-list/dpr': "Use this to record today's work progress at the site.",
      Routes.civilDpr: "Use this to record today's work progress at the site.",
      Routes.roofingDpr:
          "Use this to record today's work progress at the site.",
      Routes.fabricationDpr:
          "Use this to record today's work progress at the site.",
      '/site-list/structure-pm-entry':
          'Use this to enter plant and machinery work for today.',
      '/site-list/add-exp': 'Use this to add money spent on site work.',
      '/site-list/inv-entry':
          'Use this to record material received, issued, or used.',
      '/site': 'Use this to create and manage your project sites.',
      '/site-list/rate':
          'Use this to set work or item rates before entries and reports.',
      '/manpower': 'Use this to add workers and manpower details.',
      '/site-list/team': 'Use this to create teams for site work.',
      '/site-list/inv-setup':
          'Use this to set up materials before inventory entries.',
      Routes.boqUpload:
          'Use this to view BOQ items or upload new BOQ data from Excel.',
      '/site-list/structure-history-upload':
          'Use this to upload old structure work history.',
      '/site-list/addMoc':
          'Use this to set up DPR options before daily progress entries.',
      Routes.erectionSetup:
          'Use this to prepare structure erection stages, tracking, and images before DPR entry.',
      Routes.civilSetup:
          'Use this to set up DPR options before daily progress entries.',
      Routes.roofingSetup:
          'Use this to set up DPR options before daily progress entries.',
      Routes.fabricationSetup:
          'Use this to set up DPR options before daily progress entries.',
      '/site-list/work-assignment': 'Use this to assign work items to teams.',
      '/site-list/structure-pm-setup':
          'Use this to choose P&M categories and add the works used in daily P&M entries.',
      '/summary': 'Use this to see a quick summary of project progress.',
      '/salary': 'Use this to check and download salary slips.',
      '/site-list/dprReport': 'Use this to view or download DPR reports.',
      '/site-list/structure-pm-report': 'Use this to check P&M report details.',
      '/site-list/expense': 'Use this to view or download expense records.',
      '/site-list/att-sheet':
          'Use this to view or download attendance records.',
      '/site-list/inv-Report': 'Use this to check inventory summaries.',
      '/profile': 'Use this to view or update your profile.',
      '/subscription': 'Use this to manage your plan and subscription.',
      '/upcoming-update': 'Use this to see new and upcoming app updates.',
      '/theme': 'Use this to change the app look.',
      '/language': 'Use this to change the app language.',
      '/help': 'Use this when you need support or guidance.',
    };

    final routeDescription = byRoute[item.routeName];
    if (routeDescription != null) return routeDescription;

    final lookup = '${item.labelKey} $title'.toLowerCase();
    if (lookup.contains('attendance')) {
      return 'Use this to mark who came to work today.';
    }
    if (lookup.contains('dpr') || lookup.contains('daily_progress')) {
      return "Use this to record today's work progress at the site.";
    }
    if (lookup.contains('expense')) {
      return 'Use this to add or check money spent on site work.';
    }
    if (lookup.contains('inventory')) {
      return 'Use this to manage material details for site work.';
    }
    if (lookup.contains('site')) {
      return 'Use this to create and manage your project sites.';
    }
    if (lookup.contains('rate')) {
      return 'Use this to set rates before entries and reports.';
    }
    if (lookup.contains('team')) {
      return 'Use this to create teams for site work.';
    }
    if (lookup.contains('report') || lookup.contains('sheet')) {
      return 'Use this to check summaries and download work records.';
    }
    return 'Open this module to manage $title.';
  }

  void _onSiteChanged(SiteModel? newSite) {
    if (newSite == null) {
      ref.read(siteDropdownValueProvider.notifier).state = null;
      ref.read(selectedSiteProvider.notifier).clear();
      ref.read(selectedSiteIdProvider.notifier).state = null;

      ref.read(teamDropdownValueProvider.notifier).state = null;
      ref.read(selectedTeamProvider.notifier).clear();
      ref.read(selectedTeamIdProvider.notifier).state = "";

      final notifier = ref.read(teamProvider.notifier);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      notifier.state = notifier.state.copyWith(
        teams: [],
        hasData: false,
      );
      return;
    }

    ref.read(selectedSiteProvider.notifier).select(newSite);

    final type = ref.read(typeProvider);
    final notifier = ref.read(teamProvider.notifier);
    if (type == "mechanical_work") {
      notifier.fetchMechanicalCombined(siteId: newSite.id);
    } else if (type == "insulation_work") {
      notifier.fetchInsulationCombined(siteId: newSite.id);
    } else {
      notifier.fetchTeams(type: type ?? newSite.type, siteId: newSite.id);
    }
  }

  void _onTeamChanged(TeamModel? newTeam) {
    if (newTeam == null) {
      ref.read(teamDropdownValueProvider.notifier).state = null;
      ref.read(selectedTeamProvider.notifier).clear();
      ref.read(selectedTeamIdProvider.notifier).state = "";
      return;
    }

    ref.read(selectedTeamProvider.notifier).select(newTeam);
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
    final selectedSite = ref.read(siteDropdownValueProvider);
    final selectedTeam = ref.read(teamDropdownValueProvider);
    await context.push(item.routeName, extra: {
      'selectedSite': selectedSite,
      'selectedTeam': selectedTeam,
    });
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
  Color _pageBackgroundColor(ColorScheme cs, bool isDark) =>
      isDark ? cs.surface : cs.surfaceContainerLowest;
  Color _panelColor(ColorScheme cs, bool isDark) =>
      isDark ? cs.surfaceContainerHigh : cs.surface;
  Color _moduleCardBorderColor(ColorScheme cs, bool isDark) => isDark
      ? cs.outline.withOpacity(0.35)
      : cs.outlineVariant.withOpacity(0.55);

  // ── NEW Design Tokens ──────────────────────────────────────────────────────
  Color _cardBg(ColorScheme cs, bool isDark) =>
      isDark ? cs.surfaceContainerHigh : Colors.white;
  Color _borderColor(ColorScheme cs, bool isDark) => isDark
      ? cs.outline.withOpacity(0.35)
      : cs.outlineVariant.withOpacity(0.5);

  List<BoxShadow> _dockShadow() => [
        BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 32,
            offset: const Offset(0, 10))
      ];

  // ── NEW Helpers ────────────────────────────────────────────────────────────
  void _showToast(String msg) {
    setState(() {
      _toastMessage = msg;
      _toastVisible = true;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  void _attachModuleCard(Translator t) {
    setState(() {
      _moduleCardAttached = true;
      _moduleCardVisible = false;
    });
    ModulePreferences.setCardAttached(true);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() {});
      _showToast("Module card attached to nav");
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _detachModuleCard() {
    setState(() {
      _moduleCardAttached = false;
    });
    ModulePreferences.setCardAttached(false);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _moduleCardVisible = true);
        _showToast("Module card moved to page");
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  Widget _buildScrollBody(Translator t, ColorScheme cs, bool isDark) {
    ref.watch(workflowControllerProvider);
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildContextualHeader(t),
          const SizedBox(height: 24),
          _buildDropdownRow(),
          const SizedBox(height: 20),
          // CONDITIONAL: inline module card (detached state)
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: _moduleCardAttached || !_moduleCardVisible
                ? const SizedBox.shrink()
                : _buildInlineModuleCard(t, cs, isDark),
          ),
          const SizedBox(height: 16),
          if (_currentIndex == 0) ...[
            _buildDailyStatsSection(cs, isDark),
            const SizedBox(height: 10),
          ],
          // bottom padding = dock height + 24
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            height: _getDockSpacerHeight(_currentModules),
          ),
        ],
      ),
    );
  }

  Widget _buildToastOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      top: _toastVisible ? 20 : -50,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _toastVisible ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _toastMessage,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowFab(ColorScheme cs, bool isDark) {
    return Positioned(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
      right: 20,
      child: FloatingActionButton.extended(
        onPressed: _navigateToWorkflowGate,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Add Entry",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _navigateToWorkflowGate() {
    context.push(Routes.workflowGate,
        extra: {'workflowId': WorkflowRegistry.dailyEntryId});
  }

  double _getDockSpacerHeight(List<ModuleItem> currentModules) {
    double base = 62 + 16 + 24;
    if (_moduleCardAttached) {
      int rows = (currentModules.length / 4).ceil();
      base += 58 + (rows * 78.0) + 30;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch these to ensure the page rebuilds when any filter changes
    ref.watch(typeProvider);
    ref.watch(siteDropdownValueProvider);
    ref.watch(teamDropdownValueProvider);
    ref.watch(workflowControllerProvider);
    ref.watch(appTourControllerProvider);

    ref.watch(siteProvider);
    final homeModuleAsync = ref.watch(languageModuleProvider('home'));
    return homeModuleAsync.when(
      loading: () => _buildLoadingState(),
      error: (e, _) => _buildLoadingState(),
      data: (homeData) {
        final t = Translator(homeData);

        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: _pageBackgroundColor(cs, isDark),
          body: ShowCaseWidget(
            builder: (showcaseContext) {
              _syncModuleTour(showcaseContext, t);
              return KeyedSubtree(
                key: ModuleScreenTourTargets.screenKey,
                child: GestureDetector(
                  onTap: () {
                    if (_showQuickSettings)
                      setState(() => _showQuickSettings = false);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: Scrollable page content
                      SafeArea(
                        child: _buildScrollBody(t, cs, isDark),
                      ),

                      // Layer 2: Floating dock (nav + optional attached card)
                      _buildFloatingDock(t, cs, isDark),

                      // Layer 3: Quick settings panel
                      if (_showQuickSettings)
                        Positioned(
                          bottom: 84 + MediaQuery.of(context).padding.bottom,
                          left: 20,
                          child: _buildQuickSettingsMenu(t, cs, isDark),
                        ),

                      // Layer 4: Toast notification
                      _buildToastOverlay(),

                      // Layer 5: Access overlay loading spinner
                      if (_overlayLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child:
                                const Center(child: CircularProgressIndicator()),
                          ),
                        ),

                      // Layer 6: Access overlay widget
                      if (!_overlayLoading &&
                          _overlayType != null &&
                          _overlayType != AccessState.noSubscription)
                        Positioned.fill(
                          child: AccessOverlay(
                            type: _overlayType!,
                            onUnlocked: _onUnlocked,
                            onDismiss: _hideOverlay,
                          ),
                        ),

                      // Layer 7: Workflow FAB
                      if (_currentIndex == 0) _buildWorkflowFab(cs, isDark),
                    ],
                  ),
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
    final user = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerLow,
                border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.4), width: 1.0),
              ),
              child: ClipOval(
                child: (user?.profilePhoto != null &&
                        user!.profilePhoto!.isNotEmpty)
                    ? Image.network(
                        user.profilePhoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: cs.primary),
                      )
                    : Icon(Icons.person_rounded, size: 20, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (context) {
                  final hour = DateTime.now().hour;
                  final String greeting;
                  if (hour < 12) {
                    greeting = "Good Morning";
                  } else if (hour < 17) {
                    greeting = "Good Afternoon";
                  } else {
                    greeting = "Good Evening";
                  }
                  return Text(
                    greeting.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: cs.primary,
                    ),
                  );
                }),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user?.fullName.toUpperCase() ?? 'GUEST',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const BeautifulThemeSwitcher(compact: true),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push(UpdatesRoutes.list),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.4), width: 0.8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_rounded,
                      size: 22, color: cs.onSurfaceVariant),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Part 3: Dropdowns ──────────────────────────────────────────────────────
  Widget _buildDropdownRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildCustomDropdown(label: "TYPE")),
          const SizedBox(width: 8),
          Expanded(child: _buildCustomDropdown(label: "MODE")),
          const SizedBox(width: 8),
          Expanded(child: _buildCustomDropdown(label: "SITE")),
          const SizedBox(width: 8),
          Expanded(child: _buildCustomDropdown(label: "TEAM")),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({required String label}) {
    final cs = Theme.of(context).colorScheme;

    // Data for Site/Team
    final siteState = ref.watch(siteProvider);
    final allSites = siteState.sites;
    final selectedSite = ref.watch(siteDropdownValueProvider);
    final teamState = ref.watch(teamProvider);
    final selectedTeam = ref.watch(teamDropdownValueProvider);

    // Data for Work Type
    final currentTypeApi = ref.watch(typeProvider);
    final currentWorkType = WorkType.fromApiValue(currentTypeApi);

    final bool isLoading = (label == "SITE" && siteState.isLoading) ||
        (label == "TEAM" && teamState.isLoading);
    Widget dropdown;

    if (isLoading) {
      dropdown = Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: cs.primary.withOpacity(0.5)),
        ),
      );
    } else if (label == "SITE") {
      dropdown = DropdownButton<SiteModel?>(
        value: selectedSite,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: cs.primary),
        hint: const Text("Site",
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600)),
        items: [
          const DropdownMenuItem<SiteModel?>(
            value: null,
            child: Text('None', style: TextStyle(fontSize: 8.5)),
          ),
          ...allSites.map((s) => DropdownMenuItem<SiteModel?>(
                value: s,
                child: Text(s.siteName,
                    style: const TextStyle(fontSize: 8.5),
                    overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: _onSiteChanged,
      );
    } else if (label == "TEAM") {
      dropdown = DropdownButton<TeamModel?>(
        value: selectedTeam,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: cs.primary),
        hint: const Text("Team",
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600)),
        items: [
          const DropdownMenuItem<TeamModel?>(
            value: null,
            child: Text('None', style: TextStyle(fontSize: 8.5)),
          ),
          ...teamState.teams.map((t) => DropdownMenuItem<TeamModel?>(
                value: t,
                child: Text(t.teamName,
                    style: const TextStyle(fontSize: 8.5),
                    overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: _onTeamChanged,
      );
    } else if (label == "TYPE") {
      dropdown = DropdownButton<WorkType?>(
        value: currentWorkType,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: cs.primary),
        hint: const Text("Type",
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600)),
        items: WorkType.values
            .map((wt) => DropdownMenuItem<WorkType?>(
                  value: wt,
                  child: Text(wt.displayNameShort,
                      style: const TextStyle(fontSize: 8.5),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (wt) {
          if (wt != null) {
            ref.read(typeProvider.notifier).setType(wt.apiValue);
            ref.read(siteDropdownValueProvider.notifier).state = null;
            ref.read(selectedSiteProvider.notifier).clear();
            ref.read(selectedSiteIdProvider.notifier).state = null;
            ref.read(teamDropdownValueProvider.notifier).state = null;
            ref.read(selectedTeamProvider.notifier).clear();
            ref.read(selectedTeamIdProvider.notifier).state = "";
            final teamNotifier = ref.read(teamProvider.notifier);
            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            teamNotifier.state = teamNotifier.state.copyWith(
              teams: [],
              hasData: false,
            );
            ref.read(siteProvider.notifier).fetchSites();
          }
        },
      );
    } else {
      // MODE
      dropdown = DropdownButton<bool>(
        value: _multipleEntryMode,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: cs.primary),
        items: const [
          DropdownMenuItem(
            value: false,
            child: Text("Single", style: TextStyle(fontSize: 8.5)),
          ),
          DropdownMenuItem(
            value: true,
            child: Text("Multi", style: TextStyle(fontSize: 8.5)),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _multipleEntryMode = val);
            ModulePreferences.setMultipleEntry(val);
          }
        },
      );
    }

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: cs.primary.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 2, bottom: 2),
              child: DropdownButtonHideUnderline(
                child: dropdown,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ── Daily Entry Stats (Daily tab only) ─────────────────────────────────────

  Widget _buildDailyStatsSection(ColorScheme cs, bool isDark) {
    final type = ref.watch(typeProvider);
    final selectedSite = ref.watch(siteDropdownValueProvider);
    final selectedTeam = ref.watch(teamDropdownValueProvider);

    final params = DashboardParams(
      type: type,
      siteId: selectedSite?.id,
      teamId: selectedTeam?.id,
    );

    final asyncSummary = ref.watch(dashboardSummaryProvider(params));
    final asyncDrafts = ref.watch(dashboardDraftsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          asyncSummary.when(
            loading: () => _buildStatsShimmer(cs),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => Column(
              children: [
                _buildStatsGrid(summary, cs, isDark),
                const SizedBox(height: 14),
                _buildLastEntriesSection(summary, cs, isDark),
              ],
            ),
          ),
          asyncDrafts.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (drafts) => _buildDraftsSection(drafts, cs, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLastEntriesSection(
      DashboardSummary s, ColorScheme cs, bool isDark) {
    String _fmtTime(String? isoDate) {
      if (isoDate == null) return '—';
      try {
        final dt = DateTime.parse(isoDate).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      } catch (_) {
        return '—';
      }
    }

    String entryText(String module, DashLastEntry? entry, [String? extra]) {
      if (entry == null) return "No $module entries found yet.";
      final site = entry.siteName ?? "unknown site";
      final team = entry.teamName != null ? "by ${entry.teamName}" : "";
      final time = _fmtTime(entry.createdAt);
      final detail = extra != null ? " ($extra)" : "";
      return "Last $module filed$detail at $site $team $time";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLastEntryRow(cs, Icons.history_rounded,
              entryText("Attendance", s.attendance.lastEntry)),
          const SizedBox(height: 8),
          _buildLastEntryRow(
              cs,
              Icons.history_rounded,
              entryText("DPR", s.dpr.lastEntry,
                  s.dpr.totalQty != null ? "${s.dpr.totalQty} units" : null)),
          const SizedBox(height: 8),
          _buildLastEntryRow(
              cs,
              Icons.history_rounded,
              entryText(
                  "Expense",
                  s.expenses.lastEntry,
                  s.expenses.category != null
                      ? "${s.expenses.category} · ₹${s.expenses.lastAmount ?? 0}"
                      : null)),
          const SizedBox(height: 8),
          _buildLastEntryRow(
              cs,
              Icons.history_rounded,
              entryText(
                  "Inventory",
                  s.inventory.lastEntry,
                  s.inventory.lastMaterial != null
                      ? "${s.inventory.lastMaterial} · ${s.inventory.lastQty} ${s.inventory.uom ?? ''}"
                      : null)),
        ],
      ),
    );
  }

  Widget _buildLastEntryRow(ColorScheme cs, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 10, color: cs.primary.withOpacity(0.6)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant.withOpacity(0.8),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsShimmer(ColorScheme cs) {
// ...
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            height: 80,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid(DashboardSummary s, ColorScheme cs, bool isDark) {
    String fmtAmount(num v) {
      if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
      return '₹${v.toStringAsFixed(0)}';
    }

    String fmtTime(String? isoDate) {
      if (isoDate == null) return '—';
      try {
        final dt = DateTime.parse(isoDate).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      } catch (_) {
        return '—';
      }
    }

    final hasLowStock = s.inventory.lowStockItems > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow label
        Row(children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            "Today's Work Update",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ]),
        const SizedBox(height: 8),

        // 4 stat tiles — single row
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildStatTile(
              cs: cs,
              isDark: isDark,
              icon: Icons.how_to_reg_rounded,
              iconColor: Colors.green,
              label: 'Attendance',
              value: '${s.attendance.totalPresent}',
              sub: '${s.attendance.totalAbsent} absent',
              subColor: s.attendance.totalAbsent > 0
                  ? Colors.orange
                  : cs.onSurfaceVariant,
              time: fmtTime(s.attendance.lastEntry?.createdAt),
            ),
            const SizedBox(width: 8),
            _buildStatTile(
              cs: cs,
              isDark: isDark,
              icon: Icons.description_rounded,
              iconColor: Colors.indigo,
              label: 'DPR',
              value: s.dpr.lastEntry != null ? 'DPR Update' : 'None',
              sub: s.dpr.totalQty != null
                  ? 'Qty ${s.dpr.totalQty}'
                  : (s.dpr.remarks ?? '—'),
              subColor: cs.onSurfaceVariant,
              time: fmtTime(s.dpr.lastEntry?.createdAt),
            ),
            const SizedBox(width: 8),
            _buildStatTile(
              cs: cs,
              isDark: isDark,
              icon: Icons.receipt_long_rounded,
              iconColor: Colors.orange,
              label: 'Expenses',
              value: fmtAmount(s.expenses.totalAmount),
              sub: s.expenses.category ?? '—',
              subColor: cs.onSurfaceVariant,
              time: fmtTime(s.expenses.lastEntry?.createdAt),
            ),
            const SizedBox(width: 8),
            _buildStatTile(
              cs: cs,
              isDark: isDark,
              icon: Icons.inventory_2_rounded,
              iconColor: hasLowStock ? Colors.redAccent : Colors.teal,
              label: 'Inventory',
              value: '${s.inventory.totalItems}',
              sub: hasLowStock
                  ? '${s.inventory.lowStockItems} low'
                  : 'All stocked',
              subColor: hasLowStock ? Colors.redAccent : Colors.teal,
              time: null,
              highlight: hasLowStock,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required ColorScheme cs,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    String? time,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? Colors.redAccent.withOpacity(0.4)
                : cs.outlineVariant.withOpacity(0.4),
            width: highlight ? 1.2 : 0.8,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: cs.onSurfaceVariant.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Part 5: Module Card ─────────────────────────────────────────────────────
  Widget _buildInlineModuleCard(Translator t, ColorScheme cs, bool isDark) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: _moduleCardVisible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        offset: _moduleCardVisible ? Offset.zero : const Offset(0, 0.15),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 32),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: _cardBg(cs, isDark),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _borderColor(cs, isDark), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.18),
                    blurRadius: 36,
                    spreadRadius: 6,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP BAR: drag hint + attach button
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () => _attachModuleCard(t),
                      //   child: Container(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 10, vertical: 5),
                      //     decoration: BoxDecoration(
                      //       color: cs.primary.withOpacity(0.09),
                      //       borderRadius: BorderRadius.circular(20),
                      //       border:
                      //           Border.all(color: cs.primary.withOpacity(0.2)),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(Icons.south_rounded,
                      //             size: 11, color: cs.primary),
                      //         const SizedBox(width: 4),
                      //         Text("Attach to nav",
                      //             style: TextStyle(
                      //                 fontSize: 10,
                      //                 fontWeight: FontWeight.w700,
                      //                 color: cs.primary)),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCardTabLabel(t),
                  const SizedBox(height: 14),
                  _buildIconGrid(t),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachedModulePanel(Translator t, ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh.withOpacity(0.96)
            : Colors.white.withOpacity(0.97),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
        border: Border(
          top: BorderSide(color: _borderColor(cs, isDark), width: 0.8),
          left: BorderSide(color: _borderColor(cs, isDark), width: 0.8),
          right: BorderSide(color: _borderColor(cs, isDark), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, -8))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TOP BAR: drag pill + detach button
          Row(
            children: [
              const SizedBox(width: 88), // balance spacer
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Detach chip
              GestureDetector(
                onTap: _detachModuleCard,
                child: Container(
                  width: 88,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.north_rounded, size: 11, color: cs.primary),
                      const SizedBox(width: 4),
                      Text("Detach",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCardTabLabel(t),
          const SizedBox(height: 14),
          _buildIconGrid(t),
        ],
      ),
    );
  }

  Widget _buildFloatingDock(Translator t, ColorScheme cs, bool isDark) {
    return Positioned(
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      left: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached panel — slides in/out with AnimatedSize
          AnimatedSize(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            child: _moduleCardAttached
                ? _buildAttachedModulePanel(t, cs, isDark)
                : const SizedBox.shrink(),
          ),
          // Nav bar — always visible
          _buildNavBar(t, cs, isDark),
        ],
      ),
    );
  }

  Widget _buildNavBar(Translator t, ColorScheme cs, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 62,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh.withOpacity(0.88)
            : Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_moduleCardAttached ? 0 : 30),
          topRight: Radius.circular(_moduleCardAttached ? 0 : 30),
          bottomLeft: const Radius.circular(30),
          bottomRight: const Radius.circular(30),
        ),
        border: Border(
          // when attached, no top border (seamless join with panel)
          top: _moduleCardAttached
              ? BorderSide.none
              : BorderSide(
                  color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
          left:
              BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
          right:
              BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
          bottom:
              BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
        ),
        boxShadow: _dockShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_moduleCardAttached ? 0 : 30),
          topRight: Radius.circular(_moduleCardAttached ? 0 : 30),
          bottomLeft: const Radius.circular(30),
          bottomRight: const Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _buildMenuButton(),
                const SizedBox(width: 8),
                Expanded(child: _buildTabPills()),
                const SizedBox(width: 8),
                _buildAiButton(t),
              ],
            ),
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
    const currentTabName = "Quick Access";

    return Stack(
      alignment: Alignment.center,
      children: [
        // Centered Title
        Text(
          currentTabName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        // Dots on the right
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(left: 4),
                width: i == _currentIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentIndex
                      ? cs.primary
                      : cs.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTourTarget({
    required GlobalKey key,
    required Widget child,
    EdgeInsets targetPadding = const EdgeInsets.all(6),
    double overlayOpacity = 0.08,
  }) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: overlayOpacity,
      targetPadding: targetPadding,
      targetBorderRadius: BorderRadius.circular(18),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  Widget _buildIconGrid(Translator t) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = constraints.maxWidth / 4;
      final modules = _currentModules;
      return Wrap(
        spacing: 0,
        runSpacing: 24,
        alignment: WrapAlignment.start,
        children: [
          for (var i = 0; i < modules.length; i++)
            _buildModuleIconItem(modules[i], itemWidth, t, i),
        ],
      );
    });
  }

  Widget _buildModuleIconItem(
      ModuleItem item, double width, Translator t, int index) {
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color.lerp(
                      item.iconColor.withOpacity(0.13),
                      isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
                      0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: item.iconColor.withOpacity(isDark ? 0.22 : 0.18),
                      width: 0.8),
                ),
                child: Icon(item.icon,
                    size: 24,
                    color: Color.lerp(
                        item.iconColor, cs.onSurface, isDark ? 0.08 : 0.15)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.t(item.labelKey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.85),
                  height: 1.3),
            ),
          ],
        ),
      ),
    );

    return _buildTourTarget(
      key: _moduleTourTargetKey(item, index),
      targetPadding: const EdgeInsets.all(8),
      overlayOpacity: 0.72,
      child: content,
    );
  }

  // ── Part 6: Floating NavBar ────────────────────────────────────────────────

  Widget _buildMenuButton() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _showQuickSettings = !_showQuickSettings),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        ),
        child:
            Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildQuickSettingsMenu(Translator t, ColorScheme cs, bool isDark) {
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
              color: isDark
                  ? cs.surfaceContainerHigh.withOpacity(0.85)
                  : cs.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickSettingRow("Multiple Entry Mode", _multipleEntryMode,
                    (val) {
                  setState(() => _multipleEntryMode = val);
                  ModulePreferences.setMultipleEntry(val);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSettingRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

  Widget _buildTabPills() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.25), width: 0.6),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final pillWidth =
            (totalWidth - 24) / 4; // 4px spacing * 6 (edges + gaps)

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
                    BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabPill(label: 'Daily', index: 0),
                _buildTabPill(label: 'Setup', index: 1),
                _buildTabPill(label: 'Reports', index: 2),
                _buildTabPill(label: 'More', index: 3),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabPill({required String label, required int index}) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _currentIndex == index;
    Widget pill = GestureDetector(
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
                color: isActive
                    ? Colors.white
                    : cs.onSurfaceVariant.withOpacity(0.65)),
            child: Text(label),
          ),
        ),
      ),
    );

    return Expanded(
      child: _buildTourTarget(
        key: _tabTourKey(index),
        targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: pill,
      ),
    );

    /*
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
    */
  }

  GlobalKey _tabTourKey(int index) {
    switch (index) {
      case 0:
        return ModuleScreenTourTargets.dailyTabKey;
      case 1:
        return ModuleScreenTourTargets.setupTabKey;
      case 2:
        return ModuleScreenTourTargets.reportsTabKey;
      case 3:
        return ModuleScreenTourTargets.moreTabKey;
      default:
        return ModuleScreenTourTargets.dailyTabKey;
    }
  }

  Widget _buildAiButton(Translator t) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _overlayType != null
              ? null
              : () {
                  if (!_moduleCardAttached) {
                    _attachModuleCard(t);
                  } else {
                    _handleAiAnalysisTap();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Space for shadow pulse
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: cs.primary
                          .withOpacity(0.12 + (_pulseAnimation.value * 0.1)),
                      blurRadius: 8 + (_pulseAnimation.value * 6),
                      spreadRadius: _pulseAnimation.value * 2)
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
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                    ShimmerImage(height: 10, width: 100, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerImage(height: 26, width: 180, borderRadius: 8),
                    SizedBox(height: 4),
                    ShimmerImage(height: 10, width: 120, borderRadius: 6),
                  ])),
              const ShimmerImage(height: 28, width: 80, borderRadius: 14),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: const [
              Expanded(
                  child: ShimmerImage(
                      height: 54, width: double.infinity, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(
                  child: ShimmerImage(
                      height: 54, width: double.infinity, borderRadius: 14)),
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
                border: Border.all(
                    color: _moduleCardBorderColor(cs, isDark), width: 0.8),
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
                  border: Border.all(
                      color: _moduleCardBorderColor(cs, isDark), width: 0.8),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(children: [
                  Row(children: [
                    const ShimmerImage(height: 18, width: 4, borderRadius: 2),
                    const SizedBox(width: 8),
                    const ShimmerImage(height: 14, width: 100, borderRadius: 6),
                    const Spacer(),
                    Row(
                        children: List.generate(
                            4,
                            (i) => Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ShimmerImage(
                                      height: 6,
                                      width: i == 0 ? 16 : 6,
                                      borderRadius: 3),
                                ))),
                  ]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 20,
                      alignment: WrapAlignment.spaceAround,
                      children: List.generate(
                          8,
                          (i) => SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 64) /
                                        4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    ShimmerImage(
                                        height: 52,
                                        width: 52,
                                        borderRadius: 16),
                                    SizedBox(height: 6),
                                    ShimmerImage(
                                        height: 10, width: 44, borderRadius: 5),
                                  ],
                                ),
                              )),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ShimmerImage(
                height: 62, width: double.infinity, borderRadius: 30),
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
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
            ShimmerImage(height: 11, width: double.infinity, borderRadius: 5),
            SizedBox(height: 4),
            ShimmerImage(height: 9, width: 80, borderRadius: 4),
          ])),
    ]);
  }

  Widget _buildDraftsSection(
      List<DashDraft> drafts, ColorScheme cs, bool isDark) {
    if (drafts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              "Unsaved Drafts",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await DprDraftRepo().clearAllDrafts();
                await InsuDprDraftRepo().clearAllDrafts();
                ref.invalidate(dashboardDraftsProvider);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Clear All",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.error.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...drafts.map((d) => _buildDraftItem(d, cs, isDark)),
      ],
    );
  }

  Widget _buildDraftItem(DashDraft d, ColorScheme cs, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (d.type == 'mech') {
          context.push(Routes.dprDescription, extra: {'draftWork': d.data});
        } else {
          context.push(Routes.dprInsuDescription, extra: {'draftWork': d.data});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_document,
                size: 14, color: cs.error.withOpacity(0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    "You have an unsaved draft in ${d.module.split('(').first.trim()}",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (d.type == 'mech') {
                  await DprDraftRepo().removeDraft(d.id);
                } else {
                  await InsuDprDraftRepo().removeDraft(d.id);
                }
                ref.invalidate(dashboardDraftsProvider);
              },
              child: Icon(Icons.close_rounded,
                  size: 16, color: cs.error.withOpacity(0.5)),
            ),
            const SizedBox(width: 10),
            Text(
              "RESUME",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: cs.error,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
