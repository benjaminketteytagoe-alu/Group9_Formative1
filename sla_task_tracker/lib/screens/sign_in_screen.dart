import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_mode_provider.dart';

/// Sign-in screen with username and password fields.
/// Validates credentials against stored team members and navigates
/// to the home shell on success.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _signingIn = false;
  String? _errorMessage;
  bool _showDemoCredentials = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _signingIn = true;
      _errorMessage = null;
    });

    final provider = context.read<MemberProvider>();
    final error = await provider.signInWithCredentials(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _signingIn = false;
        _errorMessage = error;
      });
      return;
    }

    // Success — show welcome message
    final user = provider.currentUser!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome back, ${user.name}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().members;
    final tasks = context.watch<TaskProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            Expanded(
              child: members.isEmpty
                  ? const _EmptyTeam()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final open = tasks
                            .tasksForMember(m.id)
                            .where((t) => t.status.name != 'done')
                            .length;
                        return _MemberCard(
                          member: m,
                          openTasks: open,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                    ),
                  // Sign-in form
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          keyboardType: TextInputType.text,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your username.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (v.length < 4) {
                              return 'Password must be at least 4 characters.';
                            }
                            if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                              return 'Password must contain at least one letter.';
                            }
                            if (!RegExp(r'\d').hasMatch(v)) {
                              return 'Password must contain at least one number.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _signingIn ? null : _signIn,
                    icon: _signingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(
                        () => _showDemoCredentials = !_showDemoCredentials,
                      );
                    },
                    icon: Icon(
                      _showDemoCredentials
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    label: Text(
                      _showDemoCredentials
                          ? 'Hide demo credentials'
                          : 'Show demo credentials',
                    ),
                  ),
                  if (_showDemoCredentials)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Demo Accounts',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          for (final m in members)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${m.name}: ${m.username} / ${m.password}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Stack(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.task_alt,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SLA Task Tracker',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to manage your project tasks.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          // Theme toggle in the top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: _ThemeToggle(),
          ),
        ],
      ),
    );
  }
}

/// Small widget that cycles the theme: system → dark → light.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeModeProvider>().mode;
    IconData icon;
    String tooltip;
    switch (mode) {
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        tooltip = 'Switch to light mode';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        tooltip = 'Switch to system mode';
        break;
      case ThemeMode.system:
      default:
        icon = Icons.brightness_auto_outlined;
        tooltip = 'Switch to dark mode';
        break;
    }
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => context.read<ThemeModeProvider>().toggle(),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.openTasks,
  });

  final dynamic member;
  final int openTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(member.colorValue);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(member.initials),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${member.role} · $openTasks open task${openTasks == 1 ? '' : 's'}',
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
      ),
    );
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No team members yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Team members will appear here once they are added.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
