import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../utils/app_routes.dart';
import '../utils/sla_colors.dart';
import '../utils/workload.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_avatar.dart';
import '../widgets/summary_tile.dart';
import '../widgets/task_card.dart';

/// One member's profile: details, SLA breakdown and their tasks.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  IconData _iconFor(SlaStatus s) {
    switch (s) {
      case SlaStatus.onTrack:
        return Icons.check_circle_outline;
      case SlaStatus.atRisk:
        return Icons.warning_amber_rounded;
      case SlaStatus.overdue:
        return Icons.error_outline;
      case SlaStatus.completed:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = context.watch<MemberProvider>().byId(memberId);
    final taskProvider = context.watch<TaskProvider>();

    // The member may have been deleted while this screen was open.
    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off,
          title: 'Member not found',
        ),
      );
    }

    // Open tasks first, each group ordered by due date.
    final tasks = taskProvider.tasksForMember(member.id)
      ..sort((a, b) {
        final aDone = a.status == TaskStatus.done ? 1 : 0;
        final bDone = b.status == TaskStatus.done ? 1 : 0;
        if (aDone != bDone) return aDone.compareTo(bDone);
        return a.dueDate.compareTo(b.dueDate);
      });
    final stats = MemberStats(tasks);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        actions: [
          IconButton(
            tooltip: 'Edit member',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.memberForm,
              arguments: member.id,
            ),
          ),
        ],
      ),
      appBar: AppBar(title: Text(member.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Column(
            children: [
              MemberAvatar(member: member, radius: 40),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(member.role),
              if (member.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Chip(
                avatar: Icon(Icons.work_outline,
                    size: 18, color: stats.workload.color),
                label: Text(
                  '${stats.workload.label} workload · ${stats.open} open',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                for (final s in SlaStatus.values)
                  SummaryTile(
                    label: s.label,
                    count: stats.sla[s] ?? 0,
                    color: s.color,
                    icon: _iconFor(s),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              'Assigned tasks (${tasks.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No tasks assigned',
              ),
            )
          else
            for (final t in tasks)
              TaskCard(
                task: t,
                status: taskProvider.slaOf(t),
                assignee: member,
              ),
        ],
      ),
    );
  }
}
