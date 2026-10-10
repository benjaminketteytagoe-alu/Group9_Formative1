import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app theme mode (light / dark / system) and persists the
/// choice so it survives app restarts.
class ThemeModeProvider extends ChangeNotifier {
  ThemeModeProvider() : _mode = ThemeMode.system;

  static const _key = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;

  /// Load the saved preference.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      _mode = ThemeMode.values.byName(value);
    }
    notifyListeners();
  }

  /// Cycle: system → dark → light → system …
  void toggle() {
    switch (_mode) {
      case ThemeMode.system:
        _mode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _mode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _mode = ThemeMode.system;
        break;
    }
    _save();
    notifyListeners();
  }

  /// Set an explicit mode.
  void setMode(ThemeMode m) {
    if (_mode != m) {
      _mode = m;
      _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
  }
}
