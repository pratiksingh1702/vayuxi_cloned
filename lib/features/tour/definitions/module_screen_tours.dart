import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class ModuleScreenTourTargets {
  ModuleScreenTourTargets._();

  static final screenKey = GlobalKey(debugLabel: 'tour_module_screen');
  static final moduleCardKey = GlobalKey(debugLabel: 'tour_module_card');
  static final dailyTabKey = GlobalKey(debugLabel: 'tour_daily_tab');
  static final setupTabKey = GlobalKey(debugLabel: 'tour_setup_tab');
  static final reportsTabKey = GlobalKey(debugLabel: 'tour_reports_tab');
  static final moreTabKey = GlobalKey(debugLabel: 'tour_more_tab');
}

class ModuleScreenTours {
  ModuleScreenTours._();

  static const welcomeId = 'welcome';
  static const dailyId = 'daily_entry';
  static const setupId = 'setup';
  static const reportsId = 'reports';
  static const moreId = 'more';

  static final welcome = AppTourDefinition(
    id: welcomeId,
    title: 'Welcome to ERP',
    description: 'A short orientation for the module dashboard.',
    icon: Icons.auto_awesome_rounded,
    steps: [
      AppTourStep(
        id: 'welcome_sample_site',
        title: 'Welcome to ERP',
        body:
            'This demo can use a sample site. To create your own project data, go to Setup and open Site Details.',
        targetKey: ModuleScreenTourTargets.screenKey,
        progressLabel: 'Sample site note',
        useSpotlight: false,
      ),
    ],
  );

  static final dailyEntry = AppTourDefinition(
    id: dailyId,
    title: 'Daily Entry',
    description: 'Quick entry points for daily project activity.',
    icon: Icons.edit_calendar_rounded,
    tabIndex: 0,
    steps: [
      AppTourStep(
        id: 'daily_tab',
        title: 'Daily Entry',
        body:
            "Use this tab for today's work updates: attendance, DPR, P&M, expenses, and inventory entries.",
        targetKey: ModuleScreenTourTargets.dailyTabKey,
        progressLabel: 'Daily tab',
      ),
      AppTourStep(
        id: 'daily_modules',
        title: 'Daily Modules',
        body:
            'The cards here follow your selected work type and site context, so the DPR and P&M options can change automatically.',
        targetKey: ModuleScreenTourTargets.moduleCardKey,
        progressLabel: 'Visible daily cards',
      ),
    ],
  );

  static final setup = AppTourDefinition(
    id: setupId,
    title: 'Setup',
    description: 'Configure the data used by daily entries and reports.',
    icon: Icons.tune_rounded,
    tabIndex: 1,
    steps: [
      AppTourStep(
        id: 'setup_tab',
        title: 'Setup',
        body:
            'Setup is where you prepare the project: sites, rates, manpower, teams, inventory, DPR setup, BOQ, assignments, and P&M setup.',
        targetKey: ModuleScreenTourTargets.setupTabKey,
        progressLabel: 'Setup tab',
      ),
      AppTourStep(
        id: 'setup_modules',
        title: 'Setup Modules',
        body:
            'Open only the setup module you need. These tours are independent, so no user is forced through a long setup chain.',
        targetKey: ModuleScreenTourTargets.moduleCardKey,
        progressLabel: 'Visible setup cards',
      ),
    ],
  );

  static final reports = AppTourDefinition(
    id: reportsId,
    title: 'Reports',
    description: 'Review project progress and exported summaries.',
    icon: Icons.bar_chart_rounded,
    tabIndex: 2,
    steps: [
      AppTourStep(
        id: 'reports_tab',
        title: 'Reports',
        body:
            'Reports collect the output from your entries and setup data so supervisors and admins can review progress.',
        targetKey: ModuleScreenTourTargets.reportsTabKey,
        progressLabel: 'Reports tab',
      ),
      AppTourStep(
        id: 'reports_modules',
        title: 'Report Modules',
        body:
            'Use these cards for module-specific summaries, downloads, and review workflows.',
        targetKey: ModuleScreenTourTargets.moduleCardKey,
        progressLabel: 'Visible reports',
      ),
    ],
  );

  static final more = AppTourDefinition(
    id: moreId,
    title: 'More',
    description: 'Utility tools and app preferences.',
    icon: Icons.more_horiz_rounded,
    tabIndex: 3,
    steps: [
      AppTourStep(
        id: 'more_tab',
        title: 'More',
        body:
            'More contains utility modules like updates, theme, language, and help.',
        targetKey: ModuleScreenTourTargets.moreTabKey,
        progressLabel: 'More tab',
      ),
      AppTourStep(
        id: 'more_modules',
        title: 'Utility Modules',
        body:
            'These cards are safe to revisit anytime when you want to adjust the app or get support.',
        targetKey: ModuleScreenTourTargets.moduleCardKey,
        progressLabel: 'Visible utilities',
      ),
    ],
  );

  static final List<AppTourDefinition> all = [
    welcome,
    dailyEntry,
    setup,
    reports,
    more,
  ];

  static AppTourDefinition byId(String id) {
    return all.firstWhere((tour) => tour.id == id);
  }

  static String tabTourId(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return dailyId;
      case 1:
        return setupId;
      case 2:
        return reportsId;
      case 3:
        return moreId;
      default:
        return dailyId;
    }
  }
}
