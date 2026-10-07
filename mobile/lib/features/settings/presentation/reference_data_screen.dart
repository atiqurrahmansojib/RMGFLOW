import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';

/// Document 7 (#9-14): read-only view of the organization's master data —
/// seasons, currencies, countries, incoterms, payment terms, document types,
/// defect types and the T&A milestone library — so users can see the exact
/// codes and names every picker offers. Editing stays an admin task.
class _RefSet {
  const _RefSet(this.title, this.path, this.icon, this.describe, [this.color = AppColors.info]);
  final String title;
  final Color color;
  final String path;
  final IconData icon;

  /// Row → (title, subtitle).
  final (String, String?) Function(Map<String, dynamic>) describe;
}

String? _join(List<Object?> parts) {
  final kept = parts.where((p) => p != null && p.toString().trim().isNotEmpty).map((p) => p.toString()).toList();
  return kept.isEmpty ? null : kept.join(' · ');
}

final _sets = <_RefSet>[
  _RefSet(
      'Seasons',
      '/seasons',
      Icons.wb_sunny_outlined,
      (r) => (
            '${r['name']}',
            _join([
              r['year'],
              if (r['startDate'] != null)
                '${formatApiDate(r['startDate'] as String)} – ${formatApiDate(r['endDate'] as String?)}',
            ]),
          )),
  _RefSet('Currencies', '/currencies', Icons.currency_exchange_rounded, (r) => ('${r['code']}', r['name'] as String?),
      AppColors.success),
  _RefSet(
      'Countries', '/countries', Icons.public_rounded, (r) => ('${r['code']}', r['name'] as String?), AppColors.teal),
  _RefSet('Incoterms', '/incoterms', Icons.sailing_outlined, (r) => ('${r['code']}', r['name'] as String?),
      AppColors.indigo),
  _RefSet(
      'Payment terms', '/payment-terms', Icons.payments_outlined, (r) => ('${r['name']}', r['description'] as String?)),
  _RefSet(
      'Document types',
      '/document-types',
      Icons.description_outlined,
      (r) => (
            '${r['name']}',
            _join([r['category'], if (r['mandatoryDefault'] == true) 'Mandatory by default']),
          )),
  _RefSet(
      'Defect types',
      '/defect-types',
      Icons.report_problem_outlined,
      (r) => (
            '${r['name']}',
            _join([r['category'], r['severity'] == null ? null : AppStatus.humanize(r['severity'] as String)]),
          )),
  _RefSet(
      'T&A milestone types',
      '/milestone-types',
      Icons.flag_outlined,
      (r) => (
            '${r['name']}',
            _join([
              'Sequence ${r['defaultSequence']}',
              if (r['typicalOffsetDays'] != null) '${r['typicalOffsetDays']} days before ex-factory',
            ]),
          )),
];

class ReferenceDataScreen extends StatelessWidget {
  const ReferenceDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reference Data')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          for (final set in _sets)
            LinkCard(
              icon: set.icon,
              color: set.color,
              title: set.title,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _RefListScreen(set: set))),
            ),
        ],
      ),
    );
  }
}

final _refRowsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, path) => getJsonList(ref, path),
);

class _RefListScreen extends ConsumerStatefulWidget {
  const _RefListScreen({required this.set});
  final _RefSet set;

  @override
  ConsumerState<_RefListScreen> createState() => _RefListScreenState();
}

class _RefListScreenState extends ConsumerState<_RefListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final async = ref.watch(_refRowsProvider(set.path));
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorStateView(failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_refRowsProvider(set.path))),
        data: (rows) {
          final q = _query.trim().toLowerCase();
          final described = rows.map(set.describe).where((d) {
            if (q.isEmpty) return true;
            return d.$1.toLowerCase().contains(q) || (d.$2?.toLowerCase().contains(q) ?? false);
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: SearchField(
                    hintText: 'Search ${set.title.toLowerCase()}', onChanged: (v) => setState(() => _query = v)),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_refRowsProvider(set.path)),
                  child: described.isEmpty
                      ? RefreshableEmpty(
                          child: EmptyStateView(
                            message: rows.isEmpty
                                ? 'No ${set.title.toLowerCase()} are set up yet. Ask an administrator to add them.'
                                : 'Nothing matches your search.',
                            icon: set.icon,
                            color: set.color,
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: AppSpacing.page,
                          itemCount: described.length,
                          itemBuilder: (context, i) => RecordTile(
                            accentColor: set.color,
                            title: described[i].$1,
                            subtitle: described[i].$2,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
