import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import '../services/storage_service.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._storage);

  final StorageService _storage;
  static const _uuid = Uuid();
  static const _maxEntries = 50; // keep storage small

  List<ActivityLog> _logs = []; // newest first

  List<ActivityLog> get all => List.unmodifiable(_logs);

  /// Latest 10 entries for the dashboard "Recent Activity" card.
  List<ActivityLog> get recent => _logs.take(10).toList();

  Future<void> load() async {
    _logs = await _storage.loadActivity();
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> log(String message, String memberId) async {
    _logs.insert(
      0,
      ActivityLog(
        id: _uuid.v4(),
        message: message,
        memberId: memberId,
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > _maxEntries) {
      _logs.removeRange(_maxEntries, _logs.length);
    }
    notifyListeners();
    await _storage.saveActivity(_logs);
  }
}