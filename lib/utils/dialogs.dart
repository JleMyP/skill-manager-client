import 'package:flutter/material.dart';


Future<void> showSimpleDialog(BuildContext parentContext, String title,
    String content) async {
  await showDialog(
    context: parentContext,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        ElevatedButton(
          child: const Text('ОК'),
          onPressed: () => Navigator.of(parentContext).pop(),
        ),
      ],
    ),
  );
}


Future<bool> showConfirmDialog(BuildContext parentContext, String title,
    String content) async {
  return await showDialog(
    context: parentContext,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        ElevatedButton(
          child: const Text('Нет'),
          onPressed: () => Navigator.of(parentContext).pop(false),
        ),
        ElevatedButton(
          child: const Text('Да'),
          onPressed: () => Navigator.of(parentContext).pop(true),
        ),
      ],
    ),
  );
}
