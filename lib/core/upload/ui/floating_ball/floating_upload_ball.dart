import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/dpr_draft_repo.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/offline/repo/insu_dpr_draft_repo.dart';
import '../../manager/upload_manager.dart';
import '../../models/upload_job.dart';
import '../../models/upload_status.dart';
import 'floating_ball_controller.dart';
import 'floating_status_panel.dart';

class FloatingUploadBall extends ConsumerStatefulWidget {
  const FloatingUploadBall({super.key});

  @override
  ConsumerState<FloatingUploadBall> createState() => _FloatingUploadBallState();
}

class _FloatingUploadBallState extends ConsumerState<FloatingUploadBall>
    with TickerProviderStateMixin {
  final DprDraftRepo _draftRepo = DprDraftRepo();
  final InsuDprDraftRepo _insuDraftRepo = InsuDprDraftRepo();
  // ── Animation controllers
  late AnimationController _morphController; // entry morph-in
  late AnimationController _bounceController; // tap bounce
  late AnimationController _pulseController; // active pulse ring
  late AnimationController _rippleController; // drag ripple
  late AnimationController _rotateController; // upload spinner ring

  late Animation<double> _morphScaleAnim;
  late Animation<double> _morphFadeAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _morphScaleAnim = CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    );
    _morphFadeAnim = CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.00), weight: 15),
    ]).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnim =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rippleAnim =
        CurvedAnimation(parent: _rippleController, curve: Curves.easeOut);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _morphController.forward();
  }

  @override
  void dispose() {
    _morphController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // ── Status theming
  _BallTheme _theme(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploading:
        return const _BallTheme(
          core: Color(0xFF1565C0),
          glow: Color(0xFF42A5F5),
          ring: Color(0xFF90CAF9),
          icon: Icons.cloud_upload_rounded,
          label: 'Uploading',
        );
      case UploadStatus.processing:
        return const _BallTheme(
          core: Color(0xFF4A148C),
          glow: Color(0xFFAB47BC),
          ring: Color(0xFFCE93D8),
          icon: Icons.sync_rounded,
          label: 'Processing',
        );
      case UploadStatus.success:
        return const _BallTheme(
          core: Color(0xFF1B5E20),
          glow: Color(0xFF43A047),
          ring: Color(0xFFA5D6A7),
          icon: Icons.check_rounded,
          label: 'Done',
        );
      case UploadStatus.failed:
        return const _BallTheme(
          core: Color(0xFFB71C1C),
          glow: Color(0xFFEF5350),
          ring: Color(0xFFEF9A9A),
          icon: Icons.warning_rounded,
          label: 'Failed',
        );
      case UploadStatus.queued:
        return const _BallTheme(
          core: Color(0xFF212121),
          glow: Color(0xFF757575),
          ring: Color(0xFFBDBDBD),
          icon: Icons.hourglass_top_rounded,
          label: 'Queued',
        );
    }
  }

  UploadJob _priorityJob(List<UploadJob> jobs) {
    return jobs.firstWhere((j) => j.status == UploadStatus.uploading,
        orElse: () => jobs.firstWhere(
              (j) => j.status == UploadStatus.processing,
              orElse: () => jobs.firstWhere(
                (j) => j.status == UploadStatus.success,
                orElse: () => jobs.first,
              ),
            ));
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0);
    ref.read(floatingBallControllerProvider.notifier).togglePanel();
  }

  void _onToggleMode() {
    HapticFeedback.mediumImpact();
    ref.read(floatingBallControllerProvider.notifier).morphToBanner();
  }

  void _onLongPress() {
    _onToggleMode();
  }

  void _onDragStart() {
    setState(() => _isDragging = true);
    _rippleController.forward(from: 0);
    ref.read(floatingBallControllerProvider.notifier).closePanel();
    HapticFeedback.selectionClick();
  }

  void _onDragEnd(Size screenSize) {
    setState(() => _isDragging = false);
    HapticFeedback.lightImpact();
    ref.read(floatingBallControllerProvider.notifier).snapToEdge(screenSize);
  }

  @override
  Widget build(BuildContext context) {
    final ballState = ref.watch(floatingBallControllerProvider);
    final jobs = ref.watch(uploadManagerProvider);

    if (jobs.isEmpty) return const SizedBox.shrink();

    final priority = _priorityJob(jobs);
    final theme = _theme(priority.status);
    final screenSize = MediaQuery.of(context).size;
    final isActive = priority.status.isActive;

    return Positioned(
      left: ballState.position.dx,
      top: ballState.position.dy,
      child: FadeTransition(
        opacity: _morphFadeAnim,
        child: ScaleTransition(
          scale: _morphScaleAnim,
          child: SizedBox(
            // Extra space so pulse ring + panel don't clip
            width: 300,
            height: 300,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Pulse ring (active uploads only)
                if (isActive)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        final v = _pulseAnim.value;
                        final size = 56.0 + (v * 32);
                        final opacity = (1.0 - v).clamp(0.0, 1.0) * 0.35;
                        return Container(
                          width: size,
                          height: size,
                          margin: EdgeInsets.all(
                              (56.0 - size) / 2 + (size - 56) / 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.glow.withOpacity(opacity),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Main ball
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: _onTap,
                    onLongPress: _onLongPress,
                    onPanStart: (_) => _onDragStart(),
                    onPanUpdate: (details) {
                      final newPos = ballState.position + details.delta;
                      ref
                          .read(floatingBallControllerProvider.notifier)
                          .updatePosition(
                            Offset(
                              newPos.dx.clamp(0, screenSize.width - 56),
                              newPos.dy.clamp(80, screenSize.height - 160),
                            ),
                          );
                    },
                    onPanEnd: (_) => _onDragEnd(screenSize),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_bounceAnim]),
                      builder: (_, child) {
                        final scale = _isDragging
                            ? 1.18
                            : _bounceController.isAnimating
                                ? _bounceAnim.value
                                : 1.0;
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _BallBody(
                        theme: theme,
                        job: priority,
                        isDragging: _isDragging,
                        rotateController: _rotateController,
                        rippleAnim: _rippleAnim,
                      ),
                    ),
                  ),
                ),

                // ── Job count badge
                if (jobs.length > 1)
                  Positioned(
                    left: 36,
                    top: -4,
                    child: _CountBadge(count: jobs.length),
                  ),

                // ── Mode Switch Icon (Ball → Banner)
                Positioned(
                  left: -8,
                  top: -8,
                  child: GestureDetector(
                    onTap: _onToggleMode,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.core,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_fullscreen_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Status panel
                if (ballState.isPanelOpen)
                  Positioned(
                    left: _panelOffsetX(ballState.position, screenSize),
                    top: _panelOffsetY(ballState.position, screenSize),
                    child: FloatingStatusPanel(
                      jobs: jobs,
                      ballPosition: ballState.position,
                      screenSize: screenSize,
                      onDismiss: () => ref
                          .read(floatingBallControllerProvider.notifier)
                          .closePanel(),
                      onRetry: (id) =>
                          ref.read(uploadManagerProvider.notifier).retry(id),
                      onNavigate: (route) {
                        ref
                            .read(floatingBallControllerProvider.notifier)
                            .closePanel();
                        Navigator.of(context).pushNamed(route);
                      },
                      onEdit: (job) async {
                        final draftId = job.metadata['draftId']?.toString();
                        if (draftId == null || draftId.isEmpty) return;

                        Object? work;
                        String route = Routes.dprDescription;

                        if (job.moduleId == 'dpr_insu') {
                          route = Routes.dprInsuDescription;
                          final rawWork = job.metadata['draftWork'];
                          if (rawWork != null) {
                            work = rawWork;
                          } else {
                            final record =
                                await _insuDraftRepo.getDraft(draftId);
                            work = record?.draft;
                          }
                        } else {
                          final rawWork = job.metadata['draftWork'];
                          if (rawWork != null) {
                            work = rawWork;
                          } else {
                            final record = await _draftRepo.getDraft(draftId);
                            work = record?.draft;
                          }
                        }

                        if (work == null || !mounted) return;
                        ref
                            .read(uploadManagerProvider.notifier)
                            .stopAutoDismiss(job.jobId);
                        ref
                            .read(floatingBallControllerProvider.notifier)
                            .closePanel();
                        context.push(route, extra: {'draftWork': work});
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _panelOffsetX(Offset pos, Size screen) {
    // Open right if ball is on left half, left if on right half
    return pos.dx < screen.width / 2 ? 64 : -248;
  }

  double _panelOffsetY(Offset pos, Size screen) {
    // Keep panel vertically centered near ball, clamped to screen
    return -20.0;
  }
}

// ── Ball visual body — separated for clarity
class _BallBody extends StatelessWidget {
  final _BallTheme theme;
  final UploadJob job;
  final bool isDragging;
  final AnimationController rotateController;
  final Animation<double> rippleAnim;

  const _BallBody({
    required this.theme,
    required this.job,
    required this.isDragging,
    required this.rotateController,
    required this.rippleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.core,
        boxShadow: [
          BoxShadow(
            color: theme.glow.withOpacity(isDragging ? 0.7 : 0.45),
            blurRadius: isDragging ? 24 : 14,
            spreadRadius: isDragging ? 3 : 1,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer arc ring (upload progress)
          if (job.status == UploadStatus.uploading)
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: job.progress.clamp(0.0, 1.0),
                strokeWidth: 2.5,
                color: theme.ring,
                backgroundColor: Colors.white.withOpacity(0.12),
                strokeCap: StrokeCap.round,
              ),
            ),

          // ── Rotating dashed ring (processing)
          if (job.status == UploadStatus.processing)
            RotationTransition(
              turns: rotateController,
              child: SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.ring.withOpacity(0.7),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),

          // ── Center icon
          _CenterIcon(theme: theme, job: job),

          // ── Drag ripple overlay
          AnimatedBuilder(
            animation: rippleAnim,
            builder: (_, __) {
              if (!isDragging && rippleAnim.value <= 0) {
                return const SizedBox.shrink();
              }
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.white.withOpacity((1 - rippleAnim.value) * 0.12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CenterIcon extends StatelessWidget {
  final _BallTheme theme;
  final UploadJob job;

  const _CenterIcon({required this.theme, required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.status == UploadStatus.uploading) {
      // Show percentage text when far enough
      final pct = (job.progress * 100).toInt();
      if (pct > 10) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$pct',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            Text(
              '%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        );
      }
    }

    return Icon(
      theme.icon,
      color: Colors.white,
      size: job.status == UploadStatus.success ? 26 : 22,
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Theme data per status
class _BallTheme {
  final Color core;
  final Color glow;
  final Color ring;
  final IconData icon;
  final String label;

  const _BallTheme({
    required this.core,
    required this.glow,
    required this.ring,
    required this.icon,
    required this.label,
  });
}
