import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class SiteRateModuleTours {
  SiteRateModuleTours._();

  static const siteDetailsId = 'site_details_module';
  static const rateId = 'rate_module';

  static final siteDetails = AppTourDefinition(
    id: siteDetailsId,
    title: 'Site Details',
    description: 'A short guide for creating and managing project sites.',
    icon: Icons.location_city_rounded,
    steps: const [
      AppTourStep(
        id: 'site_details_intro',
        title: 'Site Details',
        body: 'Use this module to create, view, and manage your project sites.',
        progressLabel: 'Site Details intro',
        useSpotlight: false,
      ),
    ],
  );

  static final rate = AppTourDefinition(
    id: rateId,
    title: 'Rate Setup',
    description: 'A short guide for creating and managing work rates.',
    icon: Icons.currency_rupee_rounded,
    steps: const [
      AppTourStep(
        id: 'rate_intro',
        title: 'Rate Setup',
        body: 'Use this module to set item or work rates before entries and reports.',
        progressLabel: 'Rate intro',
        useSpotlight: false,
      ),
    ],
  );

  static final List<AppTourDefinition> all = [
    siteDetails,
    rate,
  ];
}
