import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../services/sla_service.dart';
import '../services/storage_service.dart';
import 'activity_provider.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(
      this._storage,
      this._activity, {
        String? Function()? currentUserId,
      }) : _currentUserId = currentUserId;

  final StorageService _storage;
  final ActivityProvider _activity;
  final String? Function()? _currentUserId; // who is performing the action
  static const _uuid = Uuid();

  List<Task> _tasks = [];
  bool _isLoading = true;

  // ---------- State ----------

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  /// New unique id for the Create Task form.
  String newId() => _uuid.v4();

  Task? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    _tasks = await _storage.loadTasks();
    _isLoading = false;
    notifyListeners();
  }

  // ---------- CRUD ----------

  Future<void> addTask(Task task) async {
    _tasks = [..._tasks, _normalize(task)];
    notifyListeners();
    await _log('created', task.title);
    await _storage.saveTasks(_tasks);
  }

  Future<void> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    final wasDone = _tasks[i].status == TaskStatus.done;
    final updated = _normalize(task);
    _tasks = [..._tasks]..[i] = updated;
    notifyListeners();
    final nowDone = updated.status == TaskStatus.done;
    await _log(nowDone && !wasDone ? 'completed' : 'updated', task.title);
    await _storage.saveTasks(_tasks);
  }

  Future<void> deleteTask(String id) async {
    final task = byId(id);
    if (task == null) return;
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _log('deleted', task.title);
    await _storage.saveTasks(_tasks);
  }

  /// Quick status change (used by the dropdown on Task Details).
  Future<void> setStatus(String id, TaskStatus status) async {
    final task = byId(id);
    if (task == null || task.status == status) return;
    final i = _tasks.indexWhere((t) => t.id == id);
    final updated = _normalize(task.copyWith(status: status));
    _tasks = [..._tasks]..[i] = updated;
    notifyListeners();
    await _log(
      status == TaskStatus.done ? 'completed' : 'moved to ${status.label}:',
      task.title,
    );
    await _storage.saveTasks(_tasks);
  }

  // ---------- SLA helpers ----------

  SlaStatus slaOf(Task t, {DateTime? now}) =>
      SlaService.statusFor(t, now: now);

  int countBySla(SlaStatus s, {DateTime? now}) =>
      _tasks.where((t) => slaOf(t, now: now) == s).length;

  /// Map for the dashboard cards, donut chart and bar chart.
  Map<SlaStatus, int> slaCounts({DateTime? now}) => {
    for (final s in SlaStatus.values) s: countBySla(s, now: now),
  };

  /// Share of tasks that are completed (0.0 to 1.0) for the progress bar.
  double get progress => _tasks.isEmpty
      ? 0
      : _tasks.where((t) => t.status == TaskStatus.done).length /
      _tasks.length;

  /// Overdue first, then At Risk, each ordered by due date.
  List<Task> needsAttention({DateTime? now}) {
    final list = _tasks.where((t) {
      final s = slaOf(t, now: now);
      return s == SlaStatus.overdue || s == SlaStatus.atRisk;
    }).toList();
    list.sort((a, b) {
      final sa = slaOf(a, now: now) == SlaStatus.overdue ? 0 : 1;
      final sb = slaOf(b, now: now) == SlaStatus.overdue ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return a.dueDate.compareTo(b.dueDate);
    });
    return list;
  }

  /// Not done and not overdue, soonest first (Task Statistics screen).
  List<Task> upcomingDeadlines({int limit = 5, DateTime? now}) {
    final list = _tasks.where((t) {
      final s = slaOf(t, now: now);
      return s == SlaStatus.atRisk || s == SlaStatus.onTrack;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list.take(limit).toList();
  }

  List<Task> tasksForMember(String memberId) =>
      _tasks.where((t) => t.assigneeId == memberId).toList();

  // ---------- Private ----------

  /// Keeps completedAt consistent with status.
  Task _normalize(Task t) {
    if (t.status == TaskStatus.done && t.completedAt == null) {
      return t.copyWith(completedAt: DateTime.now());
    }
    if (t.status != TaskStatus.done && t.completedAt != null) {
      return t.copyWith(clearCompletedAt: true);
    }
    return t;
  }

  Future<void> _log(String verb, String title) =>
      _activity.log('$verb $title', _currentUserId?.call() ?? 'unknown');
}