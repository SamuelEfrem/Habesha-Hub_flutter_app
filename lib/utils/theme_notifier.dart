import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lytter på ThemeMode og lagrer valget i SharedPreferences.
/// Bruk: themeNotifier.toggle() eller themeNotifier.isDark
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'theme_dark';
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true; // standard: dark
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}

final themeNotifier = ThemeNotifier();
