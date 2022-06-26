import 'package:flutter/foundation.dart';

import '../base_model.dart';

class ImportedResource extends BaseModel {
  String name;
  String? description;
  bool isIgnored;
  final DateTime createdAt;
  String type;
  Map<String, dynamic> typeSpecific;

  ImportedResource({
    required int id,
    required this.name,
    this.description,
    required this.isIgnored,
    required this.createdAt,
    required this.type,
    required this.typeSpecific,
  }) : super(id: id);

  void update({
    bool? isIgnored,
    String? name,
    String? description,
    Map<String, dynamic>? typeSpecific,
  }) {
    var changed = false;

    if (isIgnored != null && this.isIgnored != isIgnored) {
      this.isIgnored = isIgnored;
      changed = true;
    }

    if (name != null && this.name != name) {
      this.name = name;
      changed = true;
    }

    if (description != null && this.description != description) {
      this.description = description;
      changed = true;
    }

    if (typeSpecific != null && mapEquals(this.typeSpecific, typeSpecific)) {
      this.typeSpecific = typeSpecific;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void updateFrom(covariant ImportedResource other) {
    update(
      isIgnored: other.isIgnored,
      name: other.name,
      description: other.description,
      typeSpecific: other.typeSpecific,
    );
  }
}
