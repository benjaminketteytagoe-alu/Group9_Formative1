import 'package:flutter/material.dart';

import '../screens/member_profile_screen.dart';
import '../screens/create_edit_task_screen.dart';
import '../screens/task_details_screen.dart';

/// Route names for screens opened on top of the bottom navigation.
///
/// Usage:
///   Navigator.pushNamed(context, AppRoutes.taskDetails, arguments: task.id);
///   Navigator.pushNamed(context, AppRoutes.taskForm);                  // new
///   Navigator.pushNamed(context, AppRoutes.taskForm, arguments: id);   // edit
class AppRoutes {
  static const taskDetails = '/task';
  static const taskForm = '/task/edit';
  static const memberProfile = '/member';
  static const memberForm = '/member/edit';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case memberProfile:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MemberProfileScreen(memberId: id),
        );
      // case taskDetails:
      //   final id = settings.arguments as String;
      //   return MaterialPageRoute(
      //     settings: settings,
      //     builder: (_) => TaskDetailsScreen(taskId: id),
      //   );
    }
    return null;
  }
}
