import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/lookups/module_access.dart';
import '../../common/widgets/widgets.dart';
import '../approval/presentation/approval_inbox_screen.dart';
import '../auth/application/auth_controller.dart';
import '../buyers/presentation/buyer_list_screen.dart';
import '../costing/presentation/costing_list_screen.dart';
import '../dashboard/application/my_day_controller.dart';
import '../dashboard/presentation/my_day_screen.dart';
import '../factories/presentation/factory_list_screen.dart';
import '../inquiries/presentation/inquiry_list_screen.dart';
import '../notification/presentation/notification_list_screen.dart';
import '../order/presentation/order_list_screen.dart';
import '../quotation/presentation/quotation_list_screen.dart';
import '../report/presentation/report_hub_screen.dart';
import '../sample/presentation/sample_list_screen.dart';
import '../styles/presentation/style_list_screen.dart';
import '../task/presentation/task_list_screen.dart';
import '../claim/presentation/all_claims_screen.dart';
import '../document/domain/commercial_document.dart';
import '../document/presentation/commercial_document_list_screen.dart';
import '../financial/presentation/receivables_payables_screen.dart';
import '../order/domain/order.dart';
import '../production/presentation/production_progress_screen.dart';
import '../quality/presentation/inspection_list_screen.dart';
import '../settings/presentation/more_screen.dart';
import '../shipment/presentation/shipment_list_screen.dart';
import '../ta/presentation/ta_milestone_list_screen.dart';
import 'order_picker_sheet.dart';

/// Document 7's module launcher, presented as a dashboard: brand header with
/// the global actions, today's attention KPIs (from Doc 14.9's My Day
/// endpoint), a prominent Reports entry and the grouped module grid.
///
/// Modules that only exist in the context of one order (T&A, production,
/// quality, shipment, documents) ask for the order first; Financial and
/// Claims open their organization-wide screens directly, and "More" holds
/// the remaining org-wide tools and settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myDay = ref.watch(myDayControllerProvider);
    final loaded = myDay is MyDayLoaded ? myDay.myDay : null;
    final user = ref.watch(currentUserProvider);

    final allGroups = <_ModuleGroup>[
      _ModuleGroup('Sourcing & Development', 'Buyers, vendors, inquiries and styles', Icons.travel_explore_rounded, [
        _ModuleLink(AppModules.buyers, () => const BuyerListScreen()),
        _ModuleLink(AppModules.factories, () => const FactoryListScreen()),
        _ModuleLink(AppModules.inquiries, () => const InquiryListScreen()),
        _ModuleLink(AppModules.styles, () => const StyleListScreen()),
        _ModuleLink(AppModules.sampling, () => const SampleListScreen()),
      ]),
      _ModuleGroup('Commercial Pricing', 'Cost sheets, quotations and sign-off', Icons.payments_rounded, [
        _ModuleLink(AppModules.costing, () => const CostingListScreen()),
        _ModuleLink(AppModules.quotation, () => const QuotationListScreen()),
        _ModuleLink(
          AppModules.approvals,
          () => const ApprovalInboxScreen(),
          badge: loaded?.organizationPendingApprovals.length,
        ),
      ]),
      _ModuleGroup(
        'Order Execution',
        'Tap a module, pick the order, and you are there',
        Icons.local_shipping_rounded,
        [
          _ModuleLink(AppModules.orders, () => const OrderListScreen(), caption: 'All orders'),
          _ModuleLink.forOrder(
              AppModules.ta, (o) => TaMilestoneListScreen(orderId: o.id, styleId: o.items.first.styleId)),
          _ModuleLink.forOrder(AppModules.production, (o) => ProductionProgressScreen(orderId: o.id)),
          _ModuleLink.forOrder(AppModules.quality, (o) => InspectionListScreen(orderId: o.id)),
          _ModuleLink.forOrder(AppModules.shipment, (o) => ShipmentListScreen(orderId: o.id)),
          _ModuleLink.forOrder(AppModules.documents,
              (o) => CommercialDocumentListScreen(entityType: DocumentEntityType.order, entityId: o.id)),
          // Org-wide ledgers and register open directly — no order pick needed.
          _ModuleLink(AppModules.financial, () => const ReceivablesPayablesScreen(), caption: 'All orders'),
          _ModuleLink(AppModules.claims, () => const AllClaimsScreen(), caption: 'Register'),
        ],
      ),
      _ModuleGroup('My Work', 'Tasks, alerts and analytics', Icons.work_outline_rounded, [
        _ModuleLink(AppModules.tasks, () => const TaskListScreen(), badge: loaded?.myOverdueTasks.length),
        _ModuleLink(AppModules.notifications, () => const NotificationListScreen()),
        _ModuleLink(AppModules.reports, () => const ReportHubScreen()),
        _ModuleLink(_moreModule, () => const MoreScreen(), caption: 'Ledgers, setup'),
      ]),
    ];
    // Hide modules this user's role cannot open, so every tile leads somewhere.
    final groups = [
      for (final g in allGroups)
        if (g.links.any((l) => canOpenModule(user, l.module.id)))
          _ModuleGroup(g.title, g.subtitle, g.icon, g.links.where((l) => canOpenModule(user, l.module.id)).toList()),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(myDayControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _HomeHeader(
                onMyDay: () => _push(context, const MyDayScreen()),
                onReports: () => _push(context, const ReportHubScreen()),
                onNotifications: () => _push(context, const NotificationListScreen()),
                onMore: () => _push(context, const MoreScreen()),
                onLogout: () => ref.read(authControllerProvider.notifier).logout(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      'Needs attention today',
                      icon: Icons.bolt_rounded,
                      accentColor: AppColors.marigold,
                      actionLabel: 'My Day',
                      onAction: () => _push(context, const MyDayScreen()),
                    ),
                    _AttentionKpis(
                      state: myDay,
                      onRetry: () => ref.read(myDayControllerProvider.notifier).refresh(),
                      onMyDay: () => _push(context, const MyDayScreen()),
                      onApprovals: () => _push(context, const ApprovalInboxScreen()),
                      onTasks: () => _push(context, const TaskListScreen()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ReportsBanner(onTap: () => _push(context, const ReportHubScreen())),
                    for (final group in groups) ...[
                      SectionHeader(
                        group.title,
                        subtitle: group.subtitle,
                        icon: group.icon,
                        accentColor: group.links.first.module.color,
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisExtent: _tileExtent,
                        ),
                        itemCount: group.links.length,
                        itemBuilder: (context, i) {
                          final link = group.links[i];
                          return ModuleTile.fromModule(
                            link.module,
                            badgeCount: link.badge,
                            caption: link.caption,
                            onTap: () async {
                              final forOrder = link.orderBuilder;
                              if (forOrder == null) {
                                _push(context, link.builder!());
                                return;
                              }
                              final order = await pickOrder(context, link.module);
                              if (order == null || !context.mounted) return;
                              if (link.module.id == 'ta' && (order.exFactoryDate == null || order.items.isEmpty)) {
                                showErrorSnack(
                                    context, 'T&A needs an ex-factory date and at least one item on ${order.orderNo}.');
                                return;
                              }
                              _push(context, forOrder(order));
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home-only pseudo-module for the "More" tile (org-wide tools & settings).
const _moreModule = AppModule(id: 'more', label: 'More', icon: Icons.apps_rounded, color: AppColors.neutral);

/// Fixed tile height so two-line labels / captions never overflow.
const double _tileExtent = 144;

class _ModuleGroup {
  const _ModuleGroup(this.title, this.subtitle, this.icon, this.links);
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ModuleLink> links;
}

class _ModuleLink {
  const _ModuleLink(this.module, Widget Function() this.builder, {this.badge, this.caption}) : orderBuilder = null;
  const _ModuleLink.forOrder(this.module, Widget Function(Order) this.orderBuilder)
      : builder = null,
        badge = null,
        caption = 'Pick order';
  final AppModule module;
  final Widget Function()? builder;
  final Widget Function(Order)? orderBuilder;
  final int? badge;
  final String? caption;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onMyDay,
    required this.onReports,
    required this.onNotifications,
    required this.onMore,
    required this.onLogout,
  });

  final VoidCallback onMyDay;
  final VoidCallback onReports;
  final VoidCallback onNotifications;
  final VoidCallback onMore;
  final VoidCallback onLogout;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      eyebrow: _greeting(),
      title: 'RMGFlow',
      subtitle: 'Buying-house operations',
      icon: Icons.checkroom_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: onNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.apps_rounded, color: Colors.white),
            tooltip: 'More',
            onPressed: onMore,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ],
      ),
      bottom: Row(
        children: [
          Expanded(
              child: _HeaderAction(icon: Icons.today_outlined, label: 'My Day', tooltip: 'My Day', onTap: onMyDay)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                _HeaderAction(icon: Icons.bar_chart_outlined, label: 'Reports', tooltip: 'Reports', onTap: onReports),
          ),
        ],
      ),
    );
  }
}

/// Translucent pill button that sits on the gradient header.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.tooltip, required this.onTap});

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2x2 KPI grid fed by the My Day endpoint (one call, already used by the
/// My Day screen) — no numbers are computed or invented client-side beyond
/// counting the returned items.
class _AttentionKpis extends StatelessWidget {
  const _AttentionKpis({
    required this.state,
    required this.onRetry,
    required this.onMyDay,
    required this.onApprovals,
    required this.onTasks,
  });

  final MyDayState state;
  final VoidCallback onRetry;
  final VoidCallback onMyDay;
  final VoidCallback onApprovals;
  final VoidCallback onTasks;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case MyDayLoading():
        return const LoadingView(layout: LoadingLayout.grid, itemCount: 3, padding: EdgeInsets.zero);
      case MyDayError(:final failure):
        return AppCard(
          margin: EdgeInsets.zero,
          child: ErrorStateView(failure: failure, onRetry: onRetry, compact: true),
        );
      case MyDayLoaded(:final myDay):
        final milestones = myDay.myOverdueMilestones.length;
        final approvals = myDay.organizationPendingApprovals.length;
        final tasks = myDay.myOverdueTasks.length;
        final total = milestones + approvals + tasks;
        return Column(
          children: [
            _KpiRow(
              left: StatCard(
                value: '$total',
                label: 'Items need attention',
                icon: Icons.bolt_rounded,
                color: AppColors.indigo,
                filled: true,
                caption: total == 0 ? 'All clear today' : null,
                onTap: onMyDay,
              ),
              right: StatCard(
                value: '$approvals',
                label: 'Pending approvals',
                icon: AppModules.approvals.icon,
                color: AppModules.approvals.color,
                onTap: onApprovals,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _KpiRow(
              left: StatCard(
                value: '$milestones',
                label: 'Overdue T&A milestones',
                icon: AppModules.ta.icon,
                color: milestones > 0 ? AppColors.danger : AppModules.ta.color,
                onTap: onMyDay,
              ),
              right: StatCard(
                value: '$tasks',
                label: 'My overdue tasks',
                icon: AppModules.tasks.icon,
                color: tasks > 0 ? AppColors.warning : AppModules.tasks.color,
                onTap: onTasks,
              ),
            ),
          ],
        );
    }
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Prominent, colourful Reports entry point.
class _ReportsBanner extends StatelessWidget {
  const _ReportsBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const module = AppModules.reports;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: theme.brightness == Brightness.dark ? null : AppColors.softShadow(module.color),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [module.color, AppColors.marigold],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -AppSpacing.md,
                  bottom: -AppSpacing.xl,
                  child: Icon(module.icon, size: 110, color: Colors.white.withValues(alpha: 0.12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(module.icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reports & Analytics',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: AppSpacing.xxs),
                            Text('Business reports with CSV/PDF download',
                                style:
                                    theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
