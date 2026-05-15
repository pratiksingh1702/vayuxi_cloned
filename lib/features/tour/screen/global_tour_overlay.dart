// lib/features/tour/screen/global_tour_overlay.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL TOUR OVERLAY
// Sits at the root of the widget tree and renders the BuddyOverlay whenever
// the tour engine is running and the user is on the correct route.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/global_sync_banner.dart';
import '../../../core/router/app_router.dart';
import '../../../core/upload/ui/upload_banner.dart';

import '../domain/tour_controller.dart';
import '../domain/tour_step_model.dart';
import 'buddy_overlay.dart';

import '../../../core/router/app_access.dart';
class GlobalTourOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalTourOverlay({super.key, required this.child});

  @override
  ConsumerState<GlobalTourOverlay> createState() => _GlobalTourOverlayState();
}

class _GlobalTourOverlayState extends ConsumerState<GlobalTourOverlay> {
  Offset? _buddyOffset;
  String? _positionedForStepId;

  // ── Banners stack (when user is not logged in / booting) ──────────────────
  Widget _withBanners(Widget child) {
    return Stack(
      children: [
        child,
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(appAccessProvider);
    final isInsideApp = !access.isBooting && access.loggedIn;

    if (!isInsideApp) return _withBanners(widget.child);

    final tourState = ref.watch(tourControllerProvider);
    final ctrl = ref.read(tourControllerProvider.notifier);
    final step = ctrl.currentStep;

    if (_positionedForStepId != step?.id) {
      _positionedForStepId = step?.id;
      _buddyOffset = null;
    }

    // ── Buddy visibility: rely on tourState.buddyVisible (set by syncToRoute) ──
    // instead of reading GoRouter state which can lag during navigation.
    // The app calls syncToRoute(currentRoute) when it knows the correct route context.
    final showBuddy = tourState.status == TourStatus.running &&
      step != null &&
      tourState.buddyVisible;

    if (kDebugMode && tourState.status == TourStatus.running) {
      debugPrint(
         '🌐 [GlobalTourOverlay] Build: status=${tourState.status}, stepId=${step?.id}, stepRoute=${step?.route}, buddyVisible=${tourState.buddyVisible}, showBuddy=$showBuddy');
    }

    return Stack(
      children: [
        widget.child,

        // Upload + sync banners — always on top of content
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),

        // ── Buddy Overlay ────────────────────────────────────────────────────
        if (showBuddy)
          Builder(
            builder: (context) {
              final mq = MediaQuery.of(context);
              final screenSize = mq.size;
              final safeTop = mq.padding.top;
              final safeBottom = mq.padding.bottom;

              final panelWidth = (screenSize.width - 20).clamp(280.0, 560.0);
              final initial = _initialOffset(
                screenSize: screenSize,
                safeTop: safeTop,
                safeBottom: safeBottom,
                panelWidth: panelWidth,
                placement: step!.buddyPlacement,
              );

              final offset = _clampOffset(
                raw: _buddyOffset ?? initial,
                screenSize: screenSize,
                safeTop: safeTop,
                safeBottom: safeBottom,
                panelWidth: panelWidth,
              );

              if (_buddyOffset == null) {
                _buddyOffset = offset;
              }

              return Positioned(
                left: offset.dx,
                top: offset.dy,
                width: panelWidth,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    final nextRaw = offset + details.delta;
                    setState(() {
                      _buddyOffset = _clampOffset(
                        raw: nextRaw,
                        screenSize: screenSize,
                        safeTop: safeTop,
                        safeBottom: safeBottom,
                        panelWidth: panelWidth,
                      );
                    });
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: BuddyOverlay(
                      onNext: () async {
                        await ctrl.next();
                        final nextStep = ctrl.currentStep;
                        if (nextStep != null) {
                          final router = ref.read(appRouterProvider);
                          final now =
                              router.routerDelegate.currentConfiguration.uri.path;
                          if (nextStep.route != now) {
                            router.go(nextStep.route);
                          }
                        }
                      },
                      step: step,
                      currentStepIndex: tourState.stepIndex,
                      totalSteps: ctrl.totalSteps,
                      showHint: tourState.showHint,
                      isMuted: tourState.isMuted,
                      onBack: () => ctrl.back(),
                      onSkip: () => ctrl.skip(),
                      onReplayVoice: () => ctrl.replayVoice(),
                      onToggleMute: () => ctrl.toggleMute(),
                    ),
                  ),
                ),
              );
            },
          ),
      ], // end outer Stack children
    );
  }

  Offset _initialOffset({
    required Size screenSize,
    required double safeTop,
    required double safeBottom,
    required double panelWidth,
    required BuddyPlacement placement,
  }) {
    const estimatedPanelHeight = 220.0;
    final centeredX = (screenSize.width - panelWidth) / 2;

    if (placement == BuddyPlacement.top) {
      return Offset(centeredX, safeTop + 10);
    }

    return Offset(
      centeredX,
      screenSize.height - safeBottom - estimatedPanelHeight - 12,
    );
  }

  Offset _clampOffset({
    required Offset raw,
    required Size screenSize,
    required double safeTop,
    required double safeBottom,
    required double panelWidth,
  }) {
    const estimatedPanelHeight = 260.0;
    const margin = 8.0;

    final minX = margin;
    final maxX = (screenSize.width - panelWidth - margin).clamp(minX, double.infinity);
    final minY = safeTop + margin;
    final maxY = (screenSize.height - safeBottom - estimatedPanelHeight - margin)
        .clamp(minY, double.infinity);

    return Offset(
      raw.dx.clamp(minX, maxX),
      raw.dy.clamp(minY, maxY),
    );
  }
}
