import 'enums.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String assigneeId;
  final String notes;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.assigneeId,
    this.notes = '',
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? assigneeId,
    String? notes,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false, // set true to reset completedAt to null
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      assigneeId: assigneeId ?? this.assigneeId,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'assigneeId': assigneeId,
    'notes': notes,
    'priority': priority.name,
    'status': status.name,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    category: j['category'] as String? ?? '',
    assigneeId: j['assigneeId'] as String,
    notes: j['notes'] as String? ?? '',
    priority: TaskPriority.values.byName(j['priority'] as String),
    status: TaskStatus.values.byName(j['status'] as String),
    dueDate: DateTime.parse(j['dueDate'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.parse(j['completedAt'] as String),
  );
}