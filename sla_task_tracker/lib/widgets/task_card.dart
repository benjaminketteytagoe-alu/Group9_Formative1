import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import 'status_chip.dart';

/// One row in the task list: avatar, title, category, due date, SLA chip.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.status,
    this.assignee,
    this.onTap,
  });

  final Task task;
  final SlaStatus status;
  final TeamMember? assignee;
  final VoidCallback? onTap;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _dueText =>
      '${task.dueDate.day} ${_months[task.dueDate.month - 1]} ${task.dueDate.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(assignee?.colorValue ?? 0xFF9E9E9E),
                child: Text(
                  assignee?.initials ?? '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.category,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text('Due $_dueText', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(status: status),
            ],
          ),
        ),
      ),
    );
  }
}