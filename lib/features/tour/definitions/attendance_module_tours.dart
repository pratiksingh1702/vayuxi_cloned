import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class AttendanceModuleTours {
  AttendanceModuleTours._();

  static const attendanceId = 'attendance_module';

  static final attendance = AppTourDefinition(
    id: attendanceId,
    title: 'Attendance',
    description: 'A short guide for marking daily attendance.',
    icon: Icons.how_to_reg_rounded,
    steps: const [
      AppTourStep(
        id: 'attendance_intro',
        title: 'Attendance',
        body: 'Use this screen to mark who came to work and save their hours.',
        progressLabel: 'Attendance intro',
        useSpotlight: false,
      ),
    ],
  );

  static final List<AppTourDefinition> all = [
    attendance,
  ];
}
