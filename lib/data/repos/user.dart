import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../config.dart';
import '../models/user.dart';


abstract class UserRepo implements ChangeNotifier {
  Future<User> authenticate(String username, String password);
  void logout();
}


class UserHttpRepo extends ChangeNotifier implements UserFakeRepo {
  late HttpApiClient _client;
  User? currentUser;

  UserHttpRepo({ HttpApiClient? client }) {
    if (client != null) {
      _client = client;
    }
  }

  Future<User> authenticate(String username, String password) async {
    var authData = {'username': username, 'password': password};
    await _client.authenticate(authData);
    currentUser = User(
      username: username,
    );
    notifyListeners();
    return currentUser!;
  }

  void logout() {
    currentUser = null;
    _client.logout();
  }
}


class UserFakeRepo extends ChangeNotifier implements UserRepo {
  User? currentUser;

  Future<User> authenticate(String username, String password) async {
    currentUser = User(username: username);
    notifyListeners();
    return currentUser!;
  }

  void logout() {
    currentUser = null;
  }
}


class UserDelayWrapper extends ChangeNotifier implements UserRepo {
  final UserRepo _repo;
  final int _netDelay;

  UserDelayWrapper(this._repo, this._netDelay) {
    _repo.addListener(notifyListeners);
  }

  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> delay() async {
    await Future.delayed(Duration(seconds: _netDelay));
  }

  Future<User> authenticate(String username, String password) async {
    await delay();
    return _repo.authenticate(username, password);
  }
  void logout() {}
}


UserRepo createUserRepo(Config config, HttpApiClient? client) {
  UserRepo repo;

  if (config.fake) {
    repo = UserFakeRepo();
  } else {
    repo = UserHttpRepo(client: client!);
  }

  if (config.netDelay != 0) {
    repo = UserDelayWrapper(repo, config.netDelay);
  }

  return repo;
}
