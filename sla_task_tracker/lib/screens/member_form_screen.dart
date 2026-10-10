import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team_member.dart';
import '../providers/member_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_avatar.dart';

/// Add a new team member, or edit an existing one when [memberId] is given.
class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key, this.memberId});

  final String? memberId;

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  /// Avatar colours the user can pick from.
  static const _palette = [
    0xFF1565C0, // blue
    0xFF7E57C2, // purple
    0xFF2E7D32, // green
    0xFFEF6C00, // orange
    0xFFC2185B, // pink
    0xFF00838F, // teal
    0xFF5D4037, // brown
    0xFF455A64, // blue grey
  ];

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _email = TextEditingController();

  TeamMember? _editing; // null when adding
  late int _colorValue;
  bool _saving = false;

  bool get _isEdit => widget.memberId != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MemberProvider>();
    _editing = provider.byId(widget.memberId);

    if (_editing != null) {
      _name.text = _editing!.name;
      _role.text = _editing!.role;
      _email.text = _editing!.email;
      _colorValue = _editing!.colorValue;
    } else {
      // Start a new member on a colour nobody else is using yet.
      final used = provider.members.map((m) => m.colorValue).toSet();
      _colorValue = _palette.firstWhere(
        (c) => !used.contains(c),
        orElse: () => _palette.first,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    super.dispose();
  }

  // ---------- Validation ----------

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateRole(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Role is required';
    return null;
  }

  /// Email is optional, but must look valid and not belong to someone else.
  String? _validateEmail(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    final taken = context.read<MemberProvider>().members.any(
          (m) => m.id != widget.memberId && m.email.toLowerCase() == v,
        );
    if (taken) return 'Another member already uses this email';
    return null;
  }

  // ---------- Save ----------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<MemberProvider>();
    final name = _name.text.trim();
    final role = _role.text.trim();
    final email = _email.text.trim();

    if (_editing != null) {
      await provider.updateMember(
        _editing!.copyWith(
          name: name,
          role: role,
          email: email,
          colorValue: _colorValue,
        ),
      );
    } else {
      await provider.addMember(
        TeamMember(
          id: provider.newId(),
          name: name,
          role: role,
          email: email,
          colorValue: _colorValue,
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? '$name updated' : '$name added')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Asked to edit a member that no longer exists.
    if (_isEdit && _editing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Member')),
        body: const EmptyState(
          icon: Icons.person_off,
          title: 'Member not found',
        ),
      );
    }

    // Live preview of the avatar while typing.
    final preview = TeamMember(
      id: '',
      name: _name.text,
      role: '',
      colorValue: _colorValue,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Member' : 'Add Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: MemberAvatar(member: preview, radius: 40)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _validateName,
              onChanged: (_) => setState(() {}), // refresh the preview
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Role *',
                hintText: 'e.g. Mobile Developer',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _validateRole,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 24),
            Text(
              'Avatar colour',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in _palette)
                  _ColorDot(
                    color: Color(c),
                    selected: c == _colorValue,
                    onTap: () => setState(() => _colorValue = c),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Save changes' : 'Add member'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
