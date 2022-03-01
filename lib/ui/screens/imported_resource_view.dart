import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../data/models/imported_resource.dart';
import '../../data/paginators.dart';
import '../store.dart';
import '../webview.dart';
import '../widgets.dart';


class ImportedResourceViewPage extends StatefulWidget {
  @override
  ImportedResourceViewState createState() => ImportedResourceViewState();
}


class ImportedResourceViewState extends State<ImportedResourceViewPage> {
  Future? future;
  late ImportedResource shortItem;

  @override
  Widget build(BuildContext context) {
    final pair = ModalRoute.of(context)!.settings.arguments as ItemWithPaginator;
    shortItem = pair.item as ImportedResource;
    final paginator = pair.paginator as LimitOffsetPaginator<ImportedResource>;

    if (future == null) {
      if (!pair.shouldFetch) {
        future = Future.value(shortItem);
      } else {
        // TODO: обновлять существующий
        future = paginator.repo.getDetail(shortItem);
      }
    }

    retry() async => setState(() {
      // TODO: обновлять существующий
      future = paginator.repo.getDetail(shortItem);
    });

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(shortItem.name),
            ),
            body: const BodyLoading(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(shortItem.name),
            ),
            body: RetryBody(retry),
          );
        }

        return ImportedResourceViewLoadedPage(
          importedResource: snapshot.data as ImportedResource,
          refresh: retry,
        );
      },
    );
  }
}


class ImportedResourceViewLoadedPage extends StatelessWidget {
  final ImportedResource importedResource;
  final Future<void> Function() refresh;

  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  ImportedResourceViewLoadedPage({
    required this.importedResource,
    required this.refresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: вывести остальные поля: дата, игнор, языки, топики, ссыль, дом ссыль
    return ChangeNotifierProvider.value(
      value: importedResource,
      child: Consumer<ImportedResource>(
        builder: (context, _, __) => ScaffoldMessenger(
          key: _scaffoldKey,
          child: Scaffold(
            appBar: AppBar(
              title: Text(importedResource.name),
              actions: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _edit(context),
                ),
                PopupMenuButton(
                  onSelected: (action) => (action as Function)(context),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _ignore,
                      child: const Text('Заигнорить'),
                    ),
                    PopupMenuItem(
                      value: _unignore,
                      child: const Text('Разигнорить'),
                    ),
                    PopupMenuItem(
                      value: _createResource,
                      child: const Text('Создать ресурс'),
                    ),
                    PopupMenuItem(
                      value: _delete,
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: _buildItemBody(context),
            ),
          ),
        ),
      ),
    );
  }

  _buildItemBody(BuildContext context) {
    String? content = importedResource.typeSpecific['readme'];

    if (content == null || content == '') {
      return Text(importedResource.description ?? '');
    }
    return Markdown(
      data: content,
      onTapLink: (text, href, title) {
        if (!href!.startsWith('#')) openWeb(context, href);
      },
    );
  }

  _edit(BuildContext context) async {
    await Navigator.of(context).pushNamed('/imported_resource/edit', arguments: importedResource);
  }

  _ignore(BuildContext context) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _unignore(BuildContext context) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _createResource(BuildContext context) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _delete(BuildContext context) async {
    // TODO: спросить, грохнуть, грохнуть из пагинатора
  }
}
