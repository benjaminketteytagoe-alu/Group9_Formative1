import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/activity_provider.dart';
import 'providers/member_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'services/seed_data.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await SeedData.seedIfFirstLaunch(storage);

  final activity = ActivityProvider(storage);
  final members = MemberProvider(storage);
  final tasks = TaskProvider(
    storage,
    activity,
    currentUserId: () => members.currentUser?.id,
  );
  final themeMode = ThemeModeProvider();

  // Load everything before the first frame, so screens never flash empty.
  await Future.wait([
    activity.load(),
    members.load(),
    tasks.load(),
    themeMode.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: activity),
        ChangeNotifierProvider.value(value: members),
        ChangeNotifierProvider.value(value: tasks),
        ChangeNotifierProvider.value(value: themeMode),
      ],
      child: const MyApp(),
    ),
  );
}