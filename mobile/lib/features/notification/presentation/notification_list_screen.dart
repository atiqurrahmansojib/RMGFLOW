import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../order/presentation/open_order.dart';
import '../application/notification_controller.dart';
import '../domain/notification.dart';

/// Document 7 (#88): the in-app notification feed — tapping a notification
/// marks it read and, for order notifications, opens the order.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
  static final _when = DateFormat('dd MMM, HH:mm');
  bool _unreadOnly = false;

  NotificationListController get _ctrl => ref.read(notificationListControllerProvider.notifier);

  bool _isOrder(AppNotification n) => n.entityType.toUpperCase() == 'ORDER';

  Future<void> _markRead(AppNotification n) async {
    if (n.read) return;
    try {
      await _ctrl.markRead(n.id);
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not mark the notification as read');
    }
  }

  void _open(AppNotification n) {
    _markRead(n);
    if (_isOrder(n)) openOrderById(context, ref, n.entityId);
  }

  void _actions(AppNotification n) => showQuickActions(
        context,
        title: n.message,
        subtitle: entityRefLabel(ref, n.entityType, n.entityId),
        actions: [
          if (_isOrder(n))
            QuickAction(
              icon: AppModules.orders.icon,
              label: 'Open order',
              color: AppModules.orders.color,
              onTap: () => _open(n),
            ),
          if (!n.read)
            QuickAction(
              icon: Icons.mark_email_read_rounded,
              label: 'Mark as read',
              color: AppModules.notifications.color,
              onTap: () => _markRead(n),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      // Swipe right on a notification to mark it read; long-press for actions.
      body: Column(
        children: [
          FilterChipBar<bool>(
            values: const [true],
            selected: _unreadOnly ? true : null,
            labelOf: (_) {
              final st = state;
              final unread = st is NotificationListLoaded ? st.notifications.where((n) => !n.read).length : 0;
              return unread > 0 ? 'Unread ($unread)' : 'Unread';
            },
            allLabel: 'All',
            onSelected: (v) => setState(() => _unreadOnly = v ?? false),
          ),
          Expanded(
            child: switch (state) {
              NotificationListLoading() => const LoadingView(),
              NotificationListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(notificationListControllerProvider.notifier).refresh(),
                ),
              NotificationListLoaded(:final notifications) => Builder(builder: (context) {
                  final visible = _unreadOnly ? notifications.where((n) => !n.read).toList() : notifications;
                  return RefreshIndicator(
                    onRefresh: () => ref.read(notificationListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              title: _unreadOnly ? 'No unread notifications' : 'No notifications',
                              message: 'Alerts about overdue milestones, approvals and tasks will appear here.',
                              icon: Icons.notifications_none_outlined,
                              color: AppModules.notifications.color,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.page,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final n = visible[index];
                              final theme = Theme.of(context);
                              final color = n.read ? AppColors.neutral : AppModules.notifications.color;
                              return SwipeAction(
                                key: ValueKey('notif-${n.id}'),
                                startLabel: 'Mark read',
                                startIcon: Icons.mark_email_read_rounded,
                                startColor: AppModules.notifications.color,
                                onSwipeStart: n.read ? null : () => _markRead(n),
                                child: AppCard(
                                  accentColor: n.read ? null : color,
                                  color: n.read
                                      ? null
                                      : Color.alphaBlend(color.withValues(alpha: 0.06), theme.colorScheme.surface),
                                  onTap: () => _open(n),
                                  onLongPress: () => _actions(n),
                                  child: RecordRow(
                                    leading: IconBadge(
                                      icon: n.read ? Icons.notifications_none_rounded : AppModules.notifications.icon,
                                      color: color,
                                      size: 40,
                                    ),
                                    title: n.message,
                                    subtitle: '${entityRefLabel(ref, n.entityType, n.entityId)} · '
                                        '${_when.format(n.createdAt.toLocal())}',
                                    trailing: _isOrder(n)
                                        ? Icon(Icons.chevron_right_rounded, color: AppModules.orders.color)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
            },
          ),
        ],
      ),
    );
  }
}
