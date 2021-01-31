import '../utils/base_model.dart';

class ImportedResource extends BaseModel {
  final String name;
  final String description;
  final bool isIgnored;
  final DateTime createdAt;
  final String type;
  final Map<String, dynamic> typeSpecific;

  ImportedResource({
    id,
    this.name,
    this.description,
    this.isIgnored,
    this.createdAt,
    this.type,
    this.typeSpecific,
  }): super(id: id);
}
