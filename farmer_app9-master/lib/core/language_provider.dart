import 'package:flutter/material.dart';
import 'language_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'en';

  String get language => _language;

  Future<void> loadLanguage() async {
    _language = await LanguageService.getSavedLanguage() ?? 'en';
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    _language = lang;
    await LanguageService.saveLanguage(lang);
    notifyListeners();
  }
}
