import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../activity/presentation/activity_list_screen.dart';
import '../../claim/presentation/claim_list_screen.dart';
import '../../document/domain/commercial_document.dart';
import '../../document/presentation/commercial_document_list_screen.dart';
import '../../financial/presentation/order_financial_screen.dart';
import '../../production/presentation/production_progress_screen.dart';
import '../../quality/presentation/inspection_list_screen.dart';
import '../../shipment/presentation/shipment_list_screen.dart';
import '../../ta/presentation/ta_milestone_list_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../application/order_action_controller.dart';
import '../domain/order.dart';
import 'order_amendments_screen.dart';

/// Hub tiles that are not top-level Home modules reuse a registry colour.
final _amendmentsModule = AppModule(
  id: 'amendments',
  label: 'Amendments',
  icon: Icons.edit_note_rounded,
  color: AppModules.quotation.color,
);
final _activityModule = AppModule(
  id: 'activity',
  label: 'Activity',
  icon: Icons.forum_rounded,
  color: AppModules.inquiries.color,
);
final _financialsModule = AppModule(
  id: 'financial',
  label: 'Financials',
  icon: AppModules.financial.icon,
  color: AppModules.financial.color,
);

/// Document 7 (#49-51): order detail is the hub of every follow-up module —
/// one tap from here to T&A, production, quality, shipment, documents,
/// amendments, financials, claims, tasks and the activity log.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await promptForReason(
      context,
      title: 'Cancel order ${order.orderNo}?',
      message: 'This cannot be undone. Open T&A tasks, production and shipments for this order will stop.',
      label: 'Cancellation reason',
      confirmLabel: 'Cancel order',
      destructive: true,
    );
    if (reason == null) return;
    await ref.read(orderActionControllerProvider.notifier).cancel(order.id, reason);
    if (!context.mounted) return;
    if (ref.read(orderActionControllerProvider) is OrderActionSuccess) {
      showSuccessSnack(context, 'Order ${order.orderNo} cancelled');
      Navigator.of(context).pop(true);
    }
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(orderActionControllerProvider, (previous, next) {
      if (next is OrderActionFailed) showErrorSnack(context, next.failure.message);
    });
    final theme = Theme.of(context);
    final busy = ref.watch(orderActionControllerProvider) is OrderActionInProgress;
    final hasTa = order.exFactoryDate != null && order.items.isNotEmpty;
    final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final daysLeft = daysFromToday(order.exFactoryDate);
    final buyer = lookupLabel(ref, buyerLookupProvider, order.buyerId, fallback: 'Buyer #${order.buyerId}');

    final tiles = <(AppModule, String?, VoidCallback)>[
      (
        AppModules.ta,
        hasTa ? 'Milestones' : 'Needs ex-factory',
        hasTa
            ? () => _push(context, TaMilestoneListScreen(orderId: order.id, styleId: order.items.first.styleId))
            : () => showErrorSnack(context, 'Set an ex-factory date (via amendment) to generate the T&A calendar'),
      ),
      (AppModules.production, 'Cut · sew · pack', () => _push(context, ProductionProgressScreen(orderId: order.id))),
      (AppModules.quality, 'Inspections', () => _push(context, InspectionListScreen(orderId: order.id))),
      (AppModules.shipment, 'ETD · ETA · B/L', () => _push(context, ShipmentListScreen(orderId: order.id))),
      (
        AppModules.documents,
        'Commercial',
        () => _push(context, CommercialDocumentListScreen(entityType: DocumentEntityType.order, entityId: order.id)),
      ),
      (_amendmentsModule, 'Changes', () => _push(context, OrderAmendmentsScreen(orderId: order.id))),
      (_financialsModule, 'AR · AP', () => _push(context, OrderFinancialScreen(orderId: order.id))),
      (AppModules.claims, 'Buyer · factory', () => _push(context, ClaimListScreen(orderId: order.id))),
      (
        AppModules.tasks,
        'To-dos',
        () => _push(context, TaskListScreen(target: (entityType: 'Order', entityId: order.id))),
      ),
      (
        _activityModule,
        'Calls · notes',
        () => _push(context, ActivityListScreen(entityType: 'Order', entityId: order.id)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNo)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          GradientHeader.module(
            AppModules.orders,
            eyebrow: 'PO ${order.buyerPoNo}',
            title: order.orderNo,
            subtitle: buyer,
            trailing: StatusChip(order.status.apiValue, label: order.status.label),
            bottom: Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.md,
              children: [
                HeaderStat(value: fmtQty(totalQty), label: 'Pieces'),
                HeaderStat(value: '${order.currency} ${fmtCompact(order.totalValue)}', label: 'Order value'),
                HeaderStat(
                  value: daysLeft == null ? '—' : (daysLeft >= 0 ? '$daysLeft d' : '${-daysLeft} d late'),
                  label: daysLeft == null ? 'Ex-factory not set' : 'To ex-factory',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader('Follow-up',
                    icon: Icons.dashboard_customize_rounded, accentColor: AppModules.orders.color),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tiles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 5 : 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 132,
                  ),
                  itemBuilder: (context, i) {
                    final (module, caption, onTap) = tiles[i];
                    return ModuleTile.fromModule(module, caption: caption, onTap: onTap);
                  },
                ),
                SectionHeader('Order details', icon: Icons.receipt_long_rounded, accentColor: AppModules.orders.color),
                AppCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'Order no.', value: order.orderNo, copyable: true),
                      InfoRow(label: 'Buyer PO', value: order.buyerPoNo, copyable: true),
                      InfoRow(label: 'Buyer', value: buyer),
                      if (order.quotationId != null)
                        InfoRow(
                            label: 'Quotation',
                            value: lookupLabel(ref, quotationLookupProvider(null), order.quotationId)),
                      InfoRow(label: 'Order date', value: formatApiDate(order.orderDate)),
                      InfoRow(
                        label: 'Ex-factory',
                        value: order.exFactoryDate == null
                            ? null
                            : '${formatApiDate(order.exFactoryDate)}'
                                '${daysLeft == null ? '' : ' · ${relativeDays(daysLeft)}'}',
                        valueColor: daysLeft != null && daysLeft < 0 ? AppColors.danger : null,
                      ),
                      InfoRow(
                          label: 'Delivery',
                          value: order.deliveryDate == null ? null : formatApiDate(order.deliveryDate)),
                      if (order.incoterm != null) InfoRow(label: 'Incoterm', value: order.incoterm),
                      if (order.destinationCountry != null)
                        InfoRow(label: 'Destination', value: order.destinationCountry),
                      const Divider(height: AppSpacing.xl),
                      InfoRow(label: 'Total value', value: fmtMoney(order.currency, order.totalValue), emphasize: true),
                    ],
                  ),
                ),
                SectionHeader('Items',
                    count: order.items.length, icon: Icons.checkroom_rounded, accentColor: AppModules.styles.color),
                ...order.items.map((item) => AppCard(
                      accentColor: AppModules.styles.color,
                      child: RecordRow(
                        title: lookupLabel(ref, styleLookupProvider(null), item.styleId,
                            fallback: 'Style #${item.styleId}'),
                        subtitle: lookupLabel(ref, factoryLookupProvider, item.factoryId,
                            fallback: 'Factory #${item.factoryId}'),
                        meta: [
                          if (item.color != null) item.color!,
                          if (item.size != null) 'Size ${item.size}',
                          '${fmtQty(item.quantity)} pcs',
                        ].join(' · '),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmtMoney(order.currency, item.unitPrice),
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text('per pc',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )),
                if (order.status != OrderStatus.cancelled && order.status != OrderStatus.closed) ...[
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel order',
                    variant: ButtonVariant.danger,
                    loading: busy,
                    onPressed: () => _cancel(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
