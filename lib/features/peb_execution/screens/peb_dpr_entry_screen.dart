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
  final String initialTeamId;

  const PebDprEntryScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
    this.initialTeamId = '',
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
  String? _loadError;
  DateTime _selectedDate = DateTime.now();
  String _teamId = '';
  PebSetup? _setup;
  List<PebTeam> _teams = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  final Map<String, String> _markQuantityInputs = {};
  final Map<String, String> _markRemarks = {};
  final Map<String, String> _variationReasons = {};
  String? _activeWorkKey;
  _DprMarkActionMode _markActionMode = _DprMarkActionMode.none;
  final Set<String> _selectedDetailMarks = {};
  PebMarkStatus _status =
      const PebMarkStatus(completedByKey: {}, inProgressByKey: {});

  @override
  void initState() {
    super.initState();
    _teamId = widget.initialTeamId;
    _load();
  }

  @override
  void didUpdateWidget(covariant PebDprEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteId != widget.siteId ||
        oldWidget.executionType != widget.executionType) {
      _teamId = '';
      _teams = [];
      _setup = null;
      _boqs = [];
      _assignments = [];
      _activeWorkKey = null;
      _markActionMode = _DprMarkActionMode.none;
      _selectedDetailMarks.clear();
      _status = const PebMarkStatus(completedByKey: {}, inProgressByKey: {});
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true, bool autoScroll = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final teams =
          await _service.getTeams(widget.siteId, widget.executionType);
      final selectedTeamId = teams.any((team) => team.id == _teamId)
          ? _teamId
          : teams.isNotEmpty
              ? teams.first.id
              : '';
      final results = await Future.wait([
        _service.getSetup(widget.siteId, widget.executionType),
        _service.getBoqs(widget.siteId),
        _service.getAssignments(widget.siteId, widget.executionType,
            teamId: selectedTeamId, status: 'all'),
        _service.getDprMarkStatus(widget.siteId, widget.executionType),
      ]);

      if (!mounted) return;
      setState(() {
        _teams = teams;
        _teamId = selectedTeamId;
        _setup = results[0] as PebSetup?;
        _boqs = results[1] as List<PebBoq>;
        _assignments = (results[2] as List<PebWorkAssignment>)
            .where((assignment) => assignment.status != 'cancelled')
            .toList();
        _status = results[3] as PebMarkStatus;
        if (_activeWorkKey != null &&
            !_visibleWorks().any((work) => work.key == _activeWorkKey)) {
          _activeWorkKey = null;
          _markActionMode = _DprMarkActionMode.none;
          _selectedDetailMarks.clear();
        }
        _loadError = null;
      });
      if (autoScroll && _activeWorkKey == null) _scrollToFirstActiveWork();
    } catch (error) {
      final message = extractBackendError(error);
      if (mounted) setState(() => _loadError = message);
      AppToast.error(message);
    } finally {
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  String get _dateText => _selectedDate.toIso8601String().split('T').first;

  List<PebBoqMark> get _allMarks => _boqs.expand((boq) => boq.items).toList();

  String _markInputKey(_VisibleWork work, String mark) => '${work.key}::$mark';

  PebBoqMark? _boqMarkFor(String mark) {
    for (final item in _allMarks) {
      if (item.assemblyMark == mark) return item;
    }
    return null;
  }

  _VisibleWork? _activeWork(List<_VisibleWork> works) {
    final key = _activeWorkKey;
    if (key == null) return null;
    for (final work in works) {
      if (work.key == key) return work;
    }
    return null;
  }

  Future<void> _openWorkDetail(_VisibleWork work) async {
    if (!work.isActive) {
      AppToast.info(work.inactiveReason ?? 'This work is not assigned');
      return;
    }
    setState(() {
      _activeWorkKey = work.key;
      _markActionMode = _DprMarkActionMode.none;
      _selectedDetailMarks.clear();
    });
  }

  void _closeWorkDetail() {
    setState(() {
      _activeWorkKey = null;
      _markActionMode = _DprMarkActionMode.none;
      _selectedDetailMarks.clear();
    });
  }

  void _handleWorkBack() {
    if (_markActionMode != _DprMarkActionMode.none) {
      setState(() {
        _markActionMode = _DprMarkActionMode.none;
        _selectedDetailMarks.clear();
      });
      return;
    }
    _closeWorkDetail();
  }

  Widget _statusChoiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSelectableMarksForMode(
    _VisibleWork work,
    _DprMarkActionMode mode,
  ) {
    final unlockedMarks = _unlockedMarksForWork(work).toSet();
    return work.assignedMarks.any((mark) {
      final completed = _completedForWork(work).contains(mark);
      final inProgress = _inProgressForWork(work).contains(mark);
      if (!unlockedMarks.contains(mark) || completed) return false;
      if (mode == _DprMarkActionMode.inProgress && inProgress) return false;
      return true;
    });
  }

  double _markQuantity(String mark) {
    return _allMarks.where((item) => item.assemblyMark == mark).fold<double>(
        0,
        (sum, item) =>
            sum + (item.remainingQty > 0 ? item.remainingQty : item.quantity));
  }

  double _markWeightKg(String mark) {
    final matches =
        _allMarks.where((item) => item.assemblyMark == mark).toList();
    if (matches.isEmpty) return _markQuantity(mark);
    final totalWeight = matches.fold<double>(
        0,
        (sum, item) =>
            sum + (item.totalNetWeight > 0 ? item.totalNetWeight : 0));
    if (totalWeight > 0) return totalWeight;
    final perUnitWeight = matches.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item.remainingQty > 0 ? item.remainingQty : item.quantity) *
              item.netWeightPerUnit),
    );
    return perUnitWeight > 0 ? perUnitWeight : _markQuantity(mark);
  }

  String _prettyNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  double _enteredWeightKgForMark(_VisibleWork work, String mark) {
    final key = _markInputKey(work, mark);
    return double.tryParse(_markQuantityInputs[key] ?? '') ??
        _markWeightKg(mark);
  }

  bool _isWeightChanged(_VisibleWork work, String mark) {
    final key = _markInputKey(work, mark);
    if (!_markQuantityInputs.containsKey(key)) return false;
    final entered = double.tryParse(_markQuantityInputs[key] ?? '');
    if (entered == null) return false;
    return (entered - _markWeightKg(mark)).abs() > 0.0001;
  }

  void _startMarkAction(_DprMarkActionMode mode) {
    final work = _activeWork(_visibleWorks());
    final hasSelectableMarks =
        work != null && _hasSelectableMarksForMode(work, mode);
    final hasCompletedMarks = work != null &&
        mode == _DprMarkActionMode.completed &&
        work.assignedMarks.any(_completedForWork(work).contains);

    if (!hasSelectableMarks && !hasCompletedMarks) {
      AppToast.info(mode == _DprMarkActionMode.completed
          ? 'No pending marks available to complete'
          : 'No pending marks available for in progress');
      return;
    }

    setState(() {
      _markActionMode = mode;
      _selectedDetailMarks.clear();
    });
  }

  void _toggleDetailMark(_VisibleWork work, String mark) {
    if (_markActionMode == _DprMarkActionMode.none) return;
    final completed = _completedForWork(work).contains(mark);
    final inProgress = _inProgressForWork(work).contains(mark);
    final unlocked = _unlockedMarksForWork(work).contains(mark);
    if (completed ||
        !unlocked ||
        (_markActionMode == _DprMarkActionMode.inProgress && inProgress)) {
      return;
    }
    setState(() {
      if (_selectedDetailMarks.contains(mark)) {
        _selectedDetailMarks.remove(mark);
      } else {
        _selectedDetailMarks.add(mark);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _activeWorkKey = null;
      _markActionMode = _DprMarkActionMode.none;
      _selectedDetailMarks.clear();
    });
    await _load(showLoader: true, autoScroll: true);
  }

  List<_VisibleWork> _visibleWorks() {
    final setup = _setup;
    if (setup == null || _teamId.isEmpty) return [];
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

  GlobalKey _keyForWork(_VisibleWork work, int index) {
    return _workCardKeys.putIfAbsent('${work.key}::$index', GlobalKey.new);
  }

  void _scrollToFirstActiveWork() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _VisibleWork? activeWork;
      final works = _visibleWorks().where((work) => work.isActive).toList();
      for (var index = 0; index < works.length; index++) {
        final work = works[index];
        if (_isWorkActionable(work)) {
          activeWork = work;
          break;
        }
      }
      if (activeWork == null) return;
      final activeIndex =
          works.indexWhere((work) => work.key == activeWork!.key);
      final context =
          _workCardKeys['${activeWork.key}::$activeIndex']?.currentContext;
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

  PebSetupItem? _nextPendingPrerequisite(_VisibleWork work, String mark) {
    final items = _setup?.items ?? const <PebSetupItem>[];
    final index = items.indexWhere((item) => item.id == work.setupItem.id);
    if (index <= 0) return null;
    for (final item in items.take(index)) {
      final completed = _status.completedByKey[item.id] ?? <String>{};
      if (!completed.contains(mark)) return item;
    }
    return null;
  }

  String _setupItemName(PebSetupItem item) {
    final name = item.name.trim();
    return name.isEmpty ? 'previous work' : name;
  }

  String _prerequisiteMessage(PebSetupItem item) {
    return 'Please complete ${_setupItemName(item)} first.';
  }

  List<String> _unlockedMarksForWork(_VisibleWork work) {
    final prev = _previousSetupItem(work);
    if (prev == null || work.assignedMarks.isEmpty) return work.assignedMarks;
    final previousCompleted = _status.completedByKey[prev.id] ?? <String>{};
    return work.assignedMarks.where(previousCompleted.contains).toList();
  }

  Set<String> _completedForWork(_VisibleWork work) {
    return {
      ...?_status.completedByKey[work.setupItem.id],
      if (work.assignmentId.isNotEmpty) ...?_status.completedByKey[work.key],
    };
  }

  Set<String> _inProgressForWork(_VisibleWork work) {
    final completed = _completedForWork(work);
    final raw = {
      ...?_status.inProgressByKey[work.setupItem.id],
      if (work.assignmentId.isNotEmpty) ...?_status.inProgressByKey[work.key],
    };
    return raw.where((mark) => !completed.contains(mark)).toSet();
  }

  DateTime? _completedDateForWork(_VisibleWork work) {
    DateTime? latest;
    for (final mark in work.assignedMarks) {
      final dates = <DateTime?>[
        _status.completedDateByKey[work.setupItem.id]?[mark],
        if (work.assignmentId.isNotEmpty)
          _status.completedDateByKey[work.key]?[mark],
      ];
      for (final date in dates) {
        if (date != null && (latest == null || date.isAfter(latest))) {
          latest = date;
        }
      }
    }
    return latest;
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
      return 'Please complete the previous task before proceeding.';
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
    if (rawMarks.isEmpty) {
      await _openQuantityAction(work);
      return;
    }
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
    if (completedAction) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete selected work?'),
          content: Text(
            'Mark ${selected.length} member${selected.length == 1 ? '' : 's'} '
            'as completed on ${DateFormat('dd MMM yyyy').format(_selectedDate)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _submitProgress(work, selected, completedAction ? 100 : 50);
  }

  Future<void> _submitSelectedDetailMarks(_VisibleWork work) async {
    if (_markActionMode == _DprMarkActionMode.none) return;
    if (_selectedDetailMarks.isEmpty) {
      AppToast.error('Select at least one mark number');
      return;
    }

    final completedAction = _markActionMode == _DprMarkActionMode.completed;
    for (final mark in _selectedDetailMarks) {
      if (_isWeightChanged(work, mark)) {
        final key = _markInputKey(work, mark);
        if ((_variationReasons[key] ?? '').trim().isEmpty) {
          AppToast.error('Variation reason is required for $mark');
          return;
        }
      }
    }

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final marksToSubmit = _selectedDetailMarks.toList();
      for (final mark in marksToSubmit) {
        final rawTargetQty = _markQuantity(mark);
        final targetQty = rawTargetQty > 0 ? rawTargetQty : 1.0;
        final enteredWeightKg = _enteredWeightKgForMark(work, mark);
        if (enteredWeightKg <= 0) {
          AppToast.error('Enter a valid weight for $mark');
          return;
        }
        final progress = completedAction ? 100 : 50;
        final actualQty = completedAction ? targetQty : targetQty * 0.5;
        final key = _markInputKey(work, mark);
        final weightChanged = _isWeightChanged(work, mark);
        await _submitProgress(
          work,
          [mark],
          progress,
          actualQtyOverride: actualQty,
          targetQtyOverride: targetQty,
          weightMode: weightChanged ? 'manual' : 'actual',
          manualWeightKg: weightChanged ? enteredWeightKg : 0.0,
          totalWeightKg: enteredWeightKg,
          remarks: (_markRemarks[key] ?? '').trim(),
          variationReason:
              weightChanged ? (_variationReasons[key] ?? '').trim() : '',
          variationRemarks:
              weightChanged ? (_markRemarks[key] ?? '').trim() : '',
          reloadAfter: false,
          showToast: false,
        );
      }
      AppToast.success('DPR updated successfully');
      setState(() {
        _markActionMode = _DprMarkActionMode.none;
        _selectedDetailMarks.clear();
      });
      await _load(showLoader: false, autoScroll: false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openQuantityAction(_VisibleWork work) async {
    final quantity = TextEditingController();
    final entered = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(work.stageName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approved quantity: ${work.assignedQty.toStringAsFixed(2)} ${work.setupItem.uom}',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: quantity,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Actual Progress Quantity',
                suffixText: work.setupItem.uom,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(quantity.text.trim()) ?? 0;
              if (value <= 0) {
                AppToast.error('Enter a valid progress quantity');
                return;
              }
              context.pop(value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    quantity.dispose();
    if (entered == null) return;

    final progress = work.assignedQty > 0
        ? ((entered / work.assignedQty) * 100).clamp(0, 100).round()
        : 0;
    await _submitProgress(
      work,
      const [],
      progress,
      actualQtyOverride: entered,
      trackingLevel: 'semi_structured',
    );
  }

  Future<void> _submitProgress(
    _VisibleWork work,
    List<String> marks,
    int progress, {
    double? actualQtyOverride,
    double? targetQtyOverride,
    String trackingLevel = 'advanced',
    String remarks = '',
    String variationReason = '',
    String variationRemarks = '',
    String weightMode = 'none',
    double estimatedWeightPerUnitKg = 0,
    double manualWeightKg = 0,
    double totalWeightKg = 0,
    bool reloadAfter = true,
    bool showToast = true,
  }) async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final targetQty = targetQtyOverride ??
          (marks.isEmpty
              ? work.assignedQty
              : marks.fold<double>(
                  0, (sum, mark) => sum + _markQuantity(mark)));
      final actualQty = actualQtyOverride ?? targetQty * progress / 100;
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
        trackingLevel: trackingLevel,
        remarks: remarks,
        variationReason: variationReason,
        variationRemarks: variationRemarks,
        weightMode: weightMode,
        estimatedWeightPerUnitKg: estimatedWeightPerUnitKg,
        manualWeightKg: manualWeightKg,
        totalWeightKg: totalWeightKg,
      );
      if (showToast) AppToast.success('DPR updated successfully');
      if (reloadAfter) await _load(showLoader: false, autoScroll: true);
    } on PebBoqVariationRequired catch (variation) {
      if (mounted) {
        final response = await _showVariationDialog(variation.variations);
        if (response != null) {
          await _submitProgress(
            work,
            marks,
            progress,
            actualQtyOverride: actualQtyOverride,
            targetQtyOverride: targetQtyOverride,
            trackingLevel: trackingLevel,
            remarks: remarks,
            variationReason: response.reason,
            variationRemarks: response.remarks,
            weightMode: weightMode,
            estimatedWeightPerUnitKg: estimatedWeightPerUnitKg,
            manualWeightKg: manualWeightKg,
            totalWeightKg: totalWeightKg,
            reloadAfter: reloadAfter,
            showToast: showToast,
          );
        }
      }
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<_VariationResponse?> _showVariationDialog(
      List<dynamic> variations) async {
    final reason = TextEditingController();
    final remarks = TextEditingController();
    final variation = variations.isNotEmpty && variations.first is Map
        ? variations.first as Map
        : const {};
    final approved =
        NumberFormat('0.##').format((variation['approvedBoqQty'] as num?) ?? 0);
    final executed =
        NumberFormat('0.##').format((variation['executedQty'] as num?) ?? 0);
    final difference =
        NumberFormat('0.##').format((variation['variationQty'] as num?) ?? 0);
    final uom = variation['uom']?.toString() ?? '';

    final result = await showDialog<_VariationResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('BOQ Variation Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'The executed quantity exceeds the approved BOQ quantity.'),
              const SizedBox(height: 14),
              Text('BOQ Quantity: $approved $uom'),
              Text('Executed Quantity: $executed $uom'),
              Text(
                'Variation Quantity: +$difference $uom',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                decoration: const InputDecoration(
                  labelText: 'Variation Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarks,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) {
                AppToast.error('Variation reason is required');
                return;
              }
              context.pop(_VariationResponse(
                reason: reason.text.trim(),
                remarks: remarks.text.trim(),
              ));
            },
            child: const Text('Save DPR'),
          ),
        ],
      ),
    );
    reason.dispose();
    remarks.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final works = _visibleWorks();
    final activeWork = _activeWork(works);
    final assignedWorks = works.where((work) => work.isActive).toList();
    return PopScope(
      canPop: _activeWorkKey == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _activeWorkKey != null) {
          _handleWorkBack();
        }
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: CustomAppBar(title: '${widget.executionType.title} DPR'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildLoadErrorState()
                : _teams.isEmpty
                    ? _buildNoTeamsState()
                    : Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              children: activeWork == null
                                  ? [
                                      _buildFilters(),
                                      const SizedBox(height: 18),
                                      _buildAssignedWorkHeader(assignedWorks),
                                      const SizedBox(height: 16),
                                      if (assignedWorks.isEmpty)
                                        _boqs.isEmpty
                                            ? _buildNoBoqState()
                                            : const Card(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                      'No assigned work found for this team.'),
                                                ),
                                              )
                                      else
                                        ...assignedWorks.asMap().entries.map(
                                              (entry) => KeyedSubtree(
                                                key: _keyForWork(
                                                    entry.value, entry.key),
                                                child:
                                                    _buildWorkCard(entry.value),
                                              ),
                                            ),
                                      const SizedBox(height: 90),
                                    ]
                                  : _markActionMode == _DprMarkActionMode.none
                                      ? [
                                          _buildStatusStepperScreen(activeWork),
                                          const SizedBox(height: 90),
                                        ]
                                      : [
                                          _buildWorkDetailHeader(activeWork),
                                          const SizedBox(height: 12),
                                          ...activeWork.assignedMarks.map(
                                            (mark) => _buildMarkEntryCardV2(
                                              activeWork,
                                              mark,
                                              enabled: _unlockedMarksForWork(
                                                      activeWork)
                                                  .contains(mark),
                                            ),
                                          ),
                                          if (activeWork.assignedMarks.isEmpty)
                                            _buildQuantityWorkEntryCard(
                                                activeWork),
                                          const SizedBox(height: 190),
                                        ],
                            ),
                          ),
                          if (activeWork != null &&
                              activeWork.assignedMarks.isNotEmpty)
                            _buildDetailBottomBar(activeWork),
                          if (_submitting)
                            Positioned.fill(
                              child: AbsorbPointer(
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  child: const Center(
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
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
      ),
    );
  }

  Widget _buildLoadErrorState() {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_rounded, size: 64, color: cs.error),
          const SizedBox(height: 18),
          Text(
            'Unable to load DPR Entry',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Sites'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeamsState() {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.groups_2_outlined, size: 68, color: cs.primary),
          const SizedBox(height: 18),
          Text(
            'No team available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a ${widget.executionType.title} team in Setup > Team, then return here to enter DPR progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Teams'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Sites'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBoqState() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.playlist_add_rounded, color: cs.primary, size: 34),
            const SizedBox(height: 12),
            const Text(
              'No BOQ marks available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Add BOQ items manually or upload BOQ first, then return here for DPR entry.',
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.push('/site-list/boq-upload'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add BOQ Items'),
            ),
          ],
        ),
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
                    key: ValueKey('team-$_teamId-${_teams.length}'),
                    initialValue: _teamId.isEmpty ? null : _teamId,
                    decoration: const InputDecoration(
                        labelText: 'Team', border: OutlineInputBorder()),
                    items: _teams
                        .map((team) => DropdownMenuItem(
                            value: team.id, child: Text(team.name)))
                        .toList(),
                    onChanged: (value) async {
                      final selectedTeamId = value ?? '';
                      if (selectedTeamId.isEmpty || selectedTeamId == _teamId) {
                        return;
                      }
                      setState(() {
                        _teamId = selectedTeamId;
                        _activeWorkKey = null;
                        _markActionMode = _DprMarkActionMode.none;
                        _selectedDetailMarks.clear();
                      });
                      await _load(showLoader: true, autoScroll: true);
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

  Widget _buildAssignedWorkHeader(List<_VisibleWork> assignedWorks) {
    final cs = Theme.of(context).colorScheme;
    String selectedTeam = '';
    for (final team in _teams) {
      if (team.id == _teamId) {
        selectedTeam = team.name;
        break;
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Assigned Work",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                selectedTeam.isEmpty
                    ? 'Open a work item to update progress'
                    : '$selectedTeam • Open a work item to update progress',
                style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${assignedWorks.length}',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 5),
              Text('works',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkCard(_VisibleWork work) {
    final counts = _counts(work);
    final isCompleted = _isWorkFullyCompleted(work);
    final deadline = work.expectedCompletionDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(work.expectedCompletionDate!);
    final completedDate = _completedDateForWork(work);
    const accent = Color(0xFF4B16B7);
    final completion = counts.total > 0
        ? (counts.completed / counts.total).clamp(0.0, 1.0)
        : 0.0;
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openWorkDetail(work),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.14),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: _workCardImage(work),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.displayName ?? work.stageName,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _workCountBlock(
                                'Assigned', counts.total, Colors.black87)),
                        Expanded(
                            child: _workCountBlock('In Progress',
                                counts.inProgress, Colors.orange)),
                        Expanded(
                            child: _workCountBlock('Completed',
                                counts.completed, Colors.green.shade700)),
                        Icon(Icons.chevron_right_rounded,
                            size: 32, color: accent),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _completionBar(
                      value: completion,
                      color: Colors.green.shade700,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    _deadlineBanner(work, completedDate, deadline),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Opacity(
      opacity: work.isActive || isCompleted ? 1 : 0.46,
      child: card,
    );
  }

  Widget _workCardImage(_VisibleWork work) {
    return Center(
      child: SizedBox.square(
        dimension: 58,
        child: Image(
          image: pebWorkImageProvider(work.setupItem, widget.executionType),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => pebWorkImageFallback(
            work.setupItem,
            widget.executionType,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionBar({
    required double value,
    required Color color,
    required Color backgroundColor,
  }) {
    final percent = (value.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _workCountBlock(String label, int count, Color color) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('$count',
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const Text('Mark Nos.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _deadlineBanner(
      _VisibleWork work, DateTime? completedDate, String deadline) {
    if (_isWorkFullyCompleted(work) && completedDate != null) {
      return _pillBanner(
        icon: Icons.check_circle,
        color: Colors.green.shade700,
        text: 'Completed on ${DateFormat('dd MMM yyyy').format(completedDate)}',
      );
    }
    if (work.expectedCompletionDate == null) {
      return _pillBanner(
        icon: Icons.schedule,
        color: Colors.blueGrey,
        text: 'TCD not set',
      );
    }
    final today =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final tcd = DateTime(work.expectedCompletionDate!.year,
        work.expectedCompletionDate!.month, work.expectedCompletionDate!.day);
    final days = tcd.difference(today).inDays;
    final missed = days < 0;
    return _pillBanner(
      icon: Icons.schedule,
      color: missed ? Colors.red.shade700 : const Color(0xFF174EA6),
      text: missed
          ? 'TCD was $deadline (${days.abs()} Days Missed)'
          : 'TCD is $deadline ($days Days Left)',
    );
  }

  Widget _pillBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailHeader(_VisibleWork work) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _handleWorkBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Status'),
        ),
        Text(
          work.displayName ?? work.stageName,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          _markActionMode == _DprMarkActionMode.completed
              ? 'Select mark numbers to complete.'
              : 'Select mark numbers to mark as in progress.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStepperScreen(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final counts = _counts(work);
    final inProgressColor = const Color(0xFFE56F00);
    final completedColor = Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _closeWorkDetail,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Assigned Work'),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
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
                  _stepCircle('1', true, cs.primary),
                  Expanded(
                      child: _stepLine(cs.primary.withValues(alpha: 0.35))),
                  _stepCircle('2', true, cs.primary),
                  Expanded(
                      child: _stepLine(cs.primary.withValues(alpha: 0.35))),
                  _stepCircle('3', true, cs.primary),
                  Expanded(
                      child: _stepLine(cs.primary.withValues(alpha: 0.35))),
                  _stepCircle('4', true, cs.primary),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                work.displayName ?? work.stageName,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the progress status before selecting mark numbers.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child:
                        _workCountBlock('Assigned', counts.total, cs.onSurface),
                  ),
                  Expanded(
                    child: _workCountBlock(
                        'In Progress', counts.inProgress, inProgressColor),
                  ),
                  Expanded(
                    child: _workCountBlock(
                        'Completed', counts.completed, completedColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statusChoiceButton(
                      label: 'In Progress',
                      icon: Icons.pending_actions_rounded,
                      color: inProgressColor,
                      onTap: () =>
                          _startMarkAction(_DprMarkActionMode.inProgress),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statusChoiceButton(
                      label: 'Completed',
                      icon: Icons.check_circle_rounded,
                      color: completedColor,
                      onTap: () =>
                          _startMarkAction(_DprMarkActionMode.completed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCircle(String label, bool active, Color color) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.65)),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stepLine(Color color) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: color,
    );
  }

  Widget _buildQuantityWorkEntryCard(_VisibleWork work) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quantity based work',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isWorkActionable(work)
                  ? () => _openAction(
                        work,
                        _markActionMode == _DprMarkActionMode.completed,
                      )
                  : null,
              child: Text(_markActionMode == _DprMarkActionMode.completed
                  ? 'Enter Completed Quantity'
                  : 'Enter In Progress Quantity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBottomBar(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final selecting = _markActionMode != _DprMarkActionMode.none;
    if (!selecting) return const SizedBox.shrink();
    final isCompletedMode = _markActionMode == _DprMarkActionMode.completed;
    final inProgressColor = const Color(0xFFE56F00);
    final completedColor = Colors.green.shade700;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _markActionMode = _DprMarkActionMode.none;
                    _selectedDetailMarks.clear();
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedDetailMarks.isEmpty || _submitting
                      ? null
                      : () => _submitSelectedDetailMarks(work),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isCompletedMode ? completedColor : inProgressColor,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Save (${_selectedDetailMarks.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkEntryCardV2(
    _VisibleWork work,
    String markNumber, {
    required bool enabled,
  }) {
    final cs = Theme.of(context).colorScheme;
    final key = _markInputKey(work, markNumber);
    final boqMark = _boqMarkFor(markNumber);
    final boqDescription = (boqMark?.typeDescription ?? '').trim();
    final title = boqDescription.isNotEmpty
        ? boqDescription
        : work.displayName ?? work.stageName;
    final completed = _completedForWork(work).contains(markNumber);
    final inProgress = _inProgressForWork(work).contains(markNumber);
    final selecting = _markActionMode != _DprMarkActionMode.none;
    final selected = _selectedDetailMarks.contains(markNumber);
    final pendingPrerequisite = _nextPendingPrerequisite(work, markNumber);
    final selectable = selecting &&
        pendingPrerequisite == null &&
        !completed &&
        !(_markActionMode == _DprMarkActionMode.inProgress && inProgress);
    final actionComplete = selecting &&
        selected &&
        _markActionMode == _DprMarkActionMode.completed;
    final actionProgress = selecting &&
        selected &&
        _markActionMode == _DprMarkActionMode.inProgress;
    final effectiveCompleted = completed || actionComplete;
    final effectiveInProgress =
        !effectiveCompleted && (inProgress || actionProgress);
    final locked = pendingPrerequisite != null && !completed && !inProgress;
    final editable = enabled || completed || inProgress;
    final contentOpacity = completed ? 0.56 : 1.0;
    final weightKg = _markWeightKg(markNumber);
    final isVariationOpen = _isWeightChanged(work, markNumber);
    final inProgressColor = const Color(0xFFE56F00);
    final statusColor = effectiveCompleted
        ? Colors.green.shade700
        : effectiveInProgress
            ? inProgressColor
            : cs.onSurfaceVariant;
    final cardColor = effectiveCompleted
        ? Colors.green.shade50
        : effectiveInProgress
            ? Colors.orange.shade50
            : cs.surface;
    final borderColor = effectiveCompleted
        ? Colors.green.shade500
        : effectiveInProgress
            ? Colors.orange.shade500
            : cs.outlineVariant;
    final imageBg = effectiveCompleted
        ? Colors.green.shade100
        : effectiveInProgress
            ? Colors.orange.shade100
            : Colors.blueGrey.shade50;
    final statusBadge = effectiveCompleted
        ? _statusBadge(
            label: 'Completed',
            color: Colors.green.shade700,
            icon: Icons.check_circle_rounded,
          )
        : effectiveInProgress
            ? _statusBadge(
                label: 'In Progress',
                color: inProgressColor,
                icon: Icons.pending_actions_rounded,
              )
            : _statusBadge(
                label: 'Pending',
                color: cs.onSurfaceVariant,
                icon: Icons.radio_button_unchecked_rounded,
              );

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selecting || completed) ...[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(
                      value: completed ? true : selected,
                      onChanged: selectable
                          ? (_) => _toggleDetailMark(work, markNumber)
                          : null,
                      activeColor:
                          _markActionMode == _DprMarkActionMode.completed
                              ? Colors.green.shade700
                              : inProgressColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              const TextSpan(text: 'Mark Number: '),
                              TextSpan(
                                text: markNumber,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: statusBadge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _markRemarks[key] ?? '',
                        enabled: editable,
                        decoration: InputDecoration(
                          labelText: 'Remarks',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 1,
                        onChanged: (value) => _markRemarks[key] = value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (locked) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: Colors.orange.shade900, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _prerequisiteMessage(pendingPrerequisite),
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Opacity(
              opacity: contentOpacity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: imageBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: borderColor.withValues(alpha: 0.28)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Image(
                          image: pebWorkImageProvider(
                            work.setupItem,
                            widget.executionType,
                          ),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Center(
                            child: pebWorkImageFallback(
                              work.setupItem,
                              widget.executionType,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Weight (Kg)',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          initialValue: _markQuantityInputs[key] ??
                              _prettyNumber(weightKg),
                          enabled: editable,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surface,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _markQuantityInputs[key] = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isVariationOpen) ...[
              const SizedBox(height: 12),
              _pillBanner(
                icon: Icons.add_chart_rounded,
                color: statusColor,
                text: 'Variation detected from edited weight',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _variationReasons[key] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Variation Reason',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => _variationReasons[key] = value,
              ),
            ],
          ],
        ),
      ),
    );

    return InkWell(
      onTap: selecting
          ? selectable
              ? () => _toggleDetailMark(work, markNumber)
              : () {
                  if (locked) {
                    AppToast.info(_prerequisiteMessage(pendingPrerequisite));
                  } else if (completed) {
                    AppToast.info('This mark number is already completed.');
                  } else if (_markActionMode == _DprMarkActionMode.inProgress &&
                      inProgress) {
                    AppToast.info('This mark number is already in progress.');
                  }
                }
          : locked
              ? () => AppToast.info(_prerequisiteMessage(pendingPrerequisite))
              : null,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }

  // ignore: unused_element
  Widget _buildMarkEntryCard(
    _VisibleWork work,
    String markNumber, {
    required bool enabled,
  }) {
    final cs = Theme.of(context).colorScheme;
    final key = _markInputKey(work, markNumber);
    final completed = _completedForWork(work).contains(markNumber);
    final inProgress = _inProgressForWork(work).contains(markNumber);
    final weightKg = _markWeightKg(markNumber);
    final selecting = _markActionMode != _DprMarkActionMode.none;
    final selected = _selectedDetailMarks.contains(markNumber);
    final selectable = enabled &&
        !completed &&
        !(_markActionMode == _DprMarkActionMode.inProgress && inProgress);
    final isVariationOpen = _isWeightChanged(work, markNumber);
    final Widget? statusBadge = completed
        ? _statusBadge(
            label: 'Completed',
            color: Colors.green.shade700,
            icon: Icons.check_circle_rounded,
          )
        : inProgress
            ? _statusBadge(
                label: 'In Progress',
                color: Colors.deepOrange.shade700,
                icon: Icons.pending_actions_rounded,
              )
            : null;

    return InkWell(
      onTap: selecting
          ? selectable
              ? () => _toggleDetailMark(work, markNumber)
              : () {
                  if (!enabled) {
                    AppToast.info(
                        'Please complete the previous task before proceeding.');
                  }
                }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: completed
              ? Colors.green.shade50
              : selected
                  ? const Color(0xFFF3ECFF)
                  : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected
                ? const Color(0xFF6A00F4)
                : completed
                    ? Colors.green.shade500
                    : inProgress
                        ? Colors.deepOrange.shade300
                        : cs.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (statusBadge != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: statusBadge,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.green.shade100
                          : Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Center(
                        child: Image(
                          image: pebWorkImageProvider(
                            work.setupItem,
                            widget.executionType,
                          ),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Center(
                            child: pebWorkImageFallback(
                              work.setupItem,
                              widget.executionType,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Mark no',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          markNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Weight (Kg)',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _markQuantityInputs[key] ??
                              _prettyNumber(weightKg),
                          enabled: enabled && !completed,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _markQuantityInputs[key] = value),
                        ),
                      ],
                    ),
                  ),
                  if (selecting) ...[
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Checkbox(
                        value: selected,
                        onChanged: selectable
                            ? (_) => _toggleDetailMark(work, markNumber)
                            : null,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _markRemarks[key] ?? '',
                enabled: enabled && !completed,
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => _markRemarks[key] = value,
              ),
              if (isVariationOpen) ...[
                const SizedBox(height: 12),
                _pillBanner(
                  icon: Icons.add_chart_rounded,
                  color: Colors.deepPurple,
                  text: 'Variation detected from edited weight',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _variationReasons[key] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Variation Reason',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (value) => _variationReasons[key] = value,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _DprMarkActionMode { none, inProgress, completed }

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
            !widget.completedMarks.contains(mark) &&
            (widget.completedAction || !widget.inProgressMarks.contains(mark)))
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
                  final selectable = enabled &&
                      !completed &&
                      (widget.completedAction || !inProgress);
                  return Container(
                    color: color,
                    child: CheckboxListTile(
                      value: completed ||
                          selected ||
                          (!widget.completedAction && inProgress),
                      onChanged: !selectable
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

class _VariationResponse {
  final String reason;
  final String remarks;

  const _VariationResponse({
    required this.reason,
    required this.remarks,
  });
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
