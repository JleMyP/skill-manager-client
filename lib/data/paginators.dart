import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../utils/logger.dart';
import 'base_model.dart';
import 'base_repository.dart';

class LimitOffsetPaginator<K extends BaseModel> extends ChangeNotifier {
  AbstractRepository<K>? repo;
  int limit;

  Map<String, dynamic>? _params;
  late Map<String, dynamic> _baseParams;
  List<K>? _items;

  bool _isLoading = false;
  bool _isFailed = false;
  int? _count;
  late Logger _logger;

  LimitOffsetPaginator({
    this.repo,
    this.limit = 25,
    Map<String, dynamic>? baseParams,
    Logger? logger,
  }) {
    _baseParams = baseParams ?? {};
    _logger = logger ?? createLogger();
  }

  UnmodifiableListView<K> get items => UnmodifiableListView(_items ?? []);

  int? get count => _count;
  bool get isConnected => _count != null;
  bool get isNotConnected => !isConnected;
  bool get isEnd => isConnected && _items!.length >= _count!;
  bool get isLoading => _isLoading;
  bool get isFailed => _isFailed;
  bool get isEmpty => isConnected && items.isEmpty;
  int get offset => _params?['offset'] ?? 0;

  void setParams(Map<String, dynamic>? params) {
    _params = params;
    _items?.clear();
    _count = null;

    if (_params != null) {
      _params!['limit'] = limit;
    }
    notifyListeners();
  }

  Map<String, dynamic>? get params {
    if (_params == null) return null;
    return UnmodifiableMapView(_params!);
  }

  void reset() {
    _params = null;
    _items?.clear();
    _count = null;
    _isFailed = false;
    _isLoading = false;
  }

  Future<void> fetchNext({bool notifyStart = true}) async {
    _logger.v('fetch start');

    if (_isLoading) {
      _logger.w('try to fetch while fetch');
      return;
    }

    if (_items == null || _params == null) {
      // еще не скачали первую страницу
      _params = {
        'limit': limit,
        'offset': 0,
      };
    } else {
      _params!['offset'] = _items!.length;
    }

    for (final pair in _baseParams.entries) {
      if (!_params!.containsKey(pair.key)) {
        _params![pair.key] = params!.values;
      }
    }

    _isFailed = false;
    _isLoading = true;
    _logger.v('params=$_params');

    if (notifyStart) {
      notifyListeners();
    }

    ResultAndMeta<K> pair;
    try {
      pair = await repo!.getList(params: _params);
    } on Exception catch (e, s) {
      _isFailed = true;
      _isLoading = false;
      _logger.e('get list error', e, s);
      notifyListeners();
      return;
    }

    _count = pair.meta?['count'] ?? pair.result.length;
    if (_items == null) {
      _items = pair.result;
    } else {
      // TODO: отфильтровать дубли
      _items!.addAll(pair.result);
    }
    _isLoading = false;
    notifyListeners();
    return;
  }

  Future<void> deleteItem(K item) async {
    _logger.v('deleting item $item');
    await repo!.deleteItem(item);
    _items!.remove(item);
    _count = count! - 1;
    notifyListeners();
  }
}
