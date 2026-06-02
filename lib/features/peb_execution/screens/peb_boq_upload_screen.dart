import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
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
  _BoqScreenMode _mode = _BoqScreenMode.home;

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
      if (mounted) setState(() => _mode = _BoqScreenMode.view);
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
      showDragHandle: true,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: _service.getBoqItems(widget.siteId, boq.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          final cs = Theme.of(context).colorScheme;
          final totalQty = items.fold<double>(0, (sum, raw) {
            final item = raw is Map ? raw : {};
            final value = item['quantity'];
            return sum + (value is num ? value.toDouble() : 0);
          });
          final totalWeight = items.fold<double>(0, (sum, raw) {
            final item = raw is Map ? raw : {};
            final value = item['totalNetWeight'];
            return sum + (value is num ? value.toDouble() : 0);
          });
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.86,
            maxChildSize: 0.95,
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
                            boq.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            boq.number.isEmpty
                                ? widget.siteName
                                : '${widget.siteName} • ${boq.number}',
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text('No BOQ items found',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child:
                            _summaryTile(cs, 'Items', items.length.toString()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryTile(
                            cs, 'Quantity', _prettyNumber(totalQty)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryTile(
                            cs, 'Weight', _prettyNumber(totalWeight)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BOQ Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.take(200).map((raw) {
                    final item = raw is Map ? raw : {};
                    final assemblyMark =
                        item['assemblyMark']?.toString() ?? '-';
                    final description =
                        item['typeDescription']?.toString() ?? '-';
                    final detailedMark = item['detailedMark']?.toString() ?? '';
                    final qty = item['quantity'];
                    final weight = item['totalNetWeight'];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.account_tree_outlined,
                            color: cs.primary),
                        title: Text(
                          assemblyMark,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          detailedMark.isEmpty
                              ? description
                              : '$description\n$detailedMark',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        isThreeLine: detailedMark.isNotEmpty,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Qty ${qty ?? '-'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            if (weight is num && weight > 0)
                              Text(
                                _prettyNumber(weight.toDouble()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (items.length > 200)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Showing first 200 items',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
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
    final titleSuffix = switch (_mode) {
      _BoqScreenMode.home => 'BOQ Setup',
      _BoqScreenMode.view => 'View BOQ',
      _BoqScreenMode.addChoice => 'Add BOQ',
      _BoqScreenMode.manual => 'Manual BOQ',
      _BoqScreenMode.upload => 'Upload BOQ',
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
                    if (_mode != _BoqScreenMode.home)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _mode = _mode == _BoqScreenMode.manual ||
                                    _mode == _BoqScreenMode.upload
                                ? _BoqScreenMode.addChoice
                                : _BoqScreenMode.home;
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
      case _BoqScreenMode.home:
        return [_homeOptions(cs)];
      case _BoqScreenMode.view:
        return [_existingBoqs(cs)];
      case _BoqScreenMode.addChoice:
        return [_addOptions(cs)];
      case _BoqScreenMode.manual:
        return [_manualCard(cs)];
      case _BoqScreenMode.upload:
        return [_uploadCard(cs)];
    }
  }

  Widget _homeOptions(ColorScheme cs) {
    return Column(
      children: [
        _selectCardGrid(
          firstIcon: Icons.visibility_rounded,
          firstColor: Colors.blue,
          firstLabel: 'View',
          firstTap: () => setState(() => _mode = _BoqScreenMode.view),
          secondIcon: Icons.add_circle_outline_rounded,
          secondColor: Colors.green,
          secondLabel: 'add',
          secondTap: () => setState(() => _mode = _BoqScreenMode.addChoice),
        ),
        const SizedBox(height: 16),
        _infoCard(
          cs,
          'Choose an option',
          '• View: You can view, edit and delete existing BOQs.\n'
              '• Add: You can create a BOQ manually or upload an Excel file.',
        ),
      ],
    );
  }

  Widget _addOptions(ColorScheme cs) {
    return Column(
      children: [
        _selectCardGrid(
          firstIcon: Icons.edit_note_rounded,
          firstColor: Colors.blue,
          firstLabel: 'Manual',
          firstTap: () => setState(() => _mode = _BoqScreenMode.manual),
          secondIcon: Icons.upload_file_rounded,
          secondColor: Colors.green,
          secondLabel: 'Upload',
          secondTap: () => setState(() => _mode = _BoqScreenMode.upload),
        ),
        const SizedBox(height: 16),
        _infoCard(
          cs,
          'Choose an option',
          '• Manual: Add BOQ rows directly from the app.\n'
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
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? cs.shadow.withOpacity(0.12)
                : cs.shadow.withOpacity(0.06),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Existing BOQs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (_boqs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No BOQ uploaded yet',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          )
        else
          ..._boqs.map((boq) => Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  onTap: () => _viewBoq(boq),
                  leading: Icon(Icons.description_outlined, color: cs.primary),
                  title: Text(
                    boq.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    boq.number.isEmpty
                        ? '${boq.items.length} items'
                        : '${boq.items.length} items • ${boq.number}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.visibility_outlined, color: cs.tertiary),
                        onPressed: () => _viewBoq(boq),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: cs.error),
                        onPressed: _saving ? null : () => _deleteBoq(boq),
                      ),
                    ],
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

enum _BoqScreenMode { home, view, addChoice, manual, upload }

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
