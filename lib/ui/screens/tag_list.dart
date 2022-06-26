import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../data/config.dart';
import '../../data/models/tag.dart';
import '../../data/paginators.dart';
import '../../data/repos/tag.dart';
import '../dialogs.dart';
import '../store.dart';
import '../widgets.dart';

typedef TagPaginator = LimitOffsetPaginator<Tag>;

class TagListPage extends StatelessWidget {
  static const name = 'tag_list_page';

  final VoidCallback? sideMenuTap;

  TagListPage(this.sideMenuTap, Key? key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? menu;
    if (sideMenuTap != null) {
      menu = IconButton(
        icon: const Icon(Icons.menu),
        onPressed: sideMenuTap,
      );
    }

    final isLinux = context.read<Config>().isLinux;
    var actions = <Widget>[];
    if (isLinux) {
      actions = [
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () {
            final paginator = context.read<TagPaginator>();
            paginator.reset();
            paginator.fetchNext();
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => Navigator.of(context).pushNamed('/tag/create'),
        ),
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ];
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ButtonState>(
          create: (context) => ButtonState(),
        ),
        ChangeNotifierProxyProvider<TagRepo, TagPaginator>(
          create: (context) => TagPaginator(),
          update: (context, repo, prev) {
            if (prev!.repo != repo) {
              prev.repo = repo;
              prev.reset();
            }
            return prev;
          },
        ),
      ],
      child: Consumer<ButtonState>(
        child: Body(),
        builder: (context, buttonState, child) {
          final showButton = buttonState.show && !isLinux;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Метки'),
              leading: menu,
              actions: actions,
            ),
            body: SafeArea(
              child: child!,
            ),
            endDrawer: Drawer(
              child: TagFilter(),
            ),
            floatingActionButton: showButton ? FloatingButton() : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }
}

class Body extends StatefulWidget {
  @override
  BodyState createState() => BodyState();
}

class BodyState extends State<Body> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<Tag>(
      (context, item) => TagListItem(
        tag: item,
        key: ObjectKey(item),
      ),
      _scrollController,
    );
  }

  _handleScroll() {
    if (context.read<Config>().isLinux) {
      return;
    }

    final buttonState = context.read<ButtonState>();

    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      buttonState.show = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      buttonState.show = true;
    }
  }
}

class TagListItem extends StatefulWidget {
  final Tag tag;

  TagListItem({
    required this.tag,
    Key? key,
  }) : super(key: key);

  @override
  State<TagListItem> createState() => TagListItemState();
}

class TagListItemState extends State<TagListItem> {
  bool _isLikeLoading = false;

  @override
  Widget build(BuildContext context) {
    final wrappedItem = ChangeNotifierProvider<Tag>.value(
      value: widget.tag,
      child: Consumer<Tag>(
        builder: (context, item, _) {
          Widget trailing;
          if (_isLikeLoading) {
            trailing = const CircularProgressIndicator();
          } else {
            trailing = IconButton(
              icon: item.like
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : const Icon(Icons.favorite_border),
              onPressed: _changeLike,
            );
          }

          return ListTile(
            leading: item.icon != null ? Text(item.icon!) : null,
            title: Text(item.name),
            trailing: trailing,
            onTap: _openItem,
          );
        },
      ),
    );

    final _actions = [
      ItemAction('Изменить', Icons.edit, Colors.blue, _editItem),
      ItemAction('Удалить', Icons.delete, Colors.red, _deleteItem),
    ];
    return wrapActions(context, wrappedItem, _actions);
  }

  _changeLike() async {
    setState(() {
      _isLikeLoading = true;
    });

    final repo = context.read<TagRepo>();
    try {
      await repo.updateItem(widget.tag, {'like': !widget.tag.like});
      _isLikeLoading = false;
    } on Exception {
      ScaffoldMessenger.of(context).showSnackBar(
        createErrorSnackBar(_changeLike),
      );
      setState(() {
        _isLikeLoading = false;
      });
    }
  }

  _openItem() async {
    final paginator = context.read<TagPaginator>();
    await Navigator.of(context).pushNamed(
      '/tag/view',
      arguments: ItemWithPaginator(
        paginator: paginator,
        item: widget.tag,
        shouldFetch: false,
      ),
    );
  }

  _editItem(BuildContext context) async {
    // await Navigator.of(context).pushNamed('/tag/edit', arguments: widget.tag);
  }

  _deleteItem(BuildContext context) async {
    final confirm = await showConfirmDialog(context, 'Удалить метку?', widget.tag.name);

    if (!confirm) {
      return;
    }

    final paginator = context.read<TagPaginator>();
    await paginator.deleteItem(widget.tag);
  }
}

class TagFilter extends StatefulWidget {
  @override
  TagFilterState createState() => TagFilterState();
}

class TagFilterState extends State<TagFilter> {
  final _formKey = GlobalKey<FormState>();
  bool? _like;

  @override
  void initState() {
    super.initState();
    final paginator = context.read<TagPaginator>();
    _like = paginator.params?['like'] ?? null;
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
                    decoration: const InputDecoration(labelText: 'Лайк'),
                    value: _like,
                    onChanged: (newVal) => setState(() => _like = newVal),
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
                if (_like != null) params['like'] = _like;
                final paginator = context.read<TagPaginator>();
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

class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).pushNamed('/tag/create'),
      );
}
