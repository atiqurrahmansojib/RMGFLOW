import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';

/// Document 7 (#54-55): T&A templates — the milestone plans (with offsets from
/// ex-factory) that an order's critical path is generated from. Creating or
/// changing templates needs TA_TEMPLATE_MANAGE; the server enforces it.
final _templatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => getJsonList(ref, '/ta-templates'),
);

final _templateMilestonesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, id) async {
  final rows = await getJsonList(ref, '/ta-templates/$id/milestones');
  rows.sort((a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int));
  return rows;
});

final milestoneTypeLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await getJsonList(ref, '/milestone-types');
  rows.sort((a, b) => ((a['defaultSequence'] as int?) ?? 0).compareTo((b['defaultSequence'] as int?) ?? 0));
  return rows
      .map((t) => LookupOption(
            id: t['id'] as int,
            label: t['name'] as String,
            subtitle:
                t['typicalOffsetDays'] == null ? null : 'Typically ${t['typicalOffsetDays']} days before ex-factory',
          ))
      .toList();
});

Future<bool> _post(BuildContext context, WidgetRef ref, String path, Map<String, dynamic> body, String success) async {
  try {
    await authorizedWidgetCall(ref, (dio) => dio.post(path, data: body));
    if (context.mounted) showSuccessSnack(context, success);
    return true;
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    return false;
  }
}

class TaTemplateListScreen extends ConsumerWidget {
  const TaTemplateListScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, const _TemplateSheet());
    if (body == null || !context.mounted) return;
    if (await _post(context, ref, '/ta-templates', body, 'Template created')) ref.invalidate(_templatesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_templatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('T&A Templates')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New template'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorStateView(failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_templatesProvider)),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_templatesProvider),
          child: rows.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No T&A templates',
                    message: 'A template lists the milestones (lab dip, PP sample, inspection…) and how many days '
                        'before ex-factory each is due. Orders generate their critical path from it.',
                    icon: Icons.timeline_rounded,
                    color: AppModules.ta.color,
                    actionLabel: 'New template',
                    onAction: () => _create(context, ref),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.listWithFab,
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final t = rows[i];
                    final buyerId = t['buyerId'] as int?;
                    final isDefault = t['isDefault'] == true || t['default'] == true;
                    return AppCard(
                      accentColor: AppModules.ta.color,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _TemplateDetailScreen(id: t['id'] as int, name: t['name'] as String? ?? ''),
                      )),
                      child: RecordRow(
                        leading: IconBadge(icon: AppModules.ta.icon, color: AppModules.ta.color),
                        title: t['name'] as String? ?? 'Template #${t['id']}',
                        subtitle: buyerId == null
                            ? 'All buyers'
                            : 'For ${lookupLabel(ref, buyerLookupProvider, buyerId, fallback: 'Buyer #$buyerId')}',
                        trailing: isDefault
                            ? const StatusChip('ACTIVE', label: 'Default', dense: true, showIcon: false)
                            : Icon(Icons.chevron_right_rounded, color: AppModules.ta.color),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet();

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  int? _buyerId;
  bool _default = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: 'New T&A template',
        actionLabel: 'Create template',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop({'name': _name.text.trim(), 'buyerId': _buyerId, 'isDefault': _default});
        },
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Template name', hintText: 'e.g. Knit basic 90-day'),
            validator: Validators.required('Template name'),
          ),
          LookupField(
            label: 'Buyer (optional)',
            icon: Icons.storefront_outlined,
            options: buyerLookupProvider,
            helperText: 'Leave empty to use it for any buyer',
            onChanged: (v) => _buyerId = v,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Default template'),
            subtitle: const Text('Used when an order has no buyer-specific template'),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
        ],
      );
}

class _TemplateDetailScreen extends ConsumerWidget {
  const _TemplateDetailScreen({required this.id, required this.name});
  final int id;
  final String name;

  Future<void> _add(BuildContext context, WidgetRef ref, int nextSequence) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, _MilestoneSheet(nextSequence: nextSequence));
    if (body == null || !context.mounted) return;
    if (await _post(context, ref, '/ta-templates/$id/milestones', body, 'Milestone added')) {
      ref.invalidate(_templateMilestonesProvider(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_templateMilestonesProvider(id));
    final next = ((async.valueOrNull?.lastOrNull?['sequence'] as int?) ?? 0) + 1;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, next),
        icon: const Icon(Icons.add),
        label: const Text('Add milestone'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(
            failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_templateMilestonesProvider(id))),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_templateMilestonesProvider(id)),
          child: rows.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No milestones',
                    message: 'Add milestones in the order they happen, with days before ex-factory.',
                    icon: Icons.flag_outlined,
                    color: AppModules.ta.color,
                    actionLabel: 'Add milestone',
                    onAction: () => _add(context, ref, next),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.listWithFab,
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final m = rows[i];
                    final offset = m['offsetDaysFromExfactory'] as int? ?? 0;
                    final dependsOn = m['dependsOnMilestoneId'] as int?;
                    final dep = dependsOn == null ? null : rows.where((r) => r['id'] == dependsOn).firstOrNull;
                    return AppCard(
                      accentColor: AppModules.ta.color,
                      child: RecordRow(
                        leading: CircleAvatar(
                          backgroundColor: AppModules.ta.color,
                          foregroundColor: Colors.white,
                          child: Text('${m['sequence']}'),
                        ),
                        title: lookupLabel(ref, milestoneTypeLookupProvider, m['milestoneTypeId'] as int?),
                        subtitle: [
                          offset == 0
                              ? 'On ex-factory day'
                              : offset > 0
                                  ? '$offset days before ex-factory'
                                  : '${-offset} days after ex-factory',
                          if (dep != null)
                            'after ${lookupLabel(ref, milestoneTypeLookupProvider, dep['milestoneTypeId'] as int?)}',
                        ].join(' · '),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _MilestoneSheet extends StatefulWidget {
  const _MilestoneSheet({required this.nextSequence});
  final int nextSequence;

  @override
  State<_MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<_MilestoneSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _sequence = TextEditingController(text: '${widget.nextSequence}');
  final _offset = TextEditingController();
  int? _typeId;

  @override
  void dispose() {
    _sequence.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: 'Add milestone',
        actionLabel: 'Add milestone',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop({
            'milestoneTypeId': _typeId,
            'sequence': int.parse(_sequence.text.trim()),
            'offsetDaysFromExfactory': int.parse(_offset.text.trim()),
          });
        },
        children: [
          LookupField(
            label: 'Milestone',
            icon: Icons.flag_outlined,
            options: milestoneTypeLookupProvider,
            required: true,
            emptyMessage: 'No milestone types are set up in master data.',
            onChanged: (v) => _typeId = v,
          ),
          TextFormField(
            controller: _sequence,
            keyboardType: TextInputType.number,
            inputFormatters: NumberInput.integer,
            decoration: const InputDecoration(labelText: 'Sequence', helperText: 'Order in the plan: 1, 2, 3…'),
            validator: Validators.positiveInt(what: 'Sequence'),
          ),
          TextFormField(
            controller: _offset,
            keyboardType: TextInputType.number,
            inputFormatters: NumberInput.integer,
            decoration: const InputDecoration(
              labelText: 'Days before ex-factory',
              suffixText: 'days',
              helperText: 'e.g. 60 for lab dip approval, 7 for final inspection',
            ),
            validator: Validators.positiveInt(allowZero: true, what: 'Days'),
          ),
        ],
      );
}
