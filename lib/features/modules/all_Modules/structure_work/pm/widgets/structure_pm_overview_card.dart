import 'package:flutter/material.dart';
import '../models/structure_pm_entry_model.dart';

const _kBrown = Color(0xFF7B3F00);

class StructurePmOverviewCard extends StatelessWidget {
  final StructurePmSummary summary;
  const StructurePmOverviewCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 18, color: _kBrown),
              const SizedBox(width: 8),
              Text(
                'P&M Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricBox(
                label: 'Required',
                value: summary.totalRequired.toStringAsFixed(0),
                color: Colors.blue,
                cs: cs,
              ),
              _MetricBox(
                label: 'Actual',
                value: summary.totalActual.toStringAsFixed(0),
                color: Colors.green,
                cs: cs,
              ),
              _MetricBox(
                label: 'Gap',
                value: summary.totalGap.toStringAsFixed(0),
                color: summary.totalGap > 0 ? Colors.red : Colors.green,
                cs: cs,
              ),
              _MetricBox(
                label: 'Resources',
                value: summary.totalResources.toString(),
                color: Colors.purple,
                cs: cs,
              ),
              _MetricBox(
                label: 'Filled',
                value: summary.filledResources.toString(),
                color: Colors.teal,
                cs: cs,
              ),
              _MetricBox(
                label: 'Pending',
                value: summary.pendingResources.toString(),
                color: Colors.orange,
                cs: cs,
              ),
              _MetricBox(
                label: 'Categories',
                value: summary.totalCategories.toString(),
                color: _kBrown,
                cs: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
