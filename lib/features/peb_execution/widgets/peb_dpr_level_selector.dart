import 'package:flutter/material.dart';

import '../models/peb_execution_models.dart';

class PebDprLevelOptionCard extends StatelessWidget {
  final PebDprLevel level;
  final bool selected;
  final bool enabled;
  final VoidCallback? onSelected;

  const PebDprLevelOptionCard({
    super.key,
    required this.level,
    this.selected = false,
    this.enabled = true,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = PebDprLevelInfo.fromLevel(level);
    return InkWell(
      onTap: enabled ? onSelected : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.55)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                info.icon,
                color: selected ? cs.onPrimary : cs.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          level.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    info.shortSummary,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: info.chips
                        .map((chip) => _LevelChip(label: chip))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showPebDprLevelDetails(context, level),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text(
                        'View More',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PebDprLevelPickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const PebDprLevelPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: PebDprLevel.values
                      .map(
                        (level) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PebDprLevelOptionCard(
                            level: level,
                            onSelected: () => Navigator.of(context).pop(level),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPebDprLevelDetails(
  BuildContext context,
  PebDprLevel level,
) {
  final info = PebDprLevelInfo.fromLevel(level);
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(info.icon, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.shortSummary,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailSection(title: 'What It Means', lines: info.meaning),
              _DetailSection(title: 'How It Works', lines: info.howItWorks),
              _DetailSection(title: 'Available Features', lines: info.features),
              _DetailSection(title: 'Choose This When', lines: info.chooseWhen),
              _DetailSection(
                title: 'Limitations & Dependencies',
                lines: info.limitations,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PebDprLevelInfo {
  final IconData icon;
  final String shortSummary;
  final List<String> chips;
  final List<String> meaning;
  final List<String> howItWorks;
  final List<String> features;
  final List<String> chooseWhen;
  final List<String> limitations;

  const PebDprLevelInfo({
    required this.icon,
    required this.shortSummary,
    required this.chips,
    required this.meaning,
    required this.howItWorks,
    required this.features,
    required this.chooseWhen,
    required this.limitations,
  });

  factory PebDprLevelInfo.fromLevel(PebDprLevel level) {
    switch (level) {
      case PebDprLevel.basicProgress:
        return const PebDprLevelInfo(
          icon: Icons.edit_note_rounded,
          shortSummary: 'Enter daily progress directly stage by stage.',
          chips: ['No BOQ', 'No Assignment', 'Stage wise'],
          meaning: [
            'Basic Progress Entry is for simple sites where BOQ and Work Assignment are not required.',
            'Progress is recorded directly against each configured DPR stage.',
          ],
          howItWorks: [
            'Select a site and date.',
            'Open the standard work stages.',
            'Enter the progress weight and UOM for each stage.',
            'Save once from the bottom action.',
          ],
          features: [
            'Stage-wise daily progress entry.',
            'Editable UOM from the same screen.',
            'Cumulative progress for repeated entries.',
          ],
          chooseWhen: [
            'The site team only needs simple stage-wise progress.',
            'No BOQ has been uploaded.',
            'No team-wise or mark-number assignment is required.',
          ],
          limitations: [
            'No mark-number level tracking.',
            'No assigned, in-progress, or completed workflow.',
            'Reports are based on stage progress only.',
          ],
        );
      case PebDprLevel.itemWiseProgress:
        return const PebDprLevelInfo(
          icon: Icons.manage_search_rounded,
          shortSummary: 'Track progress item by item. BOQ is optional.',
          chips: ['BOQ optional', 'Item wise', 'Search & add'],
          meaning: [
            'Item Wise Progress Entry is for sites that need mark-number or item-wise progress without Work Assignment.',
            'A BOQ improves tracking, but the user can also add items manually if no BOQ exists.',
          ],
          howItWorks: [
            'Select a site and date.',
            'Search BOQ mark numbers if BOQ is uploaded.',
            'If no BOQ exists, add the required item manually.',
            'Enter progress quantity or weight against that item.',
          ],
          features: [
            'Search by mark number, member, or BOQ item.',
            'Manual item creation when BOQ is missing.',
            'Partial progress support for the same item.',
          ],
          chooseWhen: [
            'Work Assignment is not required.',
            'The team wants item-wise tracking.',
            'BOQ may be available now or can be added later.',
          ],
          limitations: [
            'No stage-wise workflow sequence.',
            'No assigned, in-progress, or completed stepper.',
            'BOQ is recommended for cleaner item names and weights.',
          ],
        );
      case PebDprLevel.assignedWorkProgress:
        return const PebDprLevelInfo(
          icon: Icons.assignment_turned_in_rounded,
          shortSummary: 'Track progress against assigned work.',
          chips: ['BOQ required', 'Assignment', 'Full workflow'],
          meaning: [
            'Assigned Work Progress Entry is the full controlled workflow.',
            'BOQ items are assigned to teams or manpower before DPR progress is recorded.',
          ],
          howItWorks: [
            'Upload BOQ.',
            'Create Work Assignment for stage, team, date, and mark numbers.',
            'Open DPR Entry and update assigned marks as In Progress or Completed.',
            'Reports compare assigned/planned work with actual DPR progress.',
          ],
          features: [
            'BOQ-based mark-number tracking.',
            'Team or manpower assignment control.',
            'Stage sequence validation.',
            'Detailed planned vs actual reporting.',
          ],
          chooseWhen: [
            'The site requires controlled execution tracking.',
            'BOQ and Work Assignment are part of the process.',
            'Management needs clear planned vs actual visibility.',
          ],
          limitations: [
            'BOQ and Work Assignment should be prepared first.',
            'More setup is required before daily entry.',
            'Best suited for structured execution projects.',
          ],
        );
    }
  }
}

class _LevelChip extends StatelessWidget {
  final String label;

  const _LevelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _DetailSection({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
