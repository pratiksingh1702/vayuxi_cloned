import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/custom_scrollbar.dart';
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
  static const String _defaultTeamId = '__default_team__';
  static const PebTeam _defaultTeam =
      PebTeam(id: _defaultTeamId, name: 'Default Team');

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
  bool _isDprSelectionMode = false;
  final Set<String> _selectedDetailMarks = {};
  PebMarkStatus _status =
      const PebMarkStatus(completedByKey: {}, inProgressByKey: {});

  bool get _isDefaultTeamSelected => _teamId == _defaultTeamId;

  String get _submitTeamId => _isDefaultTeamSelected ? '' : _teamId;

  // Mark search / sort / filter
  String _markSearchQuery = '';
  bool _markSortAz = true; // true = A→Z, false = Z→A
  String? _markFilterStatus; // null = all, 'pending', 'inProgress', 'completed'
  final TextEditingController _markSearchCtrl = TextEditingController();

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
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
      _status = const PebMarkStatus(completedByKey: {}, inProgressByKey: {});
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _markSearchCtrl.dispose();
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
      final displayTeams = teams.isEmpty ? const [_defaultTeam] : teams;
      final selectedTeamId = displayTeams.any((team) => team.id == _teamId)
          ? _teamId
          : displayTeams.first.id;
      final results = await Future.wait([
        _service.getSetup(widget.siteId, widget.executionType),
        _service.getBoqs(widget.siteId),
        _service.getAssignments(widget.siteId, widget.executionType,
            teamId: _isDefaultTeamId(selectedTeamId) ? null : selectedTeamId,
            status: 'all'),
        _service.getDprMarkStatus(widget.siteId, widget.executionType),
      ]);

      if (!mounted) return;
      setState(() {
        _teams = displayTeams;
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
          _isDprSelectionMode = false;
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

  bool _isDefaultTeamId(String teamId) => teamId == _defaultTeamId;

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
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
    });
  }

  void _closeWorkDetail() {
    setState(() {
      _activeWorkKey = null;
      _markActionMode = _DprMarkActionMode.none;
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
    });
  }

  void _handleWorkBack() {
    if (_markActionMode != _DprMarkActionMode.none) {
      setState(() {
        _markActionMode = _DprMarkActionMode.none;
        _isDprSelectionMode = false;
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
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: layout.compact ? 7 : 8,
          vertical: layout.compact ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: layout.compact ? 20 : 22,
              height: layout.compact ? 20 : 22,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 13),
            ),
            SizedBox(width: layout.compact ? 4 : 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: layout.compact ? 9.5 : 10,
                  ),
                ),
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
    return _displayMarksForWork(work).any((mark) {
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
    setState(() {
      _markActionMode = mode;
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
    });
  }

  void _toggleDetailMark(_VisibleWork work, String mark) {
    if (_markActionMode == _DprMarkActionMode.none) {
      return;
    }
    final completed = _completedForWork(work).contains(mark);
    final inProgress = _inProgressForWork(work).contains(mark);
    final unlocked = _unlockedMarksForWork(work).contains(mark);
    if ((!completed && !unlocked) ||
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

  void _toggleSelectAll(_VisibleWork work) {
    if (!_isDprSelectionMode || _markActionMode == _DprMarkActionMode.none) {
      return;
    }
    final selectableMarks = _selectableMarksForWork(work);

    if (selectableMarks.isEmpty) return;

    final allSelected = selectableMarks.every(_selectedDetailMarks.contains);

    setState(() {
      if (allSelected) {
        for (final mark in selectableMarks) {
          _selectedDetailMarks.remove(mark);
        }
      } else {
        _selectedDetailMarks.addAll(selectableMarks);
      }
    });
  }

  List<String> _selectableMarksForWork(_VisibleWork work) {
    final visibleMarks = _filteredSortedMarks(work);
    final inProgressMarks = _inProgressForWork(work);

    return visibleMarks.where((mark) {
      final locked = _nextPendingPrerequisite(work, mark) != null;
      final inProgress = inProgressMarks.contains(mark);

      return !locked &&
          !(_markActionMode == _DprMarkActionMode.inProgress && inProgress);
    }).toList();
  }

  void _selectAllMarks(_VisibleWork work) {
    final selectableMarks = _selectableMarksForWork(work);
    if (selectableMarks.isEmpty) {
      AppToast.info(
          'No selectable marks available. Some might be locked or already in progress.');
      return;
    }
    setState(() => _selectedDetailMarks.addAll(selectableMarks));
  }

  void _deselectAllMarks(_VisibleWork work) {
    final selectableMarks = _selectableMarksForWork(work);
    setState(() {
      for (final mark in selectableMarks) {
        _selectedDetailMarks.remove(mark);
      }
    });
  }

  Widget _selectionOptionsRow(_VisibleWork work) {
    final visibleMarks = _filteredSortedMarks(work);
    if (visibleMarks.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dprHeaderActionButton(
            label: 'Cancel',
            icon: Icons.close,
            textColor: cs.onSurfaceVariant,
            bgColor: cs.surfaceContainerHigh,
            onTap: () => setState(() {
              _isDprSelectionMode = false;
              _selectedDetailMarks.clear();
            }),
          ),
          const SizedBox(width: 8),
          _dprHeaderActionButton(
            label: 'Select All',
            icon: Icons.done_all,
            textColor: cs.primary,
            bgColor: cs.primaryContainer,
            onTap: () => _selectAllMarks(work),
          ),
          const SizedBox(width: 8),
          _dprHeaderActionButton(
            label: 'Deselect All',
            icon: Icons.remove_done,
            textColor: cs.onError,
            bgColor: cs.error,
            onTap: _selectedDetailMarks.isEmpty
                ? null
                : () => _deselectAllMarks(work),
          ),
        ],
      ),
    );
  }

  Widget _dprHeaderActionButton({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    final layout = _PebDprResponsive.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: layout.compact ? 7 : 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: onTap == null ? bgColor.withValues(alpha: 0.45) : bgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: textColor),
              SizedBox(width: layout.compact ? 3 : 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: layout.compact ? 9.5 : 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dprHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: layout.compact ? 36 : 38,
            height: layout.compact ? 36 : 38,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
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
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
    });
    await _load(showLoader: true, autoScroll: true);
  }

  List<_VisibleWork> _visibleWorks() {
    final setup = _setup;
    if (setup == null) return [];
    final teamAssignments = _assignments
        .where((assignment) =>
            !_isDefaultTeamSelected &&
            assignment.teamId == _teamId &&
            assignment.status != 'cancelled')
        .toList();
    final allValidAssignments = _assignments
        .where((assignment) => assignment.status != 'cancelled')
        .toList();
    final fallbackAllowed = setup.allowUnassignedDprFallback &&
        (_isDefaultTeamSelected
            ? true
            : _teamId.isNotEmpty
                ? teamAssignments.isEmpty
                : allValidAssignments.isEmpty);

    if (fallbackAllowed) {
      return setup.items.map((setupItem) {
        final marks = _allMarks
            .map((mark) => mark.assemblyMark)
            .where((mark) => mark.isNotEmpty)
            .toList();
        return _VisibleWork(
          key: setupItem.id,
          setupItem: setupItem,
          assignmentId: '',
          sourceType: 'boq_upload',
          stageName: setupItem.name,
          assignedMarks: marks,
          assignedQty: marks.length.toDouble(),
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
          inactiveReason: _isDefaultTeamSelected
              ? 'No work assignment found. Showing BOQ fallback.'
              : _teamId.isEmpty
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
    final marks = _displayMarksForWork(work);
    final prev = _previousSetupItem(work);
    if (prev == null || marks.isEmpty) return marks;
    final previousCompleted = _status.completedByKey[prev.id] ?? <String>{};
    return marks.where(previousCompleted.contains).toList();
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
    for (final mark in _displayMarksForWork(work)) {
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
    final marks = _displayMarksForWork(work);
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

  List<String> _displayMarksForWork(_VisibleWork work) {
    final seen = <String>{};
    final marks = <String>[];
    for (final mark in work.assignedMarks) {
      final normalized = mark.trim();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      marks.add(normalized);
    }
    return marks;
  }

  bool _isWorkFullyCompleted(_VisibleWork work) {
    if (!work.isActive) return false;
    final completed = _completedForWork(work);
    final marks = _displayMarksForWork(work);
    if (marks.isNotEmpty) {
      return marks.every(completed.contains);
    }
    final counts = _counts(work);
    return counts.total > 0 && counts.completed >= counts.total;
  }

  bool _hasUnlockedScope(_VisibleWork work) {
    if (_displayMarksForWork(work).isEmpty) return work.assignedQty > 0;
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
    final rawMarks = _displayMarksForWork(work);
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
        _isDprSelectionMode = false;
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
      final progressUom = marks.isNotEmpty && work.sourceType != 'tonnage'
          ? 'Nos'
          : work.setupItem.uom;
      await _service.submitDprProgress(
        widget.siteId,
        widget.executionType,
        date: _dateText,
        teamId: _submitTeamId,
        setupItemId: work.setupItem.id,
        assignmentId: work.assignmentId,
        sourceType: work.sourceType,
        stageName: work.stageName,
        uom: progressUom,
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
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final works = _visibleWorks();
    final activeWork = _activeWork(works);
    final activeMarks = activeWork == null
        ? const <String>[]
        : _displayMarksForWork(activeWork);
    final assignedWorks = works.where((work) => work.isActive).toList();
    final screenTitle = activeWork == null
        ? '${widget.executionType.title} DPR'
        : activeWork.displayName ?? activeWork.stageName;
    return PopScope(
      canPop: _activeWorkKey == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _activeWorkKey != null) {
          _handleWorkBack();
        }
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: CustomAppBar(title: screenTitle),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildLoadErrorState()
                : _teams.isEmpty
                    ? _buildNoTeamsState()
                    : Stack(
                        children: [
                          CustomScrollbar(
                            controller: _scrollController,
                            child: RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  layout.pagePadding,
                                  layout.pagePadding,
                                  layout.pagePadding,
                                  0,
                                ),
                                children: activeWork == null
                                    ? [
                                        _buildFilters(),
                                        SizedBox(height: layout.sectionGap),
                                        _buildAssignedWorkHeader(assignedWorks),
                                        SizedBox(height: layout.cardGap),
                                        if (assignedWorks.isEmpty)
                                          _boqs.isEmpty
                                              ? _buildNoBoqState()
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        cs.surfaceContainerLow,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    border: Border.all(
                                                        color: cs.outlineVariant
                                                            .withOpacity(0.5)),
                                                  ),
                                                  padding: EdgeInsets.all(
                                                      layout.cardPadding),
                                                  child: Text(
                                                    'No assigned work found for this team.',
                                                    style: TextStyle(
                                                      color:
                                                          cs.onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                        else
                                          ...assignedWorks.asMap().entries.map(
                                                (entry) => KeyedSubtree(
                                                  key: _keyForWork(
                                                      entry.value, entry.key),
                                                  child: _buildWorkCard(
                                                      entry.value),
                                                ),
                                              ),
                                        SizedBox(
                                          height: 84 +
                                              MediaQuery.paddingOf(context)
                                                  .bottom,
                                        ),
                                      ]
                                    : _markActionMode == _DprMarkActionMode.none
                                        ? [
                                            _buildWorkDetailHeader(activeWork),
                                            SizedBox(
                                              height: 84 +
                                                  MediaQuery.paddingOf(context)
                                                      .bottom,
                                            ),
                                          ]
                                        : [
                                            _buildWorkDetailHeader(activeWork),
                                            SizedBox(height: layout.cardGap),
                                            _buildMarkSearchBar(activeWork),
                                            SizedBox(height: layout.smallGap),
                                            ..._filteredSortedMarks(activeWork)
                                                .map(
                                              (mark) => _buildMarkEntryCardV2(
                                                activeWork,
                                                mark,
                                                enabled: _unlockedMarksForWork(
                                                        activeWork)
                                                    .contains(mark),
                                              ),
                                            ),
                                            if (_filteredSortedMarks(activeWork)
                                                    .isEmpty &&
                                                activeMarks.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        layout.sectionGap * 2),
                                                child: Center(
                                                  child: Text(
                                                    'No marks match "$_markSearchQuery"',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (activeMarks.isEmpty)
                                              _buildQuantityWorkEntryCard(
                                                  activeWork),
                                            SizedBox(
                                              height: 150 +
                                                  MediaQuery.paddingOf(context)
                                                      .bottom,
                                            ),
                                          ],
                              ),
                            ),
                          ),
                          if (activeWork != null && activeMarks.isNotEmpty)
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
    final layout = _PebDprResponsive.of(context);
    return CustomScrollbar(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(layout.emptyStatePadding),
          children: [
            SizedBox(height: layout.emptyStateTopGap),
            Icon(Icons.cloud_off_rounded,
                size: layout.emptyStateIconSize, color: cs.error),
            SizedBox(height: layout.sectionGap),
            Text(
              'Unable to load DPR Entry',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: layout.emptyStateTitleSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: layout.smallGap),
            Text(
              _loadError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: layout.sectionGap),
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
      ),
    );
  }

  Widget _buildNoTeamsState() {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return CustomScrollbar(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(layout.emptyStatePadding),
          children: [
            SizedBox(height: layout.emptyStateTopGap),
            Icon(Icons.groups_2_outlined,
                size: layout.emptyStateIconSize + 4, color: cs.primary),
            SizedBox(height: layout.sectionGap),
            Text(
              'No team available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: layout.emptyStateTitleSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: layout.smallGap),
            Text(
              'Create a ${widget.executionType.title} team in Setup > Team, then return here to enter DPR progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
            ),
            SizedBox(height: layout.sectionGap),
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
      ),
    );
  }

  Widget _buildNoBoqState() {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      padding: EdgeInsets.all(layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.playlist_add_rounded,
              color: cs.primary, size: layout.compact ? 30 : 34),
          SizedBox(height: layout.cardGap),
          Text(
            'No BOQ marks available',
            style: TextStyle(
              fontSize: layout.compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: layout.smallGap),
          Text(
            'Add BOQ items manually or upload BOQ first, then return here for DPR entry.',
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
          ),
          SizedBox(height: layout.cardGap),
          FilledButton.icon(
            onPressed: () => context.push('/site-list/boq-upload'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add BOQ Items'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Site + Type Banner ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            layout.cardPadding,
            layout.compact ? 12 : 14,
            layout.cardPadding,
            layout.compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer.withOpacity(0.55),
                cs.secondaryContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Site icon
              Container(
                width: layout.filterIconSize,
                height: layout.filterIconSize,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_city_rounded,
                    color: cs.primary, size: layout.compact ? 20 : 22),
              ),
              SizedBox(width: layout.cardGap),
              // Site name + execution type + team
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.siteName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.executionType.title} DPR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (_teamId.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        _teams
                            .firstWhere(
                              (t) => t.id == _teamId,
                              orElse: () => const PebTeam(id: '', name: ''),
                            )
                            .name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Date chip
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.compact ? 8 : 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: cs.primary.withOpacity(0.25), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: layout.compact ? 12 : 13, color: cs.primary),
                      SizedBox(width: layout.compact ? 4 : 5),
                      Text(
                        DateFormat('dd MMM yy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: layout.compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_submitting)
          Padding(
            padding: EdgeInsets.only(top: layout.smallGap),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignedWorkHeader(List<_VisibleWork> assignedWorks) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Assigned Work",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: layout.compact ? 10.5 : 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: layout.compact ? 10 : 12,
            vertical: layout.compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: assignedWorks.isEmpty
                ? cs.surfaceContainerHighest
                : cs.primaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: assignedWorks.isEmpty
                  ? cs.outlineVariant
                  : cs.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_rounded,
                size: 14,
                color: assignedWorks.isEmpty ? cs.onSurfaceVariant : cs.primary,
              ),
              SizedBox(width: layout.compact ? 4 : 5),
              Text(
                '${assignedWorks.length}',
                style: TextStyle(
                  color:
                      assignedWorks.isEmpty ? cs.onSurfaceVariant : cs.primary,
                  fontSize: layout.compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: layout.compact ? 3 : 4),
              Text(
                'items',
                style: TextStyle(
                  color:
                      assignedWorks.isEmpty ? cs.onSurfaceVariant : cs.primary,
                  fontSize: layout.compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkCard(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final counts = _counts(work);
    final isCompleted = _isWorkFullyCompleted(work);
    final deadline = work.expectedCompletionDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(work.expectedCompletionDate!);
    final completedDate = _completedDateForWork(work);
    final completion = counts.total > 0
        ? (counts.completed / counts.total).clamp(0.0, 1.0)
        : 0.0;
    final workUom =
        work.setupItem.uom.trim().isEmpty ? '-' : work.setupItem.uom.trim();

    final today =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final tcd = work.expectedCompletionDate != null
        ? DateTime(
            work.expectedCompletionDate!.year,
            work.expectedCompletionDate!.month,
            work.expectedCompletionDate!.day)
        : null;
    final days = tcd != null ? tcd.difference(today).inDays : 0;
    final missed = days < 0;

    Widget headerBadge;
    if (isCompleted && completedDate != null) {
      headerBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 12, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green),
            ),
          ],
        ),
      );
    } else if (work.expectedCompletionDate != null) {
      final badgeColor = missed ? Colors.red : cs.primary;
      headerBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Text(
          missed ? 'Overdue' : 'TCD: $deadline',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
        ),
      );
    } else {
      headerBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: cs.onSurfaceVariant.withOpacity(0.3)),
        ),
        child: Text(
          'TCD not set',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant),
        ),
      );
    }

    final card = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openWorkDetail(work),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                layout.cardPadding,
                layout.cardPadding - 2,
                layout.cardPadding,
                layout.smallGap,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      work.displayName ?? work.stageName,
                      style: TextStyle(
                        fontSize: layout.compact ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: layout.smallGap),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: headerBadge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.cardPadding,
                        0,
                        layout.columnGap / 2,
                        layout.cardPadding,
                      ),
                      child: SizedBox(
                        height: layout.workImageHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(layout.imageInset),
                            child: Image(
                              image: pebWorkImageProvider(
                                work.setupItem,
                                widget.executionType,
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) =>
                                  pebWorkImageFallback(
                                work.setupItem,
                                widget.executionType,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.columnGap / 2,
                        0,
                        layout.cardPadding,
                        layout.cardPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: layout.compact ? 7 : 8,
                              horizontal: layout.compact ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'UOM',
                                      style: TextStyle(
                                        fontSize: layout.miniLabelSize,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          workUom,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: layout.compact ? 12 : 13,
                                            fontWeight: FontWeight.w800,
                                            color: cs.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: layout.compact ? 6 : 7),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: cs.outlineVariant.withOpacity(0.35),
                                ),
                                SizedBox(height: layout.compact ? 6 : 7),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _minimalWorkCountBlock(
                                        'Assign',
                                        counts.total,
                                        cs.onSurface,
                                        cs,
                                      ),
                                    ),
                                    _workStatDivider(cs),
                                    Expanded(
                                      child: _minimalWorkCountBlock(
                                        'In Progress',
                                        counts.inProgress,
                                        Colors.orange,
                                        cs,
                                      ),
                                    ),
                                    _workStatDivider(cs),
                                    Expanded(
                                      child: _minimalWorkCountBlock(
                                        'Complete',
                                        counts.completed,
                                        Colors.green,
                                        cs,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: layout.smallGap),
                          _completionBar(
                            value: completion,
                            color: Colors.green.shade700,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                          if (work.expectedCompletionDate != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              missed
                                  ? '${days.abs()} days overdue'
                                  : '$days days remaining',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: missed
                                    ? Colors.red.shade700
                                    : cs.onSurfaceVariant,
                                fontSize: layout.compact ? 9.5 : 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          SizedBox(height: layout.smallGap),
                          Container(
                            height: layout.workButtonHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Update Progress',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: layout.compact ? 10 : 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: layout.compact ? 15 : 16,
                                    color: cs.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

    return Opacity(
      opacity: isCompleted
          ? 0.72
          : work.isActive
              ? 1
              : 0.46,
      child: Container(
        margin: EdgeInsets.only(bottom: layout.cardGap),
        child: card,
      ),
    );
  }

  Widget _workStatDivider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: cs.outlineVariant.withOpacity(0.5),
    );
  }

  Widget _minimalWorkCountBlock(
    String label,
    int count,
    Color color,
    ColorScheme cs,
  ) {
    final layout = _PebDprResponsive.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _minimalWorkBlockLabel(label, cs),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count',
            maxLines: 1,
            style: TextStyle(
              fontSize: layout.compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _minimalWorkBlockLabel(String label, ColorScheme cs) {
    final layout = _PebDprResponsive.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: layout.miniLabelSize,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
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
      return Align(
        alignment: Alignment.center,
        child: _compactPillBanner(
          icon: Icons.check_circle,
          color: Colors.green.shade700,
          text:
              'Completed on ${DateFormat('dd MMM yyyy').format(completedDate)}',
        ),
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

  /// Read-only blue box matching AssemblyCardWidget._blueBox style.
  Widget _assemblyBlueBox({
    required String label,
    required String value,
    required ColorScheme cs,
  }) {
    const blueFill = Color.fromARGB(255, 255, 255, 255);
    const darkBlueFill = Color(0xFF1E3A5F);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        Container(
          height: 26,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? darkBlueFill : cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactPillBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailHeader(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final inProgressColor = const Color(0xFFE56F00);
    final completedColor = Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                work.displayName ?? work.stageName,
                style: TextStyle(
                  fontSize: layout.detailTitleSize,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_markActionMode != _DprMarkActionMode.none)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final isIncoming =
                      animation.status == AnimationStatus.forward ||
                          animation.status == AnimationStatus.completed;
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutQuart,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(isIncoming ? 0.2 : -0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      )),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _isDprSelectionMode
                    ? KeyedSubtree(
                        key: const ValueKey('actions'),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dprHeaderActionButton(
                                label: 'Cancel',
                                icon: Icons.close,
                                textColor: cs.onSurfaceVariant,
                                bgColor: cs.surfaceContainerHigh,
                                onTap: () => setState(() {
                                  _isDprSelectionMode = false;
                                  _selectedDetailMarks.clear();
                                }),
                              ),
                              SizedBox(width: layout.compact ? 4 : 6),
                              _dprHeaderActionButton(
                                label: 'Select All',
                                icon: Icons.done_all,
                                textColor: cs.primary,
                                bgColor: cs.primaryContainer,
                                onTap: () => _selectAllMarks(work),
                              ),
                              SizedBox(width: layout.compact ? 4 : 6),
                              _dprHeaderActionButton(
                                label: 'Deselect All',
                                icon: Icons.remove_done,
                                textColor: cs.onError,
                                bgColor: cs.error,
                                onTap: _selectedDetailMarks.isEmpty
                                    ? null
                                    : () => _deselectAllMarks(work),
                              ),
                            ],
                          ),
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('icon'),
                        child: _dprHeaderIconButton(
                          icon: Icons.checklist_rounded,
                          tooltip: 'Select Items',
                          iconColor: cs.primary,
                          onTap: () =>
                              setState(() => _isDprSelectionMode = true),
                        ),
                      ),
              ),
          ],
        ),
        SizedBox(height: layout.smallGap),
        Text(
          'Entry date: ${DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: layout.compact ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: layout.smallGap),
        if (_markActionMode == _DprMarkActionMode.none) ...[
          Text(
            'Whether your work is?',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: layout.compact ? 15 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: layout.cardGap),
          Row(
            children: [
              Expanded(
                child: _statusChoiceButton(
                  label: 'In Progress',
                  icon: Icons.pending_actions_rounded,
                  color: inProgressColor,
                  onTap: () => _startMarkAction(_DprMarkActionMode.inProgress),
                ),
              ),
              SizedBox(width: layout.cardGap),
              Expanded(
                child: _statusChoiceButton(
                  label: 'Completed',
                  icon: Icons.check_circle_rounded,
                  color: completedColor,
                  onTap: () => _startMarkAction(_DprMarkActionMode.completed),
                ),
              ),
            ],
          ),
        ] else
          Text(
            _markActionMode == _DprMarkActionMode.completed
                ? 'Select mark numbers to complete.'
                : 'Select mark numbers to mark as in progress.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityWorkEntryCard(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      padding: EdgeInsets.all(layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quantity based work',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: layout.cardGap),
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
    );
  }

  Widget _buildDetailBottomBar(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final canSave = _markActionMode != _DprMarkActionMode.none &&
        _selectedDetailMarks.isNotEmpty;
    if (!canSave) return const SizedBox.shrink();
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
          padding: EdgeInsets.fromLTRB(
            layout.cardPadding,
            layout.compact ? 10 : 12,
            layout.cardPadding,
            layout.compact ? 10 : 12,
          ),
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
                    _isDprSelectionMode = false;
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
              SizedBox(width: layout.cardGap),
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

  // ─── Mark Search / Sort / Filter helpers ───────────────────────────────────

  /// Fuzzy-filters and sorts the mark numbers for [work].
  List<String> _filteredSortedMarks(_VisibleWork work) {
    final allMarks = _displayMarksForWork(work);
    final q = _markSearchQuery.trim().toLowerCase();

    var result = allMarks.where((mark) {
      // Status filter
      if (_markFilterStatus != null) {
        final completed = _completedForWork(work).contains(mark);
        final inProgress = _inProgressForWork(work).contains(mark);
        if (_markFilterStatus == 'completed' && !completed) return false;
        if (_markFilterStatus == 'inProgress' && !inProgress) return false;
        if (_markFilterStatus == 'pending' && (completed || inProgress))
          return false;
      }
      // Fuzzy search — mark no OR description OR assembly mark
      if (q.isEmpty) return true;
      final boqMark = _boqMarkFor(mark);
      final desc = (boqMark?.typeDescription ?? '').toLowerCase();
      final assemblyMark = (boqMark?.assemblyMark ?? '').toLowerCase();
      final markLower = mark.toLowerCase();
      // Contains match (lenient — partial anywhere)
      return markLower.contains(q) ||
          desc.contains(q) ||
          assemblyMark.contains(q);
    }).toList();

    // Sort
    result.sort((a, b) => _markSortAz ? a.compareTo(b) : b.compareTo(a));
    return result;
  }

  /// Search bar + filter button in manpowerList style.
  Widget _buildMarkSearchBar(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final hasFilters = _markFilterStatus != null || !_markSortAz;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _markSearchCtrl,
              onChanged: (val) => setState(() => _markSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search mark no. or description…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _markSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _markSearchCtrl.clear();
                          setState(() => _markSearchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: cs.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: layout.compact ? 10 : 12,
                  vertical: layout.compact ? 9 : 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          SizedBox(width: layout.smallGap),
          // Filter/Sort button — matches manpowerList _buildFilterButton
          GestureDetector(
            onTap: () => _showMarkFilterSheet(work),
            child: Container(
              height: 40,
              width: layout.compact ? 38 : 40,
              decoration: BoxDecoration(
                color: hasFilters ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFilters ? cs.primary : cs.outlineVariant,
                ),
                boxShadow: hasFilters
                    ? [
                        BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: hasFilters ? cs.onPrimary : cs.primary,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary, width: 1.5),
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

  void _showMarkFilterSheet(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height *
              (layout.compact ? 0.76 : 0.70),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: layout.compact ? 16 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sort & Filter',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    TextButton(
                      onPressed: () {
                        setModal(() {
                          _markSortAz = true;
                          _markFilterStatus = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(layout.compact ? 16 : 20),
                  children: [
                    // SORT SECTION
                    _buildSectionTitle('Sort By'),
                    SizedBox(height: layout.cardGap),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip(
                          setModal,
                          'Mark A → Z',
                          _markSortAz,
                          Icons.sort_by_alpha_rounded,
                          () {
                            setModal(() => _markSortAz = true);
                            setState(() {});
                          },
                        ),
                        _buildSortChip(
                          setModal,
                          'Mark Z → A',
                          !_markSortAz,
                          Icons.sort_rounded,
                          () {
                            setModal(() => _markSortAz = false);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: layout.sectionGap),

                    // FILTER BY STATUS
                    _buildSectionTitle('Filter by Status'),
                    SizedBox(height: layout.cardGap),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _markFilterChip('All', _markFilterStatus == null, () {
                          setModal(() => _markFilterStatus = null);
                          setState(() {});
                        }),
                        _markFilterChip(
                            'Pending', _markFilterStatus == 'pending', () {
                          setModal(() => _markFilterStatus = 'pending');
                          setState(() {});
                        }),
                        _markFilterChip(
                            'In Progress', _markFilterStatus == 'inProgress',
                            () {
                          setModal(() => _markFilterStatus = 'inProgress');
                          setState(() {});
                        }),
                        _markFilterChip(
                            'Completed', _markFilterStatus == 'completed', () {
                          setModal(() => _markFilterStatus = 'completed');
                          setState(() {});
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              // Apply Button
              Padding(
                padding: EdgeInsets.all(layout.compact ? 16 : 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSortChip(
    StateSetter setModalState,
    String label,
    bool isSelected,
    IconData icon,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? cs.onPrimary : cs.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _markFilterChip(String label, bool selected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      backgroundColor: cs.surface,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
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
    final layout = _PebDprResponsive.of(context);
    final key = _markInputKey(work, markNumber);
    final boqMark = _boqMarkFor(markNumber);
    final boqDescription = (boqMark?.typeDescription ?? '').trim();
    final title = boqDescription.isNotEmpty
        ? boqDescription
        : work.displayName ?? work.stageName;
    final completed = _completedForWork(work).contains(markNumber);
    final inProgress = _inProgressForWork(work).contains(markNumber);
    final selected = _selectedDetailMarks.contains(markNumber);
    final checkboxChecked = selected || completed;
    final completedContentOpacity = completed ? 0.58 : 1.0;
    final completedSecondaryOpacity = completed ? 0.68 : 1.0;
    final pendingPrerequisite = _nextPendingPrerequisite(work, markNumber);
    final selectable = _markActionMode != _DprMarkActionMode.none &&
        (enabled || completed) &&
        pendingPrerequisite == null &&
        !(_markActionMode == _DprMarkActionMode.inProgress && inProgress);
    final actionComplete =
        selected && _markActionMode == _DprMarkActionMode.completed;
    final actionProgress =
        selected && _markActionMode == _DprMarkActionMode.inProgress;
    final effectiveCompleted = completed || actionComplete;
    final effectiveInProgress =
        !effectiveCompleted && (inProgress || actionProgress);
    final locked = pendingPrerequisite != null && !completed && !inProgress;
    final editable = enabled || completed || inProgress;
    final weightKg = _markWeightKg(markNumber);
    final isVariationOpen = _isWeightChanged(work, markNumber);
    final inProgressColor = const Color(0xFFE56F00);
    final selectedIndicatorColor =
        completed || actionComplete ? Colors.green.shade700 : inProgressColor;
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
    void handleUnavailableSelection() {
      if (locked) {
        AppToast.info(_prerequisiteMessage(pendingPrerequisite));
      } else if (_markActionMode == _DprMarkActionMode.inProgress &&
          inProgress) {
        AppToast.info('This mark number is already in progress.');
      } else if (!enabled) {
        AppToast.info('Please complete the previous task before proceeding.');
      }
    }

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: selected ? 1.8 : 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selectable
            ? () => _toggleDetailMark(work, markNumber)
            : locked
                ? handleUnavailableSelection
                : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area: Title & Remark on top, Mark Number & Status Badge below
            Padding(
              padding: EdgeInsets.fromLTRB(
                layout.cardPadding,
                layout.cardPadding - 2,
                layout.cardPadding,
                layout.smallGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Heading (Left) & Remark (Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: selectable
                            ? () => _toggleDetailMark(work, markNumber)
                            : handleUnavailableSelection,
                        child: Padding(
                          padding: EdgeInsets.only(top: layout.compact ? 1 : 0),
                          child: SizedBox(
                            width: layout.compact ? 34 : 38,
                            height: layout.compact ? 32 : 34,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOut,
                                width: layout.compact ? 23 : 25,
                                height: layout.compact ? 23 : 25,
                                decoration: BoxDecoration(
                                  color: checkboxChecked
                                      ? selectedIndicatorColor
                                      : selectable
                                          ? cs.surface
                                          : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: checkboxChecked
                                        ? selectedIndicatorColor
                                        : selectable
                                            ? cs.primary
                                            : cs.outlineVariant,
                                    width: checkboxChecked ? 2.2 : 1.8,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: selectedIndicatorColor
                                                .withValues(alpha: 0.22),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: checkboxChecked
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                        weight: 700,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: layout.smallGap),
                      Expanded(
                        child: Opacity(
                          opacity: completedContentOpacity,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: layout.compact ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: layout.smallGap),
                      // RIGHT: tappable remarks corner pill (matches assembly_card / piping_card)
                      InkWell(
                        onTap: editable
                            ? () async {
                                var draftRemark = _markRemarks[key] ?? '';
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => Padding(
                                    padding: EdgeInsets.only(
                                      left: layout.cardPadding + 4,
                                      right: layout.cardPadding + 4,
                                      top: layout.cardPadding + 4,
                                      bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom +
                                          24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Remarks — Mark $markNumber',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          initialValue: draftRemark,
                                          autofocus: true,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText: 'Enter remark…',
                                            filled: true,
                                            fillColor:
                                                cs.surfaceContainerHighest,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                          ),
                                          onChanged: (value) =>
                                              draftRemark = value,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() =>
                                                      _markRemarks[key] =
                                                          draftRemark.trim());
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Opacity(
                          opacity: completedContentOpacity,
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: layout.compact ? 68 : 78,
                              maxWidth: layout.compact ? 92 : 110,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: layout.compact ? 7 : 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  cs.secondaryContainer.withValues(alpha: 0.7),
                              border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                (_markRemarks[key] ?? '').trim().isNotEmpty
                                    ? _markRemarks[key]!
                                    : 'Remark',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSecondaryContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body Area (2 Columns) — AssemblyCardWidget design
            IntrinsicHeight(
              child: Row(
                children: [
                  // LEFT COLUMN: Image & Checkbox action row
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(layout.cardPadding - 1),
                      child: Opacity(
                        opacity: completedContentOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: layout.compact ? 2 : 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: layout.v2ImageHeight,
                                padding: EdgeInsets.all(layout.imageInset),
                                child: Image(
                                  image: pebWorkImageProvider(
                                      work.setupItem, widget.executionType),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, __, ___) =>
                                      pebWorkImageFallback(
                                    work.setupItem,
                                    widget.executionType,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // RIGHT COLUMN: stretches to match image height via mainAxisSize.max + Spacers
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(layout.cardPadding - 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Opacity(
                            opacity: completedSecondaryOpacity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _assemblyBlueBox(
                                    label: 'Mark No.',
                                    value: markNumber,
                                    cs: cs,
                                  ),
                                ),
                                SizedBox(width: layout.smallGap),
                                Expanded(
                                  child: _assemblyBlueBox(
                                    label: 'Qty',
                                    value: _prettyNumber(
                                        _markQuantity(markNumber)),
                                    cs: cs,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Weight field
                          Text(
                            'Weight (Kg)',
                            style: TextStyle(
                              fontSize: layout.miniLabelSize,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: _markQuantityInputs[key] ??
                                _prettyNumber(weightKg),
                            enabled: editable,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: layout.compact ? 15 : 16,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: cs.surface,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: layout.compact ? 8 : 10,
                                vertical: layout.compact ? 9 : 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: cs.outlineVariant.withOpacity(0.5)),
                              ),
                            ),
                            onChanged: (value) => setState(
                                () => _markQuantityInputs[key] = value),
                          ),
                          const Spacer(),
                          SizedBox(height: layout.compact ? 24 : 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isVariationOpen || locked)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.cardPadding,
                  0,
                  layout.cardPadding,
                  layout.cardPadding - 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isVariationOpen) ...[
                      SizedBox(height: layout.smallGap),
                      _pillBanner(
                        icon: Icons.add_chart_rounded,
                        color: statusColor,
                        text: 'Variation detected from edited weight',
                      ),
                      SizedBox(height: layout.smallGap),
                      TextFormField(
                        initialValue: _variationReasons[key] ?? '',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Variation Reason',
                          filled: true,
                          fillColor: cs.surface,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: layout.compact ? 8 : 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (value) => _variationReasons[key] = value,
                      ),
                    ],
                    if (locked) ...[
                      SizedBox(height: layout.smallGap),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.compact ? 10 : 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info,
                                color: Color(0xFFE65100), size: 20),
                            SizedBox(width: layout.smallGap),
                            Expanded(
                              child: Text(
                                _prerequisiteMessage(pendingPrerequisite),
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: layout.cardGap),
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

class _PebDprResponsive {
  final double width;

  const _PebDprResponsive(this.width);

  factory _PebDprResponsive.of(BuildContext context) {
    return _PebDprResponsive(MediaQuery.sizeOf(context).width);
  }

  bool get compact => width <= 360;
  bool get narrow => width < 390;

  double get pagePadding => compact
      ? 12
      : narrow
          ? 14
          : 16;
  double get cardPadding => compact ? 12 : 14;
  double get emptyStatePadding => compact ? 20 : 24;
  double get smallGap => compact ? 6 : 8;
  double get cardGap => compact ? 10 : 12;
  double get sectionGap => compact ? 14 : 18;
  double get columnGap => compact ? 8 : 10;
  double get imageInset => compact ? 6 : 8;
  double get filterIconSize => compact ? 40 : 44;
  double get workButtonHeight => compact ? 30 : 32;
  double get miniLabelSize => compact ? 8.5 : 9;
  double get detailTitleSize => compact
      ? 21
      : narrow
          ? 23
          : 26;
  double get emptyStateTopGap => compact ? 72 : 100;
  double get emptyStateIconSize => compact ? 56 : 64;
  double get emptyStateTitleSize => compact ? 18 : 20;
  double get workImageHeight => compact
      ? 118
      : narrow
          ? 124
          : 130;
  double get v2ImageHeight => compact
      ? 132
      : narrow
          ? 140
          : 150;
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
