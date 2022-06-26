import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../data/base_model.dart';
import '../data/config.dart';
import '../data/paginators.dart';

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
          ElevatedButton(
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
          ElevatedButton(
            child: const Text('Повторить'),
            onPressed: retry,
          ),
        ],
      ),
    );
  }
}

class EmptyBody extends StatelessWidget {
  const EmptyBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: в вебе не центрируется по вертикали
    return const Center(child: Text('ниче нету...'));
  }
}

class BodyLoading extends StatelessWidget {
  const BodyLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ItemLoading extends StatelessWidget {
  const ItemLoading({Key? key}) : super(key: key);

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

class PaginatedListView<T extends BaseModel> extends StatelessWidget {
  final ScrollController? scrollController;
  final Widget Function(BuildContext context, T item) itemBuilder;

  PaginatedListView(this.itemBuilder, [this.scrollController]);

  @override
  Widget build(BuildContext context) {
    return Consumer<LimitOffsetPaginator<T>>(
      builder: (context, paginator, child) {
        if (paginator.isEmpty) {
          return const EmptyBody();
        }

        if (paginator.isLoading) {
          return const BodyLoading();
        }

        if (!paginator.isConnected) {
          paginator.fetchNext(notifyStart: false);
          return const BodyLoading();
        }

        if (paginator.isNotConnected && paginator.isFailed) {
          return RetryBody(paginator.fetchNext);
        }

        return RefreshIndicator(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            itemCount: paginator.items.length + (paginator.isEnd ? 0 : 1),
            itemBuilder: _itemBuilder,
            separatorBuilder: (context, index) => const Divider(),
            shrinkWrap: true,
          ),
          onRefresh: () => _refresh(context),
        );
      },
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final paginator = context.read<LimitOffsetPaginator<T>>();
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

  _refresh(BuildContext context) async {
    final paginator = context.read<LimitOffsetPaginator<T>>();
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
        const Text('Готово!'),
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

Future<void> doWithBars(
  ScaffoldMessengerState scaffold,
  VoidCallback func,
  VoidCallback retry,
) async {
  scaffold.showSnackBar(createLoadingSnackBar());

  try {
    await Future.sync(func);
  } on Exception {
    scaffold.clearSnackBars();
    scaffold.showSnackBar(createErrorSnackBar(retry));
    return;
  }

  scaffold.clearSnackBars();
  scaffold.showSnackBar(createSuccessSnackBar());
}

bool isWide(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 600;
}

class ItemAction {
  final String label;
  final IconData icon;
  final MaterialColor color;
  final void Function(BuildContext context) action;

  ItemAction(this.label, this.icon, this.color, this.action);
}

Widget wrapActions(BuildContext context, Widget widget, List<ItemAction> actions) {
  if (context.read<Config>().isLinux) {
    return Listener(
      child: widget,
      onPointerDown: (event) async {
        if (event.kind != PointerDeviceKind.mouse || event.buttons != kSecondaryMouseButton) {
          return;
        }

        final overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
        final menuItem = await showMenu(
          context: context,
          items: [
            for (final action in actions)
              PopupMenuItem(child: Text(action.label), value: action.action)
          ],
          position: RelativeRect.fromSize(event.position & const Size(48.0, 48.0), overlay.size),
        );
        if (menuItem != null) {
          menuItem(context);
        }
      },
    );
  }

  return Slidable(
    startActionPane: ActionPane(
      motion: const DrawerMotion(),
      children: [
        for (final action in actions)
          SlidableAction(
            backgroundColor: action.color,
            icon: action.icon,
            onPressed: action.action,
          ),
      ],
    ),
    child: widget,
  );
}
