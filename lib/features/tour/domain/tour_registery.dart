import 'package:flutter/material.dart';
import 'tour_step_model.dart';
import 'package:untitled2/core/router/routes.dart';

class AppRoutes {
  // ✅ Actual GoRouter routes in your app
  static const workCategory = Routes.workCategory; // ex: "/workCategory"
  static const selectModule = Routes.selectModule; // ex: "/modules"

  // ✅ Your site list route (for onboarding always module=site)
  static const sites = "/site-list/site";

  // ✅ These exist in your router
  static const manpower = "/manpower";

  // ✅ These you haven't added as routes in router file yet
  // (so don't include them in onboarding until they exist)
  // static const rates = "/rates";
  // static const dailyEntry = "/daily-entry";
  // static const reports = "/reports";

  static const moreHelp = "/help"; // your router has "/help"
}

class TourRegistry {
  // ✅ Showcase keys
  static final workCategoryKey = GlobalKey();
  static final moduleSelectKey = GlobalKey();
  static final siteCreateKey = GlobalKey();
  static final manpowerKey = GlobalKey();
  static final helpKey = GlobalKey();
  static final setupBottomNavKey = GlobalKey();
  static final setupSiteCardKey = GlobalKey();
  static final siteModuleKey = GlobalKey();
  static final rateModuleKey = GlobalKey();
  static final manpowerModuleKey = GlobalKey();
  static final teamModuleKey = GlobalKey();
  static final dprModuleKey = GlobalKey();



  static final List<TourStep> onboarding = [
    /// STEP 1: Work Category screen
    TourStep(
      id: "work_category",
      route: AppRoutes.workCategory,
      showcaseKey: workCategoryKey,
      title: "Welcome",
      buddyMessage:
          "Hey! I’m Buddy 👋\nStart by selecting your Work Category here.",
      nextRoute: AppRoutes.selectModule,
    ),
    TourStep(
      id: "setup_tab",
      route: AppRoutes.selectModule, // this is module screen
      showcaseKey: TourRegistry.setupBottomNavKey,
      title: "Setup Section",
      buddyMessage: "Tap here to open Setup modules ⚙️",
      nextRoute: null, // or next screen you want
    ),
    TourStep(
      id: "select_module",
      route: AppRoutes.selectModule,
      showcaseKey: moduleSelectKey,
      title: "Select Module",
      buddyMessage:
          "Now choose a module like Site / Rate / DPR.\nLet's start with Site ✅",
      nextRoute: AppRoutes.sites,
    ),

    /// STEP 3: Sites list (site module)
    TourStep(
      id: "site_create",
      route: AppRoutes.sites,
      showcaseKey: siteCreateKey,
      title: "Create Site",
      buddyMessage:
          "First step: create your Site here ✅\nSites organize all your work.",
      nextRoute: AppRoutes.manpower, // ✅ next screen that exists
    ),

    /// STEP 4: Manpower module
    TourStep(
      id: "manpower",
      route: AppRoutes.manpower,
      showcaseKey: manpowerKey,
      title: "Add Manpower",
      buddyMessage:
          "Now add manpower 👷\nThis helps track daily work progress.",
      nextRoute: AppRoutes.moreHelp,
    ),

    /// STEP 5: Help / Tour replay
    TourStep(
      id: "help",
      route: AppRoutes.moreHelp,
      showcaseKey: helpKey,
      title: "Help & Tour",
      buddyMessage:
          "Anytime you get confused — come here ✅\nYou can replay the full tour.",
      nextRoute: null,
    ),
  ];
}
