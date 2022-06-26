import 'package:flutter/foundation.dart';

abstract class BaseModel extends ChangeNotifier {
  final int id;
  bool isDetailLoaded;

  BaseModel({required this.id, this.isDetailLoaded = false});

  void updateFrom(BaseModel other);
}
