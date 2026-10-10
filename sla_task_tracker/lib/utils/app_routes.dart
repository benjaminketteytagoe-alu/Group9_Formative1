import 'package:flutter/material.dart';

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

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case taskDetails:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TaskDetailsScreen(taskId: id),
        );
      case taskForm:
        final arg = settings.arguments;
        if (arg is String) {
          // Edit mode — id passed; screen will look it up.
          // For now use direct navigation with the task object.
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const CreateEditTaskScreen(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateEditTaskScreen(),
        );
    }
    return null;
  }
}
