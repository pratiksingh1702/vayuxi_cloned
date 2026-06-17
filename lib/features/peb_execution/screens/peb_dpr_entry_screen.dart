import 'dart:ui' as ui;

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
import '../services/dpr_bulk_task_manager.dart';
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
  final _bulkTaskManager = DprBulkTaskManager.instance;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _workCardKeys = {};
  final Set<String> _handledBulkTaskIds = {};
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  DateTime _selectedDate = DateTime.now();
  String _teamId = '';
  PebSetup? _setup;
  PebDprLevel? _dprLevel;
  List<PebTeam> _teams = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  List<PebAssignmentPlanDetail> _planDetails = [];
  List<PebItemWiseDprItem> _itemWiseItems = [];
  final Map<String, String> _level1WeightInputs = {};
  final Map<String, String> _level1UomInputs = {};
  final Map<String, String> _markQuantityInputs = {};
  final Map<String, String> _markRemarks = {};
  final Map<String, String> _variationReasons = {};
  String? _activeWorkKey;
  _DprMarkActionMode _markActionMode = _DprMarkActionMode.none;
  bool _isDprSelectionMode = false;
  final Set<String> _selectedDetailMarks = {};
  PebMarkStatus _status =
      const PebMarkStatus(completedByKey: {}, inProgressByKey: {});
  Map<String, PebLevel1DprEntry> _level1Entries = const {};

  bool get _isDefaultTeamSelected => _teamId == _defaultTeamId;

  String get _submitTeamId => _isDefaultTeamSelected ? '' : _teamId;

  static const String _level1StageMarker = '__level1_stage__';

  // Mark search / filter
  String _markSearchQuery = '';
  String? _markFilterStatus; // null = all, 'pending', 'inProgress', 'completed'
  final TextEditingController _markSearchCtrl = TextEditingController();
  final TextEditingController _itemWiseSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _teamId = widget.initialTeamId;
    _bulkTaskManager.addListener(_handleBulkTaskUpdate);
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
      _dprLevel = null;
      _boqs = [];
      _assignments = [];
      _planDetails = [];
      _itemWiseItems = [];
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
    _bulkTaskManager.removeListener(_handleBulkTaskUpdate);
    _scrollController.dispose();
    _markSearchCtrl.dispose();
    _itemWiseSearchCtrl.dispose();
    super.dispose();
  }

  void _handleBulkTaskUpdate() {
    final completed = _bulkTaskManager.lastCompletedTask;
    if (completed == null ||
        _handledBulkTaskIds.contains(completed.id) ||
        completed.siteId != widget.siteId ||
        completed.type != widget.executionType) {
      if (mounted) setState(() {});
      return;
    }

    _handledBulkTaskIds.add(completed.id);
    if (completed.status == DprBulkTaskStatus.completed) {
      final done = completed.processed - completed.failed;
      if (completed.failed > 0) {
        AppToast.error(
          '${completed.stageName} ${completed.actionLabel.toLowerCase()} updated: $done/${completed.total}. ${completed.error ?? ''}',
        );
      } else {
        AppToast.success(
          '${completed.stageName} ${completed.actionLabel.toLowerCase()} updated: $done/${completed.total}',
        );
      }
      _load(showLoader: false, autoScroll: false);
    } else if (completed.status == DprBulkTaskStatus.failed) {
      AppToast.error(completed.error ?? 'DPR bulk update failed');
    }
    if (mounted) setState(() {});
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
      final results = await Future.wait([
        _service.getSetup(widget.siteId, widget.executionType),
        _service.getBoqs(widget.siteId),
        _service.getAssignments(widget.siteId, widget.executionType,
            status: 'all'),
        _service.getAssignmentPlanDetails(
          widget.siteId,
          widget.executionType,
          fromDate: _dateText,
          toDate: _dateText,
        ),
      ]);
      final setup = results[0] as PebSetup?;
      final boqs = results[1] as List<PebBoq>;
      final dprLevel = setup?.dprLevel;
      final apiItemWiseItems = dprLevel == PebDprLevel.itemWiseProgress
          ? await _service.getItemWiseDprItems(
              widget.siteId,
              widget.executionType,
              search: _itemWiseSearchCtrl.text,
            )
          : <PebItemWiseDprItem>[];
      final itemWiseItems = dprLevel == PebDprLevel.itemWiseProgress
          ? _mergeItemWiseItems(
              apiItemWiseItems,
              _boqMarksAsItemWiseItems(boqs),
            )
          : <PebItemWiseDprItem>[];
      final allAssignments = (results[2] as List<PebWorkAssignment>)
          .where((assignment) => assignment.status != 'cancelled')
          .toList();
      final assignedTeamIds = allAssignments
          .map((assignment) => assignment.teamId)
          .where((teamId) => teamId.trim().isNotEmpty)
          .toSet();
      final hasCurrentTeam = displayTeams.any((team) => team.id == _teamId);
      final currentTeamHasAssignment = assignedTeamIds.contains(_teamId);
      final selectedTeamId = hasCurrentTeam &&
              (currentTeamHasAssignment || assignedTeamIds.isEmpty)
          ? _teamId
          : displayTeams
              .firstWhere(
                (team) => assignedTeamIds.contains(team.id),
                orElse: () => displayTeams.first,
              )
              .id;
      final statusResults = await Future.wait([
        _service.getDprMarkStatus(
          widget.siteId,
          widget.executionType,
          date: _dateText,
          teamId: _isDefaultTeamId(selectedTeamId) ? null : selectedTeamId,
        ),
        _service.getLevel1DprEntries(
          widget.siteId,
          widget.executionType,
          date: _dateText,
          teamId: _isDefaultTeamId(selectedTeamId) ? '' : selectedTeamId,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _teams = displayTeams;
        _teamId = selectedTeamId;
        _setup = setup;
        _dprLevel = dprLevel;
        _boqs = boqs;
        _assignments = allAssignments;
        _itemWiseItems = itemWiseItems;
        _status = statusResults[0] as PebMarkStatus;
        _level1Entries = statusResults[1] as Map<String, PebLevel1DprEntry>;
        _planDetails = results[3] as List<PebAssignmentPlanDetail>;
        if (_activeWorkKey != null &&
            !_visibleWorks().any((work) => work.key == _activeWorkKey)) {
          _activeWorkKey = null;
          _markActionMode = _DprMarkActionMode.none;
          _isDprSelectionMode = false;
          _selectedDetailMarks.clear();
        }
        _loadError = null;
      });
      if (dprLevel == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureDprLevelConfigured();
        });
      }
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

  Future<void> _ensureDprLevelConfigured() async {
    if (_setup?.dprLevel != null || _loading || _submitting) return;
    final selected = await showModalBottomSheet<PebDprLevel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DprLevelPickerSheet(
        title: 'Select DPR Entry Level',
        subtitle:
            'This site does not have a DPR level configured yet. Select one to continue.',
      ),
    );
    if (selected == null) return;
    setState(() => _submitting = true);
    try {
      await _service.updateDprLevel(
          widget.siteId, widget.executionType, selected);
      AppToast.success('${selected.title} selected');
      await _load(showLoader: true, autoScroll: true);
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _dateText => _selectedDate.toIso8601String().split('T').first;

  List<PebBoqMark> get _allMarks => _boqs.expand((boq) => boq.items).toList();

  List<PebItemWiseDprItem> _boqMarksAsItemWiseItems(List<PebBoq> boqs) {
    final byMark = <String, PebItemWiseDprItem>{};
    for (final boq in boqs) {
      for (final mark in boq.items) {
        final markNo = mark.assemblyMark.trim().isNotEmpty
            ? mark.assemblyMark.trim()
            : mark.detailedMark.trim();
        if (markNo.isEmpty) continue;
        final key = markNo.toUpperCase();
        final existing = byMark[key];
        final weight = mark.totalNetWeight > 0
            ? mark.totalNetWeight
            : mark.netWeightPerUnit > 0
                ? mark.netWeightPerUnit * mark.quantity
                : mark.quantity;
        if (existing == null) {
          byMark[key] = PebItemWiseDprItem(
            source: 'boq',
            boqId: boq.id,
            boqItemId: mark.id,
            markNo: markNo,
            description: mark.typeDescription.trim().isNotEmpty
                ? mark.typeDescription.trim()
                : mark.detailedMark.trim(),
            weight: weight,
            uom: weight > 0 ? 'kg' : 'Nos',
          );
        } else {
          byMark[key] = PebItemWiseDprItem(
            source: existing.source,
            boqId: existing.boqId,
            boqItemId: existing.boqItemId,
            markNo: existing.markNo,
            description: existing.description,
            weight: existing.weight + weight,
            uom: existing.uom,
          );
        }
      }
    }
    final rows = byMark.values.toList()
      ..sort((a, b) => a.markNo.compareTo(b.markNo));
    return rows;
  }

  List<PebItemWiseDprItem> _mergeItemWiseItems(
    List<PebItemWiseDprItem> apiItems,
    List<PebItemWiseDprItem> boqItems,
  ) {
    final rows = <String, PebItemWiseDprItem>{};
    for (final item in boqItems) {
      rows[item.markNo.toUpperCase()] = item;
    }
    for (final item in apiItems) {
      final key = item.markNo.toUpperCase();
      rows[key] = item.source == 'manual'
          ? item
          : rows[key] == null
              ? item
              : PebItemWiseDprItem(
                  source: item.source,
                  boqId: item.boqId.isNotEmpty ? item.boqId : rows[key]!.boqId,
                  boqItemId: item.boqItemId.isNotEmpty
                      ? item.boqItemId
                      : rows[key]!.boqItemId,
                  markNo: item.markNo,
                  description: item.description.isNotEmpty
                      ? item.description
                      : rows[key]!.description,
                  weight: item.weight > 0 ? item.weight : rows[key]!.weight,
                  uom: item.uom.isNotEmpty ? item.uom : rows[key]!.uom,
                );
    }
    final list = rows.values.toList()
      ..sort((a, b) => a.markNo.compareTo(b.markNo));
    return list;
  }

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

  PebLevel1DprEntry? _level1EntryFor(_VisibleWork work) {
    if (!work.isLevel1Manual) return null;
    return _level1Entries[work.setupItem.id];
  }

  Future<void> _openWorkDetail(_VisibleWork work) async {
    if (!work.isActive) {
      AppToast.info(work.inactiveReason ?? 'This work is not assigned');
      return;
    }
    if (_dprLevel == PebDprLevel.basicProgress || work.isLevel1Manual) {
      await _openQuantityAction(work, completedAction: false);
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
            textColor: Colors.white,
            bgColor: Colors.green.shade700,
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
    bool flatStyle = false,
    VoidCallback? onTap,
  }) {
    final layout = _PebDprResponsive.of(context);
    final iconSize = flatStyle ? (layout.compact ? 17.0 : 18.0) : 12.0;
    final fontSize = flatStyle ? (layout.compact ? 12.0 : 12.5) : 10.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(flatStyle ? 6 : 999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: flatStyle ? (layout.compact ? 4 : 5) : 8,
            vertical: flatStyle ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: flatStyle
                ? Colors.transparent
                : onTap == null
                    ? bgColor.withValues(alpha: 0.45)
                    : bgColor,
            borderRadius: BorderRadius.circular(flatStyle ? 6 : 999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: textColor),
              SizedBox(width: flatStyle ? 5 : (layout.compact ? 3 : 4)),
              Text(
                flatStyle ? 'Select all' : label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
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
    String? label,
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
            width: label == null ? (layout.compact ? 36 : 38) : null,
            height: layout.compact ? 36 : 38,
            padding: label == null
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(horizontal: layout.compact ? 8 : 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: iconColor),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: layout.compact ? 11.5 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
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
    if (_dprLevel == PebDprLevel.itemWiseProgress) return const [];
    if (_dprLevel == PebDprLevel.basicProgress) {
      return setup.items.map((setupItem) {
        final existing = _level1Entries[setupItem.id];
        final actualQty = existing?.actualQty ?? 0;
        return _VisibleWork(
          key: setupItem.id,
          setupItem: setupItem,
          assignmentId: '',
          sourceType: 'level1_manual',
          stageName: setupItem.name,
          assignedMarks: const [],
          assignedQty: actualQty > 0
              ? actualQty
              : (setupItem.targetQty > 0 ? setupItem.targetQty : 0),
          assignmentDate: _selectedDate,
          expectedCompletionDate: null,
          isActive: true,
          isFallback: true,
          displayName: setupItem.name,
        );
      }).toList();
    }
    final teamAssignments = _assignments
        .where((assignment) =>
            !_isDefaultTeamSelected &&
            assignment.teamId == _teamId &&
            assignment.status != 'cancelled')
        .toList();
    final allValidAssignments = _assignments
        .where((assignment) => assignment.status != 'cancelled')
        .toList();
    final noBoqMarks = _allMarks.every((mark) => mark.assemblyMark.isEmpty);
    final noRelevantAssignment = _isDefaultTeamSelected
        ? allValidAssignments.isEmpty
        : _teamId.isNotEmpty
            ? teamAssignments.isEmpty
            : allValidAssignments.isEmpty;
    final fallbackAllowed =
        (setup.allowUnassignedDprFallback && noRelevantAssignment) ||
            (noBoqMarks && noRelevantAssignment);

    if (fallbackAllowed) {
      final hasBoqMarks = _allMarks.any((mark) => mark.assemblyMark.isNotEmpty);
      return setup.items.map((setupItem) {
        final marks = hasBoqMarks
            ? _allMarks
                .map((mark) => mark.assemblyMark)
                .where((mark) => mark.isNotEmpty)
                .toList()
            : const <String>[];
        return _VisibleWork(
          key: setupItem.id,
          setupItem: setupItem,
          assignmentId: '',
          sourceType: hasBoqMarks ? 'boq_upload' : 'level1_manual',
          stageName: setupItem.name,
          assignedMarks: marks,
          assignedQty: hasBoqMarks
              ? marks.length.toDouble()
              : (setupItem.targetQty > 0 ? setupItem.targetQty : 0),
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
    if (work.isLevel1Manual) {
      final completed = _completedForWork(work).contains(_level1StageMarker);
      final inProgress = _inProgressForWork(work).contains(_level1StageMarker);
      return _WorkCounts(
        total: 1,
        completed: completed ? 1 : 0,
        inProgress: !completed && inProgress ? 1 : 0,
      );
    }
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

  List<PebAssignmentPlanDetail> _planDetailsForWork(_VisibleWork work) {
    return _planDetails
        .where((detail) => detail.setupItemId == work.setupItem.id)
        .toList();
  }

  double _plannedForWork(_VisibleWork work) => _planDetailsForWork(work)
      .fold(0, (sum, detail) => sum + detail.plannedQuantity);

  double _actualForWork(_VisibleWork work) => _planDetailsForWork(work)
      .fold(0, (sum, detail) => sum + detail.actualQuantity);

  double _balanceForWork(_VisibleWork work) => _planDetailsForWork(work)
      .fold(0, (sum, detail) => sum + detail.balanceQuantity);

  double _plannedTotalForDate() =>
      _planDetails.fold(0, (sum, detail) => sum + detail.plannedQuantity);

  double _actualTotalForDate() =>
      _planDetails.fold(0, (sum, detail) => sum + detail.actualQuantity);

  double _unassignedPlanTotalForDate() => _planDetails
      .where((detail) => detail.targetType == 'unassigned')
      .fold(0, (sum, detail) => sum + detail.plannedQuantity);

  double _manpowerPlanTotalForDate() => _planDetails
      .where((detail) => detail.targetType == 'manpower')
      .fold(0, (sum, detail) => sum + detail.plannedQuantity);

  String _formatQty(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
    if (work.isLevel1Manual) {
      return _completedForWork(work).contains(_level1StageMarker);
    }
    final completed = _completedForWork(work);
    final marks = _displayMarksForWork(work);
    if (marks.isNotEmpty) {
      return marks.every(completed.contains);
    }
    final counts = _counts(work);
    return counts.total > 0 && counts.completed >= counts.total;
  }

  bool _hasUnlockedScope(_VisibleWork work) {
    if (work.isLevel1Manual) return true;
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
      await _openQuantityAction(work, completedAction: completedAction);
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
    final progress = completedAction ? 100 : 50;
    final items = <DprBulkTaskItem>[];
    final marksToSubmit = _selectedDetailMarks.toList();
    for (final mark in marksToSubmit) {
      final rawTargetQty = _markQuantity(mark);
      final targetQty = rawTargetQty > 0 ? rawTargetQty : 1.0;
      final enteredWeightKg = _enteredWeightKgForMark(work, mark);
      if (enteredWeightKg <= 0) {
        AppToast.error('Enter a valid weight for $mark');
        return;
      }
      final actualQty = completedAction ? targetQty : targetQty * 0.5;
      final key = _markInputKey(work, mark);
      final weightChanged = _isWeightChanged(work, mark);
      items.add(DprBulkTaskItem(
        mark: mark,
        actualQty: actualQty,
        targetQty: targetQty,
        weightMode: weightChanged ? 'manual' : 'actual',
        manualWeightKg: weightChanged ? enteredWeightKg : 0.0,
        totalWeightKg: enteredWeightKg,
        remarks: (_markRemarks[key] ?? '').trim(),
        variationReason:
            weightChanged ? (_variationReasons[key] ?? '').trim() : '',
        variationRemarks: weightChanged ? (_markRemarks[key] ?? '').trim() : '',
      ));
    }

    final task = _bulkTaskManager.enqueue(
      siteId: widget.siteId,
      type: widget.executionType,
      date: _dateText,
      teamId: _submitTeamId,
      setupItemId: work.setupItem.id,
      assignmentId: work.assignmentId,
      sourceType: work.sourceType,
      stageName: work.stageName,
      uom: 'Nos',
      progressPercentage: progress,
      items: items,
    );

    _showBulkTaskQueuedMessage(task);
    setState(() {
      _markActionMode = _DprMarkActionMode.none;
      _isDprSelectionMode = false;
      _selectedDetailMarks.clear();
      _activeWorkKey = null;
    });
  }

  void _showBulkTaskQueuedMessage(DprBulkTask task) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          elevation: 8,
          backgroundColor: cs.inverseSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update queued in background',
                      style: TextStyle(
                        color: cs.onInverseSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.total} mark${task.total == 1 ? '' : 's'} will be marked ${task.actionLabel.toLowerCase()}. You can continue using the app.',
                      style: TextStyle(
                        color: cs.onInverseSurface.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _openQuantityAction(
    _VisibleWork work, {
    required bool completedAction,
  }) async {
    final existingEntry = _level1EntryFor(work);
    final existingQty = existingEntry?.actualQty ?? 0;
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
              work.isLevel1Manual
                  ? existingEntry == null
                      ? 'Enter today\'s progress for ${DateFormat('dd MMM yyyy').format(_selectedDate)}.'
                      : 'Already saved: ${_prettyNumber(existingQty)} ${work.setupItem.uom}. New value will be added.'
                  : 'Approved quantity: ${work.assignedQty.toStringAsFixed(2)} ${work.setupItem.uom}',
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

    final progress = completedAction
        ? 100
        : work.isLevel1Manual
            ? 50
            : work.assignedQty > 0
                ? ((entered / work.assignedQty) * 100).clamp(0, 100).round()
                : 50;
    await _submitProgress(
      work,
      const [],
      progress,
      actualQtyOverride: entered,
      targetQtyOverride: work.isLevel1Manual
          ? (existingEntry?.targetQty ?? 0) > 0
              ? existingEntry!.targetQty
              : (work.assignedQty > 0 ? work.assignedQty : entered)
          : null,
      dprId: work.isLevel1Manual ? null : existingEntry?.dprId,
      trackingLevel: work.isLevel1Manual ? 'basic' : 'semi_structured',
      weightMode: work.isLevel1Manual ? 'manual' : 'none',
      manualWeightKg: work.isLevel1Manual ? entered : 0,
      totalWeightKg: work.isLevel1Manual ? entered : 0,
    );
  }

  List<_VisibleWork> _level1EnteredWorks([List<_VisibleWork>? source]) {
    final works = source ?? _visibleWorks();
    return works.where((work) {
      final value =
          double.tryParse(_level1WeightInputs[work.setupItem.id]?.trim() ?? '');
      final uom =
          (_level1UomInputs[work.setupItem.id] ?? work.setupItem.uom).trim();
      return value != null && value > 0 && uom.isNotEmpty;
    }).toList();
  }

  Future<void> _submitLevel1BatchProgress(
      List<_VisibleWork> sourceWorks) async {
    final works = _level1EnteredWorks(sourceWorks);
    if (works.isEmpty) {
      AppToast.error('Enter weight for at least one stage');
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final work in works) {
      final weight = double.tryParse(
              _level1WeightInputs[work.setupItem.id]?.trim() ?? '') ??
          0;
      final uom =
          (_level1UomInputs[work.setupItem.id] ?? work.setupItem.uom).trim();
      if (weight <= 0 || uom.isEmpty) continue;
      items.add({
        'setupItemId': work.setupItem.id,
        'sourceType': 'level1_manual',
        'stageName': work.stageName,
        'name': work.stageName,
        'uom': uom,
        'weight': weight,
        'weightKg': weight,
        'actualQty': weight,
        'manualWeightKg': weight,
        'totalWeightKg': weight,
        'weightMode': 'manual',
        'remarks': '',
      });
    }

    if (items.isEmpty) {
      AppToast.error('Enter weight for at least one stage');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.submitLevel1ProgressBatch(
        widget.siteId,
        widget.executionType,
        date: _dateText,
        teamId: _submitTeamId,
        items: items,
      );
      for (final work in works) {
        _level1WeightInputs.remove(work.setupItem.id);
      }
      AppToast.success('Level 1 DPR saved successfully');
      await _load(showLoader: false, autoScroll: false);
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitProgress(
    _VisibleWork work,
    List<String> marks,
    int progress, {
    String? dprId,
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
    String? uomOverride,
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
          : (uomOverride?.trim().isNotEmpty == true
              ? uomOverride!.trim()
              : work.setupItem.uom);
      await _service.submitDprProgress(
        widget.siteId,
        widget.executionType,
        dprId: dprId,
        dprLevel: work.isLevel1Manual
            ? PebDprLevel.basicProgress
            : PebDprLevel.assignedWorkProgress,
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
            dprId: dprId,
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

  Future<void> _reloadItemWiseItems() async {
    try {
      final apiItems = await _service.getItemWiseDprItems(
        widget.siteId,
        widget.executionType,
        search: _itemWiseSearchCtrl.text,
      );
      final items = _mergeItemWiseItems(
        apiItems,
        _boqMarksAsItemWiseItems(_boqs),
      );
      if (mounted) setState(() => _itemWiseItems = items);
    } catch (error) {
      AppToast.error(extractBackendError(error));
    }
  }

  List<PebItemWiseDprItem> _itemWiseFilteredItems() {
    final query = _itemWiseSearchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _itemWiseItems;
    return _itemWiseItems.where((item) {
      final haystack =
          '${item.markNo} ${item.description} ${item.source}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openItemWiseEntry(PebItemWiseDprItem item) async {
    if (item.source == 'manual' && item.weight > 0) {
      AppToast.info('Progress is already saved for this manual item.');
      return;
    }
    final weight = TextEditingController();
    final remarks = TextEditingController();
    final entered = await showDialog<_ItemWiseProgressInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.markNo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description.isEmpty
                  ? 'Item Wise Progress'
                  : item.description,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Available reference: ${_prettyNumber(item.weight)} ${item.uom}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: weight,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Progress Weight',
                suffixText: item.uom,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarks,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
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
              final value = double.tryParse(weight.text.trim()) ?? 0;
              if (value <= 0) {
                AppToast.error('Enter a valid progress weight');
                return;
              }
              context.pop(_ItemWiseProgressInput(
                weight: value,
                remarks: remarks.text.trim(),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    weight.dispose();
    remarks.dispose();
    if (entered == null) return;
    await _submitItemWiseProgress(item, entered);
  }

  Future<void> _openManualItemWiseEntry() async {
    final markNo = TextEditingController(text: _itemWiseSearchCtrl.text.trim());
    final description = TextEditingController();
    final weight = TextEditingController();
    final remarks = TextEditingController();
    final entered = await showDialog<_ManualItemWiseInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item Wise Progress'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: markNo,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Mark Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Progress Weight',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarks,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
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
              final mark = markNo.text.trim();
              final progress = double.tryParse(weight.text.trim()) ?? 0;
              if (mark.isEmpty) {
                AppToast.error('Mark Number is required');
                return;
              }
              if (progress <= 0) {
                AppToast.error('Enter a valid progress weight');
                return;
              }
              context.pop(_ManualItemWiseInput(
                markNo: mark,
                description: description.text.trim(),
                weight: progress,
                remarks: remarks.text.trim(),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    markNo.dispose();
    description.dispose();
    weight.dispose();
    remarks.dispose();
    if (entered == null) return;
    await _submitItemWiseProgress(
      PebItemWiseDprItem(
        source: 'manual',
        boqId: '',
        boqItemId: '',
        markNo: entered.markNo,
        description:
            entered.description.isEmpty ? entered.markNo : entered.description,
        weight: 0,
        uom: 'kg',
      ),
      _ItemWiseProgressInput(
        weight: entered.weight,
        remarks: entered.remarks,
      ),
    );
  }

  Future<void> _submitItemWiseProgress(
    PebItemWiseDprItem item,
    _ItemWiseProgressInput input,
  ) async {
    setState(() => _submitting = true);
    try {
      await _service.submitDprProgress(
        widget.siteId,
        widget.executionType,
        dprLevel: PebDprLevel.itemWiseProgress,
        date: _dateText,
        teamId: _submitTeamId,
        setupItemId: '',
        assignmentId: '',
        sourceType: item.source == 'boq' ? 'level2_boq' : 'level2_manual',
        stageName: item.description.isEmpty ? item.markNo : item.description,
        uom: item.uom.isEmpty ? 'kg' : item.uom,
        marks: const [],
        markNo: item.markNo,
        description: item.description,
        boqItemId: item.boqItemId,
        isManualItem: item.source != 'boq',
        actualQty: input.weight,
        targetQty: item.weight,
        progressPercentage: 0,
        trackingLevel: 'semi_structured',
        remarks: input.remarks,
        weightMode: 'manual',
        manualWeightKg: input.weight,
        totalWeightKg: input.weight,
        variationRemarks: input.remarks,
      );
      AppToast.success('Item wise DPR saved');
      await _reloadItemWiseItems();
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
                    : _dprLevel == PebDprLevel.itemWiseProgress
                        ? _buildItemWiseProgressBody()
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
                                            _buildBulkTaskBanner(),
                                            SizedBox(height: layout.sectionGap),
                                            _buildAssignedWorkHeader(
                                                assignedWorks),
                                            _buildPlanningSummaryBanner(),
                                            SizedBox(height: layout.cardGap),
                                            if (assignedWorks.isEmpty)
                                              _boqs.isEmpty
                                                  ? _buildNoBoqState()
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        color: cs
                                                            .surfaceContainerLow,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        border: Border.all(
                                                            color: cs
                                                                .outlineVariant
                                                                .withOpacity(
                                                                    0.5)),
                                                      ),
                                                      padding: EdgeInsets.all(
                                                          layout.cardPadding),
                                                      child: Text(
                                                        'No assigned work found for this team.',
                                                        style: TextStyle(
                                                          color: cs
                                                              .onSurfaceVariant,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    )
                                            else
                                              ...assignedWorks
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (entry) => KeyedSubtree(
                                                      key: _keyForWork(
                                                          entry.value,
                                                          entry.key),
                                                      child: _buildWorkCard(
                                                          entry.value),
                                                    ),
                                                  ),
                                            SizedBox(
                                              height: (_dprLevel ==
                                                          PebDprLevel
                                                              .basicProgress
                                                      ? 132
                                                      : 84) +
                                                  MediaQuery.paddingOf(context)
                                                      .bottom,
                                            ),
                                          ]
                                        : _markActionMode ==
                                                _DprMarkActionMode.none
                                            ? [
                                                _buildWorkDetailHeader(
                                                    activeWork),
                                                _buildBulkTaskBanner(),
                                                SizedBox(
                                                  height: 84 +
                                                      MediaQuery.paddingOf(
                                                              context)
                                                          .bottom,
                                                ),
                                              ]
                                            : [
                                                _buildWorkDetailHeader(
                                                    activeWork),
                                                _buildBulkTaskBanner(),
                                                SizedBox(
                                                    height: layout.cardGap),
                                                _buildMarkSearchBar(activeWork),
                                                SizedBox(
                                                    height: layout.smallGap),
                                                ..._filteredSortedMarks(
                                                        activeWork)
                                                    .map(
                                                  (mark) =>
                                                      _buildMarkEntryCardV2(
                                                    activeWork,
                                                    mark,
                                                    enabled:
                                                        _unlockedMarksForWork(
                                                                activeWork)
                                                            .contains(mark),
                                                  ),
                                                ),
                                                if (_filteredSortedMarks(
                                                            activeWork)
                                                        .isEmpty &&
                                                    activeMarks.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: layout
                                                                    .sectionGap *
                                                                2),
                                                    child: Center(
                                                      child: Text(
                                                        'No marks match "$_markSearchQuery"',
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
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
                                                      MediaQuery.paddingOf(
                                                              context)
                                                          .bottom,
                                                ),
                                              ],
                                  ),
                                ),
                              ),
                              if (_dprLevel == PebDprLevel.basicProgress &&
                                  activeWork == null)
                                _buildLevel1BottomBar(assignedWorks),
                              if (activeWork != null && activeMarks.isNotEmpty)
                                _buildDetailBottomBar(activeWork),
                              if (_submitting)
                                Positioned.fill(
                                  child: AbsorbPointer(
                                    child: Container(
                                      color:
                                          Colors.white.withValues(alpha: 0.62),
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
                                                  child:
                                                      CircularProgressIndicator(
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

  Widget _buildItemWiseProgressBody() {
    final layout = _PebDprResponsive.of(context);
    final items = _itemWiseFilteredItems();
    return Stack(
      children: [
        CustomScrollbar(
          controller: _scrollController,
          child: RefreshIndicator(
            onRefresh: () async {
              await _load(showLoader: false, autoScroll: false);
            },
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                layout.pagePadding,
                layout.pagePadding,
                layout.pagePadding,
                110 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _buildFilters(),
                SizedBox(height: layout.sectionGap),
                _buildItemWiseHeader(items.length),
                SizedBox(height: layout.cardGap),
                _buildItemWiseSearchBar(),
                SizedBox(height: layout.cardGap),
                if (items.isEmpty)
                  _buildItemWiseEmptyState()
                else
                  ...items.map(_buildItemWiseCard),
              ],
            ),
          ),
        ),
        if (_submitting)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.white.withValues(alpha: 0.62),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemWiseHeader(int count) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Wise Progress',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Search BOQ items or add a manual mark number.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _openManualItemWiseEntry,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildItemWiseSearchBar() {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: _itemWiseSearchCtrl,
      onChanged: (_) {
        setState(() {});
        _reloadItemWiseItems();
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _itemWiseSearchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _itemWiseSearchCtrl.clear();
                  setState(() {});
                  _reloadItemWiseItems();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        labelText: 'Search Mark Number, Member or BOQ Item',
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildItemWiseEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    return Container(
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: cs.primary, size: 36),
          const SizedBox(height: 10),
          Text(
            'No item found',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No BOQ item matched this search. Add a manual mark number to continue DPR entry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _openManualItemWiseEntry,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Manual Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemWiseCard(PebItemWiseDprItem item) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final isBoq = item.source == 'boq';
    final manualSaved = !isBoq && item.weight > 0;
    return Container(
      margin: EdgeInsets.only(bottom: layout.cardGap),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: manualSaved ? null : () => _openItemWiseEntry(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(layout.cardPadding),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isBoq
                      ? cs.primaryContainer.withValues(alpha: 0.72)
                      : cs.secondaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBoq ? Icons.inventory_2_rounded : Icons.edit_note_rounded,
                  color: isBoq ? cs.primary : cs.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.markNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description.isEmpty
                          ? (isBoq ? 'BOQ item' : 'Manual item')
                          : item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _itemWiseChip(
                          manualSaved
                              ? 'Saved'
                              : isBoq
                                  ? 'BOQ'
                                  : 'Manual',
                          isBoq ? cs.primary : cs.secondary,
                        ),
                        _itemWiseChip(
                          '${_prettyNumber(item.weight)} ${item.uom}',
                          cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                manualSaved
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: manualSaved ? Colors.green.shade700 : cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemWiseChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
            'No BOQ found',
            style: TextStyle(
              fontSize: layout.compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: layout.smallGap),
          Text(
            'No BOQ found. Enter stage-wise quantity manually.',
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

  Widget _buildBulkTaskBanner() {
    final task = _bulkTaskManager.currentTask;
    if (task == null ||
        task.siteId != widget.siteId ||
        task.type != widget.executionType) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final running = task.status == DprBulkTaskStatus.running;
    final progress = task.progress.clamp(0.0, 1.0);
    final failedText = task.failed > 0 ? ' - ${task.failed} failed' : '';

    return Padding(
      padding: EdgeInsets.only(bottom: layout.cardGap),
      child: Container(
        padding: EdgeInsets.all(layout.compact ? 12 : 14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: running
                      ? CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        )
                      : Icon(Icons.schedule_rounded,
                          size: 22, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${task.stageName} ${task.actionLabel} update ${running ? 'running' : 'queued'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: layout.compact ? 13 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: progress,
                backgroundColor: cs.surface.withValues(alpha: 0.8),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${task.processed}/${task.total} marks processed$failedText. You can continue using the app.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: layout.compact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

  Widget _buildPlanningSummaryBanner() {
    if (_planDetails.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final planned = _plannedTotalForDate();
    final actual = _actualTotalForDate();
    final variance = planned - actual;
    final unassigned = _unassignedPlanTotalForDate();
    final manpower = _manpowerPlanTotalForDate();

    return Container(
      margin: EdgeInsets.only(top: layout.cardGap),
      padding: EdgeInsets.all(layout.compact ? 12 : 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Today\'s Quantity Plan',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _planChip(cs, 'Planned', _formatQty(planned)),
              _planChip(cs, 'Actual', _formatQty(actual)),
              _planChip(cs, 'Variance', _formatQty(variance)),
              if (unassigned > 0)
                _planChip(cs, 'Unassigned Planning', _formatQty(unassigned)),
              if (manpower > 0)
                _planChip(cs, 'Manpower Planning', _formatQty(manpower)),
            ],
          ),
          if (unassigned > 0) ...[
            const SizedBox(height: 8),
            Text(
              'This planning is not linked to any team/manpower.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: layout.compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planChip(ColorScheme cs, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWorkPlanRow(_VisibleWork work) {
    final details = _planDetailsForWork(work);
    if (details.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final uom =
        details.first.uom.isEmpty ? work.setupItem.uom : details.first.uom;
    return Container(
      margin: EdgeInsets.only(top: layout.smallGap),
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 8 : 10,
        vertical: layout.compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _planMiniStat(
              'Planned',
              '${_formatQty(_plannedForWork(work))} $uom',
              cs,
            ),
          ),
          Expanded(
            child: _planMiniStat(
              'Actual',
              '${_formatQty(_actualForWork(work))} $uom',
              cs,
            ),
          ),
          Expanded(
            child: _planMiniStat(
              'Balance',
              '${_formatQty(_balanceForWork(work))} $uom',
              cs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planMiniStat(String label, String value, ColorScheme cs) {
    final layout = _PebDprResponsive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: layout.compact ? 9 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: layout.compact ? 10 : 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkCard(_VisibleWork work) {
    if (_dprLevel == PebDprLevel.basicProgress || work.isLevel1Manual) {
      return _buildLevel1WorkCard(work);
    }

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
                        child: _containedWorkImage(
                          work.setupItem,
                          height: layout.workImageHeight,
                          padding: 0,
                          fit: BoxFit.contain,
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _minimalWorkUomBlock(work.setupItem.uom, cs),
                                SizedBox(height: layout.compact ? 5 : 6),
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
                          _buildWorkPlanRow(work),
                          if (_planDetailsForWork(work).isNotEmpty)
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

  Widget _buildLevel1WorkCard(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final existing = _level1EntryFor(work);
    final existingQty = existing?.actualQty ?? 0;
    final weightValue = _level1WeightInputs[work.setupItem.id] ?? '';
    final uomValue = _level1UomInputs[work.setupItem.id] ??
        (existing?.uom.trim().isNotEmpty == true
            ? existing!.uom
            : work.setupItem.uom);

    return Container(
      margin: EdgeInsets.only(bottom: layout.cardGap),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 62,
                child: _containedWorkImage(
                  work.setupItem,
                  height: 62,
                  padding: 6,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.stageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      existingQty > 0
                          ? 'Saved today: ${_prettyNumber(existingQty)} $uomValue'
                          : 'Enter daily progress directly',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: weightValue,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => setState(
                      () => _level1WeightInputs[work.setupItem.id] = value),
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: uomValue,
                  onChanged: (value) => setState(
                      () => _level1UomInputs[work.setupItem.id] = value),
                  decoration: const InputDecoration(
                    labelText: 'UOM',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevel1BottomBar(List<_VisibleWork> works) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final enteredWorks = _level1EnteredWorks(works);
    final totalWeight = enteredWorks.fold<double>(0, (sum, work) {
      return sum +
          (double.tryParse(
                  _level1WeightInputs[work.setupItem.id]?.trim() ?? '') ??
              0);
    });
    final canSave = enteredWorks.isNotEmpty && !_submitting;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${enteredWorks.length} stage${enteredWorks.length == 1 ? '' : 's'} ready',
                      style: TextStyle(
                        color: canSave ? cs.onSurface : cs.onSurfaceVariant,
                        fontSize: layout.compact ? 13 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canSave
                          ? 'Total entered: ${_prettyNumber(totalWeight)}'
                          : 'Enter weight in any stage to save.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: layout.compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed:
                    canSave ? () => _submitLevel1BatchProgress(works) : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(112, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _minimalWorkUomBlock(String uom, ColorScheme cs) {
    final layout = _PebDprResponsive.of(context);
    final displayUom = uom.trim().isEmpty ? '-' : uom.trim();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.compact ? 6 : 7,
        vertical: layout.compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'UOM',
            maxLines: 1,
            style: TextStyle(
              fontSize: layout.miniLabelSize,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                // displayUom,
                "NOS",
                maxLines: 1,
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

  Widget _containedWorkImage(
    PebSetupItem item, {
    required double height,
    required double padding,
    BoxFit fit = BoxFit.contain,
  }) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(8);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: borderRadius,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox.expand(
            child: Image(
              image: pebWorkImageProvider(item, widget.executionType),
              fit: fit,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => pebWorkImageFallback(
                item,
                widget.executionType,
                fit: fit,
              ),
            ),
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
                                textColor: Colors.white,
                                bgColor: Colors.green.shade700,
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
                          label: 'Select all',
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

  /// Fuzzy-filters the mark numbers for [work] while preserving upload order.
  List<String> _filteredSortedMarks(_VisibleWork work) {
    final allMarks = _displayMarksForWork(work);
    final q = _markSearchQuery.trim().toLowerCase();

    final result = allMarks.where((mark) {
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

    return result;
  }

  /// Search bar + filter button in manpowerList style.
  Widget _buildMarkSearchBar(_VisibleWork work) {
    final cs = Theme.of(context).colorScheme;
    final layout = _PebDprResponsive.of(context);
    final hasFilters = _markFilterStatus != null;
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

  Widget _completedVisualTreatment({
    required bool completed,
    required double opacity,
    required Widget child,
  }) {
    if (!completed) return child;
    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 0.35, sigmaY: 0.35),
        child: child,
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
    final completedContentOpacity = completed ? 0.42 : 1.0;
    final completedSecondaryOpacity = completed ? 0.5 : 1.0;
    final completedWeightOpacity = completed ? 0.64 : 1.0;
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
                          child: _completedVisualTreatment(
                            completed: completed,
                            opacity: 0.46,
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
                      ),
                      SizedBox(width: layout.smallGap),
                      Expanded(
                        child: _completedVisualTreatment(
                          completed: completed,
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
                        child: _completedVisualTreatment(
                          completed: completed,
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
                      child: _completedVisualTreatment(
                        completed: completed,
                        opacity: completedContentOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: layout.compact ? 2 : 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _containedWorkImage(
                                work.setupItem,
                                height: layout.v2ImageHeight,
                                padding: 0,
                                fit: BoxFit.contain,
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
                          _completedVisualTreatment(
                            completed: completed,
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
                          _completedVisualTreatment(
                            completed: completed,
                            opacity: completedWeightOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
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
                                        color:
                                            cs.outlineVariant.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) => setState(
                                    () => _markQuantityInputs[key] = value,
                                  ),
                                ),
                              ],
                            ),
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

  bool get isLevel1Manual => sourceType == 'level1_manual';
}

class _VariationResponse {
  final String reason;
  final String remarks;

  const _VariationResponse({
    required this.reason,
    required this.remarks,
  });
}

class _ItemWiseProgressInput {
  final double weight;
  final String remarks;

  const _ItemWiseProgressInput({
    required this.weight,
    required this.remarks,
  });
}

class _ManualItemWiseInput {
  final String markNo;
  final String description;
  final double weight;
  final String remarks;

  const _ManualItemWiseInput({
    required this.markNo,
    required this.description,
    required this.weight,
    required this.remarks,
  });
}

class _DprLevelPickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DprLevelPickerSheet({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ...PebDprLevel.values.map(
              (level) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => context.pop(level),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            level == PebDprLevel.basicProgress
                                ? Icons.edit_note_rounded
                                : level == PebDprLevel.itemWiseProgress
                                    ? Icons.manage_search_rounded
                                    : Icons.assignment_turned_in_rounded,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.title,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                level.description,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: cs.primary),
                      ],
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
