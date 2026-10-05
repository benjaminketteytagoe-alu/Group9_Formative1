import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/models/task.dart';

void main() {
  test('Task survives toJson -> fromJson', () {
    final task = Task(
      id: '1',
      title: 'Design Login Screen',
      description: 'Create a clean login screen',
      category: 'UI/UX Design',
      assigneeId: 'm1',
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      dueDate: DateTime(2026, 12, 10),
      createdAt: DateTime(2026, 12, 1),
    );

    final copy = Task.fromJson(task.toJson());

    expect(copy.id, task.id);
    expect(copy.title, task.title);
    expect(copy.priority, task.priority);
    expect(copy.status, task.status);
    expect(copy.dueDate, task.dueDate);
    expect(copy.completedAt, isNull);
  });
}