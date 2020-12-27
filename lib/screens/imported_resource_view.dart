import 'package:flutter/material.dart';
import '../models/imported_resource.dart';


class ImportedResourceViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ImportedResource item = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: SafeArea(
        child: Text(item.description),
      ),
    );
  }
}
