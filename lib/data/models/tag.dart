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

  void updateFrom(BaseModel other) {
    other as TagValue;
    name = other.name;
    orderNum = other.orderNum;
    icon = other.icon;
    isDefault = other.isDefault;
    notifyListeners();
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
    id,
    required this.name,
    required this.orderNum,
    required this.like,
    required this.createdAt,
    this.icon,
    this.color,
    required this.targetType,
    required this.values,
  }): super(id: id, isDetailLoaded: true);

  void update({bool? like}) {
    if (like != null && this.like != like) {
      this.like = like;
      notifyListeners();
    }
  }

  void updateFrom(BaseModel other) {
    other as Tag;
    name = other.name;
    orderNum = other.orderNum;
    like = other.like;
    icon = other.icon;
    color = other.color;
    targetType = other.targetType;
    values = other.values;
    notifyListeners();
  }
}
