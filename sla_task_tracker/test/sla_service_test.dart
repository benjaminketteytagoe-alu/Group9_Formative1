import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/sla_service.dart';

Task makeTask({
  required DateTime due,
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
}) {
  return Task(
    id: '1',
    title: 'Test task',
    description: '',
    category: 'Testing',
    assigneeId: 'm1',
    priority: priority,
    status: status,
    dueDate: due,
    createdAt: DateTime(2026, 10, 1),
  );
}

void main() {
  //  Used the "current time" so the tests never depends on the real clock.
  final now = DateTime(2026, 10, 5, 12, 0);

  group('SlaService.statusFor', () {
    test('done task is Completed, even if the deadline has passed', () {
      final t = makeTask(due: DateTime(2026, 10, 1), status: TaskStatus.done);
      expect(SlaService.statusFor(t, now: now), SlaStatus.completed);
    });

    test('incomplete task past its deadline is Overdue', () {
      final t = makeTask(due: DateTime(2026, 10, 4));
      expect(SlaService.statusFor(t, now: now), SlaStatus.overdue);
    });

    test('task due today is not Overdue until the end of the day', () {
      final t = makeTask(due: DateTime(2026, 10, 5));
      expect(SlaService.statusFor(t, now: DateTime(2026, 10, 5, 15, 0)),
          SlaStatus.atRisk);
    });

    test('medium task due within 48h is At Risk', () {
      final t = makeTask(due: DateTime(2026, 10, 6));
      expect(SlaService.statusFor(t, now: now), SlaStatus.atRisk);
    });

    test('medium task due in about 60h is On Track', () {
      final t = makeTask(due: DateTime(2026, 10, 7));
      expect(SlaService.statusFor(t, now: now), SlaStatus.onTrack);
    });

    test('high priority task gets the longer 72h warning window', () {
      final t = makeTask(due: DateTime(2026, 10, 7), priority: TaskPriority.high);
      expect(SlaService.statusFor(t, now: now), SlaStatus.atRisk);
    });

    test('task far in the future is On Track', () {
      final t = makeTask(due: DateTime(2026, 10, 20));
      expect(SlaService.statusFor(t, now: now), SlaStatus.onTrack);
    });
  });

  group('SlaService.messageFor', () {
    test('returns the on-track message', () {
      final t = makeTask(due: DateTime(2026, 10, 20));
      expect(SlaService.messageFor(t, now: now),
          'The task is progressing as expected.');
    });
  });
}