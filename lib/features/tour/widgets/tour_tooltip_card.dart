import 'package:flutter/material.dart';

import '../core/tour_models.dart';

class TourTooltipCard extends StatelessWidget {
  final AppTourDefinition tour;
  final AppTourStep step;
  final int stepIndex;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TourTooltipCard({
    super.key,
    required this.tour,
    required this.step,
    required this.stepIndex,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = tour.steps.length;
    final progress = total == 0 ? 0.0 : (stepIndex + 1) / total;
    final canBack = stepIndex > 0;
    final isLast = stepIndex >= total - 1;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHigh.withOpacity(0.96)
              : cs.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.34 : 0.16),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: cs.primary.withOpacity(0.18)),
                  ),
                  child: Icon(tour.icon, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Step ${stepIndex + 1} of $total',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Skip tour',
                  onPressed: onSkip,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: progress,
                color: cs.primary,
                backgroundColor: cs.outlineVariant.withOpacity(0.35),
              ),
            ),
            if (step.progressLabel != null) ...[
              const SizedBox(height: 5),
              Text(
                step.progressLabel!,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              step.body,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.9),
                fontSize: 12.5,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: canBack ? onBack : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                  label: Text(isLast ? 'Finish' : 'Next'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
