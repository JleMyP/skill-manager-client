import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'base_model.dart';
import 'paginators.dart';


class RetryItem extends StatelessWidget {
  final VoidCallback retry;

  RetryItem(this.retry);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Column(
        children: [
          const Text('Шот не удалось...'),
          RaisedButton(
            child: const Text('Повторить'),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}


class RetryBody extends StatelessWidget {
  final VoidCallback retry;

  RetryBody(this.retry);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Шот не удалось...'),
          RaisedButton(
            child: const Text('Повторить'),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}


class EmptyBody extends StatelessWidget {
  const EmptyBody({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('ниче нету...'));
  }
}


class BodyLoading extends StatelessWidget {
  const BodyLoading({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}


class ItemLoading extends StatelessWidget {
  const ItemLoading({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 15, top: 10),
        child: CircularProgressIndicator(),
      ),
    );
  }
}


typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);


class PaginatedListView<T extends BaseModel> extends StatelessWidget {
  final ScrollController scrollController;
  final LimitOffsetPaginator<T> paginator;
  final ItemBuilder<T> itemBuilder;

  PaginatedListView(this.paginator, this.itemBuilder, [this.scrollController]);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LimitOffsetPaginator<T>>.value(
      value: paginator,
      child: Consumer<LimitOffsetPaginator<T>>(
        builder: (context, _paginator, child) {
          if (paginator.isEmpty) {
            return const EmptyBody();
          }

          if (paginator.isLoading) {
            return const BodyLoading();
          }

          if (paginator.isNotConnected && paginator.isFailed) {
            return RetryBody(paginator.fetchNext);
          }

          return RefreshIndicator(
            child: ListView.separated(
              controller: scrollController,
              itemCount: paginator.items.length + (paginator.isEnd ? 0 : 1),
              itemBuilder: _itemBuilder,
              separatorBuilder: (context, index) => const Divider(),
              shrinkWrap: true,
            ),
            onRefresh: _refresh,
          );
        },
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index == paginator.items.length && !paginator.isEnd) {
      if (paginator.isFailed) {
        return RetryItem(paginator.fetchNext);
      }

      // TODO: вынести бы куда-нить
      paginator.fetchNext(notifyStart: false);
      return const ItemLoading();
    }

    final item = paginator.items[index];
    return itemBuilder(context, item);
  }

  Future<void> _refresh() async {
    paginator.reset();
    await paginator.fetchNext(notifyStart: false);
  }
}


SnackBar createLoadingSnackBar() {
  return SnackBar(
    backgroundColor: Colors.yellowAccent,
    behavior: SnackBarBehavior.fixed,
    content: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(width: 25),
        const Text('грузим...'),
      ],
    ),
  );
}


SnackBar createSuccessSnackBar() {
  return SnackBar(
    backgroundColor: Colors.greenAccent,
    behavior: SnackBarBehavior.fixed,
    content: Row(
      children: [
        const Icon(Icons.check),
        const Text('Загружено!'),
      ],
    ),
  );
}


SnackBar createErrorSnackBar(VoidCallback retry) {
  return SnackBar(
    backgroundColor: Colors.redAccent,
    behavior: SnackBarBehavior.fixed,
    content: const Text('Ашипка!'),
    action: SnackBarAction(
      label: 'Повторить',
      onPressed: retry,
    ),
  );
}
