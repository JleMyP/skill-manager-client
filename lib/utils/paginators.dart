import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/base_model.dart';
import '../utils/base_repository.dart';


class LimitOffsetPaginator<T extends BaseRestRepository, K extends BaseModel>
    with ChangeNotifier {
  T repo;
  Map<String, dynamic> _params;
  List<K> _items;
  bool loadingIsFailed = false;
  int limit = 25;
  int count;

  LimitOffsetPaginator();
  LimitOffsetPaginator.withRepo(this.repo);

  UnmodifiableListView<K> get items => UnmodifiableListView(_items);

  bool get isEnd {
    return count != null && items.length >= count;
  }

  void setParams(Map<String, dynamic> params) {
    _params = params;
    _items?.clear();
    count = null;

    if (_params != null) {
      _params['limit'] = limit;
    }
  }

  void reset() {
    _params = null;
    _items?.clear();
    count = null;
    loadingIsFailed = false;
    notifyListeners();
  }

  Future<List<K>> fetchNext() async {
    if (_params == null) {  // еще не скачали первую страницу
      _params = {
        'limit': limit,
        'offset': 0,
      };
    } else {
      _params['offset'] = _items.length;
    }

    loadingIsFailed = false;

    ResultAndMeta<K> pair;
    try {
      pair = await repo.getList(params: _params);
    } on Exception {
      loadingIsFailed = true;
      notifyListeners();
      return null;
    }

    count = pair.meta == null ? pair.result.length : pair.meta['count'];
    if (_items == null) {
      _items = pair.result;
    } else {
      _items.addAll(pair.result);
    }
    notifyListeners();
    return pair.result;
  }

  Future<void> deleteItem(K item) async {
    await repo.deleteItem(item.id);
    _items.remove(item);
    count -= 1;
    notifyListeners();
  }
}
