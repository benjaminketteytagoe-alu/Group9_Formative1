import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../services/sla_service.dart';
import '../utils/sla_colors.dart';
import '../widgets/status_chip.dart';
import 'create_edit_task_screen.dart';

/// Full task view showing all fields, SLA status, and actions.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

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

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final memberProvider = context.watch<MemberProvider>();
    final task = taskProvider.byId(taskId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(
          child: Text('Task not found.'),
        ),
      );
    }

    final assignee = memberProvider.byId(task.assigneeId);
    final sla = taskProvider.slaOf(task);
    final slaMessage = SlaService.messageFor(task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateEditTaskScreen(task: task),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // SLA status
          Row(
            children: [
              StatusChip(status: sla),
              const SizedBox(width: 12),
              Icon(Icons.info_outline, size: 16, color: sla.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  slaMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: sla.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details sections
          _DetailSection(
            title: 'Task Information',
            children: [
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: task.category,
              ),
              _DetailRow(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: task.priority.label,
              ),
              _DetailRow(
                icon: Icons.assignment_outlined,
                label: 'Status',
                value: task.status.label,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due date',
                value: _formatDate(task.dueDate),
              ),
              _DetailRow(
                icon: Icons.access_time_outlined,
                label: 'Created',
                value: _formatDate(task.createdAt),
              ),
              if (task.completedAt != null)
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: _formatDate(task.completedAt!),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Assignee
          _DetailSection(
            title: 'Assignee',
            children: [
              if (assignee != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(assignee.colorValue),
                    foregroundColor: Colors.white,
                    child: Text(assignee.initials),
                  ),
                  title: Text(
                    assignee.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(assignee.role),
                )
              else
                const Text('Unassigned'),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          _DetailSection(
            title: 'Description',
            children: [
              Text(
                task.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          if (task.notes.isNotEmpty) ...[
            _DetailSection(
              title: 'Notes',
              children: [
                Text(
                  task.notes,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Status dropdown for quick update
          _DetailSection(
            title: 'Quick Actions',
            children: [
              DropdownButtonFormField<TaskStatus>(
                value: task.status,
                decoration: const InputDecoration(
                  labelText: 'Change status',
                ),
                items: TaskStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    taskProvider.setStatus(taskId, value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delete button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _deleteTask(context, taskProvider, task),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Task'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    TaskProvider provider,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text(
            'Are you sure you want to delete "${task.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await provider.deleteTask(task.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
