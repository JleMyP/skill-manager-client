import '../utils/api_client.dart';


class ResultAndMeta<T> {
  List<T> result;
  Map<String, dynamic> meta;

  ResultAndMeta(this.result, this.meta);
}


abstract class BaseRestRepository<T> {
  HttpApiClient _client;
  String resultKey;

  BaseRestRepository({this.resultKey});
  BaseRestRepository.withClient(this._client, {this.resultKey});

  String get baseUrl;
  int get fakeListCount => 30;

  set client(HttpApiClient client) => _client = client;

  Future<ResultAndMeta<T>> getList({Map<String, dynamic> params}) async {
    List<T> list;
    Map<String, dynamic> meta;

    if (_client.fake) {
      if (_client.netDelay != 0) {  // TODO: дублируется
        await Future.delayed(Duration(seconds: _client.netDelay));
      }
      list = [
        for (var i = 0; i < fakeListCount; i++)
          fakeItemForList(i)
      ];
    } else {
      var response = await _client.get(baseUrl, params: params);
      List<Map<String, dynamic>> rawList;

      if (resultKey != null) {
        meta = response;
        rawList = response[resultKey].cast<Map<String, dynamic>>();
        meta.remove(resultKey);
      } else {
        rawList = response.cast<Map<String, dynamic>>();
      }

      list = [
        for (Map<String, dynamic> item in rawList)
          parseItemFromList(item)
      ];
    }

    return ResultAndMeta<T>(list, meta);
  }

  Future<T> getDetail(int itemId) async {
    T item;

    if (_client.fake) {
      if (_client.netDelay != 0) {
        await Future.delayed(Duration(seconds: _client.netDelay));
      }
      item = fakeItemForDetail(itemId);
    } else {
      var response = await _client.get('$baseUrl/$itemId/');
      item = parseItemFromDetail(response);
    }

    return item;
  }

  Future<void> deleteItem(int itemId) async {
    if (_client.fake) {
      if (_client.netDelay != 0) {
        await Future.delayed(Duration(seconds: _client.netDelay));
      }
    } else {
      await _client.delete('$baseUrl/$itemId/');
    }
  }

  T parseItemFromList(Map<String, dynamic> item);
  T parseItemFromDetail(Map<String, dynamic> item);
  T fakeItemForList(int i);
  T fakeItemForDetail(int i);
}
