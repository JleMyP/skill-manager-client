import 'package:flutter/foundation.dart';


class SelectedScreenStore extends ChangeNotifier {
  int _screen = 0;

  int get screen => _screen;
  set screen(int val) {
    _screen = val;
    notifyListeners();
  }
}


class SelectedPageStore extends ChangeNotifier {
  String _page;

  SelectedPageStore(this._page);

  String get page => _page;
  set page(String val) {
    _page = val;
    notifyListeners();
  }
}


class ButtonState extends ChangeNotifier {
  bool _show = true;

  bool get show => _show;
  set show(bool val) {
    _show = val;
    notifyListeners();
  }
}


class BottomBarState extends ChangeNotifier {
  bool _show = true;

  bool get show => _show;
  set show(bool val) {
    _show = val;
    notifyListeners();
  }
}
