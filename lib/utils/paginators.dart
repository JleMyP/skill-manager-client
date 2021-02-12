import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'base_model.dart';
import 'base_repository.dart';
import 'logger.dart';


class LimitOffsetPaginator<T extends BaseRestRepository, K extends BaseModel>
    extends ChangeNotifier {  // TODO: stream?
  T repo;
  Map<String, dynamic> _params;
  List<K> _items;

  bool isLoading = false;
  bool loadingIsFailed = false;
  int limit = 25;
  int count;
  Exception lastException;
  Logger logger;

  LimitOffsetPaginator() {
    logger = createLogger();
  }
  LimitOffsetPaginator.withRepo(this.repo) {
    logger = createLogger();
  }

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
    lastException = null;
    isLoading = false;
  }

  Future<List<K>> fetchNext({bool notifyStart = true}) async {
    if (_items == null || _params == null) {  // еще не скачали первую страницу
      _params = {
        'limit': limit,
        'offset': 0,
      };
    } else {
      _params['offset'] = _items.length;
    }

    loadingIsFailed = false;
    lastException = null;
    isLoading = true;
    if (notifyStart) {
      notifyListeners();
    }

    ResultAndMeta<K> pair;
    try {
      pair = await repo.getList(params: _params);
    } on Exception catch(e, s) {
      loadingIsFailed = true;
      lastException = e;
      isLoading = false;
      logger.e('get list error', e, s);
      notifyListeners();
      return null;
    }

    count = pair.meta == null ? pair.result.length : pair.meta['count'];
    if (_items == null) {
      _items = pair.result;
    } else {
      _items.addAll(pair.result);
    }
    isLoading = false;
    notifyListeners();
    return pair.result;
  }

  Future<void> deleteItem(K item) async {
    await repo.deleteItem(item);
    _items.remove(item);
    count -= 1;
    notifyListeners();
  }
}
