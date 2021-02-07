import '../utils/base_model.dart';


class ImportedResource extends BaseModel {
  String name;
  String description;
  bool isIgnored;
  DateTime createdAt;
  String type;
  Map<String, dynamic> typeSpecific;

  ImportedResource({
    id,
    this.name,
    this.description,
    this.isIgnored,
    this.createdAt,
    this.type,
    this.typeSpecific,
  }): super(id: id);

  void update({bool isIgnored}) {
    if (this.isIgnored != isIgnored) {
      this.isIgnored = isIgnored;
      notifyListeners();
    }
  }
}
