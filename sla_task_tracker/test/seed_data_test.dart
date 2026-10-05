import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/sla_service.dart';

void main() {
  final now = DateTime(2026, 10, 5, 12, 0);
  final tasks = SeedData.tasks(now: now);

  int count(SlaStatus s) =>
      tasks.where((t) => SlaService.statusFor(t, now: now) == s).length;

  test('seed data covers every SLA status', () {
    expect(count(SlaStatus.completed), 6);
    expect(count(SlaStatus.overdue), 4);
    expect(count(SlaStatus.atRisk), 5);
    expect(count(SlaStatus.onTrack), 7);
    expect(tasks.length, 22);
  });

  test('every task is assigned to an existing member', () {
    final ids = SeedData.members().map((m) => m.id).toSet();
    expect(tasks.every((t) => ids.contains(t.assigneeId)), isTrue);
  });

  test('task ids are unique', () {
    expect(tasks.map((t) => t.id).toSet().length, tasks.length);
  });

  test('only done tasks have a completion date', () {
    for (final t in tasks) {
      expect(t.completedAt != null, t.status == TaskStatus.done);
    }
  });
}