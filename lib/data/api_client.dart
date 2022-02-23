import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';


typedef JsonDict = Map<String, dynamic>;


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
    accessExpire = DateTime.fromMillisecondsSinceEpoch(
      accessDecoded['exp'] * 1000);
    final refreshDecoded = JwtDecoder.decode(refresh);
    refreshExpire = DateTime.fromMillisecondsSinceEpoch(
      refreshDecoded['exp'] * 1000);
    // TODO: checks: type, time
  }

  OAuth2Token asOauth() => OAuth2Token(
    accessToken: access,
    refreshToken: refresh,
    expiresIn: accessExpire.millisecondsSinceEpoch ~/ 1000,
    tokenType: 'Token',
  );
}


class HttpApiClient {
  final _authUrl = '/token/';
  final _refreshUrl = '/token/refresh/';

  String _scheme = 'http';
  String _host = 'localhost';
  int? _port;
  late Fresh<OAuth2Token> _refresher;
  late Dio _httpClient;

  String get scheme => _scheme;
  set scheme(String value) {
    _scheme = value;
    _setBaseUrl();
  }
  String get host => _host;
  set host(String value) {
    _host = value;
    _setBaseUrl();
  }
  int? get port => _port;
  set port(int? value) {
    _port = value;
    _setBaseUrl();
  }

  HttpApiClient({ Dio? client }) {
    _httpClient = client ?? Dio();
    _setBaseUrl();

    _refresher = Fresh.oAuth2(
      tokenStorage: InMemoryTokenStorage(),  // TODO: shared preferences
      shouldRefresh: (response) {
        return response?.requestOptions.path != _authUrl &&
          response?.requestOptions.path != _refreshUrl &&
          (response?.statusCode == 401 || response?.statusCode == 403);
      },
      refreshToken: (token, client) async {
        final response = await post(_refreshUrl, {'refresh': token!.refreshToken});
        return JwtTokenPair(response['access'], token.refreshToken!).asOauth();
      },
    );
    final logger = createLogger();

    _httpClient.interceptors.addAll([
      _refresher,
      HttpFormatter(logger: logger),
    ]);
  }

  void configure({
      required String scheme,
      required String host,
      int? port,
  }) {
    _scheme = scheme;
    _host = host;
    _port = port;
    _setBaseUrl();
  }

  _setBaseUrl() {
    final portString = _port != null ? ':$_port' : '';
    _httpClient.options.baseUrl = '$scheme://$_host$portString/api/v1';
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
    sp..setString('apiClient:scheme', scheme)
      ..setString('apiClient:host', _host);

    if (_port != null) {
      sp.setInt('apiClient:port', _port!);
    } else {
      sp.remove('apiClient:port');
    }
  }

  Future<void> restoreSettings() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    _scheme = sharedPreferences.getString('apiClient:scheme') ?? 'http';
    _host = sharedPreferences.getString('apiClient:host') ?? 'localhost';
    _port = sharedPreferences.getInt('apiClient:port');
    _setBaseUrl();
  }

  Future _doRequest(Future Function() func) async {
    // wrap errors
    try {
      return await func();
    } on DioError catch (error) {
      if (error.error is SocketException) {
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
        var err = ApiException(
          rawData: data,
          originalException: error,
        );
        throw err;
      }

      if (data is! Map) {
        var err = ApiException(
          rawData: data,
          originalException: error,
        );
        throw err;
      }

      if (data.containsKey('detail')) {
        var err = ApiException(
          message: data['detail'],
          rawData: data,
          originalException: error,
        );
        throw err;
      }
      if (data.containsKey('details') && data['details'][0] is String) {
        var err = ApiException(
          message: (data['details'] as List<String>).join('\n'),
          rawData: data,
          originalException: error,
        );
        throw err;
      }

      var err = ApiException(
        rawData: data,
        originalException: error,
      );
      throw err;
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
