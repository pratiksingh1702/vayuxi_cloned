import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class ManpowerTeamModuleTours {
  ManpowerTeamModuleTours._();

  static const manpowerId = 'manpower_module';
  static const teamId = 'team_module';

  static final manpower = AppTourDefinition(
    id: manpowerId,
    title: 'Manpower',
    description: 'A short guide for adding and managing workers.',
    icon: Icons.badge_rounded,
    steps: const [
      AppTourStep(
        id: 'manpower_intro',
        title: 'Manpower',
        body: 'Use this module to add workers and manage their details.',
        progressLabel: 'Manpower intro',
        useSpotlight: false,
      ),
    ],
  );

  static final team = AppTourDefinition(
    id: teamId,
    title: 'Team Setup',
    description: 'A short guide for creating and managing teams.',
    icon: Icons.groups_rounded,
    steps: const [
      AppTourStep(
        id: 'team_intro',
        title: 'Team Setup',
        body: 'Use this module to create teams for site work.',
        progressLabel: 'Team intro',
        useSpotlight: false,
      ),
    ],
  );

  static final List<AppTourDefinition> all = [
    manpower,
    team,
  ];
}
