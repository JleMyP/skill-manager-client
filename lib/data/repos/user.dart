import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../config.dart';
import '../models/user.dart';

abstract class UserRepo implements ChangeNotifier {
  User? get currentUser;

  Future<User> authenticate(String username, String password);
  Future<User> reload();
  void logout();
}

class UserHttpRepo extends ChangeNotifier implements UserRepo {
  final HttpApiClient _client;
  User? _currentUser;
  User? get currentUser => _currentUser;
  HttpApiClient get client => _client;

  UserHttpRepo(this._client);

  Future<User> authenticate(String username, String password) async {
    var authData = {'username': username, 'password': password};
    await _client.authenticate(authData);
    _currentUser = User(username: username);
    notifyListeners();
    return _currentUser!;
  }

  Future<User> reload() async {
    final resp = await _client.get('/v1/profile/');
    _currentUser = User(username: resp['username']);
    notifyListeners();
    return _currentUser!;
  }

  void logout() {
    _currentUser = null;
    _client.logout();
    notifyListeners();
  }
}

class UserFakeRepo extends ChangeNotifier implements UserRepo {
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<User> authenticate(String username, String password) async {
    _currentUser = User(username: username);
    notifyListeners();
    return _currentUser!;
  }

  Future<User> reload() async {
    _currentUser = User(username: 'FakeUsername');
    notifyListeners();
    return _currentUser!;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

class UserDelayWrapper extends ChangeNotifier implements UserRepo {
  final UserRepo _repo;
  final int _netDelay;

  User? get currentUser => _repo.currentUser;

  UserDelayWrapper(this._repo, this._netDelay) {
    _repo.addListener(notifyListeners);
  }

  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }

  Future<User> authenticate(String username, String password) async {
    await _delay();
    return _repo.authenticate(username, password);
  }

  Future<User> reload() async {
    await _delay();
    return _repo.reload();
  }

  void logout() => _repo.logout();

  Future<void> _delay() => Future.delayed(Duration(seconds: _netDelay));
}

UserRepo createUserRepo(Config config, HttpApiClient client) {
  UserRepo repo;

  if (config.fake) {
    repo = UserFakeRepo();
  } else {
    repo = UserHttpRepo(client);
  }

  if (config.netDelay != 0) {
    repo = UserDelayWrapper(repo, config.netDelay);
  }

  return repo;
}
