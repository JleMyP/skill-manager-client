import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger_flutter/logger_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shrink_sidemenu/shrink_sidemenu.dart';

import '../repos/user.dart';
import '../utils/dialogs.dart';
import 'imported_resource_list.dart';


class SelectedScreenStore with ChangeNotifier {
  int _screen = 0;

  int get screen => _screen;
  set screen(int val) {
    _screen = val;
    notifyListeners();
  }
}


class SelectedPageStore with ChangeNotifier {
  String _page;

  SelectedPageStore(this._page);

  String get page => _page;
  set page(String val) {
    _page = val;
    notifyListeners();
  }
}

class HomePageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _exit(context),
      child: ChangeNotifierProvider<SelectedPageStore>(
        create: (context) => SelectedPageStore(ImportedResourceListPage.name),
        child: HomePage(),
      ),
    );
  }

  _exit(BuildContext context) async {
    return await showConfirmDialog(context, 'Выйти?', null);
  }
}

class HomePage extends StatelessWidget {
  final _sideMenuKey = GlobalKey<SideMenuState>();
  final _bodyKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    var page = context.watch<SelectedPageStore>().page;

    _bodyKeys.putIfAbsent(page, () => GlobalKey());
    var state = _bodyKeys[page];

    Widget body;
    switch (page) {
      case ImportedResourceListPage.name:
        body = ImportedResourceListPage(_sideMenuTap, state);
        break;
    }

    return SideMenu(
      background: Theme.of(context).dialogBackgroundColor,
      key: _sideMenuKey,
      type: SideMenuType.slideNRotate,
      menu: LeftMenu(),
      child: body,
    );
  }

  _sideMenuTap() {
    var state = _sideMenuKey.currentState;

    if (state.isOpened) {
      state.closeSideMenu();
    } else {
      state.openSideMenu();
    }
  }
}


class LeftMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var store = context.watch<SelectedPageStore>();
    return ListView(
      children: [
        ListTile(
          selected: store.page == ImportedResourceListPage.name,
          leading: Icon(Icons.archive_outlined),
          title: Text('Импортированные ресурсы'),
          onTap: () => store.page = ImportedResourceListPage.name,
        ),
        ListTile(
          leading: Icon(Icons.all_inbox),
          title: Text('Ресурсы'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.school_outlined),
          title: Text('ЗУНы'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.assignment_outlined),
          title: Text('Задачи'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.notes),
          title: Text('Заметки'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Напоминания'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.work_outline),
          title: Text('Проекты'),
          onTap: () {},
        ),
        Divider(height: 50),
        // TODO: не рендерить консольку в release mode или по флагам
        ListTile(
          leading: Icon(Icons.insert_drive_file),
          title: Text('Логи'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LogConsole(dark: true, showCloseButton: true),
          )),
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Выход'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  _logout(BuildContext context) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove('auth:login');
    sharedPreferences.remove('auth:password');
    sharedPreferences.remove('auth:autoLogin');
    context.read<UserRepo>().logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
