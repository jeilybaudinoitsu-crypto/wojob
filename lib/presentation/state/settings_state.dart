import 'package:flutter/material.dart';

/// Estado de configuración y preferencias de la app.
class SettingsState extends ChangeNotifier {
  SettingsState();

  ThemeMode _themeMode = ThemeMode.light;
  String? _locale;
  bool _biometricEnabled = false;

  ThemeMode get themeMode => _themeMode;
  String? get locale => _locale;
  bool get biometricEnabled => _biometricEnabled;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  void setBiometricEnabled(bool enabled) {
    _biometricEnabled = enabled;
    notifyListeners();
  }
}