import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workflow_step.dart';
import '../domain/workflow_controller.dart';
import '../registry/workflow_registry.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';

class WorkflowGateScreen extends ConsumerWidget {
  final String workflowId;

  const WorkflowGateScreen({super.key, required this.workflowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wfState = ref.watch(workflowControllerProvider);
    
    // If not active, we use registry steps.
    final steps = wfState.isActive ? wfState.steps : (WorkflowRegistry.stepsFor(workflowId) ?? []);
    
    // If complete, show the finish screen
    if (wfState.isActive && wfState.isComplete) {
      return _buildFinishScreen(context, ref, wfState, cs, isDark);
    }

    final currentStepIdx = wfState.isActive ? wfState.currentStepIndex : 0;
    final currentStep = steps[currentStepIdx];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Guided Workflow",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232830) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: const Icon(Icons.close_rounded, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Horizontal Progress Timeline
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _buildHorizontalTimeline(wfState, steps, cs),
            ),
            
            // 2. Active Module View
            Expanded(
              child: Stack(
                children: [
                  // Center Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Large Module Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: currentStep.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              currentStep.icon,
                              size: 48,
                              color: currentStep.color,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Text
                          Text(
                            currentStep.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentStep.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Big Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: () => _handleStepStart(context, ref, wfState, steps, currentStepIdx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 8,
                                shadowColor: cs.primary.withOpacity(0.4),
                              ),
                              child: Text(
                                wfState.isActive ? "Start ${currentStep.title}" : "Start Session",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Top Right Skip Button
                  if (wfState.isActive)
                    Positioned(
                      top: 0,
                      right: 20,
                      child: OutlinedButton(
                        onPressed: () => ref.read(workflowControllerProvider.notifier).skipCurrentStep(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurfaceVariant,
                          side: BorderSide(color: cs.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishScreen(BuildContext context, WidgetRef ref, dynamic wfState, ColorScheme cs, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF4F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                "Session Complete",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                "All required modules have been addressed for today.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => ref.read(workflowControllerProvider.notifier).finishWorkflow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Finish & Exit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTimeline(dynamic wfState, List<WorkflowStep> steps, ColorScheme cs) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isReached = wfState.isActive && (wfState.completedStepIndices.contains(stepIdx) || wfState.skippedStepIndices.contains(stepIdx));
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isReached ? cs.primary : cs.outlineVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        } else {
          final stepIdx = i ~/ 2;
          final isCompleted = wfState.completedStepIndices.contains(stepIdx);
          final isSkipped = wfState.skippedStepIndices.contains(stepIdx);
          final isActive = wfState.isActive && wfState.currentStepIndex == stepIdx;
          final isPending = !wfState.isActive && stepIdx == 0;
          
          return _TimelineNode(
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            isActive: isActive || (isPending && i == 0),
            icon: steps[stepIdx].icon,
            color: steps[stepIdx].color,
            cs: cs,
          );
        }
      }),
    );
  }

  void _handleStepStart(BuildContext context, WidgetRef ref, dynamic wfState, List<WorkflowStep> steps, int index) {
    if (!wfState.isActive) {
       ref.read(workflowControllerProvider.notifier).startWorkflow(steps: steps, workflowId: workflowId);
       // We don't push yet, let them click the big button again or we can auto-push?
       // User said "big button to start entry", so if they click "Start Session", maybe it starts and then we push?
       // Let's just start and push the first module immediately if it's the "Start Session" button.
    }

    final selectedSite = ref.read(siteDropdownValueProvider);
    final selectedTeam = ref.read(teamDropdownValueProvider);

    context.push(steps[index].route, extra: {
      'selectedSite': selectedSite,
      'selectedTeam': selectedTeam,
    });
  }
}

class _TimelineNode extends StatelessWidget {
  final bool isCompleted;
  final bool isSkipped;
  final bool isActive;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  const _TimelineNode({
    required this.isCompleted,
    required this.isSkipped,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = cs.surfaceContainerHigh;
    Color iconColor = cs.onSurfaceVariant;
    Widget? overlay;

    if (isCompleted) {
      bgColor = Colors.green;
      // Use module color for the background if you want, but checkmark usually green
      // User said "use the actual colored icon", so maybe the background should be the color?
      // Or the icon color?
      // In module_screen_v2, the cards have colored icons.
      iconColor = Colors.white;
      overlay = const Positioned(
        bottom: -2,
        right: -2,
        child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
      );
    } else if (isSkipped) {
      bgColor = cs.outlineVariant;
      iconColor = cs.onSurfaceVariant.withOpacity(0.5);
      overlay = Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(Icons.help_rounded, size: 16, color: cs.primary),
        ),
      );
    } else if (isActive) {
      bgColor = color; // Use module color for active step
      iconColor = Colors.white;
    } else {
      // Pending step - maybe subtle version of module color?
      bgColor = color.withOpacity(0.1);
      iconColor = color.withOpacity(0.5);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Center(child: Icon(icon, size: 20, color: iconColor)),
        ),
        if (overlay != null) overlay,
      ],
    );
  }
}
