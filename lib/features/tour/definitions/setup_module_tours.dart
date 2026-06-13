import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class SetupModuleTours {
  SetupModuleTours._();

  static const boqUploadId = 'boq_upload_module';
  static const dprSetupId = 'dpr_setup_module';
  static const erectionSetupId = 'structural_erection_setup_module';
  static const pmEntryId = 'pm_entry_module';
  static const pmReportsId = 'pm_reports_module';
  static const pmSetupId = 'pm_setup_module';

  static final boqUpload = AppTourDefinition(
    id: boqUploadId,
    title: 'BOQ Upload',
    description: 'A short guide for adding and managing BOQ items.',
    icon: Icons.table_rows_rounded,
    steps: const [
      AppTourStep(
        id: 'boq_upload_intro',
        title: 'BOQ Upload',
        body:
            'Use this module to view BOQ items or add new BOQ data manually or from Excel.',
        progressLabel: 'BOQ intro',
        useSpotlight: false,
      ),
    ],
  );

  static final erectionSetup = AppTourDefinition(
    id: erectionSetupId,
    title: 'Structure Erection Setup',
    description: 'A short guide for preparing structural erection DPR stages.',
    icon: Icons.architecture_rounded,
    steps: const [
      AppTourStep(
        id: 'erection_setup_intro',
        title: 'Structure Erection Setup',
        body:
            'Use this setup to manage erection stages, images, remarks, and tracking level before daily DPR entry.',
        progressLabel: 'Erection setup intro',
        useSpotlight: false,
      ),
    ],
  );

  static final dprSetup = AppTourDefinition(
    id: dprSetupId,
    title: 'DPR Setup',
    description: 'A complete guide for configuring DPR values and screens.',
    icon: Icons.settings_suggest_rounded,
    steps: const [
      AppTourStep(
        id: 'dpr_setup_intro',
        title: 'DPR Setup',
        body:
            'Use this module to view or add the values used during daily DPR entry.',
        progressLabel: 'DPR intro',
        useSpotlight: false,
      ),
    ],
  );

  static final pmSetup = AppTourDefinition(
    id: pmSetupId,
    title: 'P&M Setup',
    description: 'A short guide for preparing plant and machinery work.',
    icon: Icons.precision_manufacturing_rounded,
    steps: const [
      AppTourStep(
        id: 'pm_setup_intro',
        title: 'P&M Setup',
        body:
            'Use this setup to choose a P&M category, view existing works, or add a new work under that category.',
        progressLabel: 'P&M setup intro',
        useSpotlight: false,
      ),
    ],
  );

  static final pmEntry = AppTourDefinition(
    id: pmEntryId,
    title: 'P&M Entry',
    description: 'A short guide for adding daily plant and machinery details.',
    icon: Icons.engineering_rounded,
    steps: const [
      AppTourStep(
        id: 'pm_entry_intro',
        title: 'P&M Entry',
        body:
            'Use this module to record daily machine work, working hours, fuel, and activity details.',
        progressLabel: 'P&M entry intro',
        useSpotlight: false,
      ),
    ],
  );

  static final pmReports = AppTourDefinition(
    id: pmReportsId,
    title: 'P&M Reports',
    description: 'A short guide for checking plant and machinery summaries.',
    icon: Icons.analytics_rounded,
    steps: const [
      AppTourStep(
        id: 'pm_reports_intro',
        title: 'P&M Reports',
        body:
            'Use this module to check daily P&M totals, working hours, fuel, and saved entries.',
        progressLabel: 'P&M reports intro',
        useSpotlight: false,
      ),
    ],
  );

  static final List<AppTourDefinition> all = [
    boqUpload,
    dprSetup,
    erectionSetup,
    pmEntry,
    pmReports,
    pmSetup,
  ];
}
