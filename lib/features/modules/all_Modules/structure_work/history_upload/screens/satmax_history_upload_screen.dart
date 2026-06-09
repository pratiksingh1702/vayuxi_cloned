import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/history_upload/repository/satmax_history_repository.dart';
import 'package:untitled2/features/profile_page/provider/userProvider.dart';

class SatmaxHistoryUploadScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const SatmaxHistoryUploadScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<SatmaxHistoryUploadScreen> createState() =>
      _SatmaxHistoryUploadScreenState();
}

class _SatmaxHistoryUploadScreenState
    extends ConsumerState<SatmaxHistoryUploadScreen> {
  final SatmaxHistoryRepository _repository = SatmaxHistoryRepository();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  List<SatmaxHistoryRecord> _history = [];

  bool get _isSatmaxUser {
    final phone = ref.watch(currentUserProvider)?.phoneNumber;
    return phone?.replaceAll(RegExp(r'\D'), '') == '9509852652';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSatmaxUser) _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _repository.getHistory(widget.siteId);
      if (!mounted) return;
      setState(() => _history = history);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPickedFile(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final upload = await _repository.uploadHistory(widget.siteId, file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'History uploaded: ${upload.importedRows} rows imported',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showUploadSheet() async {
    PlatformFile? pickedFile;
    int step = 0;

    final file = await showModalBottomSheet<PlatformFile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['xlsx', 'xls'],
                withData: true,
              );
              final file = result?.files.single;
              if (file == null) return;
              setSheetState(() {
                pickedFile = file;
                step = 1;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload History',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the Date & Mark No wise Excel file, review it, then confirm upload.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 18),
                  _HistoryUploadSteps(currentStep: step),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: pickFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: pickedFile == null
                            ? scheme.surfaceContainerHighest
                            : scheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pickedFile == null
                              ? scheme.outlineVariant
                              : scheme.primary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedFile == null
                                ? Icons.upload_file_rounded
                                : Icons.check_circle_rounded,
                            color: pickedFile == null
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedFile?.name ?? 'Choose Excel file',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  pickedFile == null
                                      ? 'Supported: .xlsx, .xls'
                                      : '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (pickedFile != null) ...[
                    const SizedBox(height: 12),
                    _HistoryReviewBox(file: pickedFile!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: pickedFile == null
                          ? null
                          : () {
                              setSheetState(() => step = 2);
                              Navigator.of(sheetContext).pop(pickedFile);
                            },
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        pickedFile == null
                            ? 'Select File First'
                            : 'Confirm & Upload History',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (file != null) {
      await _uploadPickedFile(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_isSatmaxUser) {
      return Scaffold(
        appBar: CustomAppBar(title: 'History Upload'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'History upload is available only for the Satmax user.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'History Upload'),
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showUploadSheet,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(_isUploading ? 'Uploading' : 'Upload Excel'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _HeaderCard(siteName: widget.siteName),
            const SizedBox(height: 16),
            if (_error != null) _ErrorCard(message: _error!),
            if (_error != null) const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_history.isEmpty)
              const _EmptyHistoryCard()
            else
              ..._history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    item: item,
                    dateFormat: _dateFormat,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String siteName;

  const _HeaderCard({required this.siteName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_edu_rounded,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satmax History Upload',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  siteName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryUploadSteps extends StatelessWidget {
  final int currentStep;

  const _HistoryUploadSteps({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const steps = ['Select File', 'Review', 'Upload'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: lineIndex < currentStep
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 18 : 9,
                color: isDone || isActive
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 72,
              child: Text(
                steps[stepIndex],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HistoryReviewBox extends StatelessWidget {
  final PlatformFile file;

  const _HistoryReviewBox({required this.file});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ready for history validation',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The selected file will use the existing Satmax history upload process. Imported rows will be visible in history and linked reports as before.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          _HistoryReviewRow(label: 'File', value: file.name),
          _HistoryReviewRow(
            label: 'Size',
            value: '${(file.size / 1024).toStringAsFixed(1)} KB',
          ),
          _HistoryReviewRow(
            label: 'Format',
            value: file.extension?.toUpperCase() ?? 'Excel',
          ),
        ],
      ),
    );
  }
}

class _HistoryReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryReviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SatmaxHistoryRecord item;
  final DateFormat dateFormat;

  const _HistoryCard({
    required this.item,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Rows', value: item.importedRows.toString()),
              _MetricChip(label: 'Skipped', value: item.skippedRows.toString()),
              _MetricChip(
                label: 'Qty',
                value: item.totalQuantity.toStringAsFixed(0),
              ),
              _MetricChip(
                label: 'MT',
                value: item.totalNetWeightMT.toStringAsFixed(3),
              ),
            ],
          ),
          if (item.uploadedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              dateFormat.format(item.uploadedAt!.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.upload_file_rounded,
            size: 42,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No history uploaded yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload the Date & Mark No wise Excel file to make old data available in Satmax reports.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
