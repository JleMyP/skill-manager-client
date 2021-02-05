import '../models/imported_resource.dart';
import '../utils/base_repository.dart';


class ImportedResourceRepo extends BaseRestRepository<ImportedResource> {
  String get baseUrl => '/imported_resources/';

  ImportedResourceRepo(): super(resultKey: 'results');
  ImportedResourceRepo.withClient(client):
    super.withClient(client, resultKey: 'results');

  @override
  ImportedResource parseItemFromList(Map<String, dynamic> item) {
    return ImportedResource(
      id: item['id'],
      name: item['name'],
      description: item['description'],
      isIgnored: item['is_ignored'],
      createdAt: DateTime.parse(item['created_at']),
      type: item['resourcetype'],
      typeSpecific: item['type_specific'],
    );
  }

  @override
  ImportedResource fakeItemForList(int i) {
    return ImportedResource(
      id: i,
      name: 'ресурс $i',
      description: 'описание ресурса $i',
      isIgnored: i % 2 == 1,
    );
  }
}
