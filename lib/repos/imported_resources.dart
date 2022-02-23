import '../models/imported_resource.dart';
import '../utils/api_client.dart';
import '../utils/base_repository.dart';


class ImportedResourceRepo extends BaseRestRepository<ImportedResource> {
  String get baseUrl => '/imported_resources/';

  ImportedResourceRepo({ HttpApiClient client }):
    super(client: client, resultKey: 'results');

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
      createdAt: DateTime.now(),
      type: 'ImportedResourceRepo',
      typeSpecific: {'readme': '# Заголовок\n\nридми ресурса $i'},
    );
  }

  @override
  Future<ImportedResource> updateItem(ImportedResource item, Map<String, dynamic> data) async {
    data['resourcetype'] = item.type;
    return await super.updateItem(item, data);
  }
}
