import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/models/enums.dart';
import 'package:sla_task_tracker/models/task.dart';
import 'package:sla_task_tracker/providers/activity_provider.dart';
import 'package:sla_task_tracker/providers/member_provider.dart';
import 'package:sla_task_tracker/providers/task_provider.dart';
import 'package:sla_task_tracker/screens/team_screen.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/storage_service.dart';
import 'package:sla_task_tracker/utils/app_routes.dart';
import 'package:sla_task_tracker/utils/workload.dart';

void main() {
  late MemberProvider members;
  late TaskProvider tasks;

  Future<void> pumpTeam(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: members),
          ChangeNotifierProvider.value(value: tasks),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: TeamScreen(),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await SeedData.reset(storage);
    final activity = ActivityProvider(storage);
    members = MemberProvider(storage);
    tasks = TaskProvider(storage, activity);
    await Future.wait([activity.load(), members.load(), tasks.load()]);
    await members.signIn(SeedData.boazId);
  });

  group('Workload', () {
    test('levels follow the number of open tasks', () {
      expect(Workload.fromOpenTasks(0), Workload.light);
      expect(Workload.fromOpenTasks(2), Workload.light);
      expect(Workload.fromOpenTasks(3), Workload.moderate);
      expect(Workload.fromOpenTasks(4), Workload.moderate);
      expect(Workload.fromOpenTasks(5), Workload.heavy);
    });

    test('MemberStats counts open, done and SLA statuses', () {
      final now = DateTime(2026, 10, 9, 12);
      Task t(String id, TaskStatus status, int dueInDays) => Task(
            id: id,
            title: id,
            description: '',
            category: '',
            assigneeId: 'm1',
            priority: TaskPriority.medium,
            status: status,
            dueDate: DateTime(2026, 10, 9 + dueInDays),
            createdAt: DateTime(2026, 10, 1),
          );

      final stats = MemberStats([
        t('a', TaskStatus.done, -1),
        t('b', TaskStatus.todo, -2), // overdue
        t('c', TaskStatus.inProgress, 10), // on track
      ], now: now);

      expect(stats.total, 3);
      expect(stats.open, 2);
      expect(stats.done, 1);
      expect(stats.overdue, 1);
      expect(stats.sla[SlaStatus.onTrack], 1);
      expect(stats.sla[SlaStatus.completed], 1);
    });
  });

  testWidgets('shows the signed-in user and every member', (tester) async {
    await pumpTeam(tester);

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('Boaz (you)'), findsOneWidget);
    for (final m in SeedData.members().where((m) => m.id != SeedData.boazId)) {
      expect(find.text(m.name), findsOneWidget);
    }
  });

  testWidgets('tapping a member opens their profile', (tester) async {
    await pumpTeam(tester);

    await tester.tap(find.text('Kellen'));
    await tester.pumpAndSettle();

    expect(find.text('kellen@example.com'), findsOneWidget);
    expect(find.textContaining('Assigned tasks'), findsOneWidget);
  });

  testWidgets('sign out asks for confirmation, then signs out',
      (tester) async {
    await pumpTeam(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(members.isSignedIn, isTrue);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(members.isSignedIn, isFalse);
  });
}
