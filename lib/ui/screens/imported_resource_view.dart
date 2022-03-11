import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../data/config.dart';
import '../../data/models/imported_resource.dart';
import '../../data/paginators.dart';
import '../dialogs.dart';
import '../store.dart';
import '../webview.dart';
import '../widgets.dart';


class ImportedResourceViewPage extends StatefulWidget {
  @override
  ImportedResourceViewState createState() => ImportedResourceViewState();
}


class ImportedResourceViewState extends State<ImportedResourceViewPage> {
  Future? future;

  @override
  Widget build(BuildContext context) {
    final pair = ModalRoute.of(context)!.settings.arguments as ItemWithPaginator;
    final shortItem = pair.item as ImportedResource;

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
          paginator: pair.paginator,
          refresh: retry,
        );
      },
    );
  }
}


class ImportedResourceViewLoadedPage extends StatelessWidget {
  final ImportedResource importedResource;
  final LimitOffsetPaginator paginator;
  final Future<void> Function() refresh;

  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  ImportedResourceViewLoadedPage({
    required this.importedResource,
    required this.paginator,
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
                if (context.read<Config>().isLinux)
                  IconButton(
                    icon: Icon(Icons.replay),
                    onPressed: refresh,
                  ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _edit(context),
                ),
                PopupMenuButton(
                  onSelected: (action) => (action as Function)(context),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _changeIgnore,
                      child: importedResource.isIgnored ? const Text('Разигнорить')
                        : const Text('Заигнорить'),
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
    // TODO: а если игнор грузится?
    // await Navigator.of(context).pushNamed('/imported_resource/edit', arguments: importedResource);
  }

  _changeIgnore(BuildContext context) async {
    doWithBars(
      _scaffoldKey.currentState!,
      () => paginator.repo!.updateItem(importedResource, {'is_ignored': !importedResource.isIgnored}),
      () => _changeIgnore(context),
    );
  }

  _createResource(BuildContext context) async {
    // TODO
  }

  _delete(BuildContext context, {bool confirmed = false}) async {
    // TODO: а если игнор грузится?
    if (!confirmed) {
      final confirm = await showConfirmDialog(context, 'Удалить метку?', importedResource.name);

      if (!confirm) {
        return;
      }
    }

    await doWithBars(
      _scaffoldKey.currentState!,
      () async {
        await paginator.deleteItem(importedResource);
        Navigator.of(context).pop();
      },
      () => _delete(context, confirmed: true),
    );
  }
}
