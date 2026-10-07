import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/lookups/module_access.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../application/quotation_list_controller.dart';
import '../data/quotation_repository_impl.dart';
import '../domain/quotation.dart';
import 'quotation_detail_screen.dart';
import 'quotation_form_screen.dart';

/// Document 7 (#40): Quotation list — searchable by quotation no./buyer/style,
/// filterable by status (both client-side over the loaded page).
class QuotationListScreen extends ConsumerStatefulWidget {
  const QuotationListScreen({super.key});

  @override
  ConsumerState<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends ConsumerState<QuotationListScreen> {
  static const _module = AppModules.quotation;
  QuotationStatus? _status;
  String _query = '';
  int? _highlightId;

  void _refresh() => ref.read(quotationListControllerProvider.notifier).refresh();

  /// Create → the new quotation opens straight away.
  Future<void> _create() async {
    final result =
        await Navigator.of(context).push<Object?>(MaterialPageRoute(builder: (_) => const QuotationFormScreen()));
    if (!mounted) return;
    _refresh();
    if (result is Quotation) {
      setState(() => _highlightId = result.id);
      _openDetail(result);
    }
  }

  void _openDetail(Quotation q) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: q)))
      .then((_) => mounted ? _refresh() : null);

  /// Inline status change from the row's status chip. Only negative moves
  /// (rejected / expired) ask for confirmation.
  Future<void> _changeStatus(Quotation q, QuotationStatus s) async {
    if (s == QuotationStatus.rejected || s == QuotationStatus.expired) {
      final ok = await confirmAction(
        context,
        title: 'Mark as ${s.label}?',
        message: '${q.quotationNo ?? 'This quotation'} will move from ${q.status.label} to ${s.label}.',
        confirmLabel: 'Mark ${s.label.toLowerCase()}',
        destructive: true,
      );
      if (!ok) return;
    }
    try {
      await ref
          .read(authControllerProvider.notifier)
          .callAuthorized(() => ref.read(quotationRepositoryProvider).updateStatus(q.id, s));
      if (!mounted) return;
      showSuccessSnack(context, '${q.quotationNo ?? 'Quotation'} marked ${s.label.toLowerCase()}');
      _refresh();
    } on DioException catch (e) {
      if (mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    }
  }

  void _quickActions(Quotation q) => showQuickActions(
        context,
        title: q.quotationNo ?? 'Quotation #${q.id}',
        subtitle: 'Version ${q.versionNo} · ${q.status.label}',
        actions: [
          QuickAction(
              label: 'Open quotation',
              icon: Icons.open_in_new_rounded,
              color: _module.color,
              onSelected: () => _openDetail(q)),
          for (final s in nextQuotationStatuses(q.status, canApprove: canApproveQuotations(ref.read(currentUserProvider))))
            QuickAction(
              label: 'Mark ${s.label.toLowerCase()}',
              icon: AppStatus.resolve(s.apiValue).icon,
              color: AppStatus.color(s.apiValue),
              destructive: s == QuotationStatus.rejected,
              onSelected: () => _changeStatus(q, s),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New quotation'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(
                hintText: 'Search quotation no., buyer or style', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<QuotationStatus>(
            values: QuotationStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            allLabel: 'All statuses',
            onSelected: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: switch (state) {
              QuotationListLoading() => const LoadingView(),
              QuotationListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(quotationListControllerProvider.notifier).refresh(),
                ),
              QuotationListLoaded(:final quotations) when quotations.isEmpty => EmptyStateView(
                  title: 'No quotations yet',
                  message: 'Turn an approved costing into a price offer for your buyer.',
                  icon: _module.icon,
                  color: _module.color,
                  actionLabel: 'New quotation',
                  onAction: _create,
                ),
              QuotationListLoaded(:final quotations) => Builder(builder: (context) {
                  final q = _query.trim().toLowerCase();
                  final visible = quotations.where((x) {
                    if (_status != null && x.status != _status) return false;
                    if (q.isEmpty) return true;
                    final hay = [
                      x.quotationNo ?? '',
                      lookupLabel(ref, buyerLookupProvider, x.buyerId),
                      lookupLabel(ref, styleLookupProvider(null), x.styleId),
                    ].join(' ').toLowerCase();
                    return hay.contains(q);
                  }).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(quotationListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No quotations match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: _module.color,
                              actionLabel: 'New quotation',
                              onAction: _create,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final quotation = visible[index];
                              return RecordTile(
                                accentColor: AppStatus.color(quotation.status.apiValue),
                                leading: RecordAvatar(color: _module.color, text: 'v${quotation.versionNo}'),
                                title: quotation.quotationNo ?? 'Quotation #${quotation.id}',
                                subtitle:
                                    '${lookupLabel(ref, buyerLookupProvider, quotation.buyerId, fallback: 'Buyer #${quotation.buyerId}')} · '
                                    '${lookupLabel(ref, styleLookupProvider(null), quotation.styleId, fallback: 'Style #${quotation.styleId}')}',
                                meta:
                                    '${formatMoney(quotation.currency, quotation.unitPrice)} × ${quotation.quantity} pcs'
                                    ' = ${formatMoney(quotation.currency, quotation.unitPrice * quotation.quantity)}',
                                trailing: StatusMenuChip<QuotationStatus>(
                                  status: quotation.status.apiValue,
                                  label: quotation.status.label,
                                  enabled: nextQuotationStatuses(quotation.status,
                                          canApprove: canApproveQuotations(ref.watch(currentUserProvider)))
                                      .isNotEmpty,
                                  options: nextQuotationStatuses(quotation.status,
                                      canApprove: canApproveQuotations(ref.watch(currentUserProvider))),
                                  apiValueOf: (s) => s.apiValue,
                                  labelOf: (s) => s.label,
                                  onSelected: (s) => _changeStatus(quotation, s),
                                ),
                                highlighted: quotation.id == _highlightId,
                                onTap: () => _openDetail(quotation),
                                onLongPress: () => _quickActions(quotation),
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
