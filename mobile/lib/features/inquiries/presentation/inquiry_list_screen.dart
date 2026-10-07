import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/inquiry_list_controller.dart';
import '../domain/inquiry.dart';
import 'inquiry_factory_candidates_screen.dart';
import 'inquiry_form_screen.dart';
import 'inquiry_status_actions.dart';

/// Document 7 (#24)/14.2: Inquiry List — the BD pipeline view, filterable by
/// status (server-side) and searchable by inquiry no./buyer (client-side).
class InquiryListScreen extends ConsumerStatefulWidget {
  const InquiryListScreen({super.key});

  @override
  ConsumerState<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends ConsumerState<InquiryListScreen> {
  static const _module = AppModules.inquiries;
  InquiryStatus? _status;
  String _query = '';
  int? _highlightId;

  void _refresh() => ref.read(inquiryListControllerProvider.notifier).refresh();

  /// Create → the new inquiry opens straight away (status, factory
  /// candidates, tasks), so the merchandiser keeps going without searching.
  Future<void> _open([Inquiry? existing]) async {
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => InquiryFormScreen(existingInquiry: existing)));
    if (!mounted) return;
    _refresh();
    if (result is Inquiry && existing == null) {
      setState(() => _highlightId = result.id);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InquiryFormScreen(existingInquiry: result)));
      if (mounted) _refresh();
    }
  }

  Future<void> _changeStatus(Inquiry inquiry, InquiryStatus target) async {
    final ok = await changeInquiryStatusInline(context, ref, inquiry, target);
    if (ok && mounted) _refresh();
  }

  void _quickActions(Inquiry inquiry) => showQuickActions(
        context,
        title: inquiry.inquiryNo,
        subtitle: inquiry.buyerName,
        actions: [
          QuickAction(
              label: 'Open inquiry',
              icon: Icons.open_in_new_rounded,
              color: _module.color,
              onSelected: () => _open(inquiry)),
          QuickAction(
            label: 'Factory candidates',
            icon: Icons.factory_outlined,
            color: AppModules.factories.color,
            onSelected: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => InquiryFactoryCandidatesScreen(inquiry: inquiry))),
          ),
          for (final s in nextInquiryStatuses(inquiry))
            QuickAction(
              label: 'Mark ${s.label.toLowerCase()}',
              subtitle: inquiryStatusHint(s),
              icon: AppStatus.resolve(s.apiValue).icon,
              color: AppStatus.color(s.apiValue),
              destructive: s == InquiryStatus.lost,
              onSelected: () => _changeStatus(inquiry, s),
            ),
        ],
      );

  bool _matches(Inquiry i) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || i.inquiryNo.toLowerCase().contains(q) || i.buyerName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inquiryListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inquiries')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New inquiry'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(hintText: 'Search inquiry no. or buyer', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<InquiryStatus>(
            values: InquiryStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            allLabel: 'All statuses',
            onSelected: (s) {
              setState(() => _status = s);
              ref.read(inquiryListControllerProvider.notifier).setFilter(s);
            },
          ),
          Expanded(
            child: switch (state) {
              InquiryListLoading() => const LoadingView(),
              InquiryListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(inquiryListControllerProvider.notifier).refresh(),
                ),
              InquiryListLoaded(:final inquiries) when inquiries.isEmpty && _status == null => EmptyStateView(
                  title: 'No inquiries yet',
                  message: 'Log every buyer request here to track it from first contact to order.',
                  icon: _module.icon,
                  color: _module.color,
                  actionLabel: 'New inquiry',
                  onAction: _open,
                ),
              InquiryListLoaded(:final inquiries) => Builder(builder: (context) {
                  final visible = inquiries.where(_matches).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(inquiryListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No inquiries match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: _module.color,
                              actionLabel: 'New inquiry',
                              onAction: _open,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final inquiry = visible[index];
                              return RecordTile(
                                accentColor: AppStatus.color(inquiry.status.apiValue),
                                leading: RecordAvatar(color: _module.color, text: recordInitials(inquiry.buyerName)),
                                title: inquiry.buyerName,
                                subtitle: inquiry.inquiryNo,
                                meta: [
                                  if (inquiry.targetQuantity != null) '${inquiry.targetQuantity} pcs',
                                  if (inquiry.targetPrice != null)
                                    'target ${formatMoney(inquiry.targetCurrency, inquiry.targetPrice)}',
                                ].join(' · '),
                                trailing: StatusMenuChip<InquiryStatus>(
                                  status: inquiry.status.apiValue,
                                  label: inquiry.status.label,
                                  options: nextInquiryStatuses(inquiry),
                                  apiValueOf: (s) => s.apiValue,
                                  labelOf: (s) => s.label,
                                  onSelected: (s) => _changeStatus(inquiry, s),
                                ),
                                highlighted: inquiry.id == _highlightId,
                                onTap: () => _open(inquiry),
                                onLongPress: () => _quickActions(inquiry),
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
