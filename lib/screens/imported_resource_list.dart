import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../models/imported_resource.dart';
import '../repos/imported_resources.dart';
import '../utils/dialogs.dart';
import '../utils/paginators.dart';
import 'home.dart';


class ImportedResourceListPage extends StatelessWidget {
  static const name = 'imported_resource_list_page';

  final Function sideMenuTap;
  final GlobalKey bodyKey;

  ImportedResourceListPage(this.sideMenuTap, this.bodyKey);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SelectedScreenStore>(
      create: (context) => SelectedScreenStore(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Импортированные ресурсы'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: sideMenuTap,
          ),
        ),
        body: SafeArea(
          child: Body(bodyKey),
        ),
        bottomNavigationBar: ConvexBottomBar(),
        floatingActionButton: FloatingButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}


class Body extends StatefulWidget {
  Body(Key key): super(key: key);

  @override
  BodyState createState() => BodyState();
}


class BodyState extends State<Body> {
  int _prevScreen;
  LimitOffsetPaginator<ImportedResourceRepo, ImportedResource> paginator;

  @override
  Widget build(BuildContext context) {
    var repo = context.watch<ImportedResourceRepo>();
    var screen = context.watch<SelectedScreenStore>().screen;

    if (repo != paginator?.repo) {
      if (paginator == null) {
        paginator = LimitOffsetPaginator.withRepo(repo);
      } else {
        paginator.repo = repo;
      }
    }

    if (screen != _prevScreen) {
      _changeScreen(screen);
      return Center(child: CircularProgressIndicator());
    }

    if (paginator.isEnd && paginator.items.isEmpty) {
      return Center(child: Text('ниче нету...'));
    }

    return RefreshIndicator(
      child: ListView.separated(
        itemCount: paginator.items.length + (paginator.isEnd ? 0 : 1),
        itemBuilder: _buildListItem,
        separatorBuilder: (context, index) => Divider(),
        shrinkWrap: true,
      ),
      onRefresh: _refresh,
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    if (index == paginator.items.length && !paginator.isEnd) {
      if (paginator.loadingIsFailed) {
        return Padding(
          padding: EdgeInsets.only(bottom: 15, top: 10),
          child: Column(
            children: [
              Text('Шот не удалось...'),
              RaisedButton(
                child: Text('Повторить'),
                onPressed: () {
                  paginator.loadingIsFailed = false;
                  setState(() {});
                },
              )
            ],
          ),
        );
      }

      _fetchNext();
      return Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 15, top: 10),
          child: CircularProgressIndicator(),
        ),
      );
    }

    var item = paginator.items[index];
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      child: ListTile(
        title: Text(item.name),
        onTap: () async => await _openItem(item),
      ),
      actions: [
        IconSlideAction(
          caption: 'Создать \nресурс',
          color: Colors.green,
          icon: Icons.add,
          onTap: () async => await _createResource(item),
        ),
        IconSlideAction(
          caption: 'Изменить',
          color: Colors.blue,
          icon: Icons.edit,
          onTap: () async => await _editItem(item),
        ),
        IconSlideAction(
          caption: 'Удалить',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () async => await _deleteItem(item),
        ),
      ],
    );
  }

  _changeScreen(int index) async {
    if (index == 0) {
      paginator.setParams(null);
    } else if (index == 1) {
      paginator.setParams({'is_ignored': true});
    } else if (index == 2) {
      paginator.setParams({'is_ignored': false});
    } else {
      return;
    }

    _prevScreen = index;
    await _fetchNext();
  }

  _fetchNext() async {
    await paginator.fetchNext();
    setState(() {});
  }

  Future _refresh() async {
    await _changeScreen(_prevScreen);
  }

  _createResource(ImportedResource item) async {
    // await
  }

  _openItem(ImportedResource item) async {
    await Navigator.of(context).pushNamed('/imported_resource/view', arguments: item);
  }

  _editItem(ImportedResource item) async {
    await Navigator.of(context).pushNamed('/imported_resource/edit', arguments: item);
  }

  _deleteItem(ImportedResource item) async {
    var confirm = await showConfirmDialog(
        context, 'Удалить импортированный ресурс?', item.name);
    if (!confirm) {
      return;
    }

    await paginator.deleteItem(item);
    setState(() {});
  }
}


class ConvexBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var screen = context.watch<SelectedScreenStore>();

    return ConvexAppBar(
      style: TabStyle.reactCircle,
      backgroundColor: theme.primaryColor,
      color: theme.backgroundColor,
      items: [
        TabItem(icon: Icons.home, title: 'Все'),
        TabItem(icon: Icons.map, title: 'Игнор'),
        TabItem(icon: Icons.add, title: 'Не игнор'),
      ],
      onTap: (i) => _onItemTapped(screen, i),
    );
  }

  _onItemTapped(SelectedScreenStore screen, int newIndex) {
    if (screen.screen == newIndex) {
      return;
    }
    screen.screen = newIndex;
  }
}


class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {},
    );
  }
}
