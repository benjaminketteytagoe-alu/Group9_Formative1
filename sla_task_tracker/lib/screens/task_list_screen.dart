import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';
import 'create_edit_task_screen.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

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
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _query = '';
  SlaStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _assigneeFilter;
  bool _soonestFirst = true;

  /// Applies search, filters and sort to the full task list.
  List<Task> _apply(TaskProvider provider) {
    final q = _query.trim().toLowerCase();
    final list = provider.tasks.where((t) {
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      if (_statusFilter != null && provider.slaOf(t) != _statusFilter) {
        return false;
      }
      if (_priorityFilter != null && t.priority != _priorityFilter) {
        return false;
      }
      if (_assigneeFilter != null && t.assigneeId != _assigneeFilter) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => _soonestFirst
        ? a.dueDate.compareTo(b.dueDate)
        : b.dueDate.compareTo(a.dueDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final memberProvider = context.watch<MemberProvider>();
    final results = _apply(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_auto_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeModeProvider>().toggle(),
          ),
          IconButton(
            tooltip: _soonestFirst
                ? 'Soonest deadline first'
                : 'Latest deadline first',
            icon: Icon(
              _soonestFirst ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () => setState(() => _soonestFirst = !_soonestFirst),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => TaskListScreen._signOut(context),
          ),
        ],
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _statusFilter == null,
                        onSelected: (_) =>
                            setState(() => _statusFilter = null),
                      ),
                      for (final s in SlaStatus.values) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(s.label),
                          selected: _statusFilter == s,
                          onSelected: (_) =>
                              setState(() => _statusFilter = s),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<TaskPriority?>(
                          isExpanded: true,
                          value: _priorityFilter,
                          items: [
                            const DropdownMenuItem<TaskPriority?>(
                              value: null,
                              child: Text('All priorities'),
                            ),
                            for (final p in TaskPriority.values)
                              DropdownMenuItem<TaskPriority?>(
                                value: p,
                                child: Text(p.label),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _priorityFilter = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _assigneeFilter,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All assignees'),
                            ),
                            for (final m in memberProvider.members)
                              DropdownMenuItem<String?>(
                                value: m.id,
                                child: Text(m.name),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _assigneeFilter = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${results.length} of ${taskProvider.tasks.length} tasks',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: taskProvider.tasks.isEmpty
                      ? EmptyState(
                          icon: Icons.checklist_outlined,
                          title: 'No tasks yet',
                          message: 'Create your first task to get started.',
                          actionLabel: 'Create task',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateEditTaskScreen(),
                              ),
                            );
                          },
                        )
                      : results.isEmpty
                          ? const Center(
                              child: Text('No tasks match your filters'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final task = results[index];
                                return TaskCard(
                                  task: task,
                                  status: taskProvider.slaOf(task),
                                  assignee: memberProvider.byId(task.assigneeId),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailsScreen(
                                          taskId: task.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEditTaskScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}