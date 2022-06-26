import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './config.dart';
import '../utils/logger.dart';

typedef JsonDict = Map<String, dynamic>;
typedef Params = Map<String, dynamic>;

class ApiException implements Exception {
  String? message;
  dynamic rawData;
  Exception? originalException;

  ApiException({this.message, this.rawData, this.originalException});

  @override
  String toString() => message ?? originalException?.toString() ?? '';
}

class JwtTokenPair {
  String access;
  String refresh;
  late DateTime accessExpire;
  late DateTime refreshExpire;

  JwtTokenPair(this.access, this.refresh) {
    final accessDecoded = JwtDecoder.decode(access);
    accessExpire = DateTime.fromMillisecondsSinceEpoch(accessDecoded['exp'] * 1000);
    final refreshDecoded = JwtDecoder.decode(refresh);
    refreshExpire = DateTime.fromMillisecondsSinceEpoch(refreshDecoded['exp'] * 1000);
    // TODO: checks: type, time
  }

  OAuth2Token asOauth() => OAuth2Token(
        accessToken: access,
        refreshToken: refresh,
        expiresIn: accessExpire.millisecondsSinceEpoch ~/ 1000,
        tokenType: 'Token',
      );
}

class SpTokenStorage implements TokenStorage<OAuth2Token> {
  static const _accessKey = 'auth:jwt:access';
  static const _refreshKey = 'auth:jwt:refresh';

  Future<OAuth2Token?> read() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final access = sharedPreferences.getString(_accessKey);
    final refresh = sharedPreferences.getString(_refreshKey);

    if (access == null) {
      return null;
    }

    return OAuth2Token(
      accessToken: access,
      refreshToken: refresh,
      tokenType: 'Token',
    );
  }

  Future<void> write(OAuth2Token token) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(_accessKey, token.accessToken);
    await sharedPreferences.setString(_refreshKey, token.refreshToken!);
  }

  Future<void> delete() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove(_accessKey);
    await sharedPreferences.remove(_refreshKey);
  }
}

class HttpApiClient extends ChangeNotifier {
  static const _authUrl = '/v1/token/';
  static const _refreshUrl = '/v1/token/refresh/';
  // static const _verifyUrl = '/v1/token/verify/';
  static const _baseUrlKey = 'apiClient:backendApiUrl';

  late Fresh<OAuth2Token> _refresher;
  late Dio _httpClient;
  late String _defaultBackendApiUrl;
  late Level _logLevel;
  late bool _logHttp;

  set baseUrl(String url) => _httpClient.options.baseUrl = url;
  String get baseUrl => _httpClient.options.baseUrl;

  HttpApiClient({required Config config, Dio? client}) {
    _httpClient = client ?? Dio();
    _defaultBackendApiUrl = config.backendApiUrl;
    _logLevel = config.logLevel;
    _logHttp = config.logHttp;
    baseUrl = _defaultBackendApiUrl;

    _refresher = Fresh.oAuth2(
      tokenStorage: SpTokenStorage(),
      shouldRefresh: (response) {
        return response?.requestOptions.path != _authUrl &&
            response?.requestOptions.path != _refreshUrl &&
            (response?.statusCode == 401 || response?.statusCode == 403);
      },
      refreshToken: (token, client) async {
        try {
          final response = await post(_refreshUrl, {'refresh': token!.refreshToken});
          return JwtTokenPair(response['access'], token.refreshToken!).asOauth();
        } on ApiException {
          throw RevokeTokenException();
        }
      },
    );
    final logger = createLogger(_logLevel);

    _httpClient.interceptors.addAll([
      _refresher,
      if (config.logHttp) HttpFormatter(logger: logger),
    ]);
  }

  bool shouldUpdate({required Config config, Dio? client}) {
    var should = false;
    if (client != null && client != _httpClient) should = true;
    if (config.logLevel != _logLevel) should = true;
    if (config.logHttp != _logHttp) should = true;
    return should;
  }

  Future<void> authenticate(JsonDict authData) async {
    final response = await post(_authUrl, authData);
    _refresher.setToken(JwtTokenPair(response['access'], response['refresh']).asOauth());
  }

  void logout() {
    _refresher.clearToken();
  }

  Future<void> storeSettings() async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(_baseUrlKey, baseUrl);
  }

  Future<void> restoreSettings() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    baseUrl = sharedPreferences.getString(_baseUrlKey) ?? _defaultBackendApiUrl;
    notifyListeners();
  }

  Future _doRequest(Future Function() func) async {
    // wrap errors
    try {
      return await func();
    } on DioError catch (error) {
      if (error.error is SocketException || error.error == 'XMLHttpRequest error.') {
        var err = ApiException(
          message: 'сервер недоступен',
          originalException: error,
        );
        throw err;
      }

      if (error.response == null) {
        var err = ApiException(originalException: error);
        throw err;
      }

      var data = error.response?.data;
      var ct = error.response?.headers['content-type']?[0];
      if (ct == null || !ct.contains('application/json')) {
        throw ApiException(
          rawData: data,
          originalException: error,
        );
      }

      if (data is! Map) {
        throw ApiException(
          rawData: data,
          originalException: error,
        );
      }

      if (data.containsKey('detail')) {
        throw ApiException(
          message: data['detail'],
          rawData: data,
          originalException: error,
        );
      }
      if (data.containsKey('details') && data['details'][0] is String) {
        throw ApiException(
          message: (data['details'] as List<String>).join('\n'),
          rawData: data,
          originalException: error,
        );
      }

      throw ApiException(
        rawData: data,
        originalException: error,
      );
    }
  }

  Future get(String path, {Map<String, dynamic>? params}) async {
    return await _doRequest(() async {
      final response = await _httpClient.get(path, queryParameters: params);
      return response.data;
    });
  }

  Future post(String path, JsonDict data) async {
    return await _doRequest(() async {
      final response = await _httpClient.post(path, data: data);
      return response.data;
    });
  }

  Future patch(String path, JsonDict data) async {
    return await _doRequest(() async {
      final response = await _httpClient.patch(path, data: data);
      return response.data;
    });
  }

  Future delete(String path, {Map<String, dynamic>? params}) async {
    await _doRequest(() async {
      final response = await _httpClient.delete(path, queryParameters: params);
      return response.data;
    });
  }
}
