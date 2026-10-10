import '../models/enums.dart';
import '../models/task.dart';

class SlaService {
  // Hours before the deadline when a task becomes "At Risk".
  static const int at_risk_hours = 48; // normal tasks
  static const int at_risk_hours_high_priority = 72; // high priority gets an earlier warning

  /// Due dates come from a date picker (midnight), so the real deadline
  /// is treated as the END of that day (23:59:59).
  static DateTime deadlineOf(Task t) =>
      DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day, 23, 59, 59);

  /// [now] is optional so tests (and live demos) can pass any date.
  static SlaStatus statusFor(Task t, {DateTime? now}) {
    final current = now ?? DateTime.now();

    if (t.status == TaskStatus.done) return SlaStatus.completed;

    final deadline = deadlineOf(t);
    if (current.isAfter(deadline)) return SlaStatus.overdue;

    final window =
    t.priority == TaskPriority.high ? at_risk_hours_high_priority : at_risk_hours;
    if (deadline.difference(current).inHours <= window) {
      return SlaStatus.atRisk;
    }

    return SlaStatus.onTrack;
  }

  static String messageFor(Task t, {DateTime? now}) {
    switch (statusFor(t, now: now)) {
      case SlaStatus.completed:
        return 'This task has been completed.';
      case SlaStatus.overdue:
        return 'The deadline has passed. Needs immediate attention.';
      case SlaStatus.atRisk:
        return 'The deadline is close. Prioritise this task.';
      case SlaStatus.onTrack:
        return 'The task is progressing as expected.';
    }
  }
}