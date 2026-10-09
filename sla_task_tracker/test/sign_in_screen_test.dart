import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/app.dart';
import 'package:sla_task_tracker/providers/activity_provider.dart';
import 'package:sla_task_tracker/providers/member_provider.dart';
import 'package:sla_task_tracker/providers/task_provider.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  late StorageService storage;
  late MemberProvider members;
  late TaskProvider tasks;

  Future<void> pumpApp(WidgetTester tester) async {
    // Phone-sized screen, like the emulator.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: members),
          ChangeNotifierProvider.value(value: tasks),
        ],
        child: const MyApp(),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await SeedData.reset(storage);
    final activity = ActivityProvider(storage);
    members = MemberProvider(storage);
    tasks = TaskProvider(storage, activity);
    await Future.wait([activity.load(), members.load(), tasks.load()]);
  });

  testWidgets('lists every team member with a disabled button',
      (tester) async {
    await pumpApp(tester);

    for (final m in SeedData.members()) {
      expect(find.text(m.name), findsOneWidget);
    }
    expect(find.text('Select your profile'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a member and continuing signs them in',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(
      find.ancestor(of: find.text('Boaz'), matching: find.byType(ListTile)),
    );
    await tester.pump();
    expect(find.text('Continue as Boaz'), findsOneWidget);

    await tester.tap(find.text('Continue as Boaz'));
    await tester.pumpAndSettle();

    expect(members.currentUser?.id, SeedData.boazId);
    expect(await storage.getCurrentUserId(), SeedData.boazId);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Signed in as Boaz (QA Tester)'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no members',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    members = MemberProvider(StorageService());
    await members.load();
    await pumpApp(tester);

    expect(find.text('No team members yet.'), findsOneWidget);
  });
}
