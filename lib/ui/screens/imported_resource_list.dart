import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();

  ImportedResourceListPage(this.sideMenuTap, Key? key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? menu;
    if (sideMenuTap != null) {
      menu = IconButton(
        icon: const Icon(Icons.menu),
        onPressed: sideMenuTap,
      );
    }
    var actions = <Widget>[];
    if (context.read<Config>().isLinux) {
      actions = [
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () {
            final paginator = context.read<ImportedResourcePaginator>();
            paginator.reset();
            paginator.fetchNext();
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ];
    }

    return ChangeNotifierProxyProvider<ImportedResourceRepo, ImportedResourcePaginator>(
      create: (context) => ImportedResourcePaginator(),
      update: (context, repo, prev) {
        if (prev!.repo != repo) {
          prev.repo = repo;
          prev.reset();
        }
        return prev;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Импортированные ресурсы'),
          leading: menu,
          actions: actions,
        ),
        body: SafeArea(
          child: PaginatedListView<ImportedResource>(
            (context, item) => ImportedResourceListItem(
              importedResource: item,
              key: ObjectKey(item),
            ),
            _scrollController,
          ),
        ),
        endDrawer: Drawer(
          child: ImportedResourceFilter(),
        ),
      ),
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
        builder: (context, changedItem, _) {
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

          return ListTile(
            leading: typeMap[changedItem.type],
            title: Text(changedItem.name),
            subtitle: Text(changedItem.description ?? ''),
            trailing: trailing,
            onTap: _openItem,
          );
        },
      ),
    );

    final _actions = [
      ItemAction('Создать ресурс', Icons.add, Colors.green, _createResource),
      ItemAction('Изменить', Icons.edit, Colors.blue, _editItem),
      ItemAction('Удалить', Icons.delete, Colors.red, _deleteItem),
    ];
    return wrapActions(context, wrappedItem, _actions);
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
  bool? _ignore;

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
