import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';

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
  String _quantityType = 'exact';
  PebBoq? _editingBoq;
  _BoqMarkRecord? _editingMark;
  _BoqScreenMode _mode = _BoqScreenMode.view;

  List<_BoqMarkRecord> get _allMarks {
    final records = <_BoqMarkRecord>[];
    for (final boq in _boqs) {
      for (final mark in boq.items) {
        records.add(_BoqMarkRecord(boq: boq, mark: mark));
      }
    }
    return records;
  }

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
        quantityType: _quantityType,
      );
      setState(() => _step = 3);
      await _loadBoqs();
      if (mounted) setState(() => _mode = _BoqScreenMode.view);
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
        quantityType: _quantityType,
      );
      setState(() => _resetManualForm());
      await _loadBoqs();
      if (mounted) setState(() => _mode = _BoqScreenMode.view);
      AppToast.success('Manual BOQ created');
    } catch (_) {
      AppToast.error('Failed to create manual BOQ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEditedBoq() async {
    final boq = _editingBoq;
    final editingMark = _editingMark;
    if (boq == null || editingMark == null) return;
    final item = _manualRows.first.toJson();
    if (_manualName.text.trim().isEmpty ||
        item['assemblyMark'].toString().isEmpty ||
        ((item['quantity'] as num?) ?? 0) <= 0) {
      AppToast.error('BOQ name and mark details are required');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.updateBoqItem(
        widget.siteId,
        boq.id,
        editingMark.mark.id,
        item: item,
      );
      _editingBoq = null;
      _editingMark = null;
      _resetManualForm();
      await _loadBoqs();
      if (mounted) setState(() => _mode = _BoqScreenMode.view);
      AppToast.success('BOQ mark updated successfully');
    } catch (_) {
      AppToast.error('Failed to update BOQ mark');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editMark(_BoqMarkRecord record) {
    _resetManualForm(addBlank: false);
    _manualName.text = record.boq.name;
    _quantityType = record.boq.quantityType;
    _manualRows.add(_ManualBoqRow.fromMark(record.mark));
    _editingBoq = record.boq;
    _editingMark = record;
    setState(() => _mode = _BoqScreenMode.edit);
  }

  void _startManualAdd() {
    _editingBoq = null;
    _editingMark = null;
    _resetManualForm();
    _quantityType = 'exact';
    setState(() => _mode = _BoqScreenMode.manual);
  }

  void _resetManualForm({bool addBlank = true}) {
    _manualName.clear();
    for (final row in _manualRows) {
      row.dispose();
    }
    _manualRows.clear();
    if (addBlank) _manualRows.add(_ManualBoqRow());
  }

  Future<void> _deleteMark(_BoqMarkRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete BOQ mark?'),
        content: Text('Delete ${record.mark.assemblyMark}?'),
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
      if (record.boq.items.length <= 1) {
        await _service.deleteBoq(widget.siteId, record.boq.id);
      } else {
        await _service.deleteBoqItem(
          widget.siteId,
          record.boq.id,
          record.mark.id,
        );
      }
      await _loadBoqs();
      AppToast.success('BOQ mark deleted');
    } catch (_) {
      AppToast.error('Failed to delete BOQ mark');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewMark(_BoqMarkRecord record) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final mark = record.mark;
        final cs = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          maxChildSize: 0.85,
          minChildSize: 0.55,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description_outlined,
                        color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mark.assemblyMark,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.boq.name} • ${widget.siteName}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                        cs, 'Quantity', _prettyNumber(mark.quantity)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryTile(
                        cs, 'Remaining', _prettyNumber(mark.remainingQty)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryTile(
                        cs, 'Weight', _prettyNumber(mark.totalNetWeight)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(cs, 'BOQ', record.boq.name),
              _detailRow(cs, 'Description', mark.typeDescription),
              _detailRow(cs, 'Detailed Mark', mark.detailedMark),
              _detailRow(cs, 'Length', _prettyNumber(mark.length)),
              _detailRow(cs, 'Width', _prettyNumber(mark.width)),
              _detailRow(cs, 'Height', _prettyNumber(mark.height)),
              _detailRow(cs, 'Net Weight / Unit',
                  _prettyNumber(mark.netWeightPerUnit)),
              _detailRow(cs, 'Status', mark.status),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        _editMark(record);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        _deleteMark(record);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleSuffix = switch (_mode) {
      _BoqScreenMode.view => 'BOQ Marks',
      _BoqScreenMode.addChoice => 'Add BOQ',
      _BoqScreenMode.manual => 'Manual BOQ',
      _BoqScreenMode.upload => 'Upload BOQ',
      _BoqScreenMode.edit => 'Edit BOQ Mark',
    };
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: cs.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          CustomSliverAppBar(
              title: '${widget.executionType.title} $titleSuffix'),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBoqs,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_mode != _BoqScreenMode.view)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            if (_mode == _BoqScreenMode.manual ||
                                _mode == _BoqScreenMode.upload) {
                              _mode = _BoqScreenMode.addChoice;
                            } else {
                              _mode = _BoqScreenMode.view;
                            }
                          }),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                    Text(widget.siteName,
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    ..._bodyByMode(cs),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _bodyByMode(ColorScheme cs) {
    switch (_mode) {
      case _BoqScreenMode.view:
        return [_existingBoqs(cs)];
      case _BoqScreenMode.addChoice:
        return [_addOptions(cs)];
      case _BoqScreenMode.manual:
        return [_manualCard(cs)];
      case _BoqScreenMode.upload:
        return [_uploadCard(cs)];
      case _BoqScreenMode.edit:
        return [_manualCard(cs, editing: true)];
    }
  }

  Widget _addOptions(ColorScheme cs) {
    return Column(
      children: [
        _selectCardGrid(
          firstIcon: Icons.edit_note_rounded,
          firstColor: Colors.blue,
          firstLabel: 'Manual Entry',
          firstTap: _startManualAdd,
          secondIcon: Icons.upload_file_rounded,
          secondColor: Colors.deepOrange,
          secondLabel: 'Import Sheet',
          secondTap: () => setState(() => _mode = _BoqScreenMode.upload),
        ),
        const SizedBox(height: 16),
        _infoCard(
          cs,
          'Choose an option',
          '• Manual: Add one BOQ mark directly from the app.\n'
              '• Upload: Upload an Excel file and map the columns.',
        ),
      ],
    );
  }

  Widget _selectCardGrid({
    required IconData firstIcon,
    required Color firstColor,
    required String firstLabel,
    required VoidCallback firstTap,
    required IconData secondIcon,
    required Color secondColor,
    required String secondLabel,
    required VoidCallback secondTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
        children: [
          SelectCard(
            icon: SelectCardIcon(icon: firstIcon, color: firstColor),
            label: firstLabel,
            onTap: firstTap,
          ),
          SelectCard(
            icon: SelectCardIcon(icon: secondIcon, color: secondColor),
            label: secondLabel,
            onTap: secondTap,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ColorScheme cs, String title, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? cs.shadow.withValues(alpha: 0.12)
                : cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _existingBoqs(ColorScheme cs) {
    final marks = _allMarks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('BOQ Mark Numbers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () => setState(() => _mode = _BoqScreenMode.addChoice),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add BOQ'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (marks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('No BOQ mark numbers found',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _mode = _BoqScreenMode.addChoice),
                    icon: const Icon(Icons.add),
                    label: const Text('Add BOQ'),
                  ),
                ],
              ),
            ),
          )
        else
          ...marks.map((record) => Card(
                elevation: 0,
                color: cs.surface,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _viewMark(record),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.mark.assemblyMark,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (record.mark.typeDescription.isNotEmpty)
                                    record.mark.typeDescription,
                                  record.boq.name,
                                  record.boq.quantityType == 'approximate'
                                      ? 'Approximate BOQ'
                                      : 'Exact BOQ',
                                ].join(' • '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View',
                              icon: Icon(Icons.visibility_outlined,
                                  color: cs.tertiary),
                              onPressed: () => _viewMark(record),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon:
                                  Icon(Icons.edit_outlined, color: cs.primary),
                              onPressed:
                                  _saving ? null : () => _editMark(record),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: Icon(Icons.delete_outline, color: cs.error),
                              onPressed:
                                  _saving ? null : () => _deleteMark(record),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _summaryTile(ColorScheme cs, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  String _prettyNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Widget _detailRow(ColorScheme cs, String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          _quantityTypeSelector(cs),
          const SizedBox(height: 16),
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
              initialValue:
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

  Widget _manualCard(ColorScheme cs, {bool editing = false}) {
    return _card(
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(editing ? 'Edit BOQ Mark' : 'Manual BOQ Mark Entry',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'BOQ Name',
            controller: _manualName,
            isRequired: true,
          ),
          if (!editing) ...[
            const SizedBox(height: 4),
            _quantityTypeSelector(cs),
            const SizedBox(height: 8),
          ],
          ..._manualRows.asMap().entries.map((entry) {
            return _manualRow(entry.key, entry.value, cs);
          }),
          const SizedBox(height: 12),
          RoundedButton(
            text: editing
                ? (_saving ? 'Updating...' : 'Update Mark')
                : (_saving ? 'Saving...' : 'Save BOQ Mark'),
            color: cs.primary,
            textColor: cs.onPrimary,
            isLoading: _saving,
            width: double.infinity,
            onPressed: editing ? _saveEditedBoq : _createManualBoq,
          ),
        ],
      ),
    );
  }

  Widget _quantityTypeSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOQ Quantity Type',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'exact',
                icon: Icon(Icons.lock_outline),
                label: Text('Exact'),
              ),
              ButtonSegment(
                value: 'approximate',
                icon: Icon(Icons.swap_vert_circle_outlined),
                label: Text('Approximate'),
              ),
            ],
            selected: {_quantityType},
            onSelectionChanged: _saving
                ? null
                : (selection) =>
                    setState(() => _quantityType = selection.first),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _quantityType == 'approximate'
              ? 'Execution may exceed this BOQ after a variation reason is provided.'
              : 'Execution cannot exceed the approved BOQ quantity.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _manualRow(int index, _ManualBoqRow row, ColorScheme cs) {
    return Column(
      children: [
        CustomTextField(
          label: 'Assembly Mark',
          controller: row.mark,
          isRequired: true,
        ),
        CustomTextField(
          label: 'Type / Description',
          controller: row.description,
        ),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Qty',
                controller: row.qty,
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                label: 'L(m)',
                controller: row.length,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        CustomTextField(
          label: 'Net Weight / Unit',
          controller: row.weight,
          keyboardType: TextInputType.number,
        ),
        if (_manualRows.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                row.dispose();
                setState(() => _manualRows.removeAt(index));
              },
              icon: const Icon(Icons.close),
              label: const Text('Remove'),
            ),
          ),
      ],
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

enum _BoqScreenMode { view, addChoice, manual, upload, edit }

class _BoqMarkRecord {
  final PebBoq boq;
  final PebBoqMark mark;

  const _BoqMarkRecord({
    required this.boq,
    required this.mark,
  });
}

class _ManualBoqRow {
  final String? itemId;
  final mark = TextEditingController();
  final description = TextEditingController();
  final qty = TextEditingController();
  final length = TextEditingController();
  final weight = TextEditingController();

  _ManualBoqRow({this.itemId});

  factory _ManualBoqRow.fromMark(PebBoqMark mark) {
    final row = _ManualBoqRow(itemId: mark.id);
    row.mark.text = mark.assemblyMark;
    row.description.text = mark.typeDescription;
    row.qty.text = mark.quantity == mark.quantity.roundToDouble()
        ? mark.quantity.toStringAsFixed(0)
        : mark.quantity.toString();
    row.length.text = mark.length == mark.length.roundToDouble()
        ? mark.length.toStringAsFixed(0)
        : mark.length.toString();
    row.weight.text =
        mark.netWeightPerUnit == mark.netWeightPerUnit.roundToDouble()
            ? mark.netWeightPerUnit.toStringAsFixed(0)
            : mark.netWeightPerUnit.toString();
    return row;
  }

  Map<String, dynamic> toJson() => {
        if (itemId != null && itemId!.isNotEmpty) '_id': itemId,
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
