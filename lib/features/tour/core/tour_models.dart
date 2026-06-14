import 'package:flutter/material.dart';

enum AppTourStatus { idle, running, completed }

enum AppTourTrigger { automatic, replay }

class AppTourStep {
  final String id;
  final String title;
  final String body;
  final GlobalKey? targetKey;
  final String? progressLabel;
  final bool useSpotlight;
  final double? tooltipBottomOffset;
  final bool showTooltip;
  final bool autoScrollToTarget;
  final String? voiceText;
  final bool autoSpeak;

  const AppTourStep({
    required this.id,
    required this.title,
    required this.body,
    this.targetKey,
    this.progressLabel,
    this.useSpotlight = true,
    this.tooltipBottomOffset,
    this.showTooltip = true,
    this.autoScrollToTarget = false,
    this.voiceText,
    this.autoSpeak = true,
  });
}

class AppTourDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int? tabIndex;
  final List<AppTourStep> steps;

  const AppTourDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    this.tabIndex,
  });
}

class AppTourState {
  final AppTourStatus status;
  final String? activeTourId;
  final int stepIndex;
  final AppTourTrigger trigger;

  const AppTourState({
    required this.status,
    this.activeTourId,
    this.stepIndex = 0,
    this.trigger = AppTourTrigger.automatic,
  });

  static const idle = AppTourState(status: AppTourStatus.idle);

  AppTourState copyWith({
    AppTourStatus? status,
    String? activeTourId,
    int? stepIndex,
    AppTourTrigger? trigger,
  }) {
    return AppTourState(
      status: status ?? this.status,
      activeTourId: activeTourId ?? this.activeTourId,
      stepIndex: stepIndex ?? this.stepIndex,
      trigger: trigger ?? this.trigger,
    );
  }
}
