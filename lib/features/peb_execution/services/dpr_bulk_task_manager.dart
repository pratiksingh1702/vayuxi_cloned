import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled2/core/utlis/common_functions.dart';

import '../models/peb_execution_models.dart';
import 'peb_execution_service.dart';

enum DprBulkTaskStatus { queued, running, completed, failed }

class DprBulkTaskItem {
  final String mark;
  final double actualQty;
  final double targetQty;
  final String weightMode;
  final double manualWeightKg;
  final double totalWeightKg;
  final String remarks;
  final String variationReason;
  final String variationRemarks;

  const DprBulkTaskItem({
    required this.mark,
    required this.actualQty,
    required this.targetQty,
    required this.weightMode,
    required this.manualWeightKg,
    required this.totalWeightKg,
    this.remarks = '',
    this.variationReason = '',
    this.variationRemarks = '',
  });
}

class DprBulkTask {
  final String id;
  final String siteId;
  final PebExecutionType type;
  final String date;
  final String teamId;
  final String setupItemId;
  final String assignmentId;
  final String sourceType;
  final String stageName;
  final String uom;
  final int progressPercentage;
  final List<DprBulkTaskItem> items;
  final DateTime createdAt;
  final DprBulkTaskStatus status;
  final int processed;
  final int failed;
  final String? error;
  final List<String> failedDetails;

  const DprBulkTask({
    required this.id,
    required this.siteId,
    required this.type,
    required this.date,
    required this.teamId,
    required this.setupItemId,
    required this.assignmentId,
    required this.sourceType,
    required this.stageName,
    required this.uom,
    required this.progressPercentage,
    required this.items,
    required this.createdAt,
    this.status = DprBulkTaskStatus.queued,
    this.processed = 0,
    this.failed = 0,
    this.error,
    this.failedDetails = const [],
  });

  int get total => items.length;
  bool get isActive =>
      status == DprBulkTaskStatus.queued || status == DprBulkTaskStatus.running;
  double get progress => total == 0 ? 0 : processed / total;
  String get actionLabel =>
      progressPercentage >= 100 ? 'Completed' : 'In Progress';

  DprBulkTask copyWith({
    DprBulkTaskStatus? status,
    int? processed,
    int? failed,
    String? error,
    List<String>? failedDetails,
  }) {
    return DprBulkTask(
      id: id,
      siteId: siteId,
      type: type,
      date: date,
      teamId: teamId,
      setupItemId: setupItemId,
      assignmentId: assignmentId,
      sourceType: sourceType,
      stageName: stageName,
      uom: uom,
      progressPercentage: progressPercentage,
      items: items,
      createdAt: createdAt,
      status: status ?? this.status,
      processed: processed ?? this.processed,
      failed: failed ?? this.failed,
      error: error ?? this.error,
      failedDetails: failedDetails ?? this.failedDetails,
    );
  }
}

class DprBulkTaskManager extends ChangeNotifier {
  DprBulkTaskManager._();

  static final DprBulkTaskManager instance = DprBulkTaskManager._();

  static const int _batchSize = 4;
  final PebExecutionService _service = PebExecutionService();
  final Queue<String> _queue = Queue<String>();
  final Map<String, DprBulkTask> _tasks = {};
  bool _processing = false;
  String? _lastCompletedTaskId;

  List<DprBulkTask> get tasks => _tasks.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  DprBulkTask? get currentTask {
    for (final task in tasks.reversed) {
      if (task.status == DprBulkTaskStatus.running) return task;
    }
    for (final task in tasks.reversed) {
      if (task.status == DprBulkTaskStatus.queued) return task;
    }
    return null;
  }

  DprBulkTask? get lastCompletedTask {
    final id = _lastCompletedTaskId;
    return id == null ? null : _tasks[id];
  }

  DprBulkTask enqueue({
    required String siteId,
    required PebExecutionType type,
    required String date,
    required String teamId,
    required String setupItemId,
    required String assignmentId,
    required String sourceType,
    required String stageName,
    required String uom,
    required int progressPercentage,
    required List<DprBulkTaskItem> items,
  }) {
    final task = DprBulkTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      siteId: siteId,
      type: type,
      date: date,
      teamId: teamId,
      setupItemId: setupItemId,
      assignmentId: assignmentId,
      sourceType: sourceType,
      stageName: stageName,
      uom: uom,
      progressPercentage: progressPercentage,
      items: List.unmodifiable(items),
      createdAt: DateTime.now(),
    );
    _tasks[task.id] = task;
    _queue.add(task.id);
    notifyListeners();
    unawaited(_processQueue());
    return task;
  }

  bool hasActiveTaskFor(String siteId, PebExecutionType type) {
    return _tasks.values.any(
        (task) => task.siteId == siteId && task.type == type && task.isActive);
  }

  void clearFinished() {
    _tasks.removeWhere((_, task) => !task.isActive);
    _lastCompletedTaskId = null;
    notifyListeners();
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final id = _queue.removeFirst();
        final task = _tasks[id];
        if (task == null) continue;
        await _runTask(task);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _runTask(DprBulkTask task) async {
    var processed = task.processed;
    var failed = task.failed;
    final failedDetails = List<String>.from(task.failedDetails);
    _tasks[task.id] = task.copyWith(status: DprBulkTaskStatus.running);
    notifyListeners();

    try {
      for (var start = 0; start < task.items.length; start += _batchSize) {
        final batch = task.items.skip(start).take(_batchSize).toList();
        await Future.wait(batch.map((item) async {
          try {
            await _service.submitDprProgress(
              task.siteId,
              task.type,
              date: task.date,
              teamId: task.teamId,
              setupItemId: task.setupItemId,
              assignmentId: task.assignmentId,
              sourceType: task.sourceType,
              stageName: task.stageName,
              uom: task.uom,
              marks: [item.mark],
              actualQty: item.actualQty,
              targetQty: item.targetQty,
              progressPercentage: task.progressPercentage,
              trackingLevel: 'advanced',
              remarks: item.remarks,
              variationReason: item.variationReason,
              variationRemarks: item.variationRemarks,
              weightMode: item.weightMode,
              manualWeightKg: item.manualWeightKg,
              totalWeightKg: item.totalWeightKg,
            );
          } catch (error) {
            failed++;
            failedDetails.add('${item.mark}: ${_friendlyError(error)}');
          } finally {
            processed++;
          }
        }));
        _tasks[task.id] = _tasks[task.id]!.copyWith(
          processed: processed,
          failed: failed,
          failedDetails: List.unmodifiable(failedDetails),
        );
        notifyListeners();
      }

      final nextStatus = failed == task.items.length
          ? DprBulkTaskStatus.failed
          : DprBulkTaskStatus.completed;
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: nextStatus,
        processed: processed,
        failed: failed,
        failedDetails: List.unmodifiable(failedDetails),
        error: failed > 0
            ? '$failed mark update(s) failed. ${failedDetails.take(3).join(' | ')}'
            : null,
      );
      _lastCompletedTaskId = task.id;
      notifyListeners();
    } catch (error) {
      _tasks[task.id] = _tasks[task.id]!.copyWith(
        status: DprBulkTaskStatus.failed,
        error: error.toString(),
      );
      _lastCompletedTaskId = task.id;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) return extractBackendError(error);
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty || message.length > 220) {
      return 'Unable to update this mark';
    }
    return message;
  }
}
