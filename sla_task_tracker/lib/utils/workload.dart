import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../services/sla_service.dart';

/// Task numbers for one member, used on the Team screens.
class MemberStats {
  MemberStats(List<Task> tasks, {DateTime? now})
      : total = tasks.length,
        open = tasks.where((t) => t.status != TaskStatus.done).length,
        sla = {
          for (final s in SlaStatus.values)
            s: tasks
                .where((t) => SlaService.statusFor(t, now: now) == s)
                .length,
        };

  final int total;
  final int open; // not done yet
  final Map<SlaStatus, int> sla;

  int get done => total - open;
  int get overdue => sla[SlaStatus.overdue] ?? 0;
  int get atRisk => sla[SlaStatus.atRisk] ?? 0;
  Workload get workload => Workload.fromOpenTasks(open);
}

/// How busy a member is, based on their open tasks:
/// Light = 0-2, Moderate = 3-4, Heavy = 5 or more.
enum Workload {
  light('Light', Color(0xFF2E7D32)),
  moderate('Moderate', Color(0xFFF57F17)),
  heavy('Heavy', Color(0xFFC62828));

  const Workload(this.label, this.color);

  final String label;
  final Color color;

  /// Open-task count at which the workload bar is full.
  static const fullAt = 6;

  static Workload fromOpenTasks(int open) {
    if (open >= 5) return Workload.heavy;
    if (open >= 3) return Workload.moderate;
    return Workload.light;
  }
}
