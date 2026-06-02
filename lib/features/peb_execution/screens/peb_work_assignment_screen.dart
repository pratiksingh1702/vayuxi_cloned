import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import '../models/peb_execution_models.dart';
import '../services/peb_execution_service.dart';

class PebWorkAssignmentScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final PebExecutionType executionType;

  const PebWorkAssignmentScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
  });

  @override
  State<PebWorkAssignmentScreen> createState() =>
      _PebWorkAssignmentScreenState();
}

class _PebWorkAssignmentScreenState extends State<PebWorkAssignmentScreen> {
  final _service = PebExecutionService();
  final _remarksController = TextEditingController();
  final _manualMarksController = TextEditingController();
  final _qtyController = TextEditingController();
  final _markSearchController = TextEditingController();
  Timer? _markSearchDebounce;
  bool _loading = true;
  bool _saving = false;
  bool _showForm = false;
  bool _allowFallback = true;
  _WorkAssignmentMode _mode = _WorkAssignmentMode.home;
  String _teamId = '';
  String _setupItemId = '';
  String _sourceType = 'boq_upload';
  String _editingAssignmentId = '';
  DateTime _assignmentDate = DateTime.now();
  DateTime? _expectedDate;
  List<PebTeam> _teams = [];
  List<PebSetupItem> _setupItems = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  Set<String> _selectedMarks = {};
  Map<String, Set<String>> _completedBySetupItem = {};
  String _markSearchText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _manualMarksController.dispose();
    _qtyController.dispose();
    _markSearchController.dispose();
    _markSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getTeams(widget.siteId, widget.executionType),
        _service.getSetup(widget.siteId, widget.executionType),
        _service.getBoqs(widget.siteId),
        _service.getAssignments(widget.siteId, widget.executionType),
        _service.getDprMarkStatus(widget.siteId, widget.executionType),
      ]);
      final setup = results[1] as PebSetup?;
      setState(() {
        _teams = results[0] as List<PebTeam>;
        _setupItems = setup?.items ?? [];
        _allowFallback = setup?.allowUnassignedDprFallback ?? true;
        _boqs = results[2] as List<PebBoq>;
        _assignments = (results[3] as List<PebWorkAssignment>)
            .where((assignment) => assignment.status != 'cancelled')
            .toList();
        _completedBySetupItem = (results[4] as PebMarkStatus).completedByKey;
      });
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PebBoqMark> get _allMarks {
    return _boqs
        .expand((boq) => boq.items)
        .where((mark) => mark.assemblyMark.isNotEmpty)
        .toList();
  }

  Set<String> get _assignedMarksForStage {
    return _assignments
        .where((assignment) => assignment.id != _editingAssignmentId)
        .expand((assignment) => assignment.assignments)
        .where((item) => item.setupItemId == _setupItemId)
        .expand((item) => item.assemblyMarks)
        .toSet();
  }

  double _markQuantity(String assemblyMark) {
    return _allMarks
        .where((mark) => mark.assemblyMark == assemblyMark)
        .fold<double>(
            0,
            (sum, mark) =>
                sum +
                (mark.remainingQty > 0 ? mark.remainingQty : mark.quantity));
  }

  List<String> _parseManualMarks() {
    return _manualMarksController.text
        .split(RegExp(r'[\n,]'))
        .map((mark) => mark.trim())
        .where((mark) => mark.isNotEmpty)
        .toList();
  }

  Future<void> _pickDate({required bool expected}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate:
          expected ? (_expectedDate ?? _assignmentDate) : _assignmentDate,
    );
    if (picked == null) return;
    setState(() {
      if (expected) {
        _expectedDate = picked;
      } else {
        _assignmentDate = picked;
      }
    });
  }

  void _openNew(PebSetupItem item) {
    setState(() {
      _mode = _WorkAssignmentMode.add;
      _showForm = true;
      _editingAssignmentId = '';
      _setupItemId = item.id;
      _teamId = _teams.isNotEmpty ? _teams.first.id : '';
      _sourceType = _allMarks.isNotEmpty ? 'boq_upload' : 'tonnage';
      _selectedMarks = {};
      _markSearchText = '';
      _markSearchController.clear();
      _assignmentDate = DateTime.now();
      _expectedDate = null;
      _remarksController.clear();
      _manualMarksController.clear();
      _qtyController.clear();
    });
  }

  void _openEdit(PebWorkAssignment assignment) {
    if (assignment.assignments.isEmpty) return;
    final item = assignment.assignments.first;
    setState(() {
      _mode = _WorkAssignmentMode.add;
      _showForm = true;
      _editingAssignmentId = assignment.id;
      _setupItemId = item.setupItemId;
      _teamId = assignment.teamId;
      _sourceType = assignment.sourceType;
      _selectedMarks = item.assemblyMarks.toSet();
      _markSearchText = '';
      _markSearchController.clear();
      _assignmentDate = assignment.assignmentDate ?? DateTime.now();
      _expectedDate = assignment.expectedCompletionDate;
      _remarksController.text = item.remarks;
      _manualMarksController.text = item.assemblyMarks.join(', ');
      _qtyController.text = item.assignedQty.toStringAsFixed(
          item.assignedQty.truncateToDouble() == item.assignedQty ? 0 : 2);
    });
  }

  Future<void> _save({bool overrideConflict = false}) async {
    final setupItem = _findSetupItem(_setupItemId);
    if (setupItem == null) return;
    if (_teamId.isEmpty) {
      AppToast.error('Select team');
      return;
    }
    final marks = _sourceType == 'manual_boq'
        ? _parseManualMarks()
        : _sourceType == 'boq_upload'
            ? _selectedMarks.toList()
            : <String>[];
    final qty = _sourceType == 'tonnage'
        ? double.tryParse(_qtyController.text.trim()) ?? 0
        : marks.fold<double>(0, (sum, mark) => sum + _markQuantity(mark));
    final assignedQty = qty > 0 ? qty : marks.length.toDouble();
    if (assignedQty <= 0) {
      AppToast.error(_sourceType == 'tonnage'
          ? 'Enter quantity'
          : 'Select at least one mark');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveAssignment(
        widget.siteId,
        widget.executionType,
        assignmentId: _editingAssignmentId,
        teamId: _teamId,
        sourceType: _sourceType,
        assignmentDate: _assignmentDate,
        expectedCompletionDate: _expectedDate,
        boqIds: _sourceType == 'boq_upload'
            ? _boqs.map((boq) => boq.id).toList()
            : const [],
        overrideConflict: overrideConflict,
        item: PebAssignmentItem(
          setupItemId: setupItem.id,
          stageName: setupItem.name,
          assemblyMarks: marks,
          assignedQty: assignedQty,
          uom: setupItem.uom,
          remarks: _remarksController.text.trim(),
        ),
      );
      AppToast.success(_editingAssignmentId.isEmpty
          ? 'Work assignment saved'
          : 'Work assignment updated');
      setState(() {
        _showForm = false;
        _mode = _WorkAssignmentMode.view;
      });
      await _load();
    } on PebExecutionConflict catch (conflict) {
      _showConflictDialog(conflict.conflicts);
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showConflictDialog(List<dynamic> conflicts) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potential schedule conflict'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'The selected items already have planned activities during this period.'),
              const SizedBox(height: 12),
              ...conflicts.take(4).map((conflict) =>
                  Text('• ${conflict['existingStage'] ?? 'Existing stage'}')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(), child: const Text('Modify')),
          FilledButton(
            onPressed: () {
              context.pop();
              _save(overrideConflict: true);
            },
            child: const Text('Override'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(PebWorkAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete assignment'),
        content: Text(
            'Delete assignment for ${assignment.team?.name ?? 'this team'}?'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAssignment(widget.siteId, assignment.id);
      AppToast.success('Assignment deleted');
      await _load();
    } catch (error) {
      AppToast.error(extractBackendError(error));
    }
  }

  Future<void> _toggleFallback(bool value) async {
    setState(() => _allowFallback = value);
    try {
      await _service.updateFallbackSetting(
          widget.siteId, widget.executionType, value);
      AppToast.success('DPR fallback setting updated');
    } catch (error) {
      setState(() => _allowFallback = !value);
      AppToast.error(extractBackendError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleSuffix = switch (_mode) {
      _WorkAssignmentMode.home => 'Assignment',
      _WorkAssignmentMode.view => 'Assignment View',
      _WorkAssignmentMode.add => 'Assignment Add',
    };
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: '${widget.executionType.title} $titleSuffix'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_mode != _WorkAssignmentMode.home)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          if (_mode == _WorkAssignmentMode.add && _showForm) {
                            _showForm = false;
                          } else {
                            _mode = _WorkAssignmentMode.home;
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
                ],
              ),
            ),
    );
  }

  List<Widget> _bodyByMode(ColorScheme cs) {
    switch (_mode) {
      case _WorkAssignmentMode.home:
        return [_homeOptions(cs)];
      case _WorkAssignmentMode.view:
        return [_buildAssignmentList(cs), const SizedBox(height: 80)];
      case _WorkAssignmentMode.add:
        return [
          _buildTopControls(cs),
          const SizedBox(height: 16),
          if (_showForm) _buildForm(cs) else _buildStageGrid(cs),
          const SizedBox(height: 80),
        ];
    }
  }

  Widget _homeOptions(ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _optionCard(
                cs,
                icon: Icons.visibility_outlined,
                title: 'View',
                subtitle: 'View, edit and delete assigned work records',
                onTap: () => setState(() => _mode = _WorkAssignmentMode.view),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _optionCard(
                cs,
                icon: Icons.add_circle_outline,
                title: 'Add',
                subtitle: 'Assign stage work to teams',
                onTap: () => setState(() {
                  _mode = _WorkAssignmentMode.add;
                  _showForm = false;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_ind_outlined),
            title: Text(
              '${_assignments.length} assigned work record${_assignments.length == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle:
                const Text('Select View to inspect existing assignments.'),
          ),
        ),
      ],
    );
  }

  Widget _optionCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(ColorScheme cs) {
    return Card(
      child: SwitchListTile(
        value: _allowFallback,
        onChanged: _toggleFallback,
        title:
            const Text('Show incomplete materials when no assignment exists'),
        subtitle: const Text(
            'Teams with no assignment history can enter DPR for pending BOQ members.'),
      ),
    );
  }

  Widget _buildStageGrid(ColorScheme cs) {
    if (_setupItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No DPR setup stages found. Create DPR setup first.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Stage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._setupItems.map((item) {
          final count = _assignments
              .where((assignment) => assignment.assignments
                  .any((work) => work.setupItemId == item.id))
              .length;
          return Card(
            child: ListTile(
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(count == 0
                  ? 'No assignment created'
                  : '$count assignment${count == 1 ? '' : 's'} created'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openNew(item),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildForm(ColorScheme cs) {
    final setupItem = _findSetupItem(_setupItemId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    setupItem?.name ?? 'Assignment',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                    onPressed: () => setState(() => _showForm = false),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Team',
              value: _teamId,
              items: _teams
                  .map((team) =>
                      DropdownMenuItem(value: team.id, child: Text(team.name)))
                  .toList(),
              onChanged: (value) => setState(() => _teamId = value ?? ''),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildDateTile('Assignment Date', _assignmentDate,
                        () => _pickDate(expected: false))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDateTile('Expected Completion', _expectedDate,
                        () => _pickDate(expected: true))),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Scope Method',
              value: _sourceType,
              items: const [
                DropdownMenuItem(value: 'boq_upload', child: Text('BOQ Marks')),
                DropdownMenuItem(
                    value: 'manual_boq', child: Text('Manual Mark Numbers')),
                DropdownMenuItem(
                    value: 'tonnage', child: Text('Tonnage / Quantity')),
              ],
              onChanged: (value) => setState(() {
                _sourceType = value ?? 'boq_upload';
                _selectedMarks = {};
                _markSearchText = '';
                _markSearchController.clear();
              }),
            ),
            const SizedBox(height: 12),
            if (_sourceType == 'boq_upload') _buildMarkPicker(cs),
            if (_sourceType == 'manual_boq')
              TextField(
                controller: _manualMarksController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Manual Marks', border: OutlineInputBorder()),
              ),
            if (_sourceType == 'tonnage')
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Total Quantity', border: OutlineInputBorder()),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                  labelText: 'Remarks', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : () => _save(),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_editingAssignmentId.isEmpty
                    ? 'Save Assignment'
                    : 'Update Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      items: items,
      onChanged: onChanged,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        child: Text(date == null
            ? 'Select date'
            : DateFormat('dd/MM/yyyy').format(date)),
      ),
    );
  }

  Widget _buildMarkPicker(ColorScheme cs) {
    final assignedForStage = _assignedMarksForStage;
    final completedForStage = _completedBySetupItem[_setupItemId] ?? <String>{};
    if (_allMarks.isEmpty) {
      return const Text('No BOQ marks found. Upload BOQ first.');
    }
    final search = _markSearchText.trim().toLowerCase();
    final visibleMarks = search.isEmpty
        ? _allMarks
        : _allMarks.where((mark) {
            return mark.assemblyMark.toLowerCase().contains(search) ||
                mark.typeDescription.toLowerCase().contains(search);
          }).toList();
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _markSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _markSearchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _markSearchDebounce?.cancel();
                          setState(() {
                            _markSearchController.clear();
                            _markSearchText = '';
                          });
                        },
                      ),
                labelText: 'Search mark number',
                hintText: 'Search by mark or description',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _markSearchDebounce?.cancel();
                _markSearchDebounce =
                    Timer(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  setState(() => _markSearchText = value);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Text('${visibleMarks.length} of ${_allMarks.length} marks',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_selectedMarks.length} selected',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visibleMarks.isEmpty
                ? Center(
                    child: Text('No marks found',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  )
                : ListView(
                    children: visibleMarks.map((mark) {
                      final isCompleted =
                          completedForStage.contains(mark.assemblyMark);
                      final isAssigned =
                          assignedForStage.contains(mark.assemblyMark);
                      final disabled = isCompleted || isAssigned;
                      final statusText = isCompleted
                          ? ' · completed'
                          : isAssigned
                              ? ' · already assigned'
                              : '';
                      return Opacity(
                        opacity: disabled ? 0.45 : 1,
                        child: CheckboxListTile(
                          value: isCompleted ||
                              isAssigned ||
                              _selectedMarks.contains(mark.assemblyMark),
                          onChanged: disabled
                              ? null
                              : (checked) => setState(() {
                                    if (checked == true) {
                                      _selectedMarks.add(mark.assemblyMark);
                                    } else {
                                      _selectedMarks.remove(mark.assemblyMark);
                                    }
                                  }),
                          title: Text(mark.assemblyMark),
                          subtitle: Text(
                              '${mark.typeDescription} (${mark.remainingQty > 0 ? mark.remainingQty : mark.quantity})$statusText'),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work Assignment View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_assignments.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No active assignments.'))),
        ..._assignments.map((assignment) {
          final item = assignment.assignments.isNotEmpty
              ? assignment.assignments.first
              : null;
          return Card(
            child: ListTile(
              onTap: () => _showAssignmentDetails(assignment),
              title: Text(assignment.team?.name ?? 'Team',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${item?.stageName ?? 'Stage'} · ${item?.assignedQty ?? 0} ${item?.uom ?? ''}\n'
                'Start: ${_formatDate(assignment.assignmentDate)} · Expected: ${_formatDate(assignment.expectedCompletionDate)}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') _showAssignmentDetails(assignment);
                  if (value == 'edit') _openEdit(assignment);
                  if (value == 'delete') _delete(assignment);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'view', child: Text('View')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);

  void _showAssignmentDetails(PebWorkAssignment assignment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(assignment.team?.name ?? 'Team',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Status: ${assignment.status}'),
              Text('Start: ${_formatDate(assignment.assignmentDate)}'),
              Text(
                  'Expected: ${_formatDate(assignment.expectedCompletionDate)}'),
              const Divider(),
              ...assignment.assignments.map((item) => ListTile(
                    title: Text(item.stageName),
                    subtitle: Text(item.assemblyMarks.isEmpty
                        ? 'Quantity: ${item.assignedQty}'
                        : item.assemblyMarks.join(', ')),
                  )),
            ],
          ),
        );
      },
    );
  }

  PebSetupItem? _findSetupItem(String id) {
    for (final item in _setupItems) {
      if (item.id == id) return item;
    }
    return null;
  }
}

enum _WorkAssignmentMode { home, view, add }
