import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/team_member.dart';
import '../providers/member_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/empty_state.dart';

/// Team Members / Profile screen: list members, add, edit, delete.
class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  static const _presetColors = [
    0xFF1565C0, // blue
    0xFF7E57C2, // purple
    0xFF2E7D32, // green
    0xFFEF6C00, // orange
    0xFFC62828, // red
    0xFF00838F, // teal
    0xFF4E342E, // brown
  ];

  static void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                dialogContext.read<MemberProvider>().signOut();
                Navigator.pop(dialogContext);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<MemberProvider>().members;
    final currentUserId = context.watch<MemberProvider>().currentUser?.id;
    final tasks = context.watch<TaskProvider>().tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_auto_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeModeProvider>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: members.isEmpty
          ? const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No team members',
              message: 'Add team members to get started.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final m = members[index];
                final openTasks = tasks
                    .where(
                      (t) =>
                          t.assigneeId == m.id && t.status.name != 'done',
                    )
                    .length;
                final isCurrentUser = m.id == currentUserId;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(m.colorValue),
                      foregroundColor: Colors.white,
                      child: Text(m.initials),
                    ),
                    title: Row(
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${m.role} · $openTasks open task${openTasks == 1 ? '' : 's'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showMemberDialog(context, member: m);
                        } else if (value == 'delete') {
                          _deleteMember(context, m);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMemberDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Future<void> _showMemberDialog(
    BuildContext context, {
    TeamMember? member,
  }) async {
    final isEdit = member != null;
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final roleCtrl = TextEditingController(text: member?.role ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final usernameCtrl = TextEditingController(text: member?.username ?? '');
    final passwordCtrl = TextEditingController(text: member?.password ?? '');
    var colorValue = member?.colorValue ?? _presetColors.first;
    bool obscurePassword = true;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Member' : 'Add Member'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: roleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a role.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null &&
                              v.trim().isNotEmpty &&
                              !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$')
                                  .hasMatch(v.trim())) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username *',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a username for sign-in.';
                          }
                          if (v.trim().length < 3) {
                            return 'At least 3 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () => obscurePassword = !obscurePassword,
                              );
                            },
                          ),
                        ),
                        obscureText: obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter a password for sign-in.';
                          }
                          if (v.length < 4) {
                            return 'At least 4 characters.';
                          }
                          if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                            return 'Must contain at least one letter.';
                          }
                          if (!RegExp(r'\d').hasMatch(v)) {
                            return 'Must contain at least one number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Avatar color',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final c in _presetColors)
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: StatelessColorPicker(
                                color: c,
                                selected: c == colorValue,
                                onTap: () {
                                  setState(() => colorValue = c);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final provider = dialogContext.read<MemberProvider>();

                    if (isEdit) {
                      provider.updateMember(
                        member.copyWith(
                          name: nameCtrl.text.trim(),
                          role: roleCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          colorValue: colorValue,
                          username: usernameCtrl.text.trim(),
                          password: passwordCtrl.text.isNotEmpty
                              ? passwordCtrl.text
                              : member.password,
                        ),
                      );
                    } else {
                      provider.addMember(
                        TeamMember(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          role: roleCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          colorValue: colorValue,
                          username: usernameCtrl.text.trim(),
                          password: passwordCtrl.text,
                        ),
                      );
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: Text(isEdit ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    roleCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
  }

  Future<void> _deleteMember(BuildContext context, TeamMember member) async {
    final currentUserId =
        context.read<MemberProvider>().currentUser?.id;
    if (member.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the currently signed-in user.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete member'),
          content: Text(
            'Are you sure you want to remove "${member.name}" from the team?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<MemberProvider>().deleteMember(member.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed')),
      );
    }
  }
}

/// Simple color circle for the avatar color picker.
class StatelessColorPicker extends StatelessWidget {
  const StatelessColorPicker({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(
                  color: Colors.black.withValues(alpha: 0.12), width: 1),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
