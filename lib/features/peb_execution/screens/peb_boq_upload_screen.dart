import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';

import '../models/peb_execution_models.dart';
import '../services/peb_execution_service.dart';

class PebBoqUploadScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final PebExecutionType executionType;

  const PebBoqUploadScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
  });

  @override
  State<PebBoqUploadScreen> createState() => _PebBoqUploadScreenState();
}

class _PebBoqUploadScreenState extends State<PebBoqUploadScreen> {
  final _service = PebExecutionService();
  final _manualName = TextEditingController();
  final List<_ManualBoqRow> _manualRows = [_ManualBoqRow()];
  List<PebBoq> _boqs = [];
  List<String> _csvColumns = [];
  List<Map<String, dynamic>> _modelFields = [];
  List<Map<String, dynamic>> _preview = [];
  final Map<String, String> _mappings = {};
  PlatformFile? _file;
  int _step = 1;
  bool _loading = true;
  bool _saving = false;
  bool _isStandardTemplate = false;

  @override
  void initState() {
    super.initState();
    _loadBoqs();
  }

  @override
  void dispose() {
    _manualName.dispose();
    for (final row in _manualRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBoqs() async {
    setState(() => _loading = true);
    try {
      _boqs = await _service.getBoqs(widget.siteId);
    } catch (_) {
      AppToast.error('Failed to load BOQ list');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: false,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.path == null) {
      AppToast.error('Selected file is not available');
      return;
    }
    setState(() {
      _file = file;
      _step = 1;
      _csvColumns = [];
      _modelFields = [];
      _preview = [];
      _mappings.clear();
    });
  }

  Future<void> _previewUpload() async {
    if (_file == null) {
      AppToast.error('Please select an Excel file');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await _service.previewBoqUpload(widget.siteId, _file!);
      _csvColumns = (data['csvColumns'] as List? ?? [])
          .map((item) => item.toString())
          .toList();
      _modelFields = (data['modelFields'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _preview = (data['preview'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _isStandardTemplate = data['isStandardTemplate'] == true;
      _mappings.clear();
      for (final raw in (data['suggestedMappings'] as List? ?? [])) {
        if (raw is! Map) continue;
        final csvColumn = raw['csvColumn']?.toString() ?? '';
        final modelField = raw['modelField']?.toString() ?? '';
        if (csvColumn.isNotEmpty && modelField.isNotEmpty) {
          _mappings[csvColumn] = modelField;
        }
      }
      setState(() => _step = 2);
      AppToast.success('BOQ analyzed. Review the mapping.');
    } catch (error) {
      AppToast.error('Failed to analyze BOQ file');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _importUpload({bool skipMapping = false}) async {
    if (_file == null) return;
    setState(() => _saving = true);
    try {
      final mappings = _mappings.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => {
                'csvColumn': entry.key,
                'modelField': entry.value,
              })
          .toList();
      await _service.importBoqUpload(
        widget.siteId,
        _file!,
        mappings: mappings,
        skipMapping: skipMapping,
        isStandardTemplate: _isStandardTemplate,
      );
      setState(() => _step = 3);
      await _loadBoqs();
      AppToast.success('BOQ imported successfully');
    } catch (_) {
      AppToast.error('Failed to import BOQ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createManualBoq() async {
    final items = _manualRows
        .map((row) => row.toJson())
        .where((item) =>
            item['assemblyMark'].toString().isNotEmpty &&
            ((item['quantity'] as num?) ?? 0) > 0)
        .toList();
    if (_manualName.text.trim().isEmpty || items.isEmpty) {
      AppToast.error('BOQ name and at least one valid item are required');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createManualBoq(
        widget.siteId,
        widget.executionType,
        boqName: _manualName.text.trim(),
        items: items,
      );
      _manualName.clear();
      setState(() {
        for (final row in _manualRows) {
          row.dispose();
        }
        _manualRows
          ..clear()
          ..add(_ManualBoqRow());
      });
      await _loadBoqs();
      AppToast.success('Manual BOQ created');
    } catch (_) {
      AppToast.error('Failed to create manual BOQ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBoq(PebBoq boq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete BOQ?'),
        content: Text('Delete ${boq.name}?'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _service.deleteBoq(widget.siteId, boq.id);
      await _loadBoqs();
      AppToast.success('BOQ deleted');
    } catch (_) {
      AppToast.error('Failed to delete BOQ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewBoq(PebBoq boq) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: _service.getBoqItems(widget.siteId, boq.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            builder: (context, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Text(boq.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (items.isEmpty)
                  const Center(child: Text('No BOQ items found'))
                else
                  ...items.take(150).map((raw) {
                    final item = raw is Map ? raw : {};
                    return ListTile(
                      dense: true,
                      title: Text(item['assemblyMark']?.toString() ?? '-'),
                      subtitle:
                          Text(item['typeDescription']?.toString() ?? '-'),
                      trailing: Text('Qty ${item['quantity'] ?? '-'}'),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: cs.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          CustomSliverAppBar(title: '${widget.executionType.title} BOQ'),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBoqs,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.siteName,
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _existingBoqs(cs),
                    const SizedBox(height: 16),
                    _uploadCard(cs),
                    const SizedBox(height: 16),
                    _manualCard(cs),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _existingBoqs(ColorScheme cs) {
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Existing BOQs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (_boqs.isEmpty)
            Text('No BOQ uploaded yet',
                style: TextStyle(color: cs.onSurfaceVariant))
          else
            ..._boqs.map((boq) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(boq.name),
                  subtitle: Text(boq.number.isEmpty
                      ? '${boq.items.length} items'
                      : '${boq.items.length} items • ${boq.number}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: () => _viewBoq(boq),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        onPressed: _saving ? null : () => _deleteBoq(boq),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _uploadCard(ColorScheme cs) {
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload BOQ File With Mapping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _stepper(cs),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_file?.name ?? 'Choose Excel File'),
          ),
          if (_step == 1) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _previewUpload,
              child: Text(_saving ? 'Analyzing...' : 'Analyze File'),
            ),
          ],
          if (_step >= 2) _mappingSection(cs),
          if (_step == 3)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('BOQ import completed successfully.'),
            ),
        ],
      ),
    );
  }

  Widget _mappingSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Column Mapping',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ..._csvColumns.map((column) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<String>(
              value:
                  _mappings[column]?.isEmpty == true ? null : _mappings[column],
              decoration: InputDecoration(labelText: column),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Skip this column')),
                ..._modelFields.map((field) => DropdownMenuItem(
                      value: field['field']?.toString() ?? '',
                      child: Text(field['label']?.toString() ??
                          field['field']?.toString() ??
                          ''),
                    )),
              ],
              onChanged: (value) =>
                  setState(() => _mappings[column] = value ?? ''),
            ),
          );
        }),
        if (_preview.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Preview (${_preview.length} rows)',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _saving ? null : () => _importUpload(skipMapping: true),
                child: const Text('Import Without Mapping'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _importUpload,
                child: Text(_saving ? 'Importing...' : 'Import BOQ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _manualCard(ColorScheme cs) {
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manual BOQ Entry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _manualName,
            decoration: const InputDecoration(labelText: 'BOQ Name'),
          ),
          const SizedBox(height: 12),
          ..._manualRows.asMap().entries.map((entry) {
            return _manualRow(entry.key, entry.value, cs);
          }),
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    setState(() => _manualRows.add(_ManualBoqRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add Row'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _createManualBoq,
                child: const Text('Save Manual BOQ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manualRow(int index, _ManualBoqRow row, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.mark,
                  decoration: const InputDecoration(labelText: 'Assembly Mark'),
                ),
              ),
              IconButton(
                onPressed: _manualRows.length == 1
                    ? null
                    : () {
                        row.dispose();
                        setState(() => _manualRows.removeAt(index));
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          TextField(
            controller: row.description,
            decoration: const InputDecoration(labelText: 'Type / Description'),
          ),
          Row(
            children: [
              Expanded(child: _smallField(row.qty, 'Qty')),
              const SizedBox(width: 8),
              Expanded(child: _smallField(row.length, 'L(m)')),
              const SizedBox(width: 8),
              Expanded(child: _smallField(row.weight, 'Net Wt/Unit')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _stepper(ColorScheme cs) {
    final labels = ['Upload File', 'Map Fields', 'Complete'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = _step >= index + 1;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active ? cs.primary : cs.surfaceContainerHigh,
                child: Text('${index + 1}',
                    style: TextStyle(
                        color: active ? cs.onPrimary : cs.onSurfaceVariant,
                        fontSize: 12)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(labels[index],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? cs.primary : cs.onSurfaceVariant)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _card(ColorScheme cs, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ManualBoqRow {
  final mark = TextEditingController();
  final description = TextEditingController();
  final qty = TextEditingController();
  final length = TextEditingController();
  final weight = TextEditingController();

  Map<String, dynamic> toJson() => {
        'assemblyMark': mark.text.trim(),
        'typeDescription': description.text.trim(),
        'quantity': num.tryParse(qty.text.trim()) ?? 0,
        'length': num.tryParse(length.text.trim()) ?? 0,
        'width': 0,
        'height': 0,
        'netWeightPerUnit': num.tryParse(weight.text.trim()) ?? 0,
      };

  void dispose() {
    mark.dispose();
    description.dispose();
    qty.dispose();
    length.dispose();
    weight.dispose();
  }
}
