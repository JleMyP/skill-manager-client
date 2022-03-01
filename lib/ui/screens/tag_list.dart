import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../data/config.dart';
import '../../data/models/tag.dart';
import '../../data/paginators.dart';
import '../../data/repos/tag.dart';
import '../dialogs.dart';
import '../store.dart';
import '../widgets.dart';


class TagListPage extends StatelessWidget {
  static const name = 'tag_list_page';

  final VoidCallback? sideMenuTap;

  TagListPage(this.sideMenuTap, GlobalKey key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (context) => ButtonState(),
      child: Consumer<ButtonState>(
        child: Body(),
        builder: (context, buttonState, child) {
          Widget? menu;
          if (sideMenuTap != null) {
            menu = IconButton(
              icon: const Icon(Icons.menu),
              onPressed: sideMenuTap,
            );
          }
          final isLinux = context.read<Config>().isLinux;
          final showButton = buttonState.show && !isLinux;
          var actions = <Widget>[];
          if (isLinux) {
            actions = [
              IconButton(
                icon: Icon(Icons.replay),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => Navigator.of(context).pushNamed('/tag/create'),
              ),
              Builder(builder: (context) => IconButton(
                icon: Icon(Icons.filter_alt_outlined),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              )),
            ];
          }

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
  late LimitOffsetPaginator<Tag> paginator;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    final repo = context.read<TagRepo>();
    paginator = LimitOffsetPaginator<Tag>(repo: repo)
      ..fetchNext(notifyStart: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedListView(paginator, _buildListItem, _scrollController);
  }

  Widget _buildListItem(BuildContext context, Tag item) {
    return TagListItem(
      tag: item,
      paginator: paginator,
      key: ObjectKey(item),
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
  final LimitOffsetPaginator<Tag> paginator;

  TagListItem({
    required this.tag,
    required this.paginator,
    Key? key,
  }) : super(key: key);

  @override
  State<TagListItem> createState() => TagListItemState();
}


class TagListItemState extends State<TagListItem> {
  bool _isLikeLoading = false;

  @override
  Widget build(BuildContext context) {
    // TODO: переусложение - смешивание прослушивания объекта и стейта виджета
    //  вариант рещения - обертка вокруг Tag, включающая isLoading
    return Slidable(
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
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
      child: ChangeNotifierProvider<Tag>.value(
        value: widget.tag,
        child: Consumer<Tag>(
          builder: (_, __, ___) {
            Widget trailing;
            if (_isLikeLoading) {
              trailing = const CircularProgressIndicator();
            } else {
              trailing = IconButton(
                icon: widget.tag.like ? const Icon(Icons.favorite, color: Colors.red)
                    : const Icon(Icons.favorite_border),
                onPressed: _changeLike,
              );
            }

            // TODO: не ловит изменения из страницы просмотра
            return ListTile(
              leading: widget.tag.icon != null ? Text(widget.tag.icon!) : null,
              title: Text(widget.tag.name),
              trailing: trailing,
              onTap: _openItem,
            );
          },
        ),
      ),
    );
  }

  _changeLike() async {
    setState(() {
      _isLikeLoading = true;
    });

    final repo = context.read<TagRepo>();
    try {
      await repo.updateItem(widget.tag, {'like': !widget.tag.like});
      widget.tag.update(like: !widget.tag.like);
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
    await Navigator.of(context).pushNamed('/tag/view', arguments: ItemWithPaginator(
      paginator: widget.paginator,
      item: widget.tag,
      shouldFetch: false,
    ));
  }

  _editItem(BuildContext context) async {
    // await Navigator.of(context).pushNamed('/tag/edit', arguments: widget.tag);
  }

  _deleteItem(BuildContext context) async {
    final confirm = await showConfirmDialog(context, 'Удалить метку?', widget.tag.name);

    if (!confirm) {
      return;
    }

    await widget.paginator.deleteItem(widget.tag);
  }
}


class TagFilter extends StatefulWidget {
  @override
  TagFilterState createState() => TagFilterState();
}


class TagFilterState extends State<TagFilter> {
  final _formKey = GlobalKey<FormState>();
  int _like = 0;

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
                    child: const Text('Фильтры меток', style: TextStyle(fontSize: 20)),
                  ),
                  // TODO: bottomBar
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Лайк'),
                    value: _like,
                    onChanged: (newVal) => setState(() => _like = newVal!),
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


class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FloatingActionButton(
    child: const Icon(Icons.add),
    onPressed: () => Navigator.of(context).pushNamed('/tag/create'),
  );
}
