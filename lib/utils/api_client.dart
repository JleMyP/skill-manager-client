import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger.dart';


class ApiException implements Exception {
  String message;
  dynamic rawData;
  Exception originalException;

  ApiException({this.message, this.rawData, this.originalException});

  @override
  String toString() => message ?? originalException?.toString();
}


class JwtTokenPair {
  String access;
  String refresh;
  DateTime accessExpire;
  DateTime refreshExpire;

  JwtTokenPair(this.access, this.refresh) {
    var accessDecoded = JwtDecoder.decode(access);
    accessExpire = DateTime.fromMillisecondsSinceEpoch(
        accessDecoded['exp'] * 1000);
    var refreshDecoded = JwtDecoder.decode(refresh);
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


class DelayInterceptor extends Interceptor {
  int delaySeconds;

  DelayInterceptor(this.delaySeconds);

  @override
  Future onRequest(RequestOptions options) async {
    await Future.delayed(Duration(seconds: delaySeconds));
    return options;
  }
}


class ExceptionWrapInterceptor extends Interceptor {
  @override
  Future onError(DioError error) async {
    if (error.error is SocketException) {
      return ApiException(
        message: 'сервер недоступен',
        originalException: error,
      );
    }

    if (error.response == null) {
      return ApiException(originalException: error);
    }

    var data = error.response.data;
    if (!(error.response.headers['content-type'][0] ?? '').contains(
        'application/json')) {
      return ApiException(
        rawData: data,
        originalException: error,
      );
    }

    if (data is! Map) {
      return ApiException(
        rawData: data,
        originalException: error,
      );
    }

    if (data.containsKey('detail')) {
      return ApiException(
        message: data['detail'],
        rawData: data,
        originalException: error,
      );
    }
    if (data.containsKey('details') && data['details'][0] is String) {
      return ApiException(
        message: (data['details'] as List<String>).join('\n'),
        rawData: data,
        originalException: error,
      );
    }

    return ApiException(
      rawData: data,
      originalException: error,
    );
  }
}


class HttpApiClient {
  String scheme = 'http';
  String host = 'localhost';
  int port;
  bool fake = true;
  bool offline = true;
  int netDelay = 0;
  String authUrl = '/token/';
  String refreshUrl = '/token/refresh/';
  Fresh<OAuth2Token> refresher;
  DelayInterceptor delayer;
  Dio httpClient;

  HttpApiClient.withHttpClient(this.httpClient) {
    _setBaseUrl();
  }

  HttpApiClient() {
    httpClient = Dio();
    _setBaseUrl();

    refresher = Fresh.oAuth2(
      tokenStorage: InMemoryTokenStorage(),  // TODO: shared preferences
      shouldRefresh: (response) {
        return response?.request?.path != authUrl &&
          response?.request?.path != refreshUrl &&
          (response?.statusCode == 401 || response?.statusCode == 403);
      },
      refreshToken: (token, client) async {
        var response = await post(refreshUrl, {'refresh': token.refreshToken});
        return JwtTokenPair(response['access'], token.refreshToken).asOauth();
      },
    );
    delayer = DelayInterceptor(netDelay);
    var logger = createLogger();

    httpClient.interceptors.addAll([
      refresher,
      HttpFormatter(logger: logger),
      delayer,
      ExceptionWrapInterceptor(),
    ]);
  }

  void configure(String scheme, String host, int port, bool fake, bool offline,
      int netDelay) {
    this.scheme = scheme;
    this.host = host;
    this.port = port;
    this.fake = fake;
    this.offline = offline;
    this.netDelay = netDelay;
    delayer.delaySeconds = netDelay;
    _setBaseUrl();
  }

  _setBaseUrl() {
    var portString = port != null ? ':$port' : '';
    httpClient.options.baseUrl = '$scheme://$host$portString/api/v1';
  }

  void authenticate(Map<String, dynamic> authData) async {
    var response = await post(authUrl, authData);
    refresher.setToken(JwtTokenPair(response['access'],
        response['refresh']).asOauth());
  }

  void logout() {
    refresher.clearToken();
  }

  void storeSettings() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('apiClient:scheme', scheme);
    sharedPreferences.setString('apiClient:host', host);
    sharedPreferences.setInt('apiClient:port', port);
    sharedPreferences.setBool('apiClient:fake', fake);
    sharedPreferences.setBool('apiClient:offline', offline);
    sharedPreferences.setInt('apiClient:netDelay', netDelay);
  }

  void restoreSettings() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    scheme = sharedPreferences.getString('apiClient:scheme') ?? 'http';
    host = sharedPreferences.getString('apiClient:host') ?? 'localhost';
    port = sharedPreferences.getInt('apiClient:port');
    fake = sharedPreferences.getBool('apiClient:fake') ?? true;
    offline = sharedPreferences.getBool('apiClient:offline') ?? true;
    netDelay = sharedPreferences.getInt('apiClient:netDelay') ?? 0;
    delayer.delaySeconds = netDelay;
    _setBaseUrl();
  }

  Future<dynamic> _doRequest(Future<dynamic> Function() func) async {
    // хня по перевыбрасу ошибки
    try {
      return await func();
    } on DioError catch (e) {
      if (e.error is ApiException) {
        throw e.error;
      }

      rethrow;
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic> params}) async {
    return await _doRequest(() async {
      var response = await httpClient.get(path, queryParameters: params);
      return response.data;
    });
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    return await _doRequest(() async {
      var response = await httpClient.post(path, data: data);
      return response.data;
    });
  }

  Future<dynamic> patch(String path, Map<String, dynamic> data) async {
    return await _doRequest(() async {
      var response = await httpClient.patch(path, data: data);
      return response.data;
    });
  }

  Future delete(String path, {Map<String, dynamic> params}) async {
    await _doRequest(() async {
      await httpClient.delete(path, queryParameters: params);
    });
  }
}
