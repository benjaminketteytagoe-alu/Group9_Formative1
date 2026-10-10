import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team_member.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../utils/app_routes.dart';
import '../utils/workload.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';
import '../widgets/member_avatar.dart';

/// Team Members / Profile: the signed-in user's card, then every member
/// with their task counts and workload. Tap a member to see their profile.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final members = context.read<MemberProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can pick a profile again on the next screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await members.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final members = memberProvider.members;
    final me = memberProvider.currentUser;

    MemberStats statsOf(TeamMember m) =>
        MemberStats(taskProvider.tasksForMember(m.id));

    void openProfile(TeamMember m) => Navigator.pushNamed(
          context,
          AppRoutes.memberProfile,
          arguments: m.id,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      body: taskProvider.isLoading
          ? const LoadingView()
          : members.isEmpty
              ? const EmptyState(
                  icon: Icons.group_off,
                  title: 'No team members yet',
                  message: 'Members you add will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (me != null) ...[
                      _MyProfileCard(
                        member: me,
                        stats: statsOf(me),
                        onOpen: () => openProfile(me),
                        onSignOut: () => _confirmSignOut(context),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Team members (${members.length})',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final m in members)
                      _MemberWorkloadCard(
                        member: m,
                        stats: statsOf(m),
                        isMe: m.id == me?.id,
                        onTap: () => openProfile(m),
                      ),
                  ],
                ),
    );
  }
}

/// "You" card at the top, with a sign-out button.
class _MyProfileCard extends StatelessWidget {
  const _MyProfileCard({
    required this.member,
    required this.stats,
    required this.onOpen,
    required this.onSignOut,
  });

  final TeamMember member;
  final MemberStats stats;
  final VoidCallback onOpen;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(member: member, radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          member.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          member.role,
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: 'Open', value: stats.open),
                  _Stat(label: 'Done', value: stats.done),
                  _Stat(label: 'Overdue', value: stats.overdue),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

/// One member: avatar, role, task counts and a workload bar.
class _MemberWorkloadCard extends StatelessWidget {
  const _MemberWorkloadCard({
    required this.member,
    required this.stats,
    required this.isMe,
    required this.onTap,
  });

  final TeamMember member;
  final MemberStats stats;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workload = stats.workload;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(member: member),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe ? '${member.name} (you)' : member.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          member.role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _WorkloadChip(workload: workload),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (stats.open / Workload.fullAt).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: workload.color,
                  backgroundColor: workload.color.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.total} tasks · ${stats.open} open · '
                '${stats.done} done'
                '${stats.overdue > 0 ? ' · ${stats.overdue} overdue' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkloadChip extends StatelessWidget {
  const _WorkloadChip({required this.workload});

  final Workload workload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: workload.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        workload.label,
        style: TextStyle(
          color: workload.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
