import 'api_client.dart';
import 'base_model.dart';


class ResultAndMeta<T> {
  List<T> result;
  Map<String, dynamic>? meta;

  ResultAndMeta(this.result, [this.meta]);
}


abstract class AbstractRepository<T extends BaseModel> {
  Future<ResultAndMeta<T>> getList({Map<String, dynamic>? params});

  Future<T?> getDetailById(int itemId);
  Future<T?> getDetail(T item);

  Future<void> deleteItemById(int itemId);
  Future<void> deleteItem(T item);

  Future<T> updateItemById(int itemId, Map<String, dynamic> data);
  Future<T> updateItem(T item, Map<String, dynamic> data);
}


abstract class BaseHttpRepository<T extends BaseModel> implements AbstractRepository<T> {
  late HttpApiClient client;
  String? resultKey;

  BaseHttpRepository({client, this.resultKey}) {
    if (client != null) {
      this.client = client;
    }
  }

  String get baseUrl;

  Future<ResultAndMeta<T>> getList({Map<String, dynamic>? params}) async {
    JsonDict? meta;

    final response = await client.get(baseUrl, params: params);
    List<JsonDict> rawList;

    if (resultKey != null) {
      meta = response;
      rawList = response[resultKey].cast<JsonDict>();
      meta!.remove(resultKey);
    } else {
      rawList = response.cast<JsonDict>();
    }

    final list = [
      for (JsonDict item in rawList)
        parseItemFromList(item)
    ];

    return ResultAndMeta<T>(list, meta);
  }

  Future<T?> getDetailById(int itemId) async {
    final response = await client.get('$baseUrl$itemId/');
    return parseItemFromDetail(response);
  }

  Future<T?> getDetail(T item) async {
    return await getDetailById(item.id);
  }

  Future<void> deleteItemById(int itemId) async {
    await client.delete('$baseUrl$itemId/');
  }

  Future<void> deleteItem(T item) async {
    await deleteItemById(item.id);
  }

  Future<T> updateItemById(int itemId, JsonDict data) async {
    final response = await client.patch('$baseUrl$itemId/', data);
    return parseItemFromDetail(response);
  }

  Future<T> updateItem(T item, JsonDict data) async {
    return await updateItemById(item.id, data);
  }

  T parseItemFromList(JsonDict item);

  T parseItemFromDetail(JsonDict item) {
    return parseItemFromList(item);
  }
}


abstract class BaseFakeRepository<T extends BaseModel> implements AbstractRepository<T> {
  int get fakeListCount => 30;

  Future<ResultAndMeta<T>> getList({Map<String, dynamic>? params}) async {
    final list = [
      for (var i = 0; i < fakeListCount; i++)
        fakeItemForList(i)
    ];

    return ResultAndMeta<T>(list);
  }

  Future<T?> getDetailById(int itemId) async {
    return fakeItemForDetail(itemId);
  }

  Future<T?> getDetail(T item) async {
    return getDetailById(item.id);
  }

  Future<void> deleteItemById(int itemId) async {}

  Future<void> deleteItem(T item) async {}

  Future<T> updateItemById(int itemId, JsonDict data) async {
    return fakeItemForDetail(itemId);
  }

  Future<T> updateItem(T item, JsonDict data) async {
    return updateItemById(item.id, data);
  }

  T fakeItemForList(int i);

  T fakeItemForDetail(int i) {
    return fakeItemForList(i);
  }
}


abstract class BaseDelayWrapper<T extends AbstractRepository<I>, I extends BaseModel> {
  final T repo;
  final int _netDelay;

  BaseDelayWrapper(this.repo, this._netDelay);

  Future<void> delay() async {
  	await Future.delayed(Duration(seconds: _netDelay));
  }

  Future<ResultAndMeta<I>> getList({Map<String, dynamic>? params}) async {
  	await delay();
  	return await repo.getList(params: params);
  }

  Future<I?> getDetailById(int itemId) async {
  	await delay();
  	return await repo.getDetailById(itemId);
  }

  Future<I?> getDetail(I item) async {
  	return await getDetailById(item.id);
  }

  Future<void> deleteItemById(int itemId) async {
  	await delay();
  	await repo.deleteItemById(itemId);
  }

  Future<void> deleteItem(I item) async {
  	await deleteItemById(item.id);
  }

  Future<I> updateItemById(int id, JsonDict data) async {
  	await delay();
  	return await repo.updateItemById(id, data);
  }

  Future<I> updateItem(I item, JsonDict data) async {
  	return updateItemById(item.id, data);
  }
}
