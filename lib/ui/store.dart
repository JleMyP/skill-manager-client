import 'package:flutter/foundation.dart';

import '../data/base_model.dart';
import '../data/paginators.dart';

class ItemWithPaginator {
  final LimitOffsetPaginator paginator;
  final BaseModel item;
  final bool shouldFetch;

  ItemWithPaginator({
    required this.paginator,
    required this.item,
    this.shouldFetch = true,
  });
}

class SelectedScreenStore extends ChangeNotifier {
  int _screen = 0;

  int get screen => _screen;
  set screen(int val) {
    if (_screen == val) {
      return;
    }
    _screen = val;
    notifyListeners();
  }
}

class SelectedPageStore extends ChangeNotifier {
  String _page;

  SelectedPageStore(this._page);

  String get page => _page;
  set page(String val) {
    if (_page == val) {
      return;
    }
    _page = val;
    notifyListeners();
  }
}

class ButtonState extends ChangeNotifier {
  bool _show = true;

  bool get show => _show;
  set show(bool val) {
    if (_show == val) {
      return;
    }
    _show = val;
    notifyListeners();
  }
}

class BottomBarState extends ChangeNotifier {
  bool _show = true;

  bool get show => _show;
  set show(bool val) {
    if (_show == val) {
      return;
    }
    _show = val;
    notifyListeners();
  }
}
