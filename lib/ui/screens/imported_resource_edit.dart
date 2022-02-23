import 'package:flutter/material.dart';

import '../../data/models/imported_resource.dart';


class ImportedResourceEditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as ImportedResource;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: SafeArea(
        child: Text(item.description ?? ''),
      ),
    );
  }
}
