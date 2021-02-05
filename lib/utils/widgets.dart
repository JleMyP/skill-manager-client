import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'paginators.dart';


class RetryItem extends StatelessWidget {
  final VoidCallback retry;

  RetryItem(this.retry);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15, top: 10),
      child: Column(
        children: [
          Text('Шот не удалось...'),
          RaisedButton(
            child: Text('Повторить'),
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
          Text('Шот не удалось...'),
          RaisedButton(
            child: Text('Повторить'),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}


class EmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('ниче нету...'));
  }
}


class BodyLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}


class ItemLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 15, top: 10),
        child: CircularProgressIndicator(),
      ),
    );
  }
}


typedef ItemBuilder = Widget Function(BuildContext context, dynamic item);


class PaginatedListView extends StatelessWidget {
  final ScrollController scrollController;
  final LimitOffsetPaginator paginator;
  final ItemBuilder itemBuilder;

  PaginatedListView(this.paginator, this.itemBuilder, [this.scrollController]);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LimitOffsetPaginator>.value(
      value: paginator,
      child: Builder(builder: (context) {
        context.watch<LimitOffsetPaginator>();
        if (paginator.isEnd && (paginator.items?.isEmpty ?? true)) {
          return EmptyBody();
        }

        if (paginator.loadingIsFailed) {
          return RetryBody(paginator.fetchNext);
        }

        if (paginator.count == null) {
          if (!paginator.isLoading) {
            paginator.fetchNext(notifyStart: false);
          }
          return BodyLoading();
        }

        return RefreshIndicator(
          child: ListView.separated(
            controller: scrollController,
            itemCount: paginator.items.length + (paginator.isEnd ? 0 : 1),
            itemBuilder: _itemBuilder,
            separatorBuilder: (context, index) => Divider(),
            shrinkWrap: true,
          ),
          onRefresh: _refresh,
        );
      })
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index == paginator.items.length && !paginator.isEnd) {
      if (paginator.loadingIsFailed) {
        return RetryItem(paginator.fetchNext);
      }

      paginator.fetchNext(notifyStart: false);
      return ItemLoading();
    }

    var item = paginator.items[index];
    return itemBuilder(context, item);
  }

  Future<void> _refresh() async {
    paginator.reset();
    await paginator.fetchNext(notifyStart: false);
  }
}
