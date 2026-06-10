import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
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
  static const String _defaultTeamId = '__default_team__';
  static const PebTeam _defaultTeam =
      PebTeam(id: _defaultTeamId, name: 'Default Team');

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
  int _assignmentStep = 0;
  DateTime _assignmentDate = DateTime.now();
  DateTime? _expectedDate;
  List<PebTeam> _teams = [];
  List<PebSetupItem> _setupItems = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  Set<String> _selectedMarks = {};
  Map<String, Set<String>> _completedBySetupItem = {};
  String _markSearchText = '';

  bool get _isDefaultTeamSelected => _teamId == _defaultTeamId;

  String get _submitTeamId => _isDefaultTeamSelected ? '' : _teamId;

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
        if (_teams.isEmpty) _teams = const [_defaultTeam];
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

  _BoqMarkRecord? _findBoqRecord(String assemblyMark) {
    for (final boq in _boqs) {
      for (final mark in boq.items) {
        if (mark.assemblyMark == assemblyMark) {
          return _BoqMarkRecord(boq: boq, mark: mark);
        }
      }
    }
    return null;
  }

  Future<void> _bulkUpdateSelectedWeight() async {
    if (_selectedMarks.isEmpty) {
      AppToast.error('Select marks first');
      return;
    }
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => const _BulkWeightDialog(),
    );
    if (weight == null) return;

    setState(() => _saving = true);
    try {
      for (final markNumber in _selectedMarks) {
        final record = _findBoqRecord(markNumber);
        if (record == null) continue;
        await _service.updateBoqItem(
          widget.siteId,
          record.boq.id,
          record.mark.id,
          item: {
            ...record.mark.toJson(),
            'netWeightPerUnit': weight,
            'totalNetWeight': record.mark.quantity * weight,
            'remainingQty': record.mark.remainingQty,
            'status': record.mark.status,
          },
        );
      }
      AppToast.success('Weight updated for selected marks');
      await _load();
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      _assignmentStep = 0;
      _teamId = _teams.isNotEmpty ? _teams.first.id : _defaultTeamId;
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
      _assignmentStep = 0;
      _teamId = _teams.any((team) => team.id == assignment.teamId)
          ? assignment.teamId
          : _defaultTeamId;
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
        teamId: _submitTeamId,
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
    final isMarkSelectionPage = _mode == _WorkAssignmentMode.add &&
        _showForm &&
        _assignmentStep == _assignmentStepLabels.length - 1;
    final titleSuffix = switch (_mode) {
      _WorkAssignmentMode.home => 'Assignment',
      _WorkAssignmentMode.view => 'Assignment View',
      _WorkAssignmentMode.add => _showForm
          ? (_findSetupItem(_setupItemId)?.name ?? 'Assignment Add')
          : 'Assignment Add',
    };
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: '${widget.executionType.title} $titleSuffix'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isMarkSelectionPage
              ? _buildMarkSelectionPage(cs)
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
                              if (_mode == _WorkAssignmentMode.add &&
                                  _showForm) {
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMarkSelectionPage(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _assignmentStep -= 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mark Number Selection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the mark numbers to assign for this work item.',
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 16),
                _buildMarkSelectionStep(cs),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _assignmentStep -= 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _save(),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_editingAssignmentId.isEmpty
                        ? 'Save Assignment'
                        : 'Update Assignment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _bodyByMode(ColorScheme cs) {
    switch (_mode) {
      case _WorkAssignmentMode.home:
        return [_homeOptions(cs)];
      case _WorkAssignmentMode.view:
        return [_buildAssignmentList(cs)];
      case _WorkAssignmentMode.add:
        return _showForm ? [_buildForm(cs)] : [_buildStageGrid(cs)];
    }
  }

  Widget _homeOptions(ColorScheme cs) {
    return Column(
      children: [
        _selectCardGrid(
          firstIcon: Icons.visibility_rounded,
          firstColor: Colors.blue,
          firstLabel: 'View',
          firstTap: () => setState(() => _mode = _WorkAssignmentMode.view),
          secondIcon: Icons.add_circle_outline_rounded,
          secondColor: Colors.green,
          secondLabel: 'add',
          secondTap: () => setState(() {
            _mode = _WorkAssignmentMode.add;
            _showForm = false;
          }),
        ),
        const SizedBox(height: 16),
        _infoCard(
          cs,
          'Choose an option',
          '• View: You can view, edit and delete assigned work records.\n'
              '• Add: You can assign stage work to teams.',
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

  void _showFallbackInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Incomplete material fallback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'When this is enabled, teams with no assignment history can enter DPR for pending BOQ members.',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _allowFallback,
                onChanged: (value) {
                  context.pop();
                  _toggleFallback(value);
                },
                title: const Text('Show incomplete material'),
              ),
            ],
          ),
        );
      },
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
        Row(
          children: [
            const Expanded(
              child: Text('Select Work Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: _showFallbackInfo,
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: 'DPR fallback setting',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              color: cs.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _setupItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final item = _setupItems[index];
            final count = _assignments
                .where((assignment) => assignment.assignments
                    .any((work) => work.setupItemId == item.id))
                .length;
            return InkWell(
              onTap: () => _openNew(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.assignment_ind_outlined, color: cs.primary),
                    const Spacer(),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 0
                          ? 'No assignment'
                          : '$count assignment${count == 1 ? '' : 's'}',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme cs) {
    final setupItem = _findSetupItem(_setupItemId);
    final stepTitle = _assignmentStepLabels[_assignmentStep];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                setupItem?.name ?? 'Assignment',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showForm = false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AssignmentStepperHeader(
          currentStep: _assignmentStep,
          labels: _assignmentStepLabels,
          onStepTap: (step) {
            if (step <= _assignmentStep || _canMoveToAssignmentStep(step)) {
              setState(() => _assignmentStep = step);
            }
          },
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(_assignmentStep),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _AssignmentStepperHeader.iconForIndex(_assignmentStep),
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepTitle,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _assignmentStepDescriptions[_assignmentStep],
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAssignmentStepContent(cs),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _AssignmentStepperBottomBar(
          currentStep: _assignmentStep,
          totalSteps: _assignmentStepLabels.length,
          isSaving: _saving,
          canProceed: _canProceedFromAssignmentStep(_assignmentStep),
          canSkip: _assignmentStep == 1 || _assignmentStep == 2,
          onBack: _assignmentStep == 0
              ? null
              : () => setState(() => _assignmentStep -= 1),
          onSkip: _skipAssignmentStep,
          onNext: _nextAssignmentStep,
          onSubmit: () => _save(),
          submitLabel: _editingAssignmentId.isEmpty
              ? 'Save Assignment'
              : 'Update Assignment',
        ),
      ],
    );
  }

  List<String> get _assignmentStepLabels => const [
        'Team',
        'Assign Date',
        'Expected Date',
        'Marks',
      ];

  List<String> get _assignmentStepDescriptions => const [
        'Select the team that will perform this work.',
        'Select the assignment date, or skip to keep today as the default.',
        'Select the expected completion date, or skip if it is not needed.',
        'Select the mark numbers or quantity to assign for this work item.',
      ];

  bool _canMoveToAssignmentStep(int step) {
    if (step <= 0) return true;
    if (_teamId.isEmpty) return false;
    return true;
  }

  bool _canProceedFromAssignmentStep(int step) {
    if (step == 0) return _teamId.isNotEmpty;
    return true;
  }

  void _nextAssignmentStep() {
    if (_assignmentStep >= _assignmentStepLabels.length - 1) return;
    if (!_canProceedFromAssignmentStep(_assignmentStep)) {
      AppToast.error('Select team');
      return;
    }
    setState(() => _assignmentStep += 1);
  }

  void _skipAssignmentStep() {
    if (_assignmentStep == 2) {
      setState(() => _expectedDate = null);
    }
    _nextAssignmentStep();
  }

  Widget _buildAssignmentStepContent(ColorScheme cs) {
    switch (_assignmentStep) {
      case 0:
        return _buildTeamSelectionStep(cs);
      case 1:
        return _buildAssignmentDateStep(cs);
      case 2:
        return _buildExpectedDateStep(cs);
      case 3:
        return _buildMarkSelectionStep(cs);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTeamSelectionStep(ColorScheme cs) {
    if (_teams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No teams found for this site.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: _teams.map((team) {
        final selected = _teamId == team.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _teamId = team.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      team.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentDateStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateTile(
          'Assignment Date',
          _assignmentDate,
          () => _pickDate(expected: false),
        ),
        const SizedBox(height: 10),
        Text(
          'Skip keeps today as the assignment date.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildExpectedDateStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateTile(
          'Expected Completion',
          _expectedDate,
          () => _pickDate(expected: true),
        ),
        if (_expectedDate != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expectedDate = null),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Clear expected date'),
          ),
        ],
      ],
    );
  }

  Widget _buildMarkSelectionStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
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
    final selectableVisibleMarks = visibleMarks
        .where((mark) =>
            !completedForStage.contains(mark.assemblyMark) &&
            !assignedForStage.contains(mark.assemblyMark))
        .map((mark) => mark.assemblyMark)
        .toList();
    final allVisibleSelected = selectableVisibleMarks.isNotEmpty &&
        selectableVisibleMarks.every(_selectedMarks.contains);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              TextField(
                controller: _markSearchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _markSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _markSearchDebounce?.cancel();
                            setState(() {
                              _markSearchController.clear();
                              _markSearchText = '';
                            });
                          },
                        ),
                  hintText: 'Search mark number',
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  _markCounterChip(
                    '${visibleMarks.length}/${_allMarks.length}',
                    'visible',
                    cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _markCounterChip(
                    '${_selectedMarks.length}',
                    'selected',
                    cs.primary,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: allVisibleSelected
                        ? 'Clear filtered'
                        : 'Select all filtered',
                    onPressed: selectableVisibleMarks.isEmpty
                        ? null
                        : () => setState(() {
                              if (allVisibleSelected) {
                                _selectedMarks
                                    .removeAll(selectableVisibleMarks);
                              } else {
                                _selectedMarks.addAll(selectableVisibleMarks);
                              }
                            }),
                    icon: Icon(allVisibleSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Bulk edit weight',
                    onPressed: _selectedMarks.isEmpty || _saving
                        ? null
                        : _bulkUpdateSelectedWeight,
                    icon: const Icon(Icons.scale_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedMarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_selectedMarks.length} mark${_selectedMarks.length == 1 ? '' : 's'} ready to assign',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        if (visibleMarks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('No marks found',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: visibleMarks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (context, index) {
              final mark = visibleMarks[index];
              final isCompleted = completedForStage.contains(mark.assemblyMark);
              final isAssigned = assignedForStage.contains(mark.assemblyMark);
              final selected = _selectedMarks.contains(mark.assemblyMark);
              final disabled = isCompleted || isAssigned;
              final qty =
                  mark.remainingQty > 0 ? mark.remainingQty : mark.quantity;
              final statusText = isCompleted
                  ? 'Completed'
                  : isAssigned
                      ? 'Assigned'
                      : '${_prettyNumber(qty)} qty';
              return Opacity(
                opacity: disabled ? 0.45 : 1,
                child: InkWell(
                  onTap: disabled
                      ? null
                      : () => setState(() {
                            if (selected) {
                              _selectedMarks.remove(mark.assemblyMark);
                            } else {
                              _selectedMarks.add(mark.assemblyMark);
                            }
                          }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? cs.primaryContainer : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected ? cs.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.45),
                            ),
                          ),
                          child: selected || disabled
                              ? Icon(
                                  disabled
                                      ? Icons.lock_rounded
                                      : Icons.check_rounded,
                                  size: 15,
                                  color: selected
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mark.assemblyMark,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _markCounterChip(
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              onTap: () => _showAssignmentDetails(assignment),
              leading: Icon(Icons.assignment_ind_outlined, color: cs.primary),
              title: Text(
                item?.stageName ?? 'Work',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                '${assignment.team?.name ?? 'Team'} · ${item?.assignedQty ?? 0} ${item?.uom ?? ''}\n'
                'Start: ${_formatDate(assignment.assignmentDate)} · Expected: ${_formatDate(assignment.expectedCompletionDate)}',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility_outlined, color: cs.tertiary),
                    onPressed: () => _showAssignmentDetails(assignment),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: cs.primary),
                    onPressed: () => _openEdit(assignment),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: () => _delete(assignment),
                  ),
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
    final firstItem =
        assignment.assignments.isNotEmpty ? assignment.assignments.first : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(firstItem?.stageName ?? 'Work Assignment',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                assignment.team?.name ?? 'Team',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
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

  String _prettyNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _AssignmentStepperHeader extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final ValueChanged<int> onStepTap;

  const _AssignmentStepperHeader({
    required this.currentStep,
    required this.labels,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == currentStep;
          final complete = index < currentStep;
          final color = active || complete ? cs.primary : cs.onSurfaceVariant;
          return Expanded(
            child: InkWell(
              onTap: () => onStepTap(index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: complete
                            ? cs.primary
                            : active
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        complete ? Icons.check_rounded : iconForIndex(index),
                        size: 15,
                        color: complete || active
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  static IconData iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.groups_rounded;
      case 1:
        return Icons.event_available_rounded;
      case 2:
        return Icons.event_note_rounded;
      default:
        return Icons.tag_rounded;
    }
  }
}

class _BoqMarkRecord {
  final PebBoq boq;
  final PebBoqMark mark;

  const _BoqMarkRecord({
    required this.boq,
    required this.mark,
  });
}

class _AssignmentStepperBottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSaving;
  final bool canProceed;
  final bool canSkip;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final String submitLabel;

  const _AssignmentStepperBottomBar({
    required this.currentStep,
    required this.totalSteps,
    required this.isSaving,
    required this.canProceed,
    required this.canSkip,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmit,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = currentStep == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final active = index <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Back',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (canSkip) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 78,
                  child: TextButton(
                    onPressed: isSaving ? null : onSkip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving || (!canProceed && !isLast)
                      ? null
                      : isLast
                          ? onSubmit
                          : onNext,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isLast
                          ? Icons.save_rounded
                          : Icons.arrow_forward_rounded),
                  label: Text(isLast ? submitLabel : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _WorkAssignmentMode { home, view, add }

class _BulkWeightDialog extends StatefulWidget {
  const _BulkWeightDialog();

  @override
  State<_BulkWeightDialog> createState() => _BulkWeightDialogState();
}

class _BulkWeightDialogState extends State<_BulkWeightDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk update weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Net weight per unit',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_controller.text.trim()) ?? 0;
            if (value <= 0) {
              AppToast.error('Enter a valid weight');
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
