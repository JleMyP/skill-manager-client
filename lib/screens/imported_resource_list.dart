import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/imported_resource.dart';
import '../repos/imported_resources.dart';
import '../utils/dialogs.dart';
import '../utils/paginators.dart';
import '../utils/store.dart';
import '../utils/widgets.dart';


class ImportedResourceListPage extends StatefulWidget {
  static const name = 'imported_resource_list_page';

  final Function sideMenuTap;

  ImportedResourceListPage(this.sideMenuTap, GlobalKey key) : super(key: key);

  @override
  ImportedResourceListState createState() => ImportedResourceListState();
}


class ImportedResourceListState extends State<ImportedResourceListPage> {
  SelectedScreenStore _screenStore;
  BottomBarState _barState;

  @override
  void initState() {
    super.initState();
    _screenStore = SelectedScreenStore();
    _barState = BottomBarState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SelectedScreenStore>.value(
          value: _screenStore,
        ),
        ChangeNotifierProvider<BottomBarState>.value(
          value: _barState,
        ),
      ],
      child: Consumer<BottomBarState>(
        child: Body(),
        builder: (context, bs, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Импортированные ресурсы'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.sideMenuTap,
            ),
          ),
          body: SafeArea(
            child: child,
          ),
          bottomNavigationBar: bs.show ? ConvexBottomBar() : null,
        ),
      ),
    );
  }
}


class Body extends StatefulWidget {
  @override
  BodyState createState() => BodyState();
}


class BodyState extends State<Body> {
  int _prevScreen;
  LimitOffsetPaginator<ImportedResourceRepo, ImportedResource> _paginator;

  final ScrollController _scrollController = ScrollController();
  final Widget _github = SvgPicture.asset(
    'assets/github-logo.svg',
    width: 30,
    alignment: Alignment.centerLeft,
    color: Colors.grey,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    final repo = context.read<ImportedResourceRepo>();
    _paginator = LimitOffsetPaginator<ImportedResourceRepo, ImportedResource>(repo: repo)
      ..fetchNext(notifyStart: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.watch<SelectedScreenStore>().screen;

    // TODO: хуита. а можно не перерисовываться без изменения экрана?
    if (screen != _prevScreen) {
      if (screen == 0) {
        _paginator.setParams(null);
      } else if (screen == 1) {
        _paginator.setParams({'is_ignored': true});
      } else if (screen == 2) {
        _paginator.setParams({'is_ignored': false});
      }

      _prevScreen = screen;
    }

    return PaginatedListView(_paginator, _buildListItem, _scrollController);
  }

  Widget _buildListItem(BuildContext context, dynamic _item) {
    final item = _item as ImportedResource;
    final typeMap = <String, Widget>{
      'ImportedResourceRepo': _github,
    };

    return Slidable(
      key: ObjectKey(item),
      actionPane: SlidableDrawerActionPane(),
      child: ChangeNotifierProvider<ImportedResource>.value(
        value: item,
        child: Consumer<ImportedResource>(
          builder: (context, changedItem, child) => ListTile(
            leading: typeMap[changedItem.type],
            title: Text(changedItem.name),
            subtitle: Text(changedItem.description ?? ''),
            trailing: IconButton(
              icon: Icon(changedItem.isIgnored ? Icons.visibility_off : Icons.visibility),
              color: Colors.grey,
              onPressed: () => _changeIgnore(changedItem),
            ),
            onTap: () => _openItem(changedItem),
          ),
        ),
      ),
      actions: [
        IconSlideAction(
          caption: 'Создать \nресурс',
          color: Colors.green,
          icon: Icons.add,
          onTap: () => _createResource(item),
        ),
        IconSlideAction(
          caption: 'Изменить',
          color: Colors.blue,
          icon: Icons.edit,
          onTap: () => _editItem(item),
        ),
        IconSlideAction(
          caption: 'Удалить',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => _deleteItem(item),
        ),
      ],
    );
  }

  _handleScroll() {
    final buttonState = context.read<BottomBarState>();

    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      buttonState.show = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      buttonState.show = true;
    }
  }

  _createResource(ImportedResource item) async {
    // await
  }

  _openItem(ImportedResource item) async {
    final repo = context.read<ImportedResourceRepo>();
    final detailed = await repo.getDetail(item);
    await Navigator.of(context).pushNamed('/imported_resource/view', arguments: detailed);
  }

  _editItem(ImportedResource item) {
    Navigator.of(context).pushNamed('/imported_resource/edit', arguments: item);
  }

  _deleteItem(ImportedResource item) async {
    final confirm = await showConfirmDialog(context, 'Удалить импортированный ресурс?', item.name);
    if (!confirm) {
      return;
    }

    await _paginator.deleteItem(item);
  }

  _changeIgnore(ImportedResource item) async {
    final repo = context.read<ImportedResourceRepo>();
    await repo.updateItem(item, {'is_ignored': !item.isIgnored});
    // TODO: отлов ошибок
    item.update(isIgnored: !item.isIgnored);
  }
}


class ConvexBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenStore = context.watch<SelectedScreenStore>();

    return ConvexAppBar(
      style: TabStyle.reactCircle,
      backgroundColor: theme.primaryColor,
      color: theme.backgroundColor,
      initialActiveIndex: screenStore.screen,
      items: [
        const TabItem(icon: Icons.home, title: 'Все'),
        const TabItem(icon: Icons.visibility_off, title: 'Игнор'),
        const TabItem(icon: Icons.visibility, title: 'Не игнор'),
      ],
      onTap: (i) => _onItemTapped(screenStore, i),
    );
  }

  _onItemTapped(SelectedScreenStore screenStore, int newIndex) {
    screenStore.screen = newIndex;
  }
}
