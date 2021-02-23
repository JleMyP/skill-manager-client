import 'package:flutter/material.dart';
import 'package:logger_flutter/logger_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shrink_sidemenu/shrink_sidemenu.dart';

import '../repos/user.dart';
import '../utils/dialogs.dart';
import '../utils/store.dart';
import 'imported_resource_list.dart';
import 'tag_list.dart';


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
    final page = context.watch<SelectedPageStore>().page;

    _bodyKeys.putIfAbsent(page, () => GlobalKey());
    final state = _bodyKeys[page];

    Widget body;
    switch (page) {
      case ImportedResourceListPage.name:
        body = ImportedResourceListPage(_sideMenuTap, state);
        break;
      case TagListPage.name:
        body = TagListPage(_sideMenuTap, state);
        break;
    }

    return SideMenu(
      background: Theme.of(context).dialogBackgroundColor,
      key: _sideMenuKey,
      type: SideMenuType.slideNRotate,
      menu: LeftMenu(_sideMenuTap),
      child: body,
    );
  }

  _sideMenuTap() {
    final state = _sideMenuKey.currentState;

    if (state.isOpened) {
      state.closeSideMenu();
    } else {
      state.openSideMenu();
    }
  }
}


class LeftMenu extends StatelessWidget {
  final Function sideMenuTap;

  LeftMenu(this.sideMenuTap);

  @override
  Widget build(BuildContext context) {
    var store = context.watch<SelectedPageStore>();
    return ListView(
      children: [
        ListTile(
          selected: store.page == ImportedResourceListPage.name,
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Импортированные ресурсы'),
          onTap: () {
            store.page = ImportedResourceListPage.name;
            sideMenuTap();
          },
        ),
        ListTile(
          leading: const Icon(Icons.all_inbox),
          title: const Text('Ресурсы'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: const Text('ЗУНы'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.assignment_outlined),
          title: const Text('Задачи'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notes),
          title: const Text('Заметки'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Напоминания'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.work_outline),
          title: const Text('Проекты'),
          onTap: () {},
        ),
        const Divider(height: 5),
        ListTile(
          selected: store.page == TagListPage.name,
          leading: const Icon(Icons.label),
          title: const Text('Метки'),
          onTap: () {
            store.page = TagListPage.name;
            sideMenuTap();
          },
        ),
        const Divider(height: 50),
        // TODO: не рендерить консольку в release mode или по флагам
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: const Text('Логи'),
          onTap: () => _showLogs(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Выход'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  _logout(BuildContext context) async {
    await SharedPreferences.getInstance()
      ..remove('auth:login')
      ..remove('auth:password')
      ..remove('auth:autoLogin');
    context.read<UserRepo>().logout();
    await Navigator.of(context).pushReplacementNamed('/login');
  }

  _showLogs(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LogConsole(dark: true, showCloseButton: true),
    ));
  }
}
