import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UploadOverlayMode { banner, floating }

class FloatingBallState {
  final UploadOverlayMode mode;
  final Offset position;
  final bool isPanelOpen;
  final bool isMorphing;

  const FloatingBallState({
    this.mode = UploadOverlayMode.banner,
    this.position = const Offset(20, 120),
    this.isPanelOpen = false,
    this.isMorphing = false,
  });

  FloatingBallState copyWith({
    UploadOverlayMode? mode,
    Offset? position,
    bool? isPanelOpen,
    bool? isMorphing,
  }) {
    return FloatingBallState(
      mode: mode ?? this.mode,
      position: position ?? this.position,
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      isMorphing: isMorphing ?? this.isMorphing,
    );
  }
}

class FloatingBallController extends Notifier<FloatingBallState> {
  @override
  FloatingBallState build() => const FloatingBallState();

  void morphToFloating(Size screenSize) {
    state = state.copyWith(isMorphing: true);
    Future.delayed(const Duration(milliseconds: 350), () {
      state = state.copyWith(
        mode: UploadOverlayMode.floating,
        isMorphing: false,
      );
    });
  }

  void morphToBanner() {
    state = state.copyWith(isMorphing: true);
    Future.delayed(const Duration(milliseconds: 350), () {
      state = state.copyWith(
        mode: UploadOverlayMode.banner,
        isMorphing: false,
        isPanelOpen: false,
      );
    });
  }

  void updatePosition(Offset offset) {
    state = state.copyWith(position: offset);
  }

  /// Snap to nearest edge with peek offset
  void snapToEdge(Size screenSize) {
    const ballSize = 56.0;
    const peekAmount = 44.0; // how much of ball shows at edge
    const topMin = 80.0;
    const bottomMax_offset = 100.0;

    final pos = state.position;
    final screenW = screenSize.width;
    final screenH = screenSize.height;

    final centerX = pos.dx + ballSize / 2;
    final centerY = pos.dy + ballSize / 2;

    // Determine closest edge: left, right, top, bottom
    final distLeft = centerX;
    final distRight = screenW - centerX;
    final distTop = centerY - topMin;
    final distBottom = screenH - bottomMax_offset - centerY;

    final minDist =
    [distLeft, distRight, distTop, distBottom].reduce((a, b) => a < b ? a : b);

    Offset snapped;

    if (minDist == distLeft) {
      snapped = Offset(-ballSize + peekAmount, pos.dy.clamp(topMin, screenH - bottomMax_offset - ballSize));
    } else if (minDist == distRight) {
      snapped = Offset(screenW - peekAmount, pos.dy.clamp(topMin, screenH - bottomMax_offset - ballSize));
    } else if (minDist == distTop) {
      snapped = Offset(pos.dx.clamp(8, screenW - ballSize - 8), topMin);
    } else {
      snapped = Offset(
        pos.dx.clamp(8, screenW - ballSize - 8),
        screenH - bottomMax_offset - ballSize,
      );
    }

    state = state.copyWith(position: snapped);
  }

  void togglePanel() {
    state = state.copyWith(isPanelOpen: !state.isPanelOpen);
  }

  void closePanel() {
    state = state.copyWith(isPanelOpen: false);
  }
}

final floatingBallControllerProvider =
NotifierProvider<FloatingBallController, FloatingBallState>(
  FloatingBallController.new,
);