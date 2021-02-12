import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/imported_resource.dart';
import '../utils/web.dart';


class ImportedResourceViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ImportedResource item = ModalRoute.of(context).settings.arguments;
    String content = item.typeSpecific['readme'];
    Widget child;
    if (content == null) {
      child = Text(item.description);
    } else {
      child = Markdown(
        data: content,
        onTapLink: (text, href, title) {
          if (!href.startsWith('#')) openWeb(context, href);
        },
      );
    }

    // TODO: вывести остальные поля: дата, игнор, языки, топики, ссыль, дом ссыль

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _edit(context, item),
          ),
          PopupMenuButton(
            onSelected: (action) => action(item),
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
        child: child,
      ),
    );
  }

  _edit(BuildContext context, ImportedResource item) async {
    await Navigator.of(context).pushNamed('/imported_resource/edit', arguments: item);
  }

  _ignore(ImportedResource item) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _unignore(ImportedResource item) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _createResource(ImportedResource item) async {
    // TODO: обновить удаленно, обновить пагинатор
  }

  _delete(ImportedResource item) async {
    // TODO: спросить, грохнуть, грохнуть из пагинатора
  }
}
