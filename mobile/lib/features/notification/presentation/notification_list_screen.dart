import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/notification_controller.dart';

/// Document 7 (#88): the in-app notification feed — tapping an unread
/// notification marks it read.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: switch (state) {
        NotificationListLoading() => const LoadingView(),
        NotificationListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(notificationListControllerProvider.notifier).refresh(),
          ),
        NotificationListLoaded(:final notifications) when notifications.isEmpty =>
          const EmptyStateView(message: 'No notifications.', icon: Icons.notifications_none_outlined),
        NotificationListLoaded(:final notifications) => RefreshIndicator(
            onRefresh: () => ref.read(notificationListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(
                    notification.read ? Icons.notifications_none_outlined : Icons.notifications_active,
                    color: notification.read ? null : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    notification.message,
                    style: notification.read ? null : const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${notification.entityType} #${notification.entityId} · ${notification.createdAt}'),
                  onTap: notification.read
                      ? null
                      : () => ref.read(notificationListControllerProvider.notifier).markRead(notification.id),
                );
              },
            ),
          ),
      },
    );
  }
}
