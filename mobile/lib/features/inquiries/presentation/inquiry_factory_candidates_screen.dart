import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../domain/inquiry.dart';

/// Document 7 (#25 Factory Candidates tab): the shortlist of factories being
/// considered for an inquiry. Each candidate moves CANDIDATE → SELECTED or
/// REJECTED; the backend owns the transition rules.
final _candidatesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, inquiryId) => getJsonList(ref, '/inquiries/$inquiryId/factory-candidates'),
);

class InquiryFactoryCandidatesScreen extends ConsumerWidget {
  const InquiryFactoryCandidatesScreen({super.key, required this.inquiry});

  final Inquiry inquiry;

  String get _path => '/inquiries/${inquiry.id}/factory-candidates';

  Future<void> _call(BuildContext context, WidgetRef ref, Future<void> Function(Dio dio) call, String success) async {
    try {
      await authorizedWidgetCall(ref, call);
      if (context.mounted) showSuccessSnack(context, success);
      ref.invalidate(_candidatesProvider(inquiry.id));
    } on DioException catch (e) {
      if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref, Set<int> already) async {
    final factoryId = await showFormSheet<int>(context, _AddCandidateSheet(exclude: already));
    if (factoryId == null || !context.mounted) return;
    await _call(context, ref, (dio) => dio.post(_path, data: {'factoryId': factoryId}), 'Factory shortlisted');
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> c, String status) async {
    final name = c['factoryName'] as String? ?? 'this factory';
    final ok = await confirmAction(
      context,
      title: status == 'SELECTED' ? 'Select $name?' : 'Reject $name?',
      message: status == 'SELECTED'
          ? '$name will be marked as the chosen factory for ${inquiry.inquiryNo}.'
          : '$name will be dropped from the shortlist for ${inquiry.inquiryNo}.',
      confirmLabel: status == 'SELECTED' ? 'Select' : 'Reject',
      destructive: status == 'REJECTED',
    );
    if (!ok || !context.mounted) return;
    await _call(
      context,
      ref,
      (dio) => dio.put('$_path/${c['id']}/status', data: {'status': status}),
      status == 'SELECTED' ? '$name selected' : '$name rejected',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_candidatesProvider(inquiry.id));
    final rows = async.valueOrNull ?? const [];
    final already = {for (final r in rows) r['factoryId'] as int};

    return Scaffold(
      appBar: AppBar(title: Text('${inquiry.inquiryNo} · Factories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, already),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Shortlist factory'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(
          failure: mapErrorToFailure(e),
          onRetry: () => ref.invalidate(_candidatesProvider(inquiry.id)),
        ),
        data: (candidates) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_candidatesProvider(inquiry.id)),
          child: candidates.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No factories shortlisted',
                    message: 'Shortlist the factories you are asking to quote, then select the one you will work with.',
                    icon: Icons.factory_outlined,
                    color: AppModules.factories.color,
                    actionLabel: 'Shortlist factory',
                    onAction: () => _add(context, ref, already),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.listWithFab,
                  itemCount: candidates.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'Swipe right to select, left to reject. Tap the status to change it.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    final c = candidates[i - 1];
                    final status = c['status'] as String? ?? 'CANDIDATE';
                    final name = c['factoryName'] as String? ?? 'Factory #${c['factoryId']}';
                    final options = [
                      if (status != 'SELECTED') 'SELECTED',
                      if (status != 'REJECTED') 'REJECTED',
                      if (status != 'CANDIDATE') 'CANDIDATE',
                    ];
                    return SwipeActions(
                      id: c['id'] ?? i,
                      start: status == 'SELECTED'
                          ? null
                          : SwipeAction(
                              label: 'Select',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              onTrigger: () => _setStatus(context, ref, c, 'SELECTED'),
                            ),
                      end: status == 'REJECTED'
                          ? null
                          : SwipeAction(
                              label: 'Reject',
                              icon: Icons.cancel_rounded,
                              color: AppColors.danger,
                              onTrigger: () => _setStatus(context, ref, c, 'REJECTED'),
                            ),
                      child: RecordTile(
                        accentColor: AppStatus.color(status),
                        leading: RecordAvatar(color: AppModules.factories.color, icon: AppModules.factories.icon),
                        title: name,
                        subtitle: status == 'CANDIDATE' ? 'On the shortlist' : null,
                        trailing: StatusMenuChip<String>(
                          status: status,
                          options: options,
                          apiValueOf: (s) => s,
                          labelOf: (s) => switch (s) {
                            'SELECTED' => 'Select factory',
                            'REJECTED' => 'Reject',
                            _ => 'Back to shortlist',
                          },
                          onSelected: (s) => _setStatus(context, ref, c, s),
                        ),
                        onLongPress: () => showQuickActions(
                          context,
                          title: name,
                          actions: [
                            for (final o in options)
                              QuickAction(
                                label: switch (o) {
                                  'SELECTED' => 'Select factory',
                                  'REJECTED' => 'Reject',
                                  _ => 'Back to shortlist',
                                },
                                icon: AppStatus.resolve(o).icon,
                                color: AppStatus.color(o),
                                destructive: o == 'REJECTED',
                                onSelected: () => _setStatus(context, ref, c, o),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AddCandidateSheet extends StatefulWidget {
  const _AddCandidateSheet({required this.exclude});
  final Set<int> exclude;

  @override
  State<_AddCandidateSheet> createState() => _AddCandidateSheetState();
}

class _AddCandidateSheetState extends State<_AddCandidateSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _factoryId;

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: 'Shortlist a factory',
        actionLabel: 'Add to shortlist',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop(_factoryId);
        },
        children: [
          LookupField(
            label: 'Factory',
            icon: Icons.factory_outlined,
            options: factoryLookupProvider,
            required: true,
            emptyMessage: 'No active factories yet. Add one from the Factories screen.',
            onChanged: (v) => setState(() => _factoryId = v),
          ),
          if (_factoryId != null && widget.exclude.contains(_factoryId))
            const Text('This factory is already on the shortlist.'),
        ],
      );
}
