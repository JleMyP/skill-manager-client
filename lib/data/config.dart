import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Config extends ChangeNotifier {
  bool _fake = false;
  int _netDelay = 0;

  bool get fake => _fake;
  int get netDelay => _netDelay;

  Future<void> update({required bool fake, required int netDelay}) async {
    _fake = fake;
    _netDelay = netDelay;

    await SharedPreferences.getInstance()
      ..setBool('config:fake', _fake)
      ..setInt('config:netDelay', _netDelay);
    
    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _fake = prefs.getBool('config:fake') ?? false;
    _netDelay = prefs.getInt('config:netDelay') ?? 0;
  }
}
