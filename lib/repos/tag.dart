import '../models/tag.dart';
import '../utils/base_repository.dart';


class TagRepo extends BaseRestRepository<Tag> {
  String get baseUrl => '/tags/';

  TagRepo(): super(resultKey: 'results');
  TagRepo.withClient(client): super.withClient(client, resultKey: 'results');

  @override
  Tag parseItemFromList(Map<String, dynamic> item) {
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

  TagValue parseTagValueFromList(Map<String, dynamic> item) {
    return TagValue(
      id: item['id'],
      name: item['name'],
      orderNum: item['order_num'],
      createdAt: DateTime.parse(item['created_at']),
      icon: item['icon'],
      isDefault: item['is_default'],
    );
  }

  TagValue parseTagValueFromDetail(Map<String, dynamic> item) {
    return parseTagValueFromList(item);
  }

  @override
  Tag fakeItemForList(int i) {
    return Tag(
      id: i,
      name: 'метка $i',
      orderNum: 1,
      like: false,
      icon: 'T',
      color: 256,
      targetType: 7,
      values: [
        TagValue(
          id: i,
          name: 'значение $i',
          orderNum: 1,
          icon: 'V',
          isDefault: true,
        ),
      ],
    );
  }

  Future<TagValue> addValue({
    int tagId,
    String name,
    int orderNum,
    String icon,
  }) async {
    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
      return TagValue(
        id: 1,
        name: name,
        orderNum: orderNum,
        icon: icon,
        isDefault: false,
        createdAt: DateTime.now(),
      );
    } else {
      var data = {
        'name': name,
        'order_num': orderNum,
        'icon': icon,
      };
      var response = await client.post('$baseUrl$tagId/values/', data);
      return parseTagValueFromDetail(response);
    }
  }

  Future<void> removeValue(int tagId, int id) async {
    if (client.fake) {
      if (client.netDelay != 0) {
        await Future.delayed(Duration(seconds: client.netDelay));
      }
    } else {
      await client.delete('$baseUrl$tagId/values/$id/');
    }
  }
}
