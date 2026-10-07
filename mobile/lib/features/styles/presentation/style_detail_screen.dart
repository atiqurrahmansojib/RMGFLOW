import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../activity/presentation/activity_list_screen.dart';
import '../../costing/domain/costing.dart';
import '../../costing/presentation/costing_detail_screen.dart';
import '../../costing/presentation/costing_form_screen.dart';
import '../../task/presentation/task_list_screen.dart';
import '../../../core/network/failure_mapper.dart';
import '../domain/style.dart';

/// Document 7 (#29/#31): style overview plus its spec revisions. Revisions are
/// create-only (FR-31) — a spec change is a new revision, never an edit — and
/// any two can be compared side by side.
final _revisionsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, styleId) async {
  final rows = await getJsonList(ref, '/styles/$styleId/revisions');
  rows.sort((a, b) => (b['revisionNo'] as int).compareTo(a['revisionNo'] as int));
  return rows;
});

const _specFields = <(String, String)>[
  ('fabric', 'Fabric'),
  ('composition', 'Composition'),
  ('gsm', 'GSM'),
  ('color', 'Colour'),
  ('sizeRange', 'Size range'),
  ('measurementSpecJson', 'Measurements'),
];

String? _specValue(Map<String, dynamic> rev, String key) {
  final v = rev[key];
  if (key == 'measurementSpecJson' && v is String) return _readableMeasurements(v);
  if (v == null) return null;
  if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toString();
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// The server stores measurements as JSON; free text typed here comes back as
/// {"notes": "..."}. Show either as plain lines instead of raw JSON.
String? _readableMeasurements(String raw) {
  if (raw.trim().isEmpty) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return raw.trim();
  }
  String flat(Object? v) => v is Map
      ? v.entries.map((e) => '${e.key} ${flat(e.value)}').join(', ')
      : v is List
          ? v.map(flat).join(', ')
          : '$v';
  if (decoded is Map) {
    if (decoded.length == 1 && decoded['notes'] is String) return decoded['notes'] as String;
    return decoded.entries.map((e) => '${e.key}: ${flat(e.value)}').join('\n');
  }
  return flat(decoded);
}

String _when(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  return d == null ? '' : DateFormat('dd MMM yyyy, HH:mm').format(d);
}

class StyleDetailScreen extends ConsumerWidget {
  const StyleDetailScreen({super.key, required this.style});

  final Style style;

  Future<void> _addRevision(BuildContext context, WidgetRef ref, Map<String, dynamic>? latest) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, _RevisionSheet(copyFrom: latest));
    if (body == null || !context.mounted) return;
    try {
      await authorizedWidgetCall(ref, (dio) => dio.post('/styles/${style.id}/revisions', data: body));
      if (context.mounted) showSuccessSnack(context, 'New spec revision saved');
      ref.invalidate(_revisionsProvider(style.id));
    } on DioException catch (e) {
      if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    }
  }

  /// Shortcut: cost this style without re-picking it.
  Future<void> _newCosting(BuildContext context) async {
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => CostingFormScreen(initialStyleId: style.id)));
    if (result is Costing && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: result.id)));
    }
  }

  void _compare(BuildContext context, List<Map<String, dynamic>> revisions) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _RevisionCompareScreen(styleNo: style.styleNo, revisions: revisions),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_revisionsProvider(style.id));
    final revisions = async.valueOrNull ?? const <Map<String, dynamic>>[];
    const module = AppModules.styles;
    final buyer = lookupLabel(ref, buyerLookupProvider, style.buyerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(style.styleNo),
        actions: [
          if (revisions.length >= 2)
            IconButton(
              tooltip: 'Compare revisions',
              icon: const Icon(Icons.compare_arrows_rounded),
              onPressed: () => _compare(context, revisions),
            ),
          IconButton(
            tooltip: 'New costing for this style',
            icon: Icon(AppModules.costing.icon),
            onPressed: () => _newCosting(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRevision(context, ref, revisions.isEmpty ? null : revisions.first),
        icon: const Icon(Icons.note_add_outlined),
        label: Text(revisions.isEmpty ? 'Add spec' : 'New revision'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_revisionsProvider(style.id)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.listWithFab,
          children: [
            GradientHeader.module(
              module,
              margin: EdgeInsets.zero,
              eyebrow: 'Style',
              title: style.styleNo,
              subtitle: [buyer, if (style.productCategory != null) style.productCategory!].join(' · '),
              trailing: StatusChip(style.active ? 'ACTIVE' : 'INACTIVE'),
              bottom: Row(
                children: [
                  Expanded(
                    child: HeaderStat(
                      value: revisions.isEmpty ? '—' : 'R${revisions.first['revisionNo']}',
                      label: 'Current spec',
                    ),
                  ),
                  Expanded(child: HeaderStat(value: '${revisions.length}', label: 'Revisions')),
                  Expanded(child: HeaderStat(value: style.gender ?? '—', label: 'Gender')),
                ],
              ),
            ),
            SectionHeader('Overview', icon: Icons.info_outline_rounded, accentColor: module.color),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Buyer', value: buyer),
                  InfoRow(label: "Buyer's style no.", value: style.buyerStyleNo, copyable: true),
                  InfoRow(label: 'Product category', value: style.productCategory),
                  InfoRow(label: 'Gender', value: style.gender),
                  if (style.description != null)
                    InfoRow(label: 'Description', value: style.description, vertical: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinkCard(
              icon: AppModules.costing.icon,
              color: AppModules.costing.color,
              title: 'New costing',
              subtitle: 'Build a cost sheet for this style',
              onTap: () => _newCosting(context),
            ),
            RecordLinks(
              tasks: () => TaskListScreen(target: (entityType: 'Style', entityId: style.id)),
              activity: () => ActivityListScreen(entityType: 'Style', entityId: style.id),
            ),
            SectionHeader(
              'Spec revisions',
              subtitle: 'Newest first',
              count: revisions.length,
              icon: Icons.description_outlined,
              accentColor: module.color,
            ),
            ...async.when(
              loading: () => [const LoadingView(layout: LoadingLayout.list, itemCount: 2, padding: EdgeInsets.zero)],
              error: (e, _) => [
                ErrorStateView(
                    failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_revisionsProvider(style.id))),
              ],
              data: (rows) => rows.isEmpty
                  ? [
                      EmptyStateView(
                        title: 'No spec yet',
                        message:
                            'Record fabric, composition, GSM, colour and sizes. Each change becomes a new revision.',
                        icon: Icons.description_outlined,
                        color: module.color,
                        actionLabel: 'Add spec',
                        onAction: () => _addRevision(context, ref, null),
                      ),
                    ]
                  : [
                      for (final (i, r) in rows.indexed)
                        AppCard(
                          accentColor: i == 0 ? module.color : AppColors.neutral,
                          padding: EdgeInsets.zero,
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: i == 0,
                              leading: RecordAvatar(
                                color: i == 0 ? module.color : AppColors.neutral,
                                text: 'R${r['revisionNo']}',
                                size: 40,
                              ),
                              title: Text('Revision ${r['revisionNo']}'),
                              subtitle: Text(_when(r['createdAt'] as String?)),
                              trailing: i == 0 ? const StatusChip('ACTIVE', label: 'Current', dense: true) : null,
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                              children: [
                                for (final (key, label) in _specFields)
                                  InfoRow(
                                      label: label, value: _specValue(r, key), vertical: key == 'measurementSpecJson'),
                              ],
                            ),
                          ),
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevisionSheet extends StatefulWidget {
  const _RevisionSheet({this.copyFrom});

  /// Latest revision — pre-fills the form so a revision only changes what moved.
  final Map<String, dynamic>? copyFrom;

  @override
  State<_RevisionSheet> createState() => _RevisionSheetState();
}

class _RevisionSheetState extends State<_RevisionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c = {
    for (final (key, _) in _specFields)
      key: TextEditingController(text: widget.copyFrom == null ? '' : (_specValue(widget.copyFrom!, key) ?? '')),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: widget.copyFrom == null ? 'Add spec' : 'New spec revision',
        subtitle: widget.copyFrom == null
            ? null
            : 'Pre-filled from revision ${widget.copyFrom!['revisionNo']} — change what is different.',
        actionLabel: 'Save revision',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          final gsm = double.tryParse(_c['gsm']!.text.trim());
          final body = <String, dynamic>{
            for (final (key, _) in _specFields)
              if (key != 'gsm') key: blankToNull(_c[key]!.text),
            'gsm': gsm,
          };
          // Untouched pre-filled measurements: resend the original JSON, not the
          // readable text, so the structured spec isn't flattened into notes.
          final copied = widget.copyFrom;
          if (copied != null &&
              body['measurementSpecJson'] != null &&
              body['measurementSpecJson'] == _specValue(copied, 'measurementSpecJson')?.trim()) {
            body['measurementSpecJson'] = copied['measurementSpecJson'];
          }
          if (body.values.every((v) => v == null)) {
            showErrorSnack(context, 'Fill in at least one spec field');
            return;
          }
          Navigator.of(context).pop(body);
        },
        children: [
          TextFormField(
            controller: _c['fabric'],
            decoration: const InputDecoration(labelText: 'Fabric', hintText: 'e.g. Single jersey'),
          ),
          TextFormField(
            controller: _c['composition'],
            decoration: const InputDecoration(labelText: 'Composition', hintText: 'e.g. 95% cotton, 5% elastane'),
          ),
          TextFormField(
            controller: _c['gsm'],
            keyboardType: NumberInput.decimalKeyboard,
            inputFormatters: NumberInput.decimal,
            decoration: const InputDecoration(labelText: 'GSM', suffixText: 'g/m²'),
            validator: Validators.money(required: false, what: 'GSM'),
          ),
          TextFormField(
            controller: _c['color'],
            decoration: const InputDecoration(labelText: 'Colour(s)', hintText: 'e.g. Navy, Heather grey'),
          ),
          TextFormField(
            controller: _c['sizeRange'],
            decoration: const InputDecoration(labelText: 'Size range', hintText: 'e.g. S–XXL'),
          ),
          TextFormField(
            controller: _c['measurementSpecJson'],
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Measurements',
              hintText: 'Chest 52 cm, body length 70 cm…',
            ),
          ),
        ],
      );
}

/// Document 7 (#31): pick two revisions; differing fields are highlighted.
class _RevisionCompareScreen extends StatefulWidget {
  const _RevisionCompareScreen({required this.styleNo, required this.revisions});
  final String styleNo;
  final List<Map<String, dynamic>> revisions;

  @override
  State<_RevisionCompareScreen> createState() => _RevisionCompareScreenState();
}

class _RevisionCompareScreenState extends State<_RevisionCompareScreen> {
  late int _left = widget.revisions[1]['revisionNo'] as int;
  late int _right = widget.revisions[0]['revisionNo'] as int;

  Map<String, dynamic> _rev(int no) => widget.revisions.firstWhere((r) => r['revisionNo'] == no);

  Widget _picker(int value, ValueChanged<int> onChanged) => DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(isDense: true),
        items: [
          for (final r in widget.revisions)
            DropdownMenuItem(value: r['revisionNo'] as int, child: Text('Revision ${r['revisionNo']}')),
        ],
        onChanged: (v) => setState(() => onChanged(v!)),
      );

  @override
  Widget build(BuildContext context) {
    final a = _rev(_left);
    final b = _rev(_right);
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.styleNo} · Compare')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Row(
            children: [
              Expanded(child: _picker(_left, (v) => _left = v)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded)),
              Expanded(child: _picker(_right, (v) => _right = v)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (key, label) in _specFields)
            Builder(builder: (context) {
              final va = _specValue(a, key) ?? '—';
              final vb = _specValue(b, key) ?? '—';
              final changed = va != vb;
              return AppCard(
                accentColor: changed ? AppColors.warning : null,
                color: changed ? s.tertiaryContainer : null,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
                        if (changed)
                          const StatusChip('UPDATED', label: 'Changed', dense: true, tone: StatusTone.warning),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: Text(va)), const SizedBox(width: 12), Expanded(child: Text(vb))],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
