import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_task_tracker/app.dart';
import 'package:sla_task_tracker/providers/activity_provider.dart';
import 'package:sla_task_tracker/providers/member_provider.dart';
import 'package:sla_task_tracker/providers/task_provider.dart';
import 'package:sla_task_tracker/providers/theme_mode_provider.dart';
import 'package:sla_task_tracker/services/seed_data.dart';
import 'package:sla_task_tracker/services/storage_service.dart';

void main() {
  late StorageService storage;
  late MemberProvider members;
  late TaskProvider tasks;
  late ThemeModeProvider themeMode;

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
          ChangeNotifierProvider.value(value: themeMode),
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
    themeMode = ThemeModeProvider();
    await Future.wait([
      activity.load(),
      members.load(),
      tasks.load(),
      themeMode.load(),
    ]);
  });

  testWidgets('shows username and password fields', (tester) async {
    await pumpApp(tester);

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('signing in with valid credentials succeeds', (tester) async {
    await pumpApp(tester);

    // Enter credentials for Boaz
    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      'boaz',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
      'boaz1234',
    );
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(members.currentUser?.id, SeedData.boazId);
    expect(await storage.getCurrentUserId(), SeedData.boazId);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('signing in with wrong password shows error', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      'boaz',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
      'wrong1',
    );
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
    expect(members.isSignedIn, isFalse);
  });

  testWidgets('signing in with unknown username shows error', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      'unknown',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
      'pass1234',
    );
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('User not found. Please check your username.'),
        findsOneWidget);
    expect(members.isSignedIn, isFalse);
  });

  testWidgets('shows demo credentials when toggled', (tester) async {
    await pumpApp(tester);

    expect(find.text('Show demo credentials'), findsOneWidget);
    await tester.tap(find.text('Show demo credentials'));
    await tester.pumpAndSettle();

    expect(find.text('Hide demo credentials'), findsOneWidget);
    // Demo credentials are shown as "Name: username / password"
    expect(find.textContaining('benjamin'), findsWidgets);
    expect(find.textContaining('boaz'), findsWidgets);
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
