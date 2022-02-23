import '../base_model.dart';


class TagValue extends BaseModel {
  final String name;
  final int orderNum;
  final DateTime createdAt;
  final String? icon;
  final bool isDefault;

  TagValue({
    required id,
    required this.name,
    required this.orderNum,
    required this.createdAt,
    this.icon,
    required this.isDefault,
  }): super(id: id);
}


class Tag extends BaseModel {
  String name;
  int orderNum;
  bool like;
  DateTime createdAt;
  String? icon;
  int? color;
  int targetType;
  List<TagValue> values;

  Tag({
    id,
    required this.name,
    required this.orderNum,
    required this.like,
    required this.createdAt,
    this.icon,
    this.color,
    required this.targetType,
    required this.values,
  }): super(id: id);

  void update({bool? like}) {
    if (like != null && this.like != like) {
      this.like = like;
      notifyListeners();
    }
  }
}
