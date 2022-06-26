import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Config extends ChangeNotifier {
  static const bool _defaultLogHttp = bool.fromEnvironment('LOG_HTTP', defaultValue: true);
  static const String _defaultBackendApiUrl = String.fromEnvironment('BACKEND_API_URL',
      defaultValue: 'http://localhost:8000/api');
  static const _logConsole = bool.fromEnvironment('LOG_CONSOLE', defaultValue: true);

  bool _isInitialized = false;

  bool _fake = false;
  int _netDelay = 0;
  Level _logLevel = Level.debug;
  bool _logHttp = true;
  final String _backendApiUrl = _defaultBackendApiUrl;

  bool get isInitialized => _isInitialized;
  bool get fake => _fake;
  int get netDelay => _netDelay;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isWeb => kIsWeb;
  Level get logLevel => _logLevel;
  bool get logHttp => _logHttp;
  String get backendApiUrl => _backendApiUrl;
  bool get logConsole => _logConsole;

  Future<void> update({required bool fake, required int netDelay, Level? logLevel}) async {
    _fake = fake;
    _netDelay = netDelay;
    _logLevel = logLevel ?? _logLevel;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('config:fake', _fake);
    await prefs.setInt('config:netDelay', _netDelay);
    await prefs.setString('config:logLevel', _logLevel.name);
    await prefs.setBool('config:logHttp', _logHttp);

    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _fake = prefs.getBool('config:fake') ?? false;
    _netDelay = prefs.getInt('config:netDelay') ?? 0;
    _logHttp = prefs.getBool('config:logHttp') ?? _defaultLogHttp;
    final rawLevel = prefs.getString('config:logLevel');
    _logLevel = Level.values.firstWhere(
      (element) => element.name == rawLevel,
      orElse: () => Level.debug,
    );

    _isInitialized = true;
    notifyListeners();
  }
}
