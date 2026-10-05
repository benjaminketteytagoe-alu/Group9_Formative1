import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/providers/activity_provider.dart';
import 'package:sla_task_tracker/providers/member_provider.dart';
import 'package:sla_task_tracker/providers/task_provider.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  late StorageService storage;
  late ActivityProvider activity;
  late TaskProvider tasks;

  Task sample(String id) => Task(
    id: id,
    title: 'Sample $id',
    description: '',
    category: 'Testing',
    assigneeId: 'm1',
    priority: TaskPriority.medium,
    status: TaskStatus.todo,
    dueDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 10, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    activity = ActivityProvider(storage);
    tasks = TaskProvider(storage, activity, currentUserId: () => 'm1');
    await tasks.load();
  });

  group('TaskProvider', () {
    test('addTask stores the task, persists it and logs activity', () async {
      await tasks.addTask(sample('a'));

      expect(tasks.tasks.length, 1);
      expect((await StorageService().loadTasks()).length, 1);
      expect(activity.recent.first.message, 'created Sample a');
      expect(activity.recent.first.memberId, 'm1');
    });

    test('setStatus to done sets completedAt, moving back clears it', () async {
      await tasks.addTask(sample('a'));

      await tasks.setStatus('a', TaskStatus.done);
      expect(tasks.byId('a')!.completedAt, isNotNull);

      await tasks.setStatus('a', TaskStatus.inProgress);
      expect(tasks.byId('a')!.completedAt, isNull);
    });

    test('updateTask changes the task', () async {
      await tasks.addTask(sample('a'));
      await tasks.updateTask(tasks.byId('a')!.copyWith(title: 'Renamed'));
      expect(tasks.byId('a')!.title, 'Renamed');
    });

    test('deleteTask removes it from memory and storage', () async {
      await tasks.addTask(sample('a'));
      await tasks.deleteTask('a');

      expect(tasks.tasks, isEmpty);
      expect(await StorageService().loadTasks(), isEmpty);
    });

    test('SLA counts and progress match the seed data', () async {
      final now = DateTime(2026, 10, 5, 12, 0);
      await storage.saveTasks(SeedData.tasks(now: now));
      await tasks.load();

      final counts = tasks.slaCounts(now: now);
      expect(counts[SlaStatus.completed], 6);
      expect(counts[SlaStatus.overdue], 4);
      expect(counts[SlaStatus.atRisk], 5);
      expect(counts[SlaStatus.onTrack], 7);
      expect(tasks.progress, closeTo(6 / 22, 0.001));
    });

    test('needsAttention lists overdue tasks before at-risk ones', () async {
      final now = DateTime(2026, 10, 5, 12, 0);
      await storage.saveTasks(SeedData.tasks(now: now));
      await tasks.load();

      final list = tasks.needsAttention(now: now);
      expect(list.length, 9); // 4 overdue + 5 at risk
      expect(tasks.slaOf(list.first, now: now), SlaStatus.overdue);
      expect(tasks.slaOf(list.last, now: now), SlaStatus.atRisk);
    });

    test('upcomingDeadlines excludes overdue and completed tasks', () async {
      final now = DateTime(2026, 10, 5, 12, 0);
      await storage.saveTasks(SeedData.tasks(now: now));
      await tasks.load();

      final upcoming = tasks.upcomingDeadlines(limit: 20, now: now);
      expect(upcoming.length, 12); // 5 at risk + 7 on track
      for (final t in upcoming) {
        expect(t.status, isNot(TaskStatus.done));
      }
    });
  });

  group('MemberProvider', () {
    test('signIn is remembered after a restart', () async {
      await SeedData.reset(storage);
      final members = MemberProvider(storage);
      await members.load();

      await members.signIn(SeedData.benjaminId);
      expect(members.currentUser?.name, 'Benjamin');

      final restarted = MemberProvider(StorageService());
      await restarted.load();
      expect(restarted.currentUser?.id, SeedData.benjaminId);
    });

    test('signOut clears the current user', () async {
      await SeedData.reset(storage);
      final members = MemberProvider(storage);
      await members.load();

      await members.signIn(SeedData.boazId);
      await members.signOut();
      expect(members.isSignedIn, isFalse);
    });
  });
}