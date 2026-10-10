import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/member_provider.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

/// App shell. Shows the sign-in screen until a user is chosen,
/// then the bottom-navigation home.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<MemberProvider>().isSignedIn;

    return MaterialApp(
      title: 'SLA Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: signedIn ? const HomeShell() : const SignInScreen(),
    );
  }
}
