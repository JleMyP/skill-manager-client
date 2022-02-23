import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../utils/api_client.dart';


class UserRepo extends ChangeNotifier {
  HttpApiClient? _client;
  User? currentUser;

  UserRepo();

  set client(HttpApiClient value) => _client = value;

  Future<User?> authenticate(String username, String password) async {
    if (_client == null) {
      return null;
    }

    if (_client!.fake) {
      if (_client!.netDelay != 0) {
        await Future.delayed(Duration(seconds: _client!.netDelay));
      }
      currentUser = User(
        username: username,
      );
    } else {
      var authData = {'username': username, 'password': password};
      await _client!.authenticate(authData);
      currentUser = User(
        username: username,
      );
    }

    notifyListeners();
    return currentUser;
  }

  void logout() {
    currentUser = null;
    _client!.logout();
  }
}
