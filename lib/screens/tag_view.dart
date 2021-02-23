import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tag.dart';
import '../utils/dialogs.dart';
import '../utils/paginators.dart';
import '../utils/store.dart';
import '../utils/widgets.dart';



class TagViewPage extends StatefulWidget {
  @override
  TagViewState createState() => TagViewState();
}


class TagViewState extends State<TagViewPage> {
  Future future;
  Tag shortItem;
  LimitOffsetPaginator paginator;

  @override
  Widget build(BuildContext context) {
    final ItemWithPaginator pair = ModalRoute.of(context).settings.arguments;
    shortItem = pair.item;
    paginator = pair.paginator;

    if (future == null) {
      future = paginator.repo.getDetail(shortItem);
    }

    retry() async => setState(() {
      future = paginator.repo.getDetail(shortItem);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: shortItem.icon != null ? Text(shortItem.icon) : null,
              title: Text(shortItem.name),
            ),
            body: const BodyLoading(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: shortItem.icon != null ? Text(shortItem.icon) : null,
              title: Text(shortItem.name),
            ),
            body: RetryBody(retry),
          );
        }

        return TagViewLoadedPage(
          tag: snapshot.data as Tag,
          paginator: paginator,
          refresh: retry,
        );
      },
    );
  }
}


class TagViewLoadedPage extends StatelessWidget {
  final Tag tag;
  final LimitOffsetPaginator paginator;
  final Future<void> Function() refresh;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TagViewLoadedPage({this.tag, this.paginator, this.refresh, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: tag,
      child: Consumer<Tag>(
        builder: (context, _, __) => Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: tag.icon != null ? Text(tag.icon) : null,
            title: Text(tag.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _edit(context),
              ),
              PopupMenuButton(
                onSelected: (action) => action(context),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _changeLike,
                    child: tag.like ? const Text('Дизлайк')
                        : const Text('Лайк'),
                  ),
                  PopupMenuItem(
                    value: _delete,
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: tag.values.length * 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return TagInfo(tag: tag);
                }

                if (index.isEven) {
                  return Divider();
                }

                final value = tag.values[(index - 1) ~/ 2];
                return TagValueListItem(value: value);
              },
            ),
          ),
          floatingActionButton: FloatingButton(),
        ),
      ),
    );
  }

  _edit(BuildContext context) {
    Navigator.of(context).pushNamed('/tag/edit', arguments: tag);
  }

  _changeLike(BuildContext context) async {
    _showLoadingSnackBar();
    try {
      await paginator.repo.updateItem(tag, {'like': !tag.like});
      tag.update(like: !tag.like);
    } on Exception {
      _showErrorSnackBar(() => _changeLike(context));
      return;
    }

    _showSuccessSnackBar();
  }

  _delete(BuildContext context) async {
    final confirm = await showConfirmDialog(context, 'Удалить метку?', tag.name);

    if (!confirm) {
      return;
    }

    _showLoadingSnackBar();
    try {
      await paginator.deleteItem(tag);
    } on Exception {
      _showErrorSnackBar(() => _delete(context));
      return;
    }

    await Navigator.of(context).pop();
  }

  _showLoadingSnackBar() {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.fixed,
        content: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(),
            ),
            const SizedBox(width: 25),
            const Text('грузим...'),
          ],
        ),
      ),
    );
  }

  _showErrorSnackBar(VoidCallback retry) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.fixed,
        content: const Text('Ашипка!'),
        action: SnackBarAction(
          label: 'Повторить',
          onPressed: retry,
        ),
      ),
    );
  }

  _showSuccessSnackBar() {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.fixed,
        content: Row(
          children: [
            const Icon(Icons.check),
            const Text('Загружено!'),
          ],
        ),
      ),
    );
  }
}


class TagInfo extends StatelessWidget {
  final Tag tag;

  TagInfo({this.tag, Key key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    final createdAtFormatted = dateFormatter.format(tag.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: const TextStyle(fontSize: 20, height: 1.5),
                  children: [
                    const TextSpan(text: 'Метка: ', style: TextStyle(color: Colors.grey)),
                    TextSpan(text: tag.name),
                    const TextSpan(text: '\nСоздана: ', style: TextStyle(color: Colors.grey)),
                    TextSpan(text: createdAtFormatted),
                    const TextSpan(text: '\nЦвет: ', style: TextStyle(color: Colors.grey)),
                    TextSpan(text: tag.color.toString()),
                    // TODO: badges
                    const TextSpan(text: '\nТипы целей: ', style: TextStyle(color: Colors.grey)),
                    TextSpan(text: tag.targetType.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 20, color: Colors.white),
      ],
    );
  }
}


class TagValueListItem extends StatelessWidget {
  final TagValue value;

  TagValueListItem({this.value, Key key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ObjectKey(value),
      leading: value.icon != null ? Text(value.icon) : null,
      title: Text(value.name),
    );
  }
}


class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        // TODO: добавление значений
      },
    );
  }
}
