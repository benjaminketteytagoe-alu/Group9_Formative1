import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// If null, the screen creates a new task.
  /// If provided, the screen edits the existing task.
  final Task? task;

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;

  String? _assigneeId;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _isSaving = false;

  final _dateFormat = DateFormat('EEE, d MMM yyyy');

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _categoryController =
        TextEditingController(text: task?.category ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');

    _assigneeId = task?.assigneeId;
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate = _dueDate != null && !_dueDate!.isBefore(firstDate)
        ? _dueDate!
        : firstDate.add(const Duration(days: 1));

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT DEADLINE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _dueDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
      );
    });
  }

  Future<void> _showAssigneePicker() async {
    final members = context.read<MemberProvider>().members;

    if (members.isEmpty) {
      _showMessage('No team members are available yet.');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign task',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a team member responsible for this task.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...members.map(
                      (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        member.name.isEmpty
                            ? '?'
                            : member.name
                            .trim()
                            .substring(0, 1)
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: member.id == _assigneeId
                        ? Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                        : null,
                    onTap: () => Navigator.pop(context, member.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _assigneeId = selected;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_assigneeId == null) {
      _showMessage('Please assign this task to a team member.');
      return;
    }

    if (_dueDate == null) {
      _showMessage('Please choose a deadline.');
      return;
    }

    final now = DateTime.now();

    if (_dueDate!.isBefore(now)) {
      _showMessage('The deadline cannot be in the past.');
      return;
    }

    final tasks = context.read<TaskProvider>();
    final existing = widget.task;

    setState(() {
      _isSaving = true;
    });

    try {
      final task = Task(
        id: existing?.id ?? tasks.newId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        assigneeId: _assigneeId!,
        notes: _notesController.text.trim(),
        priority: _priority,
        status: existing?.status ?? TaskStatus.todo,
        dueDate: _dueDate!,
        createdAt: existing?.createdAt ?? now,
        completedAt: existing?.completedAt,
      );

      if (existing == null) {
        await tasks.addTask(task);
      } else {
        await tasks.updateTask(task);
      }

      if (!mounted) return;

      Navigator.of(context).pop(task);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Something went wrong while saving the task. Please try again.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = context.watch<MemberProvider>().members;
    final selectedMember = _assigneeId == null
        ? null
        : context.read<MemberProvider>().byId(_assigneeId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  widget.isEditing
                      ? 'Update the details below.'
                      : 'Create a task for your team.',
                  key: ValueKey(widget.isEditing),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: _inputDecoration(
                  label: 'Task title',
                  hint: 'e.g. Implement login flow',
                  icon: Icons.task_alt_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Task title must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                maxLength: 500,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint: 'Describe what needs to be done...',
                  icon: Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                decoration: _inputDecoration(
                  label: 'Category',
                  hint: 'e.g. Frontend, Backend, Testing',
                  icon: Icons.category_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Assignee',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showAssigneePicker,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    label: 'Assigned to',
                    icon: Icons.person_outline_rounded,
                  ),
                  child: selectedMember == null
                      ? Text(
                    'Choose a team member',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                      : Text(
                    selectedMember.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (_assigneeId == null && members.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    'Assignee is required',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                'Priority',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values
                    .map(
                      (priority) => ButtonSegment<TaskPriority>(
                    value: priority,
                    label: Text(priority.label),
                  ),
                )
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (selection) {
                  setState(() {
                    _priority = selection.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Deadline',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dueDate == null
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    Icons.calendar_month_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    _dueDate == null
                        ? 'Choose a deadline'
                        : _dateFormat.format(_dueDate!),
                    style: TextStyle(
                      fontWeight:
                      _dueDate == null ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  subtitle: _dueDate == null
                      ? const Text('The deadline cannot be in the past.')
                      : const Text('Tap to change the deadline'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDeadline,
                ),
              ),

              if (_dueDate == null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    'Deadline is required',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration(
                  label: 'Notes',
                  hint: 'Optional notes for the team...',
                  icon: Icons.sticky_note_2_outlined,
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(
                  widget.isEditing
                      ? Icons.save_rounded
                      : Icons.add_task_rounded,
                ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : widget.isEditing
                      ? 'Save Changes'
                      : 'Create Task',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}