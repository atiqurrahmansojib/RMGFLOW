import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/my_day_controller.dart';

/// Document 14.9: "My Day" — the recommended post-login landing view,
/// aggregating overdue T&A milestones, the organization's pending approvals,
/// and the user's overdue tasks in one screen. Every section is read-only
/// here; acting on an item routes into that module's own screen.
class MyDayScreen extends ConsumerWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myDayControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Day')),
      body: switch (state) {
        MyDayLoading() => const LoadingView(),
        MyDayError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(myDayControllerProvider.notifier).refresh(),
          ),
        MyDayLoaded(:final myDay) => RefreshIndicator(
            onRefresh: () => ref.read(myDayControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Overdue T&A Milestones (${myDay.myOverdueMilestones.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                if (myDay.myOverdueMilestones.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Nothing overdue.'))
                else
                  ...myDay.myOverdueMilestones.map((m) => Card(
                        child: ListTile(
                          title: Text('${m.milestoneTypeName} — Order #${m.orderId}'),
                          subtitle: Text('Planned ${m.plannedDate}, ${m.delayDays} day(s) overdue'),
                          trailing: Chip(label: Text(m.status.label)),
                        ),
                      )),
                const SizedBox(height: 20),
                Text('Pending Approvals (${myDay.organizationPendingApprovals.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                if (myDay.organizationPendingApprovals.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Nothing pending.'))
                else
                  ...myDay.organizationPendingApprovals.map((a) => Card(
                        child: ListTile(
                          title: Text('${a.targetType.label} #${a.targetId}'),
                          subtitle: Text('Round ${a.roundNo}'),
                          trailing: Chip(label: Text(a.status.label)),
                        ),
                      )),
                const SizedBox(height: 20),
                Text('My Overdue Tasks (${myDay.myOverdueTasks.length})', style: Theme.of(context).textTheme.titleMedium),
                if (myDay.myOverdueTasks.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Nothing overdue.'))
                else
                  ...myDay.myOverdueTasks.map((t) => Card(
                        child: ListTile(
                          title: Text(t.title),
                          subtitle: Text('${t.entityType} #${t.entityId} · Due ${t.dueDate}'),
                          trailing: Chip(label: Text(t.priority.label)),
                        ),
                      )),
              ],
            ),
          ),
      },
    );
  }
}
