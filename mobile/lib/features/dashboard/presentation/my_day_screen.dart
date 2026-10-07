import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../approval/presentation/approval_decision_screen.dart';
import '../../approval/presentation/approval_target_label.dart';
import '../../order/presentation/open_order.dart';
import '../../settings/presentation/more_screen.dart';
import '../../task/domain/task_item.dart';
import '../../task/presentation/task_list_screen.dart';
import '../application/my_day_controller.dart';

/// Document 14.9: "My Day" — the recommended post-login landing view,
/// aggregating overdue T&A milestones, the organization's pending approvals,
/// and the user's overdue tasks in one screen. Every row deep-links straight
/// into the record it is about.
class MyDayScreen extends ConsumerWidget {
  const MyDayScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myDayControllerProvider);
    void refresh() => ref.read(myDayControllerProvider.notifier).refresh();

    Future<void> openTask(TaskItem t) async {
      if (t.entityType.toUpperCase() == 'ORDER') {
        await openOrderById(context, ref, t.entityId);
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskListScreen(target: (entityType: t.entityType, entityId: t.entityId)),
        ));
      }
      if (context.mounted) refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Day'),
        actions: [
          IconButton(
            tooltip: 'More: receivables, payables, claims, templates, settings',
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreScreen())),
          ),
        ],
      ),
      body: switch (state) {
        MyDayLoading() => const LoadingView(layout: LoadingLayout.detail),
        MyDayError(:final failure) => ErrorStateView(failure: failure, onRetry: refresh),
        MyDayLoaded(:final myDay) => Builder(builder: (context) {
            final milestones = myDay.myOverdueMilestones;
            final approvals = myDay.organizationPendingApprovals;
            final tasks = myDay.myOverdueTasks;
            final total = milestones.length + approvals.length + tasks.length;
            return RefreshIndicator(
              onRefresh: () => ref.read(myDayControllerProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  GradientHeader(
                    eyebrow: _greeting(),
                    title: total == 0 ? 'All clear today' : '$total thing${total == 1 ? '' : 's'} need you',
                    subtitle: displayDateFormat.format(DateTime.now()),
                    icon: Icons.wb_sunny_rounded,
                    bottom: Row(
                      children: [
                        HeaderStat(value: '${milestones.length}', label: 'Late milestones'),
                        const SizedBox(width: AppSpacing.xl),
                        HeaderStat(value: '${approvals.length}', label: 'Approvals'),
                        const SizedBox(width: AppSpacing.xl),
                        HeaderStat(value: '${tasks.length}', label: 'Late tasks'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── T&A ─────────────────────────────────────────────
                        SectionHeader(
                          'Overdue T&A milestones',
                          icon: AppModules.ta.icon,
                          accentColor: AppModules.ta.color,
                          count: milestones.length,
                        ),
                        if (milestones.isEmpty)
                          _AllClear('No late milestones. Great job!', color: AppModules.ta.color)
                        else
                          ...milestones.map((m) => AppCard(
                                accentColor: AppStatus.color(m.status.apiValue),
                                onTap: () async {
                                  await openOrderTaById(context, ref, m.orderId);
                                  if (context.mounted) refresh();
                                },
                                child: RecordRow(
                                  leading: IconBadge(icon: AppModules.ta.icon, color: AppModules.ta.color),
                                  title: m.milestoneTypeName,
                                  subtitle:
                                      lookupLabel(ref, orderLookupProvider, m.orderId, fallback: 'Order #${m.orderId}'),
                                  meta: 'Due ${formatApiDate(m.effectiveDate)}',
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusChip(m.status.apiValue, label: m.status.label, dense: true),
                                      if (m.delayDays > 0) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        TonePill('${m.delayDays} d late',
                                            color: AppColors.danger, icon: Icons.schedule_rounded),
                                      ],
                                    ],
                                  ),
                                ),
                              )),
                        // ── Approvals ───────────────────────────────────────
                        SectionHeader(
                          'Pending approvals',
                          icon: AppModules.approvals.icon,
                          accentColor: AppModules.approvals.color,
                          count: approvals.length,
                        ),
                        if (approvals.isEmpty)
                          _AllClear('Nothing waiting for approval.', color: AppModules.approvals.color)
                        else
                          ...approvals.map((a) => AppCard(
                                accentColor: AppModules.approvals.color,
                                onTap: () async {
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => ApprovalDecisionScreen(approval: a)));
                                  if (context.mounted) refresh();
                                },
                                child: RecordRow(
                                  leading:
                                      IconBadge(icon: AppModules.approvals.icon, color: AppModules.approvals.color),
                                  title: approvalTargetLabel(ref, a.targetType, a.targetId),
                                  subtitle: 'Round ${a.roundNo} · tap to decide',
                                  trailing: StatusChip(a.status.apiValue, label: a.status.label, dense: true),
                                ),
                              )),
                        // ── Tasks ───────────────────────────────────────────
                        SectionHeader(
                          'My overdue tasks',
                          icon: AppModules.tasks.icon,
                          accentColor: AppModules.tasks.color,
                          count: tasks.length,
                          actionLabel: 'All tasks',
                          onAction: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskListScreen()));
                            if (context.mounted) refresh();
                          },
                        ),
                        if (tasks.isEmpty)
                          _AllClear('No overdue tasks.', color: AppModules.tasks.color)
                        else
                          ...tasks.map((t) {
                            final days = daysFromToday(t.dueDate);
                            return AppCard(
                              accentColor: AppColors.danger,
                              onTap: () => openTask(t),
                              child: RecordRow(
                                leading: IconBadge(icon: AppModules.tasks.icon, color: AppModules.tasks.color),
                                title: t.title,
                                subtitle: entityRefLabel(ref, t.entityType, t.entityId),
                                meta: 'Due ${formatApiDate(t.dueDate)}',
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusChip(t.priority.apiValue,
                                        label: t.priority.label, dense: true, showIcon: false),
                                    if (days != null && days < 0) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      TonePill(relativeDays(days), color: AppColors.danger, icon: Icons.alarm_rounded),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        // ── Quick links ─────────────────────────────────────
                        SectionHeader('Quick links', icon: Icons.bolt_rounded, accentColor: AppModules.reports.color),
                        AppCard(
                          accentColor: AppModules.financial.color,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreScreen())),
                          child: RecordRow(
                            leading: IconBadge(icon: Icons.apps_rounded, color: AppModules.financial.color),
                            title: 'Receivables, payables, claims & more',
                            subtitle: 'Organization-wide finance, T&A templates, reference data, profile',
                            trailing: Icon(Icons.chevron_right_rounded, color: AppModules.financial.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      },
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: false,
        color: color.withValues(alpha: 0.08),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}
