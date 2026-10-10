import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../services/sla_service.dart';
import '../widgets/status_chip.dart';
import '../widgets/task_status_selector.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final task = taskProvider.byId(taskId);

        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(
              child: Text('Task not found.'),
            ),
          );
        }

        final memberProvider = context.read<MemberProvider>();
        final assignee = memberProvider.byId(task.assigneeId);
        final slaStatus = taskProvider.slaOf(task);
        final slaMessage = SlaService.messageFor(task);
        final deadline = SlaService.deadlineOf(task);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              IconButton(
                tooltip: 'Edit task',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(task: task),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            StatusChip(status: slaStatus),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                slaMessage,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    icon: Icons.flag_outlined,
                    title: 'Status',
                  ),
                  const SizedBox(height: 10),

                  TaskStatusSelector(
                    value: task.status,
                    onChanged: (status) {
                      taskProvider.setStatus(task.id, status);
                    },
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    icon: Icons.info_outline_rounded,
                    title: 'Task Information',
                  ),
                  const SizedBox(height: 12),

                  if (task.description.trim().isNotEmpty)
                    _InfoCard(
                      icon: Icons.description_outlined,
                      title: 'Description',
                      value: task.description,
                    ),

                  _InfoCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Assignee',
                    value: assignee?.name ?? 'Unassigned',
                  ),

                  _InfoCard(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    value: task.category,
                  ),

                  _InfoCard(
                    icon: Icons.priority_high_rounded,
                    title: 'Priority',
                    value: task.priority.label,
                  ),

                  _InfoCard(
                    icon: Icons.event_outlined,
                    title: 'Deadline',
                    value: _formatDeadline(deadline),
                    trailing: Text(
                      _timeRemaining(deadline),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  if (task.notes.trim().isNotEmpty)
                    _InfoCard(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'Notes',
                      value: task.notes,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  String _formatDeadline(DateTime deadline) {
    final local = deadline.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _timeRemaining(DateTime deadline) {
    final difference = deadline.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Overdue';
    }

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);

    if (days > 0) {
      return '${days}d ${hours}h left';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    }

    return '${difference.inMinutes}m left';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}