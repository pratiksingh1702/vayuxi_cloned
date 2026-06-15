import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tour_providers.dart';

class NoCutoutTourTarget extends ConsumerStatefulWidget {
  final GlobalKey targetKey;
  final Widget child;

  const NoCutoutTourTarget({
    super.key,
    required this.targetKey,
    required this.child,
  });

  @override
  ConsumerState<NoCutoutTourTarget> createState() => _NoCutoutTourTargetState();
}

class _NoCutoutTourTargetState extends ConsumerState<NoCutoutTourTarget> {
  OverlayEntry? _entry;
  Rect? _rect;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appTourControllerProvider);
    final tourController = ref.read(appTourControllerProvider.notifier);
    final step = tourController.currentStep;
    final isActive = identical(step?.targetKey, widget.targetKey);

    if (isActive) {
      if (step?.autoScrollToTarget ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetContext = widget.targetKey.currentContext;
          if (!mounted || targetContext == null) return;
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.28,
          );
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _removeOverlay());
    }

    return KeyedSubtree(
      key: widget.targetKey,
      child: widget.child,
    );
  }

  void _showOverlay() {
    if (!mounted) return;

    final targetContext = widget.targetKey.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final nextRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (_entry == null) {
      _rect = nextRect;
      _entry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context, rootOverlay: true).insert(_entry!);
      return;
    }

    if (_rect != nextRect) {
      _rect = nextRect;
      _entry?.markNeedsBuild();
    }
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final rect = _rect;
    if (rect == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.78),
          ),
          Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    _rect = null;
  }
}
