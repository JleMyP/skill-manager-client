import '../utils/base_model.dart';


class TagValue extends BaseModel {
  final String name;
  final int orderNum;
  final DateTime createdAt;
  final String icon;
  final bool isDefault;

  TagValue({
    id,
    this.name,
    this.orderNum,
    this.createdAt,
    this.icon,
    this.isDefault,
  }): super(id: id);
}


class Tag extends BaseModel {
  String name;
  int orderNum;
  bool like;
  DateTime createdAt;
  String icon;
  int color;
  int targetType;
  List<TagValue> values;

  Tag({
    id,
    this.name,
    this.orderNum,
    this.like,
    this.createdAt,
    this.icon,
    this.color,
    this.targetType,
    this.values,
  }): super(id: id);

  void update({bool like}) {
    if (this.like != like) {
      this.like = like;
      notifyListeners();
    }
  }
}
