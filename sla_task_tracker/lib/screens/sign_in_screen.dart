import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/team_member.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';

/// Mock sign-in: the user picks their profile from the team list.
/// The choice is saved by [MemberProvider.signIn], so the app remembers
/// who is signed in after it is closed and reopened.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _selectedId;
  bool _signingIn = false;

  Future<void> _continue(TeamMember member) async {
    setState(() => _signingIn = true);
    await context.read<MemberProvider>().signIn(member.id);
    if (!mounted) return;
    setState(() => _signingIn = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome back, ${member.name}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().members;
    final tasks = context.watch<TaskProvider>();
    final selected = context.read<MemberProvider>().byId(_selectedId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
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
                            .where((t) => t.status != TaskStatus.done)
                            .length;
                        return _MemberCard(
                          member: m,
                          openTasks: open,
                          selected: m.id == _selectedId,
                          onTap: () => setState(() => _selectedId = m.id),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: selected == null || _signingIn
                    ? null
                    : () => _continue(selected),
                icon: _signingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  selected == null
                      ? 'Select your profile'
                      : 'Continue as ${selected.name}',
                ),
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
      child: Column(
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
            "Who's working today? Pick your profile to sign in.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.openTasks,
    required this.selected,
    required this.onTap,
  });

  final TeamMember member;
  final int openTasks;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(member.colorValue);

    return Card(
      margin: EdgeInsets.zero,
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? color : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
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
        trailing: selected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right),
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
