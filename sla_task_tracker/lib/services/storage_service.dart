import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
import '../models/task.dart';
import '../models/team_member.dart';

class StorageService {
  static const _tasksKey = 'tasks';
  static const _membersKey = 'members';
  static const _activityKey = 'activity';
  static const _currentUserKey = 'current_user_id';
  static const _seededKey = 'seeded';

  // ---------- Generic helpers ----------

  Future<List<T>> _loadList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  // ---------- Tasks ----------

  Future<List<Task>> loadTasks() => _loadList(_tasksKey, Task.fromJson);

  Future<void> saveTasks(List<Task> tasks) =>
      _saveList(_tasksKey, tasks.map((t) => t.toJson()).toList());

  // ---------- Team members ----------

  Future<List<TeamMember>> loadMembers() =>
      _loadList(_membersKey, TeamMember.fromJson);

  Future<void> saveMembers(List<TeamMember> members) =>
      _saveList(_membersKey, members.map((m) => m.toJson()).toList());

  // ---------- Activity log ----------

  Future<List<ActivityLog>> loadActivity() =>
      _loadList(_activityKey, ActivityLog.fromJson);

  Future<void> saveActivity(List<ActivityLog> logs) =>
      _saveList(_activityKey, logs.map((l) => l.toJson()).toList());

  // ---------- Signed-in user ----------

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> setCurrentUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // ---------- First-launch seeding flag ----------

  Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seededKey) ?? false;
  }

  Future<void> markSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, true);
  }
}