import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/feedback.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/order_repository_impl.dart';
import '../../ta/presentation/ta_milestone_list_screen.dart';
import 'order_detail_screen.dart';

/// Deep-link helper: loads an order by id and opens its detail screen, so
/// notifications, My Day and task rows can jump straight to the order.
Future<void> openOrderById(BuildContext context, WidgetRef ref, int orderId) async {
  try {
    final order = await ref
        .read(authControllerProvider.notifier)
        .callAuthorized(() => ref.read(orderRepositoryProvider).get(orderId));
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
  }
}

/// Deep-link helper: loads an order and opens its T&A calendar directly (the
/// calendar needs the order's style). Falls back to the order hub when the
/// order has no items yet.
Future<void> openOrderTaById(BuildContext context, WidgetRef ref, int orderId) async {
  try {
    final order = await ref
        .read(authControllerProvider.notifier)
        .callAuthorized(() => ref.read(orderRepositoryProvider).get(orderId));
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => order.items.isEmpty
          ? OrderDetailScreen(order: order)
          : TaMilestoneListScreen(orderId: order.id, styleId: order.items.first.styleId),
    ));
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
  }
}
