import '../api_client.dart';
import '../base_repository.dart';
import '../config.dart';
import '../models/tag.dart';


abstract class TagRepo implements AbstractRepository<Tag> {
  Future<TagValue> addValue({
    required int tagId,
    required String name,
    required int orderNum,
    required String icon,
  });
  Future<void> removeValue(int tagId, int id);
}


class TagHttpRepo extends BaseHttpRepository<Tag> implements TagRepo {
  String get baseUrl => '/tags/';

  TagHttpRepo({ client }): super(client: client, resultKey: 'results');

  @override
  Tag parseItemFromList(JsonDict item) {
    var values = item['values'].map((i) => parseTagValueFromList(i)).cast<TagValue>().toList();
    return Tag(
      id: item['id'],
      name: item['name'],
      orderNum: item['order_num'],
      like: item['like'],
      createdAt: DateTime.parse(item['created_at']),
      icon: item['icon'],
      color: item['color'],
      targetType: item['target_type'],
      values: values,
    );
  }

  TagValue parseTagValueFromList(JsonDict item) {
    return TagValue(
      id: item['id'],
      name: item['name'],
      orderNum: item['order_num'],
      createdAt: DateTime.parse(item['created_at']),
      icon: item['icon'],
      isDefault: item['is_default'],
    );
  }

  TagValue parseTagValueFromDetail(JsonDict item) {
    return parseTagValueFromList(item);
  }

  Future<TagValue> addValue({
    required int tagId,
    required String name,
    required int orderNum,
    required String icon,
  }) async {
    var data = {
      'name': name,
      'order_num': orderNum,
      'icon': icon,
    };
    var response = await client.post('$baseUrl$tagId/values/', data);
    return parseTagValueFromDetail(response);
  }

  Future<void> removeValue(int tagId, int id) async {
    await client.delete('$baseUrl$tagId/values/$id/');
  }
}


class TagFakeRepo extends BaseFakeRepository<Tag> implements TagRepo {
  TagValue parseTagValueFromList(JsonDict item) {
    return TagValue(
      id: item['id'],
      name: item['name'],
      orderNum: item['order_num'],
      createdAt: DateTime.parse(item['created_at']),
      icon: item['icon'],
      isDefault: item['is_default'],
    );
  }

  TagValue parseTagValueFromDetail(JsonDict item) {
    return parseTagValueFromList(item);
  }

  @override
  Tag fakeItemForList(int i) {
    return Tag(
      id: i,
      name: 'метка $i',
      orderNum: 1,
      like: false,
      createdAt: DateTime.now(),
      // icon: 'T',
      color: 256,
      targetType: 7,
      values: [
        TagValue(
          id: i,
          name: 'значение $i',
          orderNum: 1,
          // icon: 'V',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  Future<TagValue> addValue({
    required int tagId,
    required String name,
    required int orderNum,
    required String icon,
  }) async {
    return TagValue(
      id: 1,
      name: name,
      orderNum: orderNum,
      icon: icon,
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> removeValue(int tagId, int id) async {}
}


class TagDelayWrapper extends BaseDelayWrapper<TagRepo, Tag> implements TagRepo {
  TagDelayWrapper(TagRepo repo, int netDelay): super(repo, netDelay);

  Future<TagValue> addValue({
  	required int tagId,
  	required String name,
  	required int orderNum,
  	required String icon,
  }) async {
  	await delay();
  	return await repo.addValue(
  	  tagId: tagId,
  	  name: name,
  	  orderNum: orderNum,
  	  icon: icon,
  	);
  }

  Future<void> removeValue(int tagId, int id) async {
  	await delay();
  	return await repo.removeValue(tagId, id);
  }
}

TagRepo createTagRepo(Config config, HttpApiClient? client) {
  TagRepo repo;

  if (config.fake) {
    repo = TagFakeRepo();
  } else {
  	repo = TagHttpRepo(client: client!);
  }

  if (config.netDelay != 0) {
  	repo = TagDelayWrapper(repo, config.netDelay);
  }

  return repo;
}
