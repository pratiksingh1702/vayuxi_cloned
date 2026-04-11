import 'package:flutter/material.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';

import '../../domain/models/automated_entry_models.dart';

class ModuleImportCard extends StatelessWidget {
  const ModuleImportCard({
    super.key,
    required this.draft,
    required this.sites,
    required this.progress,
    required this.isBusy,
    required this.onPickFile,
    required this.onClearFile,
    required this.onBindingChanged,
    required this.onSiteChanged,
    this.onConfigureManpowerMapping,
    this.onManpowerConfigChanged,
  });

  final ModuleDraft draft;
  final List<SiteModel> sites;
  final double progress;
  final bool isBusy;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;
  final ValueChanged<SiteBindingMode> onBindingChanged;
  final ValueChanged<String?> onSiteChanged;
  final VoidCallback? onConfigureManpowerMapping;
  final ValueChanged<String?>? onManpowerConfigChanged;

  @override
  Widget build(BuildContext context) {
    if (draft.errorMessage != null && draft.errorMessage!.isNotEmpty) {
      debugPrint(
        '[AutomatedEntry][${draft.module.moduleId}] ${draft.errorMessage}',
      );
    }

    final statusColor = _statusColor(context, draft.runState);
    final borderColor = statusColor.withOpacity(0.34);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.95),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ModuleBadge(module: draft.module),
                const Spacer(),
                _StatusPill(state: draft.runState),
              ],
            ),
            const SizedBox(height: 14),
            _UploadBox(
              fileName: draft.fileName,
              isBusy: isBusy,
              onPickFile: onPickFile,
              onClearFile: onClearFile,
            ),
            if (draft.module.canUseUploadedSite) ...[
              const SizedBox(height: 14),
              SegmentedButton<SiteBindingMode>(
                segments: const [
                  ButtonSegment(
                    value: SiteBindingMode.uploadedInThisFlow,
                    label: Text('Use New Site'),
                    icon: Icon(Icons.bolt),
                  ),
                  ButtonSegment(
                    value: SiteBindingMode.existingSite,
                    label: Text('Use Existing Site'),
                    icon: Icon(Icons.domain),
                  ),
                ],
                selected: {draft.siteBindingMode},
                onSelectionChanged: (selection) {
                  onBindingChanged(selection.first);
                },
              ),
              if (draft.siteBindingMode == SiteBindingMode.existingSite) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: draft.selectedExistingSiteId,
                  items: sites
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(
                            s.siteName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isBusy ? null : onSiteChanged,
                  decoration: const InputDecoration(
                    labelText: 'Target Site',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
            if (draft.module == AutomatedEntryModule.manpower) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1E4FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_tree_outlined,
                          color: Color(0xFF2056A8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Column Mapping',
                          style: TextStyle(
                            color: Color(0xFF123D7A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (draft.manpowerPreviewLoading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          _MappingPill(
                            text: draft.hasReadyManpowerMapping
                                ? 'Ready'
                                : 'Needs action',
                            color: draft.hasReadyManpowerMapping
                                ? Colors.green
                                : Colors.orange,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MappingPill(
                          text: '${draft.manpowerCsvColumns.length} columns',
                          color: Colors.indigo,
                        ),
                        _MappingPill(
                          text: '${draft.autoMappingCoverageCount} mapped',
                          color: Colors.blue,
                        ),
                        _MappingPill(
                          text: draft.isFullNameMapped
                              ? 'Full Name mapped'
                              : 'Full Name missing',
                          color: draft.isFullNameMapped
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    if (draft.manpowerSavedConfigs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: draft.selectedManpowerConfigId,
                        decoration: const InputDecoration(
                          labelText: 'Saved Mapping Profile',
                          border: OutlineInputBorder(),
                        ),
                        items: draft.manpowerSavedConfigs
                            .map(
                              (config) => DropdownMenuItem<String>(
                                value: config.id,
                                child: Text(
                                  config.configurationName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: isBusy ? null : onManpowerConfigChanged,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onConfigureManpowerMapping,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Configure Mapping'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (draft.errorMessage != null &&
                draft.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                draft.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isBusy || progress > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress == 0 ? null : progress,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, ModuleRunState state) {
    switch (state) {
      case ModuleRunState.success:
        return Colors.green;
      case ModuleRunState.failed:
        return Theme.of(context).colorScheme.error;
      case ModuleRunState.running:
      case ModuleRunState.queued:
        return Colors.blue;
      case ModuleRunState.waiting:
      case ModuleRunState.blocked:
        return Colors.orange;
      case ModuleRunState.idle:
      case ModuleRunState.ready:
        return Colors.grey.shade500;
    }
  }
}

class _MappingPill extends StatelessWidget {
  const _MappingPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.module});

  final AutomatedEntryModule module;

  @override
  Widget build(BuildContext context) {
    final icon = switch (module) {
      AutomatedEntryModule.site => Icons.apartment_rounded,
      AutomatedEntryModule.rate => Icons.currency_rupee_rounded,
      AutomatedEntryModule.manpower => Icons.groups_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECF5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0A4EAD)),
          const SizedBox(width: 6),
          Text(
            module.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A4EAD),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state});

  final ModuleRunState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      ModuleRunState.success => ('Done', Colors.green),
      ModuleRunState.failed => ('Failed', Theme.of(context).colorScheme.error),
      ModuleRunState.running => ('Running', Colors.blue),
      ModuleRunState.queued => ('Queued', Colors.blueGrey),
      ModuleRunState.waiting => ('Waiting', Colors.orange),
      ModuleRunState.blocked => ('Blocked', Colors.deepOrange),
      ModuleRunState.ready => ('Ready', Colors.teal),
      ModuleRunState.idle => ('Draft', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.fileName,
    required this.isBusy,
    required this.onPickFile,
    required this.onClearFile,
  });

  final String? fileName;
  final bool isBusy;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5E4FF), width: 1.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.file_present_rounded, color: Color(0xFF29579B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? 'No file selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fileName == null
                      ? Colors.grey.shade700
                      : const Color(0xFF143A79),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: isBusy ? null : onPickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(fileName == null ? 'Choose' : 'Change'),
            ),
            if (fileName != null)
              IconButton(
                onPressed: isBusy ? null : onClearFile,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
