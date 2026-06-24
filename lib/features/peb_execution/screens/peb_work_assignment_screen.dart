import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  final bool openListDirectly;

  const PebWorkAssignmentScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.executionType,
    this.openListDirectly = false,
  });

  @override
  State<PebWorkAssignmentScreen> createState() =>
      _PebWorkAssignmentScreenState();
}

class _PebWorkAssignmentScreenState extends State<PebWorkAssignmentScreen> {
  static const String _defaultTeamId = '__default_team__';
  static const PebTeam _defaultTeam = PebTeam(id: _defaultTeamId, name: '');

  final _service = PebExecutionService();
  final _workDescriptionController = TextEditingController();
  final _remarksController = TextEditingController();
  final _manualMarksController = TextEditingController();
  final _qtyController = TextEditingController();
  final _planQtyController = TextEditingController();
  final _planRemarksController = TextEditingController();
  final _markSearchController = TextEditingController();
  final _assignmentSearchController = TextEditingController();
  Timer? _markSearchDebounce;
  bool _loading = true;
  bool _saving = false;
  bool _showForm = false;
  bool _allowFallback = true;
  _WorkAssignmentMode _mode = _WorkAssignmentMode.home;
  String _teamId = '';
  String _setupItemId = '';
  String _sourceType = 'boq_upload';
  String _planTargetType = 'team';
  String _planManpowerId = '';
  String _planPlanningType = 'daily';
  String _editingAssignmentId = '';
  String _editingPlanId = '';
  int _assignmentStep = 0;
  DateTime _assignmentDate = DateTime.now();
  DateTime? _expectedDate;
  DateTime _planStartDate = DateTime.now();
  DateTime? _planTcd;
  int? _planWeekOffDay;
  List<PebTeam> _teams = [];
  List<PebManpower> _manpower = [];
  List<PebSetupItem> _setupItems = [];
  List<PebBoq> _boqs = [];
  List<PebWorkAssignment> _assignments = [];
  List<PebAssignmentPlan> _assignmentPlans = [];
  Set<String> _selectedBoqIds = {};
  Set<String> _selectedMarks = {};
  Map<String, Set<String>> _completedBySetupItem = {};
  String _markSearchText = '';
  String _assignmentSearchText = '';
  String? _assignmentStageFilter;
  String? _assignmentTeamFilter;
  _AssignmentSortOption _assignmentSort = _AssignmentSortOption.latestFirst;

  bool get _isDefaultTeamSelected => _teamId == _defaultTeamId;

  String get _submitTeamId => _isDefaultTeamSelected ? '' : _teamId;
  DateTime get _effectiveExpectedDate => _expectedDate ?? _assignmentDate;

  @override
  void initState() {
    super.initState();
    if (widget.openListDirectly) {
      _mode = _WorkAssignmentMode.view;
    }
    _load();
  }

  @override
  void dispose() {
    _workDescriptionController.dispose();
    _remarksController.dispose();
    _manualMarksController.dispose();
    _qtyController.dispose();
    _planQtyController.dispose();
    _planRemarksController.dispose();
    _markSearchController.dispose();
    _assignmentSearchController.dispose();
    _markSearchDebounce?.cancel();
    super.dispose();
  }

  List<PebWorkAssignment> get _visibleAssignments {
    final query = _assignmentSearchText.trim().toLowerCase();
    final visible = _assignments.where((assignment) {
      final items = assignment.assignments;
      final teamName = assignment.team?.name ?? '';
      final matchesSearch = query.isEmpty ||
          teamName.toLowerCase().contains(query) ||
          items.any((item) =>
              item.stageName.toLowerCase().contains(query) ||
              item.workDescription.toLowerCase().contains(query) ||
              item.assemblyMarks
                  .any((mark) => mark.toLowerCase().contains(query)));
      final matchesStage = _assignmentStageFilter == null ||
          items.any((item) => item.stageName == _assignmentStageFilter);
      final matchesTeam = _assignmentTeamFilter == null ||
          assignment.teamId == _assignmentTeamFilter;
      return matchesSearch && matchesStage && matchesTeam;
    }).toList();

    visible.sort((a, b) {
      switch (_assignmentSort) {
        case _AssignmentSortOption.oldestFirst:
          return (a.assignmentDate ?? DateTime(1970))
              .compareTo(b.assignmentDate ?? DateTime(1970));
        case _AssignmentSortOption.stageAsc:
          final aStage =
              a.assignments.isEmpty ? '' : a.assignments.first.stageName;
          final bStage =
              b.assignments.isEmpty ? '' : b.assignments.first.stageName;
          return aStage.toLowerCase().compareTo(bStage.toLowerCase());
        case _AssignmentSortOption.latestFirst:
          return (b.assignmentDate ?? DateTime(1970))
              .compareTo(a.assignmentDate ?? DateTime(1970));
      }
    });
    return visible;
  }

  bool get _hasAssignmentFilters =>
      _assignmentStageFilter != null ||
      _assignmentTeamFilter != null ||
      _assignmentSort != _AssignmentSortOption.latestFirst;

  String _csvCell(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';

  Future<void> _downloadAssignments() async {
    final assignments = _visibleAssignments;
    if (assignments.isEmpty) {
      AppToast.info('No work assignments to download');
      return;
    }
    try {
      final rows = <List<Object?>>[
        [
          'Stage',
          'Team',
          'Assigned Quantity',
          'UOM',
          'Mark Numbers',
          'Description',
          'Assignment Date',
          'Expected Completion',
          'Status',
        ],
        ...assignments.expand(
          (assignment) => assignment.assignments.map(
            (item) => [
              item.stageName,
              assignment.team?.name ?? '',
              item.assignedQty,
              item.uom,
              item.assemblyMarks.join(', '),
              item.workDescription,
              _formatDate(assignment.assignmentDate),
              _formatDate(assignment.expectedCompletionDate),
              assignment.status,
            ],
          ),
        ),
      ];
      final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/work-assignments-${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Work assignment list',
      );
    } catch (error) {
      AppToast.error('Failed to export work assignments');
    }
  }

  void _showAssignmentFilters() {
    final stages = _assignments
        .expand((assignment) => assignment.assignments)
        .map((item) => item.stageName)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final teams = <String, String>{};
    for (final assignment in _assignments) {
      final name = assignment.team?.name.trim() ?? '';
      if (assignment.teamId.isNotEmpty && name.isNotEmpty) {
        teams[assignment.teamId] = name;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _assignmentStageFilter = null;
                          _assignmentTeamFilter = null;
                          _assignmentSort = _AssignmentSortOption.latestFirst;
                        });
                        setState(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                DropdownButtonFormField<_AssignmentSortOption>(
                  initialValue: _assignmentSort,
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownMenuItem(
                      value: _AssignmentSortOption.latestFirst,
                      child: Text('Latest first'),
                    ),
                    DropdownMenuItem(
                      value: _AssignmentSortOption.oldestFirst,
                      child: Text('Oldest first'),
                    ),
                    DropdownMenuItem(
                      value: _AssignmentSortOption.stageAsc,
                      child: Text('Stage A-Z'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() => _assignmentSort = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _assignmentStageFilter,
                  decoration: const InputDecoration(labelText: 'Stage'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All stages'),
                    ),
                    ...stages.map(
                      (stage) =>
                          DropdownMenuItem(value: stage, child: Text(stage)),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => _assignmentStageFilter = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _assignmentTeamFilter,
                  decoration: const InputDecoration(labelText: 'Team'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All teams'),
                    ),
                    ...teams.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setSheetState(() => _assignmentTeamFilter = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        _service.getManpower(widget.siteId, widget.executionType),
        _service.getAssignmentPlans(widget.siteId, widget.executionType),
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
        _manpower = results[5] as List<PebManpower>;
        _assignmentPlans = (results[6] as List<PebAssignmentPlan>)
            .where((plan) => plan.status != 'cancelled')
            .toList();
        _syncSelectedBoqs();
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

  List<PebBoqMark> get _visibleBoqMarks {
    if (_selectedBoqIds.isEmpty) return _allMarks;
    return _boqs
        .where((boq) => _selectedBoqIds.contains(boq.id))
        .expand((boq) => boq.items)
        .where((mark) => mark.assemblyMark.isNotEmpty)
        .toList();
  }

  void _syncSelectedBoqs() {
    final availableIds = _boqs.map((boq) => boq.id).toSet();
    _selectedBoqIds.removeWhere((id) => !availableIds.contains(id));
    final availableMarks = _allMarks.map((mark) => mark.assemblyMark).toSet();
    _selectedMarks.removeWhere((mark) => !availableMarks.contains(mark));
  }

  bool _isAssignableMark(
    PebBoqMark mark, {
    required Set<String> assignedForStage,
    required Set<String> completedForStage,
    required PebSetupItem? previousStage,
    required Set<String> previousStageAssignedMarks,
  }) {
    return !completedForStage.contains(mark.assemblyMark) &&
        !assignedForStage.contains(mark.assemblyMark) &&
        (previousStage == null ||
            previousStageAssignedMarks.contains(mark.assemblyMark));
  }

  List<String> _selectableMarkNumbersForBoq(
    PebBoq boq, {
    required Set<String> assignedForStage,
    required Set<String> completedForStage,
    required PebSetupItem? previousStage,
    required Set<String> previousStageAssignedMarks,
  }) {
    return boq.items
        .where((mark) => mark.assemblyMark.isNotEmpty)
        .where((mark) => _isAssignableMark(
              mark,
              assignedForStage: assignedForStage,
              completedForStage: completedForStage,
              previousStage: previousStage,
              previousStageAssignedMarks: previousStageAssignedMarks,
            ))
        .map((mark) => mark.assemblyMark)
        .toList();
  }

  void _toggleBoqFilter(PebBoq boq) {
    setState(() {
      if (_selectedBoqIds.contains(boq.id)) {
        _selectedBoqIds.remove(boq.id);
      } else {
        _selectedBoqIds.add(boq.id);
      }
    });
  }

  void _toggleAllBoqFilters() {
    final allSelected =
        _boqs.isNotEmpty && _selectedBoqIds.length == _boqs.length;
    setState(() {
      if (allSelected) {
        _selectedBoqIds.clear();
      } else {
        _selectedBoqIds.addAll(_boqs.map((boq) => boq.id));
      }
    });
  }

  void _toggleMarkSelection(String assemblyMark) {
    setState(() {
      if (_selectedMarks.contains(assemblyMark)) {
        _selectedMarks.remove(assemblyMark);
      } else {
        _selectedMarks.add(assemblyMark);
      }
    });
    _fillWorkDescriptionFromSelectedMarks();
  }

  void _selectAllVisibleMarks(List<PebBoqMark> visibleMarks) {
    if (visibleMarks.isEmpty) {
      AppToast.info('No assignable mark numbers available.');
      return;
    }
    setState(() {
      for (final mark in visibleMarks) {
        _selectedMarks.add(mark.assemblyMark);
      }
    });
    _fillWorkDescriptionFromSelectedMarks();
  }

  void _deselectAllSelectedMarks() {
    if (_selectedMarks.isEmpty) return;
    setState(() => _selectedMarks.clear());
  }

  void _fillWorkDescriptionFromSelectedMarks({bool force = false}) {
    if (!force && _workDescriptionController.text.trim().isNotEmpty) return;
    for (final mark in _allMarks) {
      if (_selectedMarks.contains(mark.assemblyMark) &&
          mark.typeDescription.trim().isNotEmpty) {
        _workDescriptionController.text = mark.typeDescription.trim();
        return;
      }
    }
  }

  List<PebBoqMark> get _filteredMarkList {
    final search = _markSearchText.trim().toLowerCase();
    final marksInView = _visibleBoqMarks;
    if (search.isEmpty) return marksInView;
    return marksInView
        .where(
          (mark) =>
              mark.assemblyMark.toLowerCase().contains(search) ||
              mark.typeDescription.toLowerCase().contains(search),
        )
        .toList();
  }

  List<PebBoqMark> _assignableMarksFrom(Iterable<PebBoqMark> marks) {
    final assignedForStage = _assignedMarksForStage;
    final completedForStage = _completedBySetupItem[_setupItemId] ?? <String>{};
    final previousStage = _previousSetupItem(_setupItemId);
    final previousStageAssignedMarks = previousStage == null
        ? <String>{}
        : _assignedMarksForSetupItem(previousStage.id);
    return marks
        .where(
          (mark) => _isAssignableMark(
            mark,
            assignedForStage: assignedForStage,
            completedForStage: completedForStage,
            previousStage: previousStage,
            previousStageAssignedMarks: previousStageAssignedMarks,
          ),
        )
        .toList();
  }

  Widget _buildMarkSearchField(ColorScheme cs) {
    return TextField(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      onChanged: (value) {
        _markSearchDebounce?.cancel();
        _markSearchDebounce = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => _markSearchText = value);
        });
      },
    );
  }

  Widget _buildMarkSelectionActionsRow(ColorScheme cs) {
    if (_sourceType != 'boq_upload' || _allMarks.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleMarks = _filteredMarkList;
    final assignableMarks = _assignableMarksFrom(visibleMarks);
    final hasSelection = _selectedMarks.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: assignableMarks.isEmpty
                ? null
                : () => _selectAllVisibleMarks(assignableMarks),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Select All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: !hasSelection ? null : () => _deselectAllSelectedMarks(),
            icon: const Icon(Icons.remove_done_rounded, size: 18),
            label: const Text('Deselect All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Set<String> get _assignedMarksForStage {
    return _assignments
        .where((assignment) => assignment.id != _editingAssignmentId)
        .expand((assignment) => assignment.assignments)
        .where((item) => item.setupItemId == _setupItemId)
        .expand((item) => item.assemblyMarks)
        .toSet();
  }

  PebSetupItem? _previousSetupItem(String setupItemId) {
    final index = _setupItems.indexWhere((item) => item.id == setupItemId);
    if (index <= 0) return null;
    return _setupItems[index - 1];
  }

  Set<String> _assignedMarksForSetupItem(String setupItemId) {
    return _assignments
        .where((assignment) =>
            assignment.id != _editingAssignmentId &&
            assignment.status != 'cancelled')
        .expand((assignment) => assignment.assignments)
        .where((item) => item.setupItemId == setupItemId)
        .expand((item) => item.assemblyMarks)
        .toSet();
  }

  String? _previousStageMessageForMarks(Iterable<String> marks) {
    final previous = _previousSetupItem(_setupItemId);
    if (previous == null) return null;

    final previousAssignedMarks = _assignedMarksForSetupItem(previous.id);
    final missing = marks
        .where((mark) => mark.trim().isNotEmpty)
        .where((mark) => !previousAssignedMarks.contains(mark))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (missing.isEmpty) return null;
    final sample = missing.take(5).join(', ');
    final extra = missing.length > 5 ? ' +${missing.length - 5} more' : '';
    return 'Please assign ${previous.name} first for $sample$extra.';
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

  Set<String> _boqIdsForMarks(Iterable<String> marks) {
    final markSet = marks.toSet();
    return _boqs
        .where((boq) =>
            boq.items.any((mark) => markSet.contains(mark.assemblyMark)))
        .map((boq) => boq.id)
        .toSet();
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
      _selectedBoqIds = {};
      _selectedMarks = {};
      _markSearchText = '';
      _markSearchController.clear();
      _assignmentDate = DateTime.now();
      _expectedDate = null;
      _workDescriptionController.clear();
      _remarksController.clear();
      _manualMarksController.clear();
      _qtyController.clear();
    });
  }

  void _openNewQuantityPlan(PebSetupItem item) {
    setState(() {
      _mode = _WorkAssignmentMode.quantityAdd;
      _showForm = true;
      _editingPlanId = '';
      _setupItemId = item.id;
      _planTargetType = _teams.isNotEmpty ? 'team' : 'unassigned';
      _teamId = _teams.isNotEmpty ? _teams.first.id : _defaultTeamId;
      _planManpowerId = _manpower.isNotEmpty ? _manpower.first.id : '';
      _planPlanningType = 'daily';
      _planStartDate = DateTime.now();
      _planTcd = null;
      _planWeekOffDay = null;
      _planQtyController.clear();
      _planRemarksController.clear();
    });
  }

  void _openEditQuantityPlan(PebAssignmentPlan plan) {
    setState(() {
      _mode = _WorkAssignmentMode.quantityAdd;
      _showForm = true;
      _editingPlanId = plan.id;
      _setupItemId = plan.setupItemId;
      _planTargetType = plan.targetType;
      _teamId = plan.team?.id ?? (_teams.isNotEmpty ? _teams.first.id : '');
      _planManpowerId =
          plan.manpower?.id ?? (_manpower.isNotEmpty ? _manpower.first.id : '');
      _planPlanningType = plan.planningType;
      _planStartDate = plan.startDate ?? DateTime.now();
      _planTcd = plan.tcd;
      _planWeekOffDay = plan.weekOffDay;
      _planQtyController.text = plan.totalQuantity.toStringAsFixed(
          plan.totalQuantity.truncateToDouble() == plan.totalQuantity ? 0 : 2);
      _planRemarksController.text = plan.remarks;
    });
  }

  Future<void> _pickPlanDate({required bool tcd}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: tcd ? (_planTcd ?? _planStartDate) : _planStartDate,
    );
    if (picked == null) return;
    setState(() {
      if (tcd) {
        _planTcd = picked;
      } else {
        _planStartDate = picked;
      }
    });
  }

  Future<void> _saveQuantityPlan() async {
    final setupItem = _findSetupItem(_setupItemId);
    if (setupItem == null) {
      AppToast.error('Select work stage');
      return;
    }

    final quantity = double.tryParse(_planQtyController.text.trim()) ?? 0;
    if (quantity <= 0) {
      AppToast.error('Enter quantity');
      return;
    }
    if (_planTargetType == 'team' &&
        (_teamId.isEmpty || _teamId == _defaultTeamId)) {
      AppToast.error('Select team');
      return;
    }
    if (_planTargetType == 'manpower' && _planManpowerId.isEmpty) {
      AppToast.error('Select manpower');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveAssignmentPlan(
        widget.siteId,
        widget.executionType,
        planId: _editingPlanId,
        setupItemId: setupItem.id,
        stageName: setupItem.name,
        targetType: _planTargetType,
        teamId: _planTargetType == 'team' ? _teamId : null,
        manpowerId: _planTargetType == 'manpower' ? _planManpowerId : null,
        planningType: _planPlanningType,
        startDate: _planStartDate,
        tcd: _planTcd,
        weekOffDay: _planPlanningType == 'weekly' ? _planWeekOffDay : null,
        monthlyOffDay: _planPlanningType == 'monthly' ? _planWeekOffDay : null,
        quantity: quantity,
        uom: setupItem.uom,
        remarks: _planRemarksController.text.trim(),
      );
      AppToast.success(_editingPlanId.isEmpty
          ? 'Quantity plan saved'
          : 'Quantity plan updated');
      setState(() {
        _showForm = false;
        _mode = _WorkAssignmentMode.quantityView;
      });
      await _load();
    } on DioException catch (error) {
      AppToast.error(extractBackendError(error));
    } catch (error) {
      AppToast.error(extractBackendError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteQuantityPlan(PebAssignmentPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel quantity plan'),
        content: Text('Cancel ${plan.stageName} quantity plan?'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('No')),
          FilledButton(
              onPressed: () => context.pop(true), child: const Text('Cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAssignmentPlan(widget.siteId, plan.id);
      AppToast.success('Quantity plan cancelled');
      await _load();
    } catch (error) {
      AppToast.error(extractBackendError(error));
    }
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
      _selectedBoqIds = _boqIdsForMarks(item.assemblyMarks);
      _selectedMarks = item.assemblyMarks.toSet();
      _markSearchText = '';
      _markSearchController.clear();
      _assignmentDate = assignment.assignmentDate ?? DateTime.now();
      _expectedDate = assignment.expectedCompletionDate;
      _workDescriptionController.text = item.workDescription;
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
    final assignmentUom = _sourceType == 'tonnage' ? setupItem.uom : 'Nos';
    if (assignedQty <= 0) {
      AppToast.error(_sourceType == 'tonnage'
          ? 'Enter quantity'
          : 'Select at least one mark');
      return;
    }
    final previousStageMessage = _previousStageMessageForMarks(marks);
    if (previousStageMessage != null) {
      AppToast.error(previousStageMessage);
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
        expectedCompletionDate: _effectiveExpectedDate,
        boqIds: _sourceType == 'boq_upload'
            ? _boqIdsForMarks(marks).toList()
            : const [],
        overrideConflict: overrideConflict,
        item: PebAssignmentItem(
          setupItemId: setupItem.id,
          stageName: setupItem.name,
          workDescription: _workDescriptionController.text.trim(),
          assemblyMarks: marks,
          assignedQty: assignedQty,
          uom: assignmentUom,
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
      _WorkAssignmentMode.quantityView => 'Quantity Plans',
      _WorkAssignmentMode.quantityAdd => _showForm
          ? (_findSetupItem(_setupItemId)?.name ?? 'Quantity Plan')
          : 'Quantity Plan',
    };
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: '${widget.executionType.title} $titleSuffix'),
      bottomNavigationBar: !_loading && _mode == _WorkAssignmentMode.view
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    top: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => setState(() {
                          _mode = _WorkAssignmentMode.add;
                          _showForm = false;
                        }),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isMarkSelectionPage
              ? _buildMarkSelectionPage(cs)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_mode != _WorkAssignmentMode.home &&
                          !(widget.openListDirectly &&
                              _mode == _WorkAssignmentMode.view))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              if (_mode == _WorkAssignmentMode.add &&
                                  _showForm) {
                                _showForm = false;
                              } else if (_mode ==
                                      _WorkAssignmentMode.quantityAdd &&
                                  _showForm) {
                                _showForm = false;
                              } else if (widget.openListDirectly) {
                                _mode = _WorkAssignmentMode.view;
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              if (_sourceType == 'boq_upload' && _allMarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMarkSelectionActionsRow(cs),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _buildMarkSelectionStep(cs, embedSelectionActions: false),
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
      case _WorkAssignmentMode.quantityView:
        return [_buildQuantityPlanList(cs)];
      case _WorkAssignmentMode.quantityAdd:
        return _showForm
            ? [_buildQuantityPlanForm(cs)]
            : [_buildQuantityStageGrid(cs)];
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
              '• Add: You can assign mark numbers to teams.\n'
              '• Quantity Plans: You can plan daily, weekly or monthly quantity targets.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                setState(() => _mode = _WorkAssignmentMode.quantityView),
            icon: const Icon(Icons.stacked_line_chart_rounded),
            label: const Text('Quantity Assignment Plans'),
          ),
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

  Widget _buildQuantityPlanList(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quantity Assignment Plans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: () => setState(() {
                _mode = _WorkAssignmentMode.quantityAdd;
                _showForm = false;
              }),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Plan daily, weekly or monthly quantity targets without changing mark-number assignments.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (_assignmentPlans.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No quantity plans created yet.'),
            ),
          ),
        ..._assignmentPlans.map((plan) {
          final target = switch (plan.targetType) {
            'team' => plan.team?.name ?? 'Team',
            'manpower' => plan.manpower?.name ?? 'Manpower',
            _ => 'Unassigned',
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ListTile(
              onTap: () => _showQuantityPlanDetails(plan),
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child:
                    Icon(Icons.stacked_line_chart_rounded, color: cs.primary),
              ),
              title: Text(
                plan.stageName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${plan.planningType.toUpperCase()} · $target\n'
                '${_formatDate(plan.startDate)} to ${_formatDate(plan.tcd)} · ${_formatNumber(plan.totalQuantity)} ${plan.uom}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') _showQuantityPlanDetails(plan);
                  if (value == 'edit') _openEditQuantityPlan(plan);
                  if (value == 'delete') _deleteQuantityPlan(plan);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'view', child: Text('View Breakdown')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Cancel')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showQuantityPlanDetails(PebAssignmentPlan plan) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return FutureBuilder<PebAssignmentPlan>(
              future: _service.getAssignmentPlanById(widget.siteId, plan.id),
              builder: (context, snapshot) {
                final loadedPlan = snapshot.data ?? plan;
                final details = loadedPlan.details;
                final planned = details.fold<double>(
                    0, (sum, detail) => sum + detail.plannedQuantity);
                final actual = details.fold<double>(
                    0, (sum, detail) => sum + detail.actualQuantity);
                final balance = details.fold<double>(
                    0, (sum, detail) => sum + detail.balanceQuantity);
                final target = switch (loadedPlan.targetType) {
                  'team' => loadedPlan.team?.name ?? 'Team',
                  'manpower' => loadedPlan.manpower?.name ?? 'Manpower',
                  _ => 'Unassigned',
                };

                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loadedPlan.stageName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loadedPlan.planningType.toUpperCase()} · $target · ${_formatDate(loadedPlan.startDate)} to ${_formatDate(loadedPlan.tcd)}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if (loadedPlan.targetType == 'unassigned') ...[
                      const SizedBox(height: 10),
                      _infoCard(
                        cs,
                        'Unassigned Planning',
                        'This planning is not linked to any team/manpower.',
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _planTotalTile(
                            cs,
                            'Planned',
                            '${_formatNumber(planned)} ${loadedPlan.uom}',
                            Icons.flag_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _planTotalTile(
                            cs,
                            'Actual',
                            '${_formatNumber(actual)} ${loadedPlan.uom}',
                            Icons.done_all_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _planTotalTile(
                            cs,
                            'Balance',
                            '${_formatNumber(balance)} ${loadedPlan.uom}',
                            Icons.balance_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (snapshot.hasError)
                      _infoCard(
                        cs,
                        'Unable to load breakdown',
                        snapshot.error.toString(),
                      )
                    else if (details.isEmpty)
                      _infoCard(
                        cs,
                        'No daily breakdown',
                        'Daily plan rows are not available for this plan.',
                      )
                    else
                      ...details.map((detail) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(detail.plannedDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      detail.status.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'P ${_formatNumber(detail.plannedQuantity)}  '
                                'A ${_formatNumber(detail.actualQuantity)}  '
                                'B ${_formatNumber(detail.balanceQuantity)} ${detail.uom}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _planTotalTile(
    ColorScheme cs,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildQuantityStageGrid(ColorScheme cs) {
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
        const Text(
          'Select Work Stage',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the stage for daily, weekly or monthly quantity planning.',
          style: TextStyle(color: cs.onSurfaceVariant),
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
            final count = _assignmentPlans
                .where((plan) => plan.setupItemId == item.id)
                .length;
            return InkWell(
              onTap: () => _openNewQuantityPlan(item),
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
                    Icon(Icons.timeline_rounded, color: cs.primary),
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
                          ? 'No quantity plan'
                          : '$count quantity plan${count == 1 ? '' : 's'}',
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

  Widget _buildQuantityPlanForm(ColorScheme cs) {
    final setupItem = _findSetupItem(_setupItemId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                setupItem?.name ?? 'Quantity Plan',
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(
                label: 'Assignment Target',
                value: _planTargetType,
                items: const [
                  DropdownMenuItem(value: 'team', child: Text('Team')),
                  DropdownMenuItem(value: 'manpower', child: Text('Manpower')),
                  DropdownMenuItem(
                      value: 'unassigned', child: Text('Unassigned')),
                ],
                onChanged: (value) =>
                    setState(() => _planTargetType = value ?? 'team'),
              ),
              const SizedBox(height: 12),
              if (_planTargetType == 'team')
                _teams.where((team) => team.id != _defaultTeamId).isEmpty
                    ? _infoCard(cs, 'No team found',
                        'Create a team first or use Unassigned planning.')
                    : _buildDropdown(
                        label: 'Team',
                        value: _teams.any((team) =>
                                team.id == _teamId && team.id != _defaultTeamId)
                            ? _teamId
                            : '',
                        items: _teams
                            .where((team) => team.id != _defaultTeamId)
                            .map((team) => DropdownMenuItem(
                                  value: team.id,
                                  child: Text(team.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _teamId = value ?? ''),
                      ),
              if (_planTargetType == 'manpower')
                _manpower.isEmpty
                    ? _infoCard(cs, 'No manpower found',
                        'Add manpower for this site first or use Unassigned planning.')
                    : _buildDropdown(
                        label: 'Manpower',
                        value:
                            _manpower.any((item) => item.id == _planManpowerId)
                                ? _planManpowerId
                                : '',
                        items: _manpower
                            .map((item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.designation.isEmpty
                                        ? item.name
                                        : '${item.name} · ${item.designation}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _planManpowerId = value ?? ''),
                      ),
              if (_planTargetType == 'unassigned')
                _infoCard(
                  cs,
                  'Planning only',
                  'This target will not be linked to a team or manpower. It can be used for project-level planning.',
                ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Planning Type',
                value: _planPlanningType,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) => setState(() {
                  _planPlanningType = value ?? 'daily';
                  if (_planPlanningType == 'daily') _planWeekOffDay = null;
                }),
              ),
              const SizedBox(height: 12),
              _buildDateTile(
                _planPlanningType == 'monthly' ? 'Month' : 'Start Date',
                _planStartDate,
                () => _pickPlanDate(tcd: false),
              ),
              const SizedBox(height: 12),
              _buildDateTile(
                'TCD',
                _planTcd,
                () => _pickPlanDate(tcd: true),
              ),
              if (_planTcd != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _planTcd = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear TCD'),
                ),
              ],
              if (_planPlanningType != 'daily') ...[
                const SizedBox(height: 12),
                _buildDropdown(
                  label: _planPlanningType == 'monthly'
                      ? 'Monthly Off Day'
                      : 'Week Off Day',
                  value: _planWeekOffDay?.toString() ?? 'none',
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('No Off Day')),
                    DropdownMenuItem(value: '0', child: Text('Sunday')),
                    DropdownMenuItem(value: '1', child: Text('Monday')),
                    DropdownMenuItem(value: '2', child: Text('Tuesday')),
                    DropdownMenuItem(value: '3', child: Text('Wednesday')),
                    DropdownMenuItem(value: '4', child: Text('Thursday')),
                    DropdownMenuItem(value: '5', child: Text('Friday')),
                    DropdownMenuItem(value: '6', child: Text('Saturday')),
                  ],
                  onChanged: (value) => setState(() {
                    _planWeekOffDay =
                        value == 'none' ? null : int.tryParse(value ?? '');
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  _planWeekOffDay == null
                      ? 'Quantity will be distributed across every day in the selected range.'
                      : 'Selected off day will be skipped while distributing planned quantity.',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _planQtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity (${setupItem?.uom ?? 'UOM'})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _planRemarksController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveQuantityPlan,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_editingPlanId.isEmpty
                      ? 'Save Quantity Plan'
                      : 'Update Quantity Plan'),
                ),
              ),
            ],
          ),
        ),
      ],
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
          _effectiveExpectedDate,
          () => _pickDate(expected: true),
        ),
        const SizedBox(height: 10),
        Text(
          'Skip keeps the expected date same as the assignment date.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildMarkSelectionStep(
    ColorScheme cs, {
    bool embedSelectionActions = true,
  }) {
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
            _selectedBoqIds = {};
            _selectedMarks = {};
            _markSearchText = '';
            _markSearchController.clear();
          }),
        ),
        const SizedBox(height: 12),
        if (_sourceType == 'boq_upload')
          _buildMarkPicker(
            cs,
            embedSelectionActions: embedSelectionActions,
          ),
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
          controller: _workDescriptionController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Work Description',
            hintText: 'Example: Twin member',
            border: OutlineInputBorder(),
          ),
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

  Widget _buildMarkPicker(
    ColorScheme cs, {
    bool embedSelectionActions = true,
  }) {
    final assignedForStage = _assignedMarksForStage;
    final completedForStage = _completedBySetupItem[_setupItemId] ?? <String>{};
    final previousStage = _previousSetupItem(_setupItemId);
    final previousStageAssignedMarks = previousStage == null
        ? <String>{}
        : _assignedMarksForSetupItem(previousStage.id);
    if (_allMarks.isEmpty) {
      return const Text('No BOQ marks found. Upload BOQ first.');
    }

    List<String> selectableMarksForBoq(PebBoq boq) {
      return _selectableMarkNumbersForBoq(
        boq,
        assignedForStage: assignedForStage,
        completedForStage: completedForStage,
        previousStage: previousStage,
        previousStageAssignedMarks: previousStageAssignedMarks,
      );
    }

    final search = _markSearchText.trim().toLowerCase();
    final marksInView = _visibleBoqMarks;
    final visibleMarks = search.isEmpty
        ? marksInView
        : marksInView.where((mark) {
            return mark.assemblyMark.toLowerCase().contains(search) ||
                mark.typeDescription.toLowerCase().contains(search);
          }).toList();
    final allBoqsSelected =
        _boqs.isNotEmpty && _selectedBoqIds.length == _boqs.length;
    final showingAllBoqs = _selectedBoqIds.isEmpty || allBoqsSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOQ Mark Numbers',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              _buildMarkSearchField(cs),
              const SizedBox(height: 10),
              Row(
                children: [
                  _markCounterChip(
                    '${visibleMarks.length}/${marksInView.length}',
                    'visible',
                    cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _markCounterChip(
                    '${_selectedMarks.length}',
                    'selected',
                    cs.primary,
                  ),
                ],
              ),
              if (embedSelectionActions) ...[
                const SizedBox(height: 10),
                _buildMarkSelectionActionsRow(cs),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectedMarks.isEmpty || _saving
                      ? null
                      : _bulkUpdateSelectedWeight,
                  icon: const Icon(Icons.scale_rounded, size: 18),
                  label: const Text('Bulk Weight'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
        if (previousStage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: cs.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only marks already assigned in ${previousStage.name} can be selected here.',
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
              final isPreviousStageMissing = previousStage != null &&
                  !previousStageAssignedMarks.contains(mark.assemblyMark);
              final selected = _selectedMarks.contains(mark.assemblyMark);
              final disabled =
                  isCompleted || isAssigned || isPreviousStageMissing;
              final qty =
                  mark.remainingQty > 0 ? mark.remainingQty : mark.quantity;
              final statusText = isCompleted
                  ? 'Completed'
                  : isAssigned
                      ? 'Assigned'
                      : isPreviousStageMissing
                          ? 'Assign ${previousStage.name} first'
                          : '${_prettyNumber(qty)} qty';
              return Opacity(
                opacity: disabled ? 0.45 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () => _toggleMarkSelection(mark.assemblyMark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: 0.45),
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
                ),
              );
            },
          ),
        if (_boqs.length > 1) ...[
          const SizedBox(height: 16),
          _buildBoqSelectionPanel(
            cs,
            allSelected: showingAllBoqs,
            onToggleAll: _toggleAllBoqFilters,
            onToggleBoq: _toggleBoqFilter,
            selectableMarksForBoq: selectableMarksForBoq,
          ),
        ],
      ],
    );
  }

  Widget _buildBoqSelectionPanel(
    ColorScheme cs, {
    required bool allSelected,
    required VoidCallback onToggleAll,
    required void Function(PebBoq boq) onToggleBoq,
    required List<String> Function(PebBoq boq) selectableMarksForBoq,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter by BOQ (optional)',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _selectedBoqIds.isEmpty
                    ? 'All ${_boqs.length} BOQs'
                    : '${_selectedBoqIds.length}/${_boqs.length} filtered',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'All mark numbers are shown by default. Select BOQs here to narrow the list.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: allSelected,
                showCheckmark: false,
                avatar: Icon(
                  allSelected
                      ? Icons.done_all_rounded
                      : Icons.select_all_rounded,
                  size: 18,
                ),
                label: Text(allSelected ? 'Show All' : 'Select All'),
                onSelected: (_) => onToggleAll(),
              ),
              ..._boqs.map((boq) {
                final selected = _selectedBoqIds.contains(boq.id);
                final selectableCount = selectableMarksForBoq(boq).length;
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    label: Text(
                      '${boq.name} ($selectableCount)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onSelected: (_) => onToggleBoq(boq),
                    selectedColor: cs.primaryContainer,
                    backgroundColor: cs.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
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
    final assignments = _visibleAssignments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Work Assignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _mode = _WorkAssignmentMode.quantityView),
              icon: const Icon(Icons.stacked_line_chart_rounded, size: 18),
              label: const Text('Quantity Plans'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_assignments.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _assignmentSearchController,
                    onChanged: (value) =>
                        setState(() => _assignmentSearchText = value),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search assignments...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _assignmentSearchText.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _assignmentSearchController.clear();
                                setState(() => _assignmentSearchText = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _assignmentToolbarButton(
                cs,
                tooltip: 'Filter and sort',
                icon: Icons.tune_rounded,
                active: _hasAssignmentFilters,
                onPressed: _showAssignmentFilters,
              ),
              const SizedBox(width: 6),
              _assignmentToolbarButton(
                cs,
                tooltip: 'Download Sheet',
                icon: Icons.download_rounded,
                onPressed: _downloadAssignments,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_assignments.isEmpty)
          _emptyAssignmentState(cs)
        else if (assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 40, color: cs.onSurfaceVariant),
                const SizedBox(height: 10),
                const Text(
                  'No assignments found',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try adjusting your search or filters.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _assignmentSearchController.clear();
                    _assignmentSearchText = '';
                    _assignmentStageFilter = null;
                    _assignmentTeamFilter = null;
                    _assignmentSort = _AssignmentSortOption.latestFirst;
                  }),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          )
        else
          ...assignments.map((assignment) {
            final item = assignment.assignments.isNotEmpty
                ? assignment.assignments.first
                : null;
            final description = item?.workDescription.trim() ?? '';
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
                  '${(assignment.team?.name.trim().isNotEmpty ?? false) ? '${assignment.team!.name} · ' : ''}${item?.assignedQty ?? 0} ${item?.uom ?? ''}\n'
                  '${description.isEmpty ? '' : '$description\n'}'
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

  Widget _emptyAssignmentState(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_ind_outlined, size: 44, color: cs.primary),
          const SizedBox(height: 10),
          const Text(
            'No Work Assignments',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Create the first assignment for this site.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => setState(() {
              _mode = _WorkAssignmentMode.add;
              _showForm = false;
            }),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Assignment'),
          ),
        ],
      ),
    );
  }

  Widget _assignmentToolbarButton(
    ColorScheme cs, {
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? cs.onPrimary : cs.primary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);

  String _formatNumber(double value) => value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

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
              if (assignment.team?.name.trim().isNotEmpty ?? false) ...[
                Text(
                  assignment.team!.name,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text('Status: ${assignment.status}'),
              Text('Start: ${_formatDate(assignment.assignmentDate)}'),
              Text(
                  'Expected: ${_formatDate(assignment.expectedCompletionDate)}'),
              if ((firstItem?.workDescription.trim() ?? '').isNotEmpty)
                Text('Description: ${firstItem!.workDescription.trim()}'),
              const Divider(),
              ...assignment.assignments.map((item) => ListTile(
                    title: Text(item.stageName),
                    subtitle: Text([
                      if (item.workDescription.trim().isNotEmpty)
                        item.workDescription.trim(),
                      item.assemblyMarks.isEmpty
                          ? 'Quantity: ${item.assignedQty}'
                          : item.assemblyMarks.join(', '),
                    ].join('\n')),
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

enum _WorkAssignmentMode { home, view, add, quantityView, quantityAdd }

enum _AssignmentSortOption { latestFirst, oldestFirst, stageAsc }

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
