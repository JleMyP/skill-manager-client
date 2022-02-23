import '../api_client.dart';
import '../base_repository.dart';
import '../config.dart';
import '../models/imported_resource.dart';


abstract class ImportedResourceRepo implements AbstractRepository<ImportedResource> {}


class ImportedResourceHttpRepo extends BaseHttpRepository<ImportedResource> implements ImportedResourceRepo {
  String get baseUrl => '/imported_resources/';

  ImportedResourceHttpRepo({ HttpApiClient? client }):
    super(client: client, resultKey: 'results');

  @override
  ImportedResource parseItemFromList(JsonDict item) {
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
  Future<ImportedResource> updateItem(ImportedResource item, JsonDict data) async {
    data['resourcetype'] = item.type;
    return await super.updateItem(item, data);
  }
}


class ImportedResourceFakeRepo extends BaseFakeRepository<ImportedResource> implements ImportedResourceRepo {
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
  Future<ImportedResource> updateItem(ImportedResource item, JsonDict data) async {
    data['resourcetype'] = item.type;
    return await super.updateItem(item, data);
  }
}


class ImportedResourceDelayWrapper extends BaseDelayWrapper<ImportedResourceRepo, ImportedResource> implements ImportedResourceRepo {
  ImportedResourceDelayWrapper(ImportedResourceRepo repo, int netDelay): super(repo, netDelay);
}

ImportedResourceRepo createImportedResourceRepo(Config config, HttpApiClient? client) {
  ImportedResourceRepo repo;

  if (config.fake) {
    repo = ImportedResourceFakeRepo();
  } else {
    repo = ImportedResourceHttpRepo(client: client!);
  }

  if (config.netDelay != 0) {
    repo = ImportedResourceDelayWrapper(repo, config.netDelay);
  }

  return repo;
}
