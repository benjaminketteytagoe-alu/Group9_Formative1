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