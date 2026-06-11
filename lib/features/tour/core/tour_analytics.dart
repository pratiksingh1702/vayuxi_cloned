import 'package:flutter/foundation.dart';

class AppTourAnalytics {
  const AppTourAnalytics();

  void started(String tourId) {
    debugPrint('Tour started: $tourId');
  }

  void stepped(String tourId, String stepId, int stepIndex) {
    debugPrint('Tour step: $tourId/$stepId index=$stepIndex');
  }

  void skipped(String tourId, String stepId) {
    debugPrint('Tour skipped: $tourId/$stepId');
  }

  void completed(String tourId) {
    debugPrint('Tour completed: $tourId');
  }
}
