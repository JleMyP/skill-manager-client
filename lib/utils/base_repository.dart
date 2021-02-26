import 'api_client.dart';
import 'base_model.dart';


class ResultAndMeta<T> {
  List<T> result;
  Map<String, dynamic> meta;

  ResultAndMeta(this.result, this.meta);
}


abstract class BaseRestRepository<T extends BaseModel> {
  HttpApiClient client;
  String resultKey;

  BaseRestRepository({this.client, this.resultKey});

  String get baseUrl;
  int get fakeListCount => 30;

  Future<ResultAndMeta<T>> getList({Map<String, dynamic> params}) async {
    List<T> list;
    Map<String, dynamic> meta;

    if (client.fake) {
      if (client.netDelay != 0) {  // TODO: дублируется
        await Future.delayed(Duration(seconds: client.netDelay));
      }
      list = [
        for (var i = 0; i < fakeListCount; i++)
          fakeItemForList(i)
      ];
    } else {
      final response = await client.get(baseUrl, params: params);
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

  Future<T> getDetailById(int itemId) async {
    T item;

    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
      item = fakeItemForDetail(itemId);
    } else {
      final response = await client.get('$baseUrl$itemId/');
      item = parseItemFromDetail(response);
    }

    return item;
  }

  Future<T> getDetail(T item) async {
    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
      item = fakeItemForDetail(item.id);
    } else {
      final response = await client.get('$baseUrl${item.id}/');
      item = parseItemFromDetail(response);
    }

    return item;
  }

  Future<void> deleteItemById(int itemId) async {
    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
    } else {
      await client.delete('$baseUrl$itemId/');
    }
  }

  Future<void> deleteItem(T item) async {
    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
    } else {
      await client.delete('$baseUrl${item.id}/');
    }
  }

  Future<T> updateItemById(int itemId, Map<String, dynamic> data) async {
    T newItem;

    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
        newItem = fakeItemForDetail(itemId);
      }
    } else {
      final response = await client.patch('$baseUrl$itemId/', data);
      newItem = parseItemFromDetail(response);
    }

    return newItem;
  }

  Future<T> updateItem(T item, Map<String, dynamic> data) async {
    T newItem;

    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
        newItem = fakeItemForDetail(item.id);
      }
    } else {
      final response = await client.patch('$baseUrl${item.id}/', data);
      newItem = parseItemFromDetail(response);
    }

    return newItem;
  }

  T parseItemFromList(Map<String, dynamic> item);

  T parseItemFromDetail(Map<String, dynamic> item) {
    return parseItemFromList(item);
  }

  T fakeItemForList(int i);

  T fakeItemForDetail(int i) {
    return fakeItemForList(i);
  }
}
