import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';

/// Form screen for creating new tasks and editing existing ones.
class CreateEditTaskScreen extends StatefulWidget {
  const CreateEditTaskScreen({super.key, this.task});

  /// If non-null, we are editing this existing task.
  final Task? task;

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final _form = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _notesCtrl;

  TaskPriority? _priority;
  TaskStatus? _status;
  String? _assigneeId;
  DateTime? _dueDate;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descriptionCtrl = TextEditingController(text: task?.description ?? '');
    _categoryCtrl = TextEditingController(text: task?.category ?? '');
    _notesCtrl = TextEditingController(text: task?.notes ?? '');

    if (task != null) {
      _priority = task.priority;
      _status = task.status;
      _assigneeId = task.assigneeId;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final members = context.read<MemberProvider>().members;
    if (_assigneeId == null && members.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assignee.')),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }

    final provider = context.read<TaskProvider>();

    if (_isEdit) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        assigneeId: _assigneeId!,
        priority: _priority!,
        status: _status!,
        dueDate: _dueDate!,
        notes: _notesCtrl.text.trim(),
      );
      await provider.updateTask(updated);
    } else {
      final newTask = Task(
        id: provider.newId(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        assigneeId: _assigneeId!,
        priority: _priority!,
        status: _status!,
        dueDate: _dueDate!,
        createdAt: DateTime.now(),
        notes: _notesCtrl.text.trim(),
      );
      await provider.addTask(newTask);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Task updated' : 'Task created'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
              ),
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter a task title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
              ),
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter a description.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category *',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter a category.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Assignee *',
              ),
              items: members
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(m.colorValue),
                            foregroundColor: Colors.white,
                            child: Text(
                              m.initials,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(m.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _assigneeId = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority *',
              ),
              items: TaskPriority.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status *',
              ),
              items: TaskStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Due date *'),
              subtitle: Text(
                _dueDate == null
                    ? 'Select a date'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Update Task' : 'Create Task'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
