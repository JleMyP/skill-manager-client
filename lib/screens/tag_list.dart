import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/tag.dart';
import '../repos/tag.dart';
import '../utils/dialogs.dart';
import '../utils/paginators.dart';
import '../utils/store.dart';
import '../utils/widgets.dart';


class TagListPage extends StatefulWidget {
  static const name = 'tag_list_page';

  final Function sideMenuTap;

  TagListPage(this.sideMenuTap, GlobalKey key) : super(key: key);

  @override
  TagListState createState() => TagListState();
}


class TagListState extends State<TagListPage> {
  ButtonState bs;

  @override
  void initState() {
    super.initState();
    bs = ButtonState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>.value(
      value: bs,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Метки'),
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: widget.sideMenuTap,
            ),
          ),
          body: SafeArea(
            child: Body(),
          ),
          endDrawer: Drawer(
            child: TagFilter(),
          ),
          floatingActionButton: context.watch<ButtonState>().show ? FloatingButton() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
  final ScrollController _scrollController = ScrollController();
  LimitOffsetPaginator<TagRepo, Tag> paginator;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    var repo = context.read<TagRepo>();
    paginator = LimitOffsetPaginator<TagRepo, Tag>.withRepo(repo);
    paginator.fetchNext(notifyStart: false);
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

  Widget _buildListItem(BuildContext context, dynamic _item) {
    var item = _item as Tag;

    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      child: ChangeNotifierProvider<Tag>.value(
        value: item,
        child: Builder(
          builder: (context) {
            var changedItem = context.watch<Tag>();
            return ListTile(
              leading: changedItem.icon != null ? Text(changedItem.icon) : null,
              title: Text(changedItem.name),
              trailing: IconButton(
                icon: changedItem.like ? Icon(Icons.favorite, color: Colors.red) : Icon(Icons.favorite_border),
                onPressed: () async => await _changeLike(changedItem),
              ),
              onTap: () async => await _openItem(changedItem),
            );
          },
        ),
      ),
      actions: [
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

  _handleScroll() {
    var buttonState = context.read<ButtonState>();

    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      buttonState.show = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      buttonState.show = true;
    }
  }

  _changeLike(Tag item) async {
    var repo = context.read<TagRepo>();
    await repo.updateItem(item, {'like': !item.like});
    // TODO: отлов ошибок
    item.update(like: !item.like);
  }

  _openItem(Tag item) async {
    var repo = context.read<TagRepo>();
    var detailed = await repo.getDetail(item);
    // await Navigator.of(context).pushNamed('/tag/view', arguments: detailed);
  }

  _editItem(Tag item) async {
    // await Navigator.of(context).pushNamed('/tag/edit', arguments: item);
  }

  _deleteItem(Tag item) async {
    var confirm = await showConfirmDialog(context, 'Удалить метку?', item.name);

    if (!confirm) {
      return;
    }

    var paginator = context.read<LimitOffsetPaginator<TagRepo, Tag>>();
    await paginator.deleteItem(item);
  }
}


class TagFilter extends StatefulWidget {
  @override
  TagFilterState createState() => TagFilterState();
}


class TagFilterState extends State<TagFilter> {
  final _formKey = GlobalKey<FormState>();

  int like = 0;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Фильтры меток', style: TextStyle(fontSize: 20)),
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Лайк'),
              value: like,
              onChanged: (newVal) => setState(() => like = newVal),
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Да'),
                ),
                DropdownMenuItem(
                  value: -1,
                  child: Text('Нет'),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text('Пофиг'),
                ),
              ],
            ),
            RaisedButton(
              child: Text('Сохранить'),
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
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () => Navigator.of(context).pushNamed('/tag/create'),
    );
  }
}
