import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/providers/activity_provider.dart';
import 'package:sla_task_tracker/providers/member_provider.dart';
import 'package:sla_task_tracker/providers/task_provider.dart';
import 'package:sla_task_tracker/screens/member_form_screen.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  late StorageService storage;
  late MemberProvider members;
  late TaskProvider tasks;

  /// Opens the form on top of a blank page, so saving can pop back.
  Future<void> pumpForm(WidgetTester tester, {String? memberId}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: members),
          ChangeNotifierProvider.value(value: tasks),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberFormScreen(memberId: memberId),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await SeedData.reset(storage);
    final activity = ActivityProvider(storage);
    members = MemberProvider(storage);
    tasks = TaskProvider(storage, activity);
    await Future.wait([activity.load(), members.load(), tasks.load()]);
  });

  testWidgets('required fields show errors and nothing is saved',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Role is required'), findsOneWidget);
    expect(members.members.length, 4);
  });

  testWidgets('rejects an invalid or already used email', (tester) async {
    await pumpForm(tester);
    await tester.enterText(field('Full name *'), 'Amina Yusuf');
    await tester.enterText(field('Role *'), 'Designer');

    await tester.enterText(field('Email (optional)'), 'not-an-email');
    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(field('Email (optional)'), 'Kellen@Example.com');
    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();
    expect(find.text('Another member already uses this email'), findsOneWidget);
    expect(members.members.length, 4);
  });

  testWidgets('adds a new member and persists it', (tester) async {
    await pumpForm(tester);

    await tester.enterText(field('Full name *'), '  Amina Yusuf ');
    await tester.enterText(field('Role *'), 'Designer');
    await tester.enterText(field('Email (optional)'), 'amina@example.com');
    await tester.pump();
    expect(find.text('AY'), findsOneWidget); // avatar preview

    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();

    expect(find.byType(MemberFormScreen), findsNothing); // went back
    final added = members.members.last;
    expect(added.name, 'Amina Yusuf');
    expect(added.role, 'Designer');
    expect(added.email, 'amina@example.com');

    final saved = await storage.loadMembers();
    expect(saved.length, 5);
    expect(saved.last.name, 'Amina Yusuf');
  });

  testWidgets('edit mode is pre-filled and saves the changes',
      (tester) async {
    await pumpForm(tester, memberId: SeedData.kellen_id);

    expect(find.text('Edit Member'), findsOneWidget);
    expect(find.text('Kellen'), findsOneWidget);
    expect(find.text('kellen@example.com'), findsOneWidget);

    await tester.enterText(field('Role *'), 'Lead Designer');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(members.members.length, 4);
    expect(members.byId(SeedData.kellen_id)?.role, 'Lead Designer');
    // Keeping your own email is not a duplicate.
    expect(members.byId(SeedData.kellen_id)?.email, 'kellen@example.com');
  });
}
