import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';
import 'dashboard_screen.dart';
import 'task_list_screen.dart';

/// Main screen after sign-in: bottom navigation with three tabs.
/// Each tab is a full screen with its own AppBar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's scroll position when switching.
      body: IndexedStack(
        index: _index,
        children: [
          const DashboardScreen(),
          const TaskListScreen(),
          // Replaced by the Team Members / Profile screen (Z2).
          Scaffold(
            appBar: AppBar(title: const Text('Team')),
            body: const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Team profiles coming soon',
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}
