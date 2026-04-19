import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/dpr_draft_repo.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/offline/repo/insu_dpr_draft_repo.dart';
import '../manager/upload_manager.dart';
import '../models/upload_job.dart';
import '../models/upload_status.dart';
import 'upload_banner_collapsed.dart';
import 'upload_banner_expanded.dart';
import 'floating_ball/floating_ball_controller.dart';
import 'floating_ball/floating_upload_ball.dart';

class GlobalUploadBanner extends ConsumerStatefulWidget {
  const GlobalUploadBanner({super.key});

  @override
  ConsumerState<GlobalUploadBanner> createState() => _GlobalUploadBannerState();
}

class _GlobalUploadBannerState extends ConsumerState<GlobalUploadBanner>
    with TickerProviderStateMixin {
  final DprDraftRepo _draftRepo = DprDraftRepo();
  final InsuDprDraftRepo _insuDraftRepo = InsuDprDraftRepo();
  bool _isExpanded = false;
  late AnimationController _animCtrl;

  // ── morph animation (banner → ball shrink-out)
  late AnimationController _morphOutCtrl;
  late Animation<double> _morphScaleAnim;
  late Animation<double> _morphFadeAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _morphOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _morphScaleAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _morphOutCtrl, curve: Curves.easeInBack),
    );
    _morphFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _morphOutCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _morphOutCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  /// Toggle mode: banner ↔ ball
  void _toggleMode() {
    final ballState = ref.read(floatingBallControllerProvider);
    if (ballState.mode == UploadOverlayMode.banner) {
      _morphToFloating();
    } else {
      ref.read(floatingBallControllerProvider.notifier).morphToBanner();
    }
  }

  /// Long press on banner → morph to floating ball
  void _morphToFloating() {
    HapticFeedback.mediumImpact();
    final size = MediaQuery.of(context).size;
    _morphOutCtrl.forward().then((_) {
      ref.read(floatingBallControllerProvider.notifier).morphToFloating(size);
      _morphOutCtrl.reset();
    });
  }

  UploadJob _priorityJob(List<UploadJob> jobs) {
    return jobs.firstWhere((j) => j.status == UploadStatus.uploading,
        orElse: () => jobs.firstWhere(
              (j) => j.status == UploadStatus.processing,
              orElse: () => jobs.firstWhere(
                (j) => j.status == UploadStatus.queued,
                orElse: () => jobs.firstWhere(
                  (j) => j.status == UploadStatus.success,
                  orElse: () => jobs.first,
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(uploadManagerProvider);
    final ballState = ref.watch(floatingBallControllerProvider);

    if (jobs.isEmpty) return const SizedBox.shrink();

    // ── Floating ball: full screen Stack, ball self-positions via Positioned
    if (ballState.mode == UploadOverlayMode.floating) {
      return Stack(children: const [FloatingUploadBall()]);
    }

    // ── Banner mode: shrink-wrap to content height, sit at top
    // Wrap in Column so height = banner height only, not full screen
    final priority = _priorityJob(jobs);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_morphScaleAnim, _morphFadeAnim]),
            builder: (context, child) => Opacity(
              opacity: _morphFadeAnim.value,
              child: Transform.scale(
                scale: _morphScaleAnim.value,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: GestureDetector(
              onLongPress: _morphToFloating,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _isExpanded
                    ? UploadBannerExpanded(
                        jobs: jobs,
                        onCollapse: _toggleExpanded,
                        onToggleMode: _toggleMode,
                        onNavigate: (route) =>
                            Navigator.of(context).pushNamed(route),
                        onRetry: (id) =>
                            ref.read(uploadManagerProvider.notifier).retry(id),
                        onDismiss: (id) => ref
                            .read(uploadManagerProvider.notifier)
                            .removeJob(id),
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
                          context.push(route, extra: {'draftWork': work});
                        },
                      )
                    : UploadBannerCollapsed(
                        job: priority,
                        totalCount: jobs.length,
                        onTap: _toggleExpanded,
                        onToggleMode: _toggleMode,
                        onNavigate: priority.targetRoute != null &&
                                priority.status == UploadStatus.success
                            ? () {
                                ref
                                    .read(uploadManagerProvider.notifier)
                                    .stopAutoDismiss(priority.jobId);
                                Navigator.of(context)
                                    .pushNamed(priority.targetRoute!);
                              }
                            : null,
                        onDismiss: () => ref
                            .read(uploadManagerProvider.notifier)
                            .removeJob(priority.jobId),
                        onStopTimer: () => ref
                            .read(uploadManagerProvider.notifier)
                            .stopAutoDismiss(priority.jobId),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
