import 'package:flutter/material.dart';

/// Route names for screens opened on top of the bottom navigation.
///
/// Usage:
///   Navigator.pushNamed(context, AppRoutes.taskDetails, arguments: task.id);
///   Navigator.pushNamed(context, AppRoutes.taskForm);                  // new
///   Navigator.pushNamed(context, AppRoutes.taskForm, arguments: id);   // edit
///
/// When a screen is ready, add a `case` for it in [onGenerateRoute].
class AppRoutes {
  static const taskDetails = '/task';
  static const taskForm = '/task/edit';
  static const memberForm = '/member/edit';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
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
