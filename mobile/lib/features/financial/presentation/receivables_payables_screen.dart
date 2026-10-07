import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../order/presentation/open_order.dart';
import '../application/ledger_providers.dart';
import '../application/order_financial_controller.dart';
import '../domain/financial.dart';
import 'order_financial_screen.dart';

/// Document 7 (#78-80): the accounts view — every receivable (buyer owes us)
/// and payable (we owe the factory) across all orders, with outstanding
/// totals per currency, status filter, search, and payment recording.
/// Statuses (PENDING/PARTIAL/RECEIVED|PAID/OVERDUE) are derived server-side.
class ReceivablesPayablesScreen extends StatelessWidget {
  const ReceivablesPayablesScreen({super.key, this.initialTab = 0});

  /// 0 = receivables, 1 = payables.
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receivables & Payables'),
          bottom: const TabBar(tabs: [Tab(text: 'Receivables'), Tab(text: 'Payables')]),
        ),
        body: const TabBarView(children: [_LedgerTab(receivables: true), _LedgerTab(receivables: false)]),
      ),
    );
  }
}

/// One row of either ledger, normalised so both tabs share the UI.
class _Entry {
  _Entry.receivable(Receivable r)
      : id = r.id,
        orderId = r.orderId,
        partyId = r.buyerId,
        amount = r.amount,
        settledAmount = r.receivedAmount,
        currency = r.currency,
        dueDate = r.dueDate,
        status = r.status;

  _Entry.payable(Payable p)
      : id = p.id,
        orderId = p.orderId,
        partyId = p.factoryId,
        amount = p.amount,
        settledAmount = p.paidAmount,
        currency = p.currency,
        dueDate = p.dueDate,
        status = p.status;

  final int id;
  final int orderId;
  final int partyId;
  final double amount;
  final double settledAmount;
  final String currency;
  final String dueDate;
  final String status;

  double get outstanding => amount - settledAmount;
  bool get settled => outstanding <= 0.0001;
  bool get overdue {
    final due = parseApiDate(dueDate);
    final today = DateTime.now();
    return !settled && due != null && due.isBefore(DateTime(today.year, today.month, today.day));
  }
}

enum _Filter { open, overdue, settled }

extension on _Filter {
  String get label => switch (this) {
        _Filter.open => 'Open',
        _Filter.overdue => 'Overdue',
        _Filter.settled => 'Settled',
      };

  bool matches(_Entry e) => switch (this) {
        _Filter.open => !e.settled,
        _Filter.overdue => e.overdue,
        _Filter.settled => e.settled,
      };
}

class _LedgerTab extends ConsumerStatefulWidget {
  const _LedgerTab({required this.receivables});
  final bool receivables;

  @override
  ConsumerState<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends ConsumerState<_LedgerTab> with AutomaticKeepAliveClientMixin {
  _Filter? _filter = _Filter.open;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  bool get _rx => widget.receivables;

  Future<void> _refresh() async {
    if (_rx) {
      ref.invalidate(allReceivablesProvider);
      await ref.read(allReceivablesProvider.future);
    } else {
      ref.invalidate(allPayablesProvider);
      await ref.read(allPayablesProvider.future);
    }
  }

  String _party(_Entry e) => _rx
      ? lookupLabel(ref, buyerLookupProvider, e.partyId, fallback: 'Buyer #${e.partyId}')
      : lookupLabel(ref, factoryLookupProvider, e.partyId, fallback: 'Factory #${e.partyId}');

  String _order(_Entry e) => lookupLabel(ref, orderLookupProvider, e.orderId, fallback: 'Order #${e.orderId}');

  Future<void> _recordPayment(_Entry e) async {
    final draft = await showFormSheet<PaymentRecordDraft>(
      context,
      PaymentSheet(
        receivableId: _rx ? e.id : null,
        payableId: _rx ? null : e.id,
        currency: e.currency,
        outstanding: e.outstanding,
      ),
    );
    if (draft == null || !mounted) return;
    await ref.read(financialActionControllerProvider.notifier).recordPayment(draft);
    final result = ref.read(financialActionControllerProvider);
    if (!mounted) return;
    if (result is FinancialActionSuccess) {
      showSuccessSnack(context, _rx ? 'Payment received recorded' : 'Payment made recorded');
      _refresh();
    } else if (result is FinancialActionFailed) {
      showErrorSnack(context, result.failure.message);
    }
  }

  void _openActions(_Entry e, {required String party, required String order}) => showQuickActions(
        context,
        title: '$party · ${fmtMoney(e.currency, e.amount)}',
        subtitle: '$order · due ${formatApiDate(e.dueDate)}',
        actions: [
          if (!e.settled)
            QuickAction(
              icon: Icons.payments_rounded,
              label: _rx ? 'Record payment received' : 'Record payment made',
              color: _rx ? AppColors.success : AppModules.production.color,
              onTap: () => _recordPayment(e),
            ),
          QuickAction(
            icon: AppModules.financial.icon,
            label: 'Open order financials',
            color: AppModules.financial.color,
            onTap: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => OrderFinancialScreen(orderId: e.orderId)));
              if (mounted) _refresh();
            },
          ),
          QuickAction(
            icon: AppModules.orders.icon,
            label: 'Open order',
            color: AppModules.orders.color,
            onTap: () => openOrderById(context, ref, e.orderId),
          ),
        ],
      );

  /// Built during build(), so the lookup-backed labels are watched there and
  /// the tap handler only reuses the resolved strings.
  Widget _tile(_Entry e, ThemeData theme) {
    final party = _party(e);
    final order = _order(e);
    final color = _rx ? AppColors.success : AppModules.production.color;
    final days = daysFromToday(e.dueDate);
    final ratio = e.amount <= 0 ? 0.0 : (e.settledAmount / e.amount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SwipeAction(
        key: ValueKey('${_rx ? 'ar' : 'ap'}-${e.id}'),
        startLabel: _rx ? 'Receive' : 'Pay',
        startIcon: Icons.payments_rounded,
        startColor: color,
        onSwipeStart: e.settled ? null : () => _recordPayment(e),
        child: AppCard(
          accentColor: e.overdue ? AppColors.danger : AppStatus.color(e.status),
          onTap: () => _openActions(e, party: party, order: order),
          onLongPress: () => _openActions(e, party: party, order: order),
          child: RecordRow(
            leading: IconBadge(
              icon: _rx ? AppModules.buyers.icon : AppModules.factories.icon,
              color: e.overdue ? AppColors.danger : (_rx ? AppModules.buyers.color : AppModules.factories.color),
            ),
            title: party,
            subtitle: '$order · ${_rx ? 'received' : 'paid'} ${fmtMoney(e.currency, e.settledAmount)}',
            meta: 'Due ${formatApiDate(e.dueDate)}'
                '${e.settled ? '' : ' · outstanding ${fmtMoney(e.currency, e.outstanding)}'}',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmtMoney(e.currency, e.amount),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                e.overdue && days != null
                    ? TonePill(relativeDays(days), color: AppColors.danger, icon: Icons.alarm_rounded)
                    : StatusChip(e.status, dense: true),
              ],
            ),
            footer: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AsyncValue<List<_Entry>> async = _rx
        ? ref.watch(allReceivablesProvider).whenData((l) => l.map(_Entry.receivable).toList())
        : ref.watch(allPayablesProvider).whenData((l) => l.map(_Entry.payable).toList());
    final theme = Theme.of(context);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorStateView(failure: mapErrorToFailure(e), onRetry: _refresh),
      data: (all) {
        final q = _query.trim().toLowerCase();
        final rows = all.where((e) {
          if (_filter != null && !_filter!.matches(e)) return false;
          if (q.isEmpty) return true;
          return _party(e).toLowerCase().contains(q) || _order(e).toLowerCase().contains(q);
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        // Outstanding per currency — never summed across currencies.
        final outstanding = <String, double>{};
        for (final e in all.where((e) => !e.settled)) {
          outstanding[e.currency] = (outstanding[e.currency] ?? 0) + e.outstanding;
        }
        final overdueCount = all.where((e) => e.overdue).length;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: _rx ? 'To collect' : 'To pay',
                        value: outstanding.isEmpty
                            ? '0'
                            : '${outstanding.keys.first} ${fmtCompact(outstanding.values.first)}',
                        caption: outstanding.length > 1
                            ? outstanding.entries.skip(1).map((e) => '+ ${e.key} ${fmtCompact(e.value)}').join(' ')
                            : null,
                        icon: _rx ? Icons.call_received_rounded : Icons.call_made_rounded,
                        color: _rx ? AppColors.success : AppColors.warning,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        label: 'Overdue',
                        value: '$overdueCount',
                        icon: Icons.alarm_rounded,
                        color: AppColors.danger,
                        filled: overdueCount > 0,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: SearchField(
                  hintText: _rx ? 'Search buyer or order' : 'Search factory or order',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FilterChipBar<_Filter>(
                values: _Filter.values,
                selected: _filter,
                labelOf: (f) => f.label,
                onSelected: (f) => setState(() => _filter = f),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: EmptyStateView(
                    color: AppModules.financial.color,
                    title: all.isEmpty ? (_rx ? 'No receivables yet' : 'No payables yet') : 'Nothing here',
                    message: all.isEmpty
                        ? 'Add ${_rx ? 'receivables' : 'payables'} from an order\'s Financials screen.'
                        : 'No ${_rx ? 'receivables' : 'payables'} match this filter.',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                )
              else
                for (final e in rows) _tile(e, theme),
            ],
          ),
        );
      },
    );
  }
}
