// lib/features/tour/domain/tour_registery.dart
//
// Legacy flat registry — kept so existing showcase calls in module_screen.dart
// continue to compile. The new modular Brain lives in tour/registry/.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'tour_step_model.dart';
import 'package:untitled2/core/router/routes.dart';

class AppRoutes {
  static const workCategory = Routes.workCategory;
  static const selectModule = Routes.selectModule;
  static const sites        = "/site-list/site";
  static const manpower     = "/manpower";
  static const moreHelp     = "/help";
}

class TourRegistry {
  // ── Showcase keys (all still used by module_screen.dart showcase calls) ────
  static final workCategoryKey   = GlobalKey(debugLabel: 'work_category');
  static final moduleSelectKey   = GlobalKey(debugLabel: 'module_select');
  static final siteCreateKey     = GlobalKey(debugLabel: 'site_create');
  static final manpowerKey       = GlobalKey(debugLabel: 'manpower');
  static final helpKey           = GlobalKey(debugLabel: 'help');
  static final setupBottomNavKey = GlobalKey(debugLabel: 'setup_bottom_nav');
  static final setupSiteCardKey  = GlobalKey(debugLabel: 'setup_site_card');
  static final siteModuleKey     = GlobalKey(debugLabel: 'site_module');
  static final rateModuleKey     = GlobalKey(debugLabel: 'rate_module');
  static final manpowerModuleKey = GlobalKey(debugLabel: 'manpower_module');
  static final teamModuleKey     = GlobalKey(debugLabel: 'team_module');
  static final dprModuleKey      = GlobalKey(debugLabel: 'dpr_module');

  // ── Legacy flat step list (used by old TourController.steps getter) ────────
  // nextRoute removed — navigation is now handled by the event-driven engine.
  static final List<TourStep> onboarding = [
    TourStep(
      id: 'work_category',
      route: AppRoutes.workCategory,
      showcaseKey: workCategoryKey,
      title: 'Welcome',
      buddyMessage: "Hey! I'm Buddy 👋\nStart by selecting your Work Category here.",
    ),
    TourStep(
      id: 'setup_tab',
      route: AppRoutes.selectModule,
      showcaseKey: setupBottomNavKey,
      title: 'Setup Section',
      buddyMessage: 'Tap here to open Setup modules ⚙️',
    ),
    TourStep(
      id: 'select_module',
      route: AppRoutes.selectModule,
      showcaseKey: moduleSelectKey,
      title: 'Select Module',
      buddyMessage: "Now choose a module like Site / Rate / DPR.\nLet's start with Site ✅",
    ),
    TourStep(
      id: 'site_create',
      route: AppRoutes.sites,
      showcaseKey: siteCreateKey,
      title: 'Create Site',
      buddyMessage: "First step: create your Site here ✅\nSites organise all your work.",
    ),
    TourStep(
      id: 'manpower',
      route: AppRoutes.manpower,
      showcaseKey: manpowerKey,
      title: 'Add Manpower',
      buddyMessage: "Now add manpower 👷\nThis helps track daily work progress.",
    ),
    TourStep(
      id: 'help',
      route: AppRoutes.moreHelp,
      showcaseKey: helpKey,
      title: 'Help & Tour',
      buddyMessage: "Anytime you get confused — come here ✅\nYou can replay the full tour.",
    ),
  ];
}
