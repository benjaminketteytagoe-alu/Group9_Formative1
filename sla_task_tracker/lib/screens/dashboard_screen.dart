import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../utils/sla_colors.dart';
import '../widgets/summary_tile.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                dialogContext.read<MemberProvider>().signOut();
                Navigator.pop(dialogContext);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

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
    final taskProvider = context.watch<TaskProvider>();
    final user = context.watch<MemberProvider>().currentUser;
    final counts = taskProvider.slaCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_auto_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeModeProvider>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  user == null ? 'Welcome' : 'Hello, ${user.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text("Here's what's happening with your project."),
                const SizedBox(height: 16),
                                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall progress: ${(taskProvider.progress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: taskProvider.progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
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
                        count: counts[s] ?? 0,
                        color: s.color,
                        icon: _iconFor(s),
                      ),
                  ],
                ),
                                const SizedBox(height: 24),
                const Text(
                  'Needs attention',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final task in taskProvider.needsAttention())
                  TaskCard(
                    task: task,
                    status: taskProvider.slaOf(task),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    assignee: context
                        .watch<MemberProvider>()
                        .byId(task.assigneeId),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TaskDetailsScreen(taskId: task.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}