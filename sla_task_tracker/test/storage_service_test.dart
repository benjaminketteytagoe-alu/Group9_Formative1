import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sample = Task(
    id: 't1',
    title: 'Design Login Screen',
    description: 'Clean and modern',
    category: 'UI/UX Design',
    assigneeId: 'm1',
    priority: TaskPriority.high,
    status: TaskStatus.inProgress,
    dueDate: DateTime(2026, 12, 10),
    createdAt: DateTime(2026, 12, 1),
  );

  setUp(() {
    // Fresh, empty fake storage before every test.
    SharedPreferences.setMockInitialValues({});
  });

  test('loadTasks returns an empty list when nothing is saved', () async {
    final storage = StorageService();
    expect(await storage.loadTasks(), isEmpty);
  });

  test('saved tasks can be loaded back (persistence)', () async {
    final storage = StorageService();
    await storage.saveTasks([sample]);

    final loaded = await StorageService().loadTasks(); // new instance, like a restart
    expect(loaded.length, 1);
    expect(loaded.first.id, 't1');
    expect(loaded.first.title, 'Design Login Screen');
    expect(loaded.first.priority, TaskPriority.high);
    expect(loaded.first.status, TaskStatus.inProgress);
  });

  test('corrupted data does not crash the app', () async {
    SharedPreferences.setMockInitialValues({'tasks': 'not valid json {{'});
    final storage = StorageService();
    expect(await storage.loadTasks(), isEmpty);
  });
}