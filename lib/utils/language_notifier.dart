import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier _instance = LanguageNotifier._internal();
  factory LanguageNotifier() => _instance;
  LanguageNotifier._internal();

  String _language = 'English';
  String get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // every start is in English; a language chosen in the app stays on every page until the app is closed
    await prefs.remove('language');
    _language = 'English';
    AppTranslations.setLanguage(_language);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = (lang == 'Tigrinya' || lang == 'Amharic') ? lang : 'English';
    AppTranslations.setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    notifyListeners();
  }

  String t(String key) => AppTranslations.get(key);
}

final languageNotifier = LanguageNotifier();
