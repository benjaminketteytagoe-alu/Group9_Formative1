import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/team_member.dart';
import '../services/storage_service.dart';

class MemberProvider extends ChangeNotifier {
  MemberProvider(this._storage);

  final StorageService _storage;
  static const _uuid = Uuid();

  List<TeamMember> _members = [];
  String? _currentUserId;

  List<TeamMember> get members => List.unmodifiable(_members);

  /// The signed-in user (null if nobody is signed in).
  TeamMember? get currentUser => byId(_currentUserId);
  bool get isSignedIn => currentUser != null;

  String newId() => _uuid.v4();

  Future<void> load() async {
    _members = await _storage.loadMembers();
    _currentUserId = await _storage.getCurrentUserId();
    notifyListeners();
  }

  TeamMember? byId(String? id) {
    if (id == null) return null;
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  // ----- Sign in / out (mock authentication) -----

  /// Validate a username/password pair and sign in the matching member.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signInWithCredentials(
    String username,
    String password,
  ) async {
    // Basic format validation
    if (username.trim().isEmpty) return 'Enter your username.';
    if (password.isEmpty) return 'Enter your password.';

    // Find member by username (case-insensitive)
    final member = _members.firstWhere(
      (m) => m.username.toLowerCase() == username.trim().toLowerCase(),
      orElse: () => const TeamMember(
        id: '',
        name: '',
        role: '',
        colorValue: 0,
        username: '',
        password: '',
      ),
    );

    if (member.id.isEmpty) {
      return 'User not found. Please check your username.';
    }
    if (member.password != password) {
      return 'Incorrect password. Please try again.';
    }

    await signIn(member.id);
    return null; // No error — credentials are valid
  }

  /// Internal sign-in by member id (used after adding a member, etc.).
  Future<void> signIn(String memberId) async {
    if (byId(memberId) == null) return;
    _currentUserId = memberId;
    notifyListeners();
    await _storage.setCurrentUserId(memberId);
  }

  Future<void> signOut() async {
    _currentUserId = null;
    notifyListeners();
    await _storage.clearCurrentUser();
  }

  // ----- CRUD -----

  Future<void> addMember(TeamMember m) async {
    _members = [..._members, m];
    notifyListeners();
    await _storage.saveMembers(_members);
  }

  Future<void> updateMember(TeamMember m) async {
    final i = _members.indexWhere((x) => x.id == m.id);
    if (i == -1) return;
    _members = [..._members]..[i] = m;
    notifyListeners();
    await _storage.saveMembers(_members);
  }

  Future<void> deleteMember(String id) async {
    _members = _members.where((m) => m.id != id).toList();
    if (_currentUserId == id) {
      _currentUserId = null;
      await _storage.clearCurrentUser();
    }
    notifyListeners();
    await _storage.saveMembers(_members);
  }
}