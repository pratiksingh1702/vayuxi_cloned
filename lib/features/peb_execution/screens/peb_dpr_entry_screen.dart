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
import '../utils/peb_work_images.dart';

class PebDprEntryScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final PebExecutionType executionType;

  const PebDprEntryScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
  });

  @override
  State<PebDprEntryScreen> createState() => _PebDprEntryScreenState();
}

class _PebDprEntryScreenState extends State<PebDprEntryScreen> {
  final _service = PebExecutionService();
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _workCardKeys = {};
  bool _loading = true;
  bool _submitting = false;
  DateTime _selectedDate = DateTime.now();
  String _teamId = '';
  PebSetup? _setup;
  List<PebTeam> _teams = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  PebMarkStatus _status =
      const PebMarkStatus(completedByKey: {}, inProgressByKey: {});

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true, bool autoScroll = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final teams =
          await _service.getTeams(widget.siteId, widget.executionType);
      final firstTeam = _teamId.isNotEmpty
          ? _teamId
          : teams.isNotEmpty
              ? teams.first.id
              : '';
      final results = await Future.wait([
        _service.getSetup(widget.siteId, widget.executionType),
        _service.getBoqs(widget.siteId),
        _service.getAssignments(widget.siteId, widget.executionType,
            teamId: firstTeam, status: 'all'),
        _service.getDprMarkStatus(
          widget.siteId,
          widget.executionType,
          date: _dateText,
        ),
      ]);

      setState(() {
        _teams = teams;
        _teamId = firstTeam;
        _setup = results[0] as PebSetup?;
        _boqs = results[1] as List<PebBoq>;
        _assignments = (results[2] as List<PebWorkAssignment>)
            .where((assignment) => assignment.status != 'cancelled')
            .toList();
        _status = results[3] as PebMarkStatus;
      });
      if (autoScroll) _scrollToFirstActiveWork();
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  String get _dateText => _selectedDate.toIso8601String().split('T').first;

  List<PebBoqMark> get _allMarks => _boqs.expand((boq) => boq.items).toList();

  double _markQuantity(String mark) {
    return _allMarks.where((item) => item.assemblyMark == mark).fold<double>(
        0,
        (sum, item) =>
            sum + (item.remainingQty > 0 ? item.remainingQty : item.quantity));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _load(autoScroll: true);
  }

  List<_VisibleWork> _visibleWorks() {
    final setup = _setup;
    if (setup == null) return [];
    final teamAssignments = _assignments
        .where((assignment) =>
            assignment.teamId == _teamId && assignment.status != 'cancelled')
        .toList();
    final allValidAssignments = _assignments
        .where((assignment) => assignment.status != 'cancelled')
        .toList();
    final fallbackAllowed = setup.allowUnassignedDprFallback &&
        (_teamId.isNotEmpty
            ? teamAssignments.isEmpty
            : allValidAssignments.isEmpty);

    if (fallbackAllowed) {
      return setup.items.map((setupItem) {
        final completed = _status.completedByKey[setupItem.id] ?? <String>{};
        final pendingMarks = _allMarks
            .map((mark) => mark.assemblyMark)
            .where((mark) => mark.isNotEmpty && !completed.contains(mark))
            .toList();
        return _VisibleWork(
          key: setupItem.id,
          setupItem: setupItem,
          assignmentId: '',
          sourceType: 'boq_upload',
          stageName: setupItem.name,
          assignedMarks: pendingMarks,
          assignedQty: pendingMarks.length.toDouble(),
          assignmentDate: _selectedDate,
          expectedCompletionDate: null,
          isActive: true,
          isFallback: true,
        );
      }).toList();
    }

    final activeBySetupId = <String, List<_VisibleWork>>{};
    final orphanActiveWorks = <_VisibleWork>[];

    for (final assignment in teamAssignments) {
      for (final item in assignment.assignments) {
        final setupItem = _findSetupItem(item.setupItemId) ??
            PebSetupItem(
                id: item.setupItemId,
                name: item.stageName,
                uom: item.uom,
                targetQty: item.assignedQty);
        final work = _VisibleWork(
          key: '${assignment.id}:${item.setupItemId}',
          setupItem: setupItem,
          assignmentId: assignment.id,
          sourceType: assignment.sourceType,
          stageName:
              item.stageName.isNotEmpty ? item.stageName : setupItem.name,
          assignedMarks: item.assemblyMarks,
          assignedQty: item.assignedQty,
          assignmentDate: assignment.assignmentDate,
          expectedCompletionDate: assignment.expectedCompletionDate,
          isActive: true,
          isFallback: false,
        );
        if (_findSetupItem(item.setupItemId) == null) {
          orphanActiveWorks.add(work);
        } else {
          activeBySetupId.putIfAbsent(item.setupItemId, () => []).add(work);
        }
      }
    }

    final orderedWorks = <_VisibleWork>[];
    for (final setupItem in setup.items) {
      final activeForStage = activeBySetupId[setupItem.id] ?? const [];
      if (activeForStage.isNotEmpty) {
        orderedWorks.addAll(activeForStage);
      } else {
        orderedWorks.add(_VisibleWork(
          key: setupItem.id,
          setupItem: setupItem,
          assignmentId: '',
          sourceType: 'boq_upload',
          stageName: setupItem.name,
          assignedMarks: const [],
          assignedQty: 0,
          assignmentDate: null,
          expectedCompletionDate: null,
          isActive: false,
          isFallback: false,
          inactiveReason: _teamId.isEmpty
              ? 'Select team to activate work'
              : 'Not assigned to selected team',
        ));
      }
    }
    orderedWorks.addAll(orphanActiveWorks);

    final counts = <String, int>{};
    return orderedWorks.map((work) {
      if (!work.isActive) return work;
      counts[work.stageName] = (counts[work.stageName] ?? 0) + 1;
      return work.copyWith(
        displayName: counts[work.stageName]! > 1
            ? '${work.stageName} ${counts[work.stageName]}'
            : work.stageName,
      );
    }).toList();
  }

  GlobalKey _keyForWork(_VisibleWork work) {
    return _workCardKeys.putIfAbsent(work.key, GlobalKey.new);
  }

  void _scrollToFirstActiveWork() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _VisibleWork? activeWork;
      for (final work in _visibleWorks()) {
        if (_isWorkActionable(work)) {
          activeWork = work;
          break;
        }
      }
      if (activeWork == null) return;
      final context = _workCardKeys[activeWork.key]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  PebSetupItem? _findSetupItem(String id) {
    for (final item in _setup?.items ?? const <PebSetupItem>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  PebSetupItem? _previousSetupItem(_VisibleWork work) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    final index = items.indexWhere((item) => item.id == work.setupItem.id);
    if (index <= 0) return null;
    return items[index - 1];
  }

  List<String> _unlockedMarksForWork(_VisibleWork work) {
    final prev = _previousSetupItem(work);
    if (prev == null || work.assignedMarks.isEmpty) return work.assignedMarks;
    final previousCompleted = _status.completedByKey[prev.id] ?? <String>{};
    return work.assignedMarks.where(previousCompleted.contains).toList();
  }

  Set<String> _completedForWork(_VisibleWork work) {
    if (work.assignmentId.isNotEmpty) {
      return _status.completedByKey[work.key] ?? <String>{};
    }
    return _status.completedByKey[work.setupItem.id] ?? <String>{};
  }

  Set<String> _inProgressForWork(_VisibleWork work) {
    final completed = _completedForWork(work);
    final raw = work.assignmentId.isNotEmpty
        ? _status.inProgressByKey[work.key] ?? <String>{}
        : _status.inProgressByKey[work.setupItem.id] ?? <String>{};
    return raw.where((mark) => !completed.contains(mark)).toSet();
  }

  _WorkCounts _counts(_VisibleWork work) {
    final marks = work.assignedMarks;
    final completed = _completedForWork(work);
    final inProgress = _inProgressForWork(work);
    final total = marks.isNotEmpty ? marks.length : work.assignedQty.round();
    return _WorkCounts(
      total: total,
      completed: marks.where(completed.contains).length,
      inProgress: marks
          .where(
              (mark) => !completed.contains(mark) && inProgress.contains(mark))
          .length,
    );
  }

  bool _isWorkFullyCompleted(_VisibleWork work) {
    if (!work.isActive) return false;
    final completed = _completedForWork(work);
    if (work.assignedMarks.isNotEmpty) {
      return work.assignedMarks.every(completed.contains);
    }
    final counts = _counts(work);
    return counts.total > 0 && counts.completed >= counts.total;
  }

  bool _hasUnlockedScope(_VisibleWork work) {
    if (work.assignedMarks.isEmpty) return work.assignedQty > 0;
    return _unlockedMarksForWork(work).isNotEmpty;
  }

  bool _isWorkActionable(_VisibleWork work) {
    return work.isActive &&
        !_isWorkFullyCompleted(work) &&
        _hasUnlockedScope(work);
  }

  String? _inactiveMessage(_VisibleWork work) {
    if (_isWorkFullyCompleted(work)) return 'Completed';
    if (work.isActive && !_hasUnlockedScope(work)) {
      return 'Previous activity must be completed first';
    }
    return work.inactiveReason;
  }

  Future<void> _openAction(_VisibleWork work, bool completedAction) async {
    if (!_isWorkActionable(work)) {
      AppToast.info(_inactiveMessage(work) ??
          'This work is not active for selected team');
      return;
    }
    final rawMarks = work.assignedMarks;
    final unlocked = _unlockedMarksForWork(work);
    if (rawMarks.isNotEmpty &&
        unlocked.isEmpty &&
        _previousSetupItem(work) != null) {
      AppToast.error(
          'Previous activity must be completed before progress can be recorded for the selected activity.');
      return;
    }
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MarkActionSheet(
        title: completedAction
            ? 'Select Completed Work'
            : 'Select In Progress Work',
        marks: rawMarks.isNotEmpty ? rawMarks : unlocked,
        enabledMarks: rawMarks.isNotEmpty ? unlocked.toSet() : unlocked.toSet(),
        completedMarks: _completedForWork(work),
        inProgressMarks: _inProgressForWork(work),
        completedAction: completedAction,
      ),
    );
    if (selected == null || selected.isEmpty) return;
    await _submitProgress(work, selected, completedAction ? 100 : 50);
  }

  Future<void> _submitProgress(
      _VisibleWork work, List<String> marks, int progress) async {
    setState(() => _submitting = true);
    try {
      final targetQty = marks.isEmpty
          ? work.assignedQty
          : marks.fold<double>(0, (sum, mark) => sum + _markQuantity(mark));
      final actualQty = targetQty * progress / 100;
      await _service.submitDprProgress(
        widget.siteId,
        widget.executionType,
        date: _dateText,
        teamId: _teamId,
        setupItemId: work.setupItem.id,
        assignmentId: work.assignmentId,
        sourceType: work.sourceType,
        stageName: work.stageName,
        uom: work.setupItem.uom,
        marks: marks,
        actualQty: actualQty,
        targetQty: targetQty,
        progressPercentage: progress,
      );
      AppToast.success('DPR updated successfully');
      await _load(showLoader: false, autoScroll: true);
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final works = _visibleWorks();
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: '${widget.executionType.title} DPR'),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildFilters(),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.executionType.section[0].toUpperCase()}${widget.executionType.section.substring(1)} Items',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                          'Add date-wise completed quantity for each selected work item'),
                      const SizedBox(height: 16),
                      if (works.isEmpty)
                        const Card(
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No work found.')))
                      else
                        ...works.map((work) => KeyedSubtree(
                              key: _keyForWork(work),
                              child: _buildWorkCard(work),
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          if (_submitting)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.62),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 14),
                            Text('Updating DPR...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _teamId.isEmpty ? null : _teamId,
                    decoration: const InputDecoration(
                        labelText: 'Team', border: OutlineInputBorder()),
                    items: _teams
                        .map((team) => DropdownMenuItem(
                            value: team.id, child: Text(team.name)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() => _teamId = value ?? '');
                      await _load(autoScroll: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Date', border: OutlineInputBorder()),
                      child:
                          Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            if (_submitting)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard(_VisibleWork work) {
    final counts = _counts(work);
    final isActionable = _isWorkActionable(work);
    final isCompleted = _isWorkFullyCompleted(work);
    final inactiveMessage = _inactiveMessage(work);
    final deadline = work.expectedCompletionDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(work.expectedCompletionDate!);
    final start = work.assignmentDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(work.assignmentDate!);
    final hasCustomImage = pebWorkImageIsCustom(work.setupItem);
    return Opacity(
      opacity: isActionable || isCompleted ? 1 : 0.38,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color:
                isCompleted ? Colors.green.shade600 : const Color(0xFF11264B),
            width: isCompleted ? 1.8 : 1.3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                work.displayName ?? work.stageName,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: Container(
                        color: Colors.blueGrey.shade50,
                        padding: EdgeInsets.all(hasCustomImage ? 0 : 10),
                        child: Image(
                          image: pebWorkImageProvider(
                              work.setupItem, widget.executionType),
                          fit: hasCustomImage ? BoxFit.cover : BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.blueGrey.shade50,
                            child: const Icon(Icons.construction, size: 42),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Work detail'),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => AppToast.info(
                                  'Members: ${counts.total} | Pending: ${counts.pending} | Deadline: $deadline'),
                              child: const Text('VIEW'),
                            ),
                          ],
                        ),
                        Text('Assign on $start'),
                        Text('TCD is $deadline'),
                        if (isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: Colors.green.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                child: Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton(
                          onPressed: isActionable
                              ? () => _openAction(work, false)
                              : null,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange,
                              side: const BorderSide(color: Colors.deepOrange)),
                          child: const Text('+ In Progress'),
                        ),
                        Text(
                            '${counts.inProgress} out of ${counts.total} in\nProgress',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton(
                          onPressed: isActionable
                              ? () => _openAction(work, true)
                              : null,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade700)),
                          child: const Text('+ Completed'),
                        ),
                        Text(
                            '${counts.completed} out of ${counts.total}\nCompleted',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isActionable && inactiveMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(inactiveMessage,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkActionSheet extends StatefulWidget {
  final String title;
  final List<String> marks;
  final Set<String> enabledMarks;
  final Set<String> completedMarks;
  final Set<String> inProgressMarks;
  final bool completedAction;

  const _MarkActionSheet({
    required this.title,
    required this.marks,
    required this.enabledMarks,
    required this.completedMarks,
    required this.inProgressMarks,
    required this.completedAction,
  });

  @override
  State<_MarkActionSheet> createState() => _MarkActionSheetState();
}

class _MarkActionSheetState extends State<_MarkActionSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final actionable = widget.marks
        .where((mark) =>
            widget.enabledMarks.contains(mark) &&
            !widget.completedMarks.contains(mark))
        .toList();
    final allSelected =
        actionable.isNotEmpty && actionable.every(_selected.contains);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title.toUpperCase(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: allSelected,
              onChanged: (checked) => setState(() {
                _selected.clear();
                if (checked == true) _selected.addAll(actionable);
              }),
              title: const Text('Select all available members'),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.marks.map((mark) {
                  final completed = widget.completedMarks.contains(mark);
                  final inProgress = widget.inProgressMarks.contains(mark);
                  final enabled = widget.enabledMarks.contains(mark);
                  final selected = _selected.contains(mark);
                  final color = completed
                      ? Colors.green.shade100
                      : inProgress
                          ? Colors.orange.shade100
                          : selected
                              ? widget.completedAction
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50
                              : !enabled
                                  ? Colors.grey.shade100
                                  : null;
                  return Container(
                    color: color,
                    child: CheckboxListTile(
                      value: completed ||
                          selected ||
                          (!widget.completedAction && inProgress),
                      onChanged: completed || !enabled
                          ? null
                          : (checked) => setState(() {
                                if (checked == true) {
                                  _selected.add(mark);
                                } else {
                                  _selected.remove(mark);
                                }
                              }),
                      title: Text(mark),
                      subtitle: !enabled && !completed
                          ? const Text(
                              'Previous activity pending',
                              style: TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => context.pop(_selected.toList()),
                    child: Text(
                        widget.completedAction ? 'Completed' : 'In Progress'),
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

class _VisibleWork {
  final String key;
  final PebSetupItem setupItem;
  final String assignmentId;
  final String sourceType;
  final String stageName;
  final List<String> assignedMarks;
  final double assignedQty;
  final DateTime? assignmentDate;
  final DateTime? expectedCompletionDate;
  final bool isActive;
  final bool isFallback;
  final String? inactiveReason;
  final String? displayName;

  const _VisibleWork({
    required this.key,
    required this.setupItem,
    required this.assignmentId,
    required this.sourceType,
    required this.stageName,
    required this.assignedMarks,
    required this.assignedQty,
    required this.assignmentDate,
    required this.expectedCompletionDate,
    required this.isActive,
    required this.isFallback,
    this.inactiveReason,
    this.displayName,
  });

  _VisibleWork copyWith({String? displayName}) {
    return _VisibleWork(
      key: key,
      setupItem: setupItem,
      assignmentId: assignmentId,
      sourceType: sourceType,
      stageName: stageName,
      assignedMarks: assignedMarks,
      assignedQty: assignedQty,
      assignmentDate: assignmentDate,
      expectedCompletionDate: expectedCompletionDate,
      isActive: isActive,
      isFallback: isFallback,
      inactiveReason: inactiveReason,
      displayName: displayName ?? this.displayName,
    );
  }
}

class _WorkCounts {
  final int total;
  final int completed;
  final int inProgress;

  const _WorkCounts({
    required this.total,
    required this.completed,
    required this.inProgress,
  });

  int get pending => (total - completed - inProgress).clamp(0, total).toInt();
}
