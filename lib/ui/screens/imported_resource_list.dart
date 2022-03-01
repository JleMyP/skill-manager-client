import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/config.dart';
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

typedef ImportedResourcePaginator = LimitOffsetPaginator<ImportedResource>;


class ImportedResourceListPage extends StatelessWidget {
  static const name = 'imported_resource_list_page';

  final VoidCallback? sideMenuTap;

  ImportedResourceListPage(this.sideMenuTap, GlobalKey key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  ChangeNotifierProxyProvider<ImportedResourceRepo, ImportedResourcePaginator>(
      create: (context) => ImportedResourcePaginator(),
      update: (context, repo, prev) {
        prev!.repo = repo;
        prev.fetchNext(notifyStart: false);
        return prev;
      },
      child: Builder(
        builder: (context) {
          final paginator = context.read<ImportedResourcePaginator>();

          Widget? menu;
          if (sideMenuTap != null) {
            menu = IconButton(
              icon: const Icon(Icons.menu),
              onPressed: sideMenuTap,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Импортированные ресурсы'),
              leading: menu,
            ),
            body: SafeArea(
              child: PaginatedListView(paginator, _buildListItem),
            ),
            endDrawer: Drawer(
              child: ImportedResourceFilter(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ImportedResource item) {
    return ImportedResourceListItem(
      importedResource: item,
      key: ObjectKey(item),
    );
  }
}


class ImportedResourceListItem extends StatefulWidget {
  final ImportedResource importedResource;

  ImportedResourceListItem({
    required this.importedResource,
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

          if (!context.read<Config>().isLinux) {
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

    if (context.read<Config>().isLinux) {
      return wrappedItem;
    }

    return Slidable(
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            backgroundColor: Colors.green,
            icon: Icons.add,
            onPressed: _createResource,
          ),
          SlidableAction(
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            onPressed: _editItem,
          ),
          SlidableAction(
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
    final paginator = context.read<ImportedResourcePaginator>();
    await Navigator.of(context).pushNamed(
      '/imported_resource/view',
      arguments: ItemWithPaginator(
        item: widget.importedResource,
        paginator: paginator,
      ),
    );
  }

  _editItem(BuildContext context) {
    Navigator.of(context).pushNamed('/imported_resource/edit', arguments: widget.importedResource);
  }

  _deleteItem(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      'Удалить импортированный ресурс?',
      widget.importedResource.name,
    );
    if (!confirm) {
      return;
    }

    final paginator = context.read<ImportedResourcePaginator>();
    // todo: try
    await paginator.deleteItem(widget.importedResource);
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


class ImportedResourceFilter extends StatefulWidget {
  @override
  ImportedResourceFilterState createState() => ImportedResourceFilterState();
}


class ImportedResourceFilterState extends State<ImportedResourceFilter> {
  final _formKey = GlobalKey<FormState>();
  bool? _ignore = false;

  @override
  void initState() {
    super.initState();
    final paginator = context.read<ImportedResourcePaginator>();
    _ignore = paginator.params?['is_ignored'] ?? null;
  }

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
                  DropdownButtonFormField<bool?>(
                    decoration: const InputDecoration(labelText: 'Игнор'),
                    value: _ignore,
                    onChanged: (newVal) => setState(() => _ignore = newVal),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: const Text('Да'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: const Text('Нет'),
                      ),
                      DropdownMenuItem(
                        value: null,
                        child: const Text('Пофиг'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text('Применить'),
              onPressed: () {
                final params = <String, dynamic>{};
                if (_ignore != null) params['is_ignored'] = _ignore;
                final paginator = context.read<ImportedResourcePaginator>();
                paginator.setParams(params);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
