import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'selected_language';
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void setLocale(Locale locale) async {
    if (!['en', 'fr'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  void clearLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefsKey);

    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Default to OS language on first run
      final systemLocale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (['en', 'fr'].contains(systemLocale)) {
        _locale = Locale(systemLocale);
      } else {
        _locale = const Locale('en');
      }
    }
    notifyListeners();
  }
}
