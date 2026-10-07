import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/sample_list_controller.dart';
import '../domain/sample.dart';
import 'sample_detail_screen.dart';
import 'sample_form_screen.dart';

/// Document 7 (#32): Sample list — status is a DERIVED rollup (Doc 8.4), shown
/// as-is from the server, never computed here. Search/filter are client-side.
class SampleListScreen extends ConsumerStatefulWidget {
  const SampleListScreen({super.key});

  @override
  ConsumerState<SampleListScreen> createState() => _SampleListScreenState();
}

class _SampleListScreenState extends ConsumerState<SampleListScreen> {
  static const _module = AppModules.sampling;
  SampleStatus? _status;
  String _query = '';
  int? _highlightId;

  void _refresh() => ref.read(sampleListControllerProvider.notifier).refresh();

  /// Create → straight into the new sample so the first revision can be sent.
  Future<void> _create() async {
    final result =
        await Navigator.of(context).push<Object?>(MaterialPageRoute(builder: (_) => const SampleFormScreen()));
    if (!mounted) return;
    _refresh();
    if (result is Sample) {
      setState(() => _highlightId = result.id);
      _openDetail(result);
    }
  }

  void _openDetail(Sample sample) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => SampleDetailScreen(sample: sample)))
      .then((_) => mounted ? _refresh() : null);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sampleListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Samples')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request sample'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(
                hintText: 'Search sample no., style or buyer', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<SampleStatus>(
            values: SampleStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            allLabel: 'All statuses',
            onSelected: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: switch (state) {
              SampleListLoading() => const LoadingView(),
              SampleListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(sampleListControllerProvider.notifier).refresh(),
                ),
              SampleListLoaded(:final samples) when samples.isEmpty => EmptyStateView(
                  title: 'No samples yet',
                  message: 'Request proto, fit, size-set or PP samples and track buyer approval.',
                  icon: _module.icon,
                  color: _module.color,
                  actionLabel: 'Request sample',
                  onAction: _create,
                ),
              SampleListLoaded(:final samples) => Builder(builder: (context) {
                  final q = _query.trim().toLowerCase();
                  final visible = samples.where((s) {
                    if (_status != null && s.currentStatus != _status) return false;
                    if (q.isEmpty) return true;
                    final hay = '${s.sampleNo} ${lookupLabel(ref, styleLookupProvider(null), s.styleId)} '
                            '${lookupLabel(ref, buyerLookupProvider, s.buyerId)}'
                        .toLowerCase();
                    return hay.contains(q);
                  }).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(sampleListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No samples match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: _module.color,
                              actionLabel: 'Request sample',
                              onAction: _create,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final sample = visible[index];
                              final status = sample.currentStatus.apiValue;
                              return RecordTile(
                                accentColor: AppStatus.color(status),
                                leading: RecordAvatar(color: _module.color, icon: _module.icon),
                                title: sample.sampleNo,
                                subtitle:
                                    '${lookupLabel(ref, styleLookupProvider(null), sample.styleId, fallback: 'Style #${sample.styleId}')} · '
                                    '${lookupLabel(ref, buyerLookupProvider, sample.buyerId, fallback: 'Buyer #${sample.buyerId}')}',
                                meta: 'Requested ${formatApiDate(sample.requestDate)}'
                                    '${sample.requiredDate != null ? ' · due ${formatApiDate(sample.requiredDate)}' : ''}',
                                trailing: StatusChip(status, label: sample.currentStatus.label, dense: true),
                                highlighted: sample.id == _highlightId,
                                onTap: () => _openDetail(sample),
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
