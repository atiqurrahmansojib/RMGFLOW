import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/costing_list_controller.dart';
import '../domain/costing.dart';
import 'costing_detail_screen.dart';
import 'costing_form_screen.dart';

/// Document 7 (#37): Costing list — shows version, status, and server-computed
/// margin for each style's costing history. Status filter is client-side.
class CostingListScreen extends ConsumerStatefulWidget {
  const CostingListScreen({super.key, this.styleId});

  final int? styleId;

  @override
  ConsumerState<CostingListScreen> createState() => _CostingListScreenState();
}

class _CostingListScreenState extends ConsumerState<CostingListScreen> {
  static const _module = AppModules.costing;
  CostingStatus? _status;
  String _query = '';
  int? _highlightId;

  void _refresh() => ref.read(costingListControllerProvider.notifier).refresh();

  /// Create → the server-computed totals/margin open straight away.
  Future<void> _create() async {
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => CostingFormScreen(initialStyleId: widget.styleId)));
    if (!mounted) return;
    _refresh();
    if (result is Costing) {
      setState(() => _highlightId = result.id);
      _openDetail(result.id);
    }
  }

  void _openDetail(int id) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: id)))
      .then((_) => mounted ? _refresh() : null);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(costingListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Costings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New costing'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(hintText: 'Search by style', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<CostingStatus>(
            values: CostingStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            allLabel: 'All statuses',
            onSelected: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: switch (state) {
              CostingListLoading() => const LoadingView(),
              CostingListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(costingListControllerProvider.notifier).refresh(),
                ),
              CostingListLoaded(:final costings) when costings.isEmpty => EmptyStateView(
                  title: 'No costings yet',
                  message: 'Build a cost sheet for a style — fabric, trims, CM and more — to work out your price.',
                  icon: _module.icon,
                  color: _module.color,
                  actionLabel: 'New costing',
                  onAction: _create,
                ),
              CostingListLoaded(:final costings) => Builder(builder: (context) {
                  final q = _query.trim().toLowerCase();
                  final visible = costings.where((c) {
                    if (_status != null && c.status != _status) return false;
                    if (q.isEmpty) return true;
                    final style = lookupLabel(ref, styleLookupProvider(null), c.styleId).toLowerCase();
                    return style.contains(q) || c.styleId.toString() == q;
                  }).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(costingListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No costings match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: _module.color,
                              actionLabel: 'New costing',
                              onAction: _create,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final costing = visible[index];
                              final style = lookupLabel(ref, styleLookupProvider(null), costing.styleId,
                                  fallback: 'Style #${costing.styleId}');
                              final margin = costing.marginPercent;
                              return RecordTile(
                                accentColor: AppStatus.color(costing.status.apiValue),
                                leading: RecordAvatar(color: _module.color, text: 'v${costing.versionNo}'),
                                title: style,
                                subtitle:
                                    costing.totalCost == null
                                        ? '${costing.currency} · ${costing.quantity} pcs'
                                        : '${formatMoney(costing.currency, costing.totalCost)} · ${costing.quantity} pcs',
                                meta: margin == null ? null : 'Margin ${margin.toStringAsFixed(1)}%',
                                trailing: StatusChip(costing.status.apiValue, label: costing.status.label, dense: true),
                                highlighted: costing.id == _highlightId,
                                onTap: () => _openDetail(costing.id),
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
