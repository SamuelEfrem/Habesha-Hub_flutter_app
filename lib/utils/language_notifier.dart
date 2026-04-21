import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier _instance = LanguageNotifier._internal();
  factory LanguageNotifier() => _instance;
  LanguageNotifier._internal();

  String _language = 'Norsk';
  String get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'Norsk';
    AppTranslations.setLanguage(_language);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    AppTranslations.setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  String t(String key) => AppTranslations.get(key);
}

final languageNotifier = LanguageNotifier();
