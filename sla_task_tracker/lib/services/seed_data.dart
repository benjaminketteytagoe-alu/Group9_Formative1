import '../models/activity_log.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import 'storage_service.dart';

class SeedData {
  // Fixed member ids so tasks can reference them.
  static const benjaminId = 'm_benjamin';
  static const michaelId = 'm_michael';
  static const kellenId = 'm_kellen';
  static const boazId = 'm_boaz';

  // ---------- Team members ----------

  static List<TeamMember> members() => const [
    TeamMember(
      id: benjaminId,
      name: 'Benjamin',
      role: 'Project Lead',
      email: 'benjamin@example.com',
      colorValue: 0xFF1565C0, // blue
    ),
    TeamMember(
      id: michaelId,
      name: 'Michael',
      role: 'Mobile Developer',
      email: 'michael@example.com',
      colorValue: 0xFF7E57C2, // purple
    ),
    TeamMember(
      id: kellenId,
      name: 'Kellen',
      role: 'UI/UX Designer',
      email: 'kellen@example.com',
      colorValue: 0xFF2E7D32, // green
    ),
    TeamMember(
      id: boazId,
      name: 'Boaz',
      role: 'QA Tester',
      email: 'boaz@example.com',
      colorValue: 0xFFEF6C00, // orange
    ),
  ];

  // ---------- Tasks ----------
  // Dates are relative to [now], so every SLA status always appears:
  //   6 Completed, 4 Overdue, 5 At Risk, 7 On Track  (22 tasks)

  static List<Task> tasks({DateTime? now}) {
    final n = now ?? DateTime.now();

    // offset in days from today (negative = past). Using the DateTime
    // constructor (not Duration) avoids daylight-saving surprises.
    DateTime day(int offset) => DateTime(n.year, n.month, n.day + offset);

    Task t(
        String id,
        String title,
        String description,
        String category,
        String assigneeId,
        TaskPriority priority,
        TaskStatus status,
        int dueOffset, {
          int createdDaysAgo = 14,
          int? completedDaysAgo,
          String notes = '',
        }) {
      return Task(
        id: id,
        title: title,
        description: description,
        category: category,
        assigneeId: assigneeId,
        priority: priority,
        status: status,
        dueDate: day(dueOffset),
        createdAt: day(-createdDaysAgo),
        completedAt: completedDaysAgo == null ? null : day(-completedDaysAgo),
        notes: notes,
      );
    }

    return [
      // COMPLETED (6)
      t('t01', 'Set up GitHub repository',
          'Create the repo, add team members and protect the main branch.',
          'DevOps', benjaminId, TaskPriority.high, TaskStatus.done, -12,
          completedDaysAgo: 13,
          notes: 'Branch protection enabled: PR + 1 approval required.'),
      t('t02', 'Define data models',
          'Task, TeamMember and ActivityLog with JSON serialization.',
          'Backend (Local)', benjaminId, TaskPriority.high, TaskStatus.done, -9,
          completedDaysAgo: 10),
      t('t03', 'Design app wireframes',
          'Low-fidelity wireframes for all six core screens.',
          'UI/UX Design', kellenId, TaskPriority.medium, TaskStatus.done, -8,
          completedDaysAgo: 9),
      t('t04', 'Implement SLA engine',
          'Rules for On Track, At Risk, Overdue and Completed.',
          'Backend (Local)', benjaminId, TaskPriority.high, TaskStatus.done, -5,
          completedDaysAgo: 6,
          notes: 'At Risk = within 48h (72h for high priority).'),
      t('t05', 'Build sign-in screen',
          'User selection screen with a mock sign-in flow.',
          'Mobile Development', boazId, TaskPriority.medium, TaskStatus.done, -3,
          completedDaysAgo: 4),
      t('t06', 'Write storage service tests',
          'Unit tests covering save, load and corrupted data.',
          'Quality Assurance', benjaminId, TaskPriority.low, TaskStatus.done, -2,
          completedDaysAgo: 3),

      // OVERDUE (4)
      t('t07', 'Create task form validation',
          'Validate title, assignee and deadline before saving.',
          'Mobile Development', michaelId, TaskPriority.high,
          TaskStatus.inProgress, -2,
          notes: 'Blocked on the date picker design.'),
      t('t08', 'Build task list filtering',
          'Filter by status, priority and assignee.',
          'Mobile Development', kellenId, TaskPriority.medium,
          TaskStatus.inProgress, -1),
      t('t09', 'Team member profile page',
          'Show member details and their assigned tasks.',
          'Mobile Development', boazId, TaskPriority.low, TaskStatus.todo, -4),
      t('t10', 'Write README setup guide',
          'Setup, run instructions and folder structure.',
          'Documentation', benjaminId, TaskPriority.low, TaskStatus.todo, -6),

      // AT RISK (5)
      t('t11', 'Implement Task Details screen',
          'Full task info, SLA badge and status dropdown.',
          'Mobile Development', michaelId, TaskPriority.high,
          TaskStatus.inProgress, 2),
      t('t12', 'Dashboard progress chart',
          'Donut chart showing tasks per SLA status.',
          'UI/UX Design', kellenId, TaskPriority.medium,
          TaskStatus.inProgress, 1),
      t('t13', 'Add team member form',
          'Form to add and edit team members.',
          'Mobile Development', boazId, TaskPriority.medium, TaskStatus.todo, 1),
      t('t14', 'Task statistics screen',
          'Bar chart of task status and upcoming deadlines.',
          'UI/UX Design', kellenId, TaskPriority.high, TaskStatus.todo, 2),
      t('t15', 'Prepare demo script',
          'Outline who presents what in the demo video.',
          'Documentation', benjaminId, TaskPriority.medium,
          TaskStatus.inProgress, 0),

      // ON TRACK (7)
      t('t16', 'Date picker for deadlines',
          'Reusable date field with validation for past dates.',
          'Mobile Development', michaelId, TaskPriority.medium,
          TaskStatus.inProgress, 4),
      t('t17', 'Search tasks by title',
          'Search bar on the task list screen.',
          'Mobile Development', kellenId, TaskPriority.low, TaskStatus.todo, 6),
      t('t18', 'Delete task confirmation',
          'Confirmation dialog before deleting a task.',
          'Mobile Development', michaelId, TaskPriority.low, TaskStatus.todo, 5),
      t('t19', 'App theme and navigation',
          'Bottom navigation, routes and consistent theme.',
          'Mobile Development', boazId, TaskPriority.high,
          TaskStatus.inProgress, 7),
      t('t20', 'Record demo video',
          'Record the 10-15 minute demonstration with every member.',
          'Documentation', kellenId, TaskPriority.high, TaskStatus.todo, 12),
      t('t21', 'Write technical report',
          'Challenges faced, solutions and citations (2-4 pages).',
          'Documentation', benjaminId, TaskPriority.medium, TaskStatus.todo, 10),
      t('t22', 'Final testing on emulator',
          'Run the full workflow on an emulator and a physical device.',
          'Quality Assurance', boazId, TaskPriority.high, TaskStatus.todo, 14),
    ];
  }

  // ---------- Recent activity ----------

  static List<ActivityLog> activity({DateTime? now}) {
    final n = now ?? DateTime.now();
    ActivityLog a(String id, String memberId, String message, int hoursAgo) =>
        ActivityLog(
          id: id,
          memberId: memberId,
          message: message,
          timestamp: n.subtract(Duration(hours: hoursAgo)),
        );

    return [
      a('a01', michaelId, 'updated Implement Task Details screen', 2),
      a('a02', kellenId, 'updated Dashboard progress chart', 5),
      a('a03', boazId, 'created Add team member form', 9),
      a('a04', benjaminId, 'updated Prepare demo script', 14),
      a('a05', kellenId, 'created Task statistics screen', 22),
      a('a06', benjaminId, 'completed Write storage service tests', 72),
      a('a07', boazId, 'completed Build sign-in screen', 96),
      a('a08', benjaminId, 'completed Implement SLA engine', 144),
    ];
  }

  // ---------- Loading ----------

  /// Seeds demo data on the very first launch only. A flag is stored, so
  /// deleting every task later does not bring the demo data back.
  static Future<void> seedIfFirstLaunch(StorageService storage) async {
    if (await storage.isSeeded()) return;
    await reset(storage);
  }

  /// Handy right before recording the demo.
  static Future<void> reset(StorageService storage) async {
    await storage.saveMembers(members());
    await storage.saveTasks(tasks());
    await storage.saveActivity(activity());
    await storage.markSeeded();
  }
}