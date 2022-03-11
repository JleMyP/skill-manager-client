import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/config.dart';
import '../../data/models/tag.dart';
import '../../data/paginators.dart';
import '../dialogs.dart';
import '../store.dart';
import '../widgets.dart';


class TagViewPage extends StatefulWidget {
  @override
  TagViewState createState() => TagViewState();
}


class TagViewState extends State<TagViewPage> {
  Future? future;

  @override
  Widget build(BuildContext context) {
    final pair = ModalRoute.of(context)!.settings.arguments as ItemWithPaginator;
    final shortItem = pair.item as Tag;

    if (future == null) {
      if (!pair.shouldFetch || shortItem.isDetailLoaded) {
        future = Future.value(shortItem);
      } else {
        // TODO: обновлять существующий
        future = pair.paginator.repo!.getDetail(shortItem);
      }
    }

    retry() async => setState(() {
      // TODO: обновлять существующий
      future = pair.paginator.repo!.getDetail(shortItem);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: shortItem.icon != null ? Text(shortItem.icon!) : null,
              title: Text(shortItem.name),
            ),
            body: const BodyLoading(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: shortItem.icon != null ? Text(shortItem.icon!) : null,
              title: Text(shortItem.name),
            ),
            body: RetryBody(retry),
          );
        }

        return TagViewLoadedPage(
          tag: snapshot.data as Tag,
          paginator: pair.paginator,
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

  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  TagViewLoadedPage({
    required this.tag,
    required this.paginator,
    required this.refresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: tag,
      child: Consumer<Tag>(
        builder: (context, _, __) => ScaffoldMessenger(
          key: _scaffoldKey,
          child: Scaffold(
            appBar: AppBar(
              leading: tag.icon != null ? Text(tag.icon!) : null,
              title: Text(tag.name),
              actions: [
                if (context.read<Config>().isLinux)
                  IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: refresh,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _edit(context),
                ),
                PopupMenuButton(
                  onSelected: (action) => (action as Function)(context),
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
                    return const Divider();
                  }

                  final value = tag.values[(index - 1) ~/ 2];
                  return TagValueListItem(value: value);
                },
              ),
            ),
            floatingActionButton: FloatingButton(),
          ),
        ),
      ),
    );
  }

  _edit(BuildContext context) {
    // TODO: а если лайк грузится?
    // Navigator.of(context).pushNamed('/tag/edit', arguments: tag);
  }

  _changeLike(BuildContext context) {
    doWithBars(
      _scaffoldKey.currentState!,
      () => paginator.repo!.updateItem(tag, {'like': !tag.like}),
      () => _changeLike(context),
    );
  }

  _delete(BuildContext context, {bool confirmed = false}) async {
    // TODO: а если лайк грузится?
    if (!confirmed) {
      final confirm = await showConfirmDialog(context, 'Удалить метку?', tag.name);

      if (!confirm) {
        return;
      }
    }

    await doWithBars(
      _scaffoldKey.currentState!,
      () async {
        await paginator.deleteItem(tag);
        Navigator.of(context).pop();
      },
      () => _delete(context, confirmed: true),
    );
  }
}


class TagInfo extends StatelessWidget {
  final Tag tag;

  TagInfo({required this.tag, Key? key}): super(key: key);

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

  TagValueListItem({required this.value, Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ObjectKey(value),
      leading: value.icon != null ? Text(value.icon!) : null,
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
