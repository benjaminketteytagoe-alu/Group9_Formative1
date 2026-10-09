import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/member_provider.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

/// App shell. Shows the sign-in screen until a user is chosen,
/// then the bottom-navigation home.
import 'screens/sign_in_screen.dart';

/// App shell. Shows the sign-in screen until a user is chosen.
/// Bottom navigation and routes are added in boaz/navigation-theme.
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
      ),
      home: signedIn ? const _SignedInPlaceholder() : const SignInScreen(),
    );
  }
}

/// Temporary home until the dashboard and navigation are merged.
class _SignedInPlaceholder extends StatelessWidget {
  const _SignedInPlaceholder();

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>();
    final user = members.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Task Tracker'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: members.signOut,
          ),
        ],
      ),
      body: Center(
        child: Text('Signed in as ${user.name} (${user.role})'),
      ),
    );
  }
}
