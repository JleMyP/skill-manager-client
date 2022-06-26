import 'package:flutter/foundation.dart';

import '../base_model.dart';


class TagValue extends BaseModel {
  String name;
  int orderNum;
  final DateTime createdAt;
  String? icon;
  bool isDefault;

  TagValue({
    required id,
    required this.name,
    required this.orderNum,
    required this.createdAt,
    this.icon,
    required this.isDefault,
  }): super(id: id, isDetailLoaded: true);

  void update({String? name, int? orderNum, String? icon, bool? isDefault}) {
    var changed = false;

    if (name != null && this.name != name) {
      this.name = name;
      changed = true;
    }

    if (orderNum != null && this.orderNum != orderNum) {
      this.orderNum = orderNum;
      changed = true;
    }

    if (icon != null && this.icon != icon) {
      this.icon = icon;
      changed = true;
    }

    if (isDefault != null && this.isDefault != isDefault) {
      this.isDefault = isDefault;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void updateFrom(covariant TagValue other) {
    update(
      name: other.name,
      orderNum: other.orderNum,
      icon: other.icon,
      isDefault: other.isDefault,
    );
  }
}


class Tag extends BaseModel {
  String name;
  int orderNum;
  bool like;
  final DateTime createdAt;
  String? icon;
  int? color;
  int targetType;
  List<TagValue> values;

  Tag({
    required int id,
    required this.name,
    required this.orderNum,
    required this.like,
    required this.createdAt,
    this.icon,
    this.color,
    required this.targetType,
    required this.values,
  }): super(id: id, isDetailLoaded: true);

  void update({
    String? name,
    int? orderNum,
    bool? like,
    String? icon,
    int? color,
    int? targetType,
    List<TagValue>? values,
  }) {
    var changed = false;

    if (name != null && this.name != name) {
      this.name = name;
      changed = true;
    }

    if (orderNum != null && this.orderNum != orderNum) {
      this.orderNum = orderNum;
      changed = true;
    }

    if (like != null && this.like != like) {
      this.like = like;
      changed = true;
    }

    if (icon != null && this.icon != icon) {
      this.icon = icon;
      changed = true;
    }

    if (color != null && this.color != color) {
      this.color = color;
      changed = true;
    }

    if (targetType != null && this.targetType != targetType) {
      this.targetType = targetType;
      changed = true;
    }

    if (values != null && listEquals(this.values, values)) {
      this.values = values;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void updateFrom(covariant Tag other) {
    update(
      name: other.name,
      orderNum: other.orderNum,
      like: other.like,
      icon: other.icon,
      color: other.color,
      targetType: other.targetType,
      values: other.values,
    );
  }
}
