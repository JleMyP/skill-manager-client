import '../utils/base_model.dart';

class ImportedResource extends BaseModel {
  final String name;
  final String description;
  final bool isIgnored;
  final DateTime createdAt;

  ImportedResource({
    id,
    this.name,
    this.description,
    this.isIgnored,
    this.createdAt,
  }): super(id: id);
}
