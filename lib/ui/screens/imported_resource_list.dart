import 'dart:io' show Platform;

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/models/imported_resource.dart';
import '../../data/paginators.dart';
import '../../data/repos/imported_resources.dart';
import '../dialogs.dart';
import '../store.dart';
import '../widgets.dart';


final _github = SvgPicture.asset(
  'assets/github-logo.svg',
  width: 30,
  alignment: Alignment.centerLeft,
  color: Colors.grey,
);

final typeMap = {
  'ImportedResourceRepo': _github,
};


class ImportedResourceListPage extends StatefulWidget {
  static const name = 'imported_resource_list_page';

  final VoidCallback? sideMenuTap;

  ImportedResourceListPage(this.sideMenuTap, GlobalKey key) : super(key: key);

  @override
  ImportedResourceListState createState() => ImportedResourceListState();
}


class ImportedResourceListState extends State<ImportedResourceListPage> {
  late SelectedScreenStore _screenStore;
  late BottomBarState _barState;

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
            leading: widget.sideMenuTap != null ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.sideMenuTap,
            ) : null,
          ),
          body: SafeArea(
            child: child!,
          ),
          endDrawer: Drawer(
            child: ImportedResourceFilter(),
          ),
          // bottomNavigationBar: bs.show ? ConvexBottomBar() : null,
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
  int? _prevScreen;
  late LimitOffsetPaginator<ImportedResource> _paginator;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    final repo = context.read<ImportedResourceRepo>();
    _paginator = LimitOffsetPaginator<ImportedResource>(repo: repo)
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

  Widget _buildListItem(BuildContext context, ImportedResource item) {
    return ImportedResourceListItem(
      importedResource: item,
      paginator: _paginator,
      key: ObjectKey(item),
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
}


class ImportedResourceListItem extends StatefulWidget {
  final ImportedResource importedResource;
  final LimitOffsetPaginator<ImportedResource> paginator;

  ImportedResourceListItem({
    required this.importedResource,
    required this.paginator,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportedResourceListItem> createState() => ImportedResourceListItemState();
}


class ImportedResourceListItemState extends State<ImportedResourceListItem> {
  bool _isIgnoreLoading = false;

  @override
  Widget build(BuildContext context) {
    final wrappedItem = ChangeNotifierProvider<ImportedResource>.value(
      value: widget.importedResource,
      child: Consumer<ImportedResource>(
        builder: (context, changedItem, child) {
          Widget trailing;
          if (_isIgnoreLoading) {
            trailing = const CircularProgressIndicator();
          } else {
            trailing = IconButton(
              icon: Icon(changedItem.isIgnored ? Icons.visibility_off : Icons.visibility),
              color: Colors.grey,
              onPressed: _changeIgnore,
              tooltip: changedItem.isIgnored ? 'Разигнорить' : 'Заигнорить',
            );
          }

          final tile = ListTile(
            leading: typeMap[changedItem.type],
            title: Text(changedItem.name),
            subtitle: Text(changedItem.description ?? ''),
            trailing: trailing,
            onTap: _openItem,
          );

          if (!Platform.isLinux) {
            return tile;
          }

          return Listener(
            child: tile,
            onPointerDown: (event) async {
              if (event.kind != PointerDeviceKind.mouse ||
                  event.buttons != kSecondaryMouseButton) {
                return;
              }

              final overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
              final menuItem = await showMenu(
                context: context,
                items: [
                  PopupMenuItem(child: Text('Создать ресурс'), value: _createResource),
                  PopupMenuItem(child: Text('Изменить'), value: _editItem),
                  PopupMenuItem(child: Text('Удалить'), value: _deleteItem),
                ],
                position: RelativeRect.fromSize(event.position & Size(48.0, 48.0), overlay.size),
              );
              if (menuItem != null) {
                menuItem(context);
              }
            }
            );
        },
      ),
    );

    if (Platform.isLinux) {
      return wrappedItem;
    }

    return Slidable(
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            label: 'Создать \nресурс',
            backgroundColor: Colors.green,
            icon: Icons.add,
            onPressed: _createResource,
          ),
          SlidableAction(
            label: 'Изменить',
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            onPressed: _editItem,
          ),
          SlidableAction(
            label: 'Удалить',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: _deleteItem,
          ),
        ],
      ),
      child: wrappedItem,
    );
  }

  _createResource(BuildContext context) async {
    // await
  }

  _openItem() async {
    await Navigator.of(context).pushNamed('/imported_resource/view', arguments: ItemWithPaginator(
      paginator: widget.paginator,
      item: widget.importedResource,
    ));
  }

  _editItem(BuildContext context) {
    Navigator.of(context).pushNamed('/imported_resource/edit', arguments: widget.importedResource);
  }

  _deleteItem(BuildContext context) async {
    final confirm = await showConfirmDialog(context, 'Удалить импортированный ресурс?', widget.importedResource.name);
    if (!confirm) {
      return;
    }

    await widget.paginator.deleteItem(widget.importedResource);
  }

  _changeIgnore() async {
    setState(() {
      _isIgnoreLoading = true;
    });

    final item = widget.importedResource;
    final repo = context.read<ImportedResourceRepo>();
    try {
      await repo.updateItem(item, {'is_ignored': !item.isIgnored});
      item.update(isIgnored: !item.isIgnored);
      _isIgnoreLoading = false;
    } on Exception {
      ScaffoldMessenger.of(context).showSnackBar(
        createErrorSnackBar(_changeIgnore),
      );
      setState(() {
        _isIgnoreLoading = false;
      });
    }
  }
}

// unused
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


class ImportedResourceFilter extends StatefulWidget {
  @override
  ImportedResourceFilterState createState() => ImportedResourceFilterState();
}


class ImportedResourceFilterState extends State<ImportedResourceFilter> {
  final _formKey = GlobalKey<FormState>();
  int _ignore = 0;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  DrawerHeader(
                    child: const Text('Фильтры', style: TextStyle(fontSize: 20)),
                  ),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Игнор'),
                    value: _ignore,
                    onChanged: (newVal) => setState(() => _ignore = newVal!),
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: const Text('Да'),
                      ),
                      DropdownMenuItem(
                        value: -1,
                        child: const Text('Нет'),
                      ),
                      DropdownMenuItem(
                        value: 0,
                        child: const Text('Пофиг'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text('Применить'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
