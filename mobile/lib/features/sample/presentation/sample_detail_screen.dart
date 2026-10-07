import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../approval/domain/approval.dart' as approval;
import '../../approval/presentation/approval_history_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../application/sample_form_controller.dart';
import '../data/sample_repository_impl.dart';
import '../domain/sample.dart';

final _sampleRevisionsProvider = FutureProvider.autoDispose.family<List<SampleRevision>, int>((ref, sampleId) {
  return ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(sampleRepositoryProvider).listRevisions(sampleId),
      );
});

/// Document 7 (#33-36)/9.3: revision history is append-only — a rejected
/// revision is never edited, only superseded by a new one that gets its own
/// fresh Approval Engine round (Doc 10.5).
class SampleDetailScreen extends ConsumerWidget {
  const SampleDetailScreen({super.key, required this.sample});

  final Sample sample;

  Future<void> _addRevision(BuildContext context, WidgetRef ref) async {
    final comments = await promptForReason(
      context,
      title: 'Submit new revision',
      message: 'Records that a new sample was sent to the buyer today and starts a fresh approval round.',
      label: 'Comments',
      confirmLabel: 'Submit revision',
      required: false,
    );
    if (comments == null) return;
    final draft = SampleRevisionDraft(
      submittedDate: toApiDate(DateTime.now())!,
      comments: blankToNull(comments),
    );
    await ref.read(sampleRevisionFormControllerProvider.notifier).submit(sample.id, draft);
    if (context.mounted && ref.read(sampleRevisionFormControllerProvider) is SampleRevisionFormSuccess) {
      showSuccessSnack(context, 'Revision submitted for approval');
    }
    ref.invalidate(_sampleRevisionsProvider(sample.id));
  }

  Future<void> _syncStatus(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .callAuthorized(() => ref.read(sampleRepositoryProvider).syncStatusFromLatestApproval(sample.id));
      if (!context.mounted) return;
      showSuccessSnack(context, 'Sample status refreshed');
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    }
  }

  void _openHistory(BuildContext context, int revisionId) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApprovalHistoryScreen(
            targetType: approval.ApprovalTargetType.sampleRevision,
            targetId: revisionId,
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sampleRevisionFormControllerProvider, (previous, next) {
      if (next is SampleRevisionFormFailed) showErrorSnack(context, next.failure.message);
    });
    final revisionsAsync = ref.watch(_sampleRevisionsProvider(sample.id));
    final submitting = ref.watch(sampleRevisionFormControllerProvider) is SampleRevisionFormSubmitting;

    const module = AppModules.sampling;
    final revisions = revisionsAsync.valueOrNull;
    final status = sample.currentStatus.apiValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(sample.sampleNo),
        actions: [
          IconButton(
            tooltip: 'Refresh status from latest approval',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => _syncStatus(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitting ? null : () => _addRevision(context, ref),
        icon: const Icon(Icons.send_rounded),
        label: const Text('New revision'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_sampleRevisionsProvider(sample.id)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.listWithFab,
          children: [
            GradientHeader.module(
              module,
              margin: EdgeInsets.zero,
              eyebrow: lookupLabel(ref, sampleTypeLookupProvider, sample.sampleTypeId, fallback: 'Sample'),
              title: sample.sampleNo,
              subtitle: '${lookupLabel(ref, styleLookupProvider(null), sample.styleId)} · '
                  '${lookupLabel(ref, buyerLookupProvider, sample.buyerId)}',
              trailing: StatusChip(status, label: sample.currentStatus.label),
              bottom: Row(
                children: [
                  Expanded(child: HeaderStat(value: '${revisions?.length ?? '—'}', label: 'Revisions')),
                  Expanded(child: HeaderStat(value: formatApiDate(sample.requestDate), label: 'Requested')),
                  Expanded(
                    child: HeaderStat(
                      value: sample.requiredDate == null ? '—' : formatApiDate(sample.requiredDate),
                      label: 'Required by',
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader('Details', icon: Icons.info_outline_rounded, accentColor: module.color),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Buyer', value: lookupLabel(ref, buyerLookupProvider, sample.buyerId)),
                  InfoRow(label: 'Style', value: lookupLabel(ref, styleLookupProvider(null), sample.styleId)),
                  InfoRow(label: 'Sample type', value: lookupLabel(ref, sampleTypeLookupProvider, sample.sampleTypeId)),
                  if (sample.factoryId != null)
                    InfoRow(label: 'Factory', value: lookupLabel(ref, factoryLookupProvider, sample.factoryId)),
                  InfoRow(label: 'Requested', value: formatApiDate(sample.requestDate)),
                  if (sample.requiredDate != null)
                    InfoRow(label: 'Required by', value: formatApiDate(sample.requiredDate)),
                ],
              ),
            ),
            SectionHeader(
              'Revisions',
              icon: Icons.layers_outlined,
              accentColor: module.color,
              count: revisions?.length,
              actionLabel: 'New revision',
              onAction: submitting ? null : () => _addRevision(context, ref),
            ),
            revisionsAsync.when(
              loading: () => const LoadingView(itemCount: 2, padding: EdgeInsets.zero),
              error: (error, _) => ErrorStateView(
                failure: mapErrorToFailure(error),
                compact: true,
                onRetry: () => ref.invalidate(_sampleRevisionsProvider(sample.id)),
              ),
              data: (revisions) => revisions.isEmpty
                  ? EmptyStateView(
                      title: 'No revisions yet',
                      message: 'Submit a revision when you send the first sample to the buyer.',
                      icon: Icons.send_outlined,
                      color: module.color,
                      actionLabel: 'Submit first revision',
                      onAction: submitting ? null : () => _addRevision(context, ref),
                    )
                  : Column(
                      children: [
                        for (final (i, r) in revisions.reversed.indexed)
                          RecordTile(
                            accentColor: i == 0 ? module.color : AppColors.neutral,
                            leading: RecordAvatar(
                                color: i == 0 ? module.color : AppColors.neutral, text: 'R${r.revisionNo}', size: 40),
                            title: 'Revision ${r.revisionNo}',
                            subtitle: r.comments,
                            meta: r.submittedDate == null ? null : 'Submitted ${formatApiDate(r.submittedDate)}',
                            trailing: i == 0 ? const StatusChip('ACTIVE', label: 'Latest', dense: true) : null,
                            onTap: () => _openHistory(context, r.id),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              icon: Icons.history_rounded,
              label: 'Latest revision approval history',
              variant: ButtonVariant.outlined,
              onPressed: revisions == null || revisions.isEmpty ? null : () => _openHistory(context, revisions.last.id),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              icon: Icons.sync_rounded,
              label: 'Refresh status from latest approval',
              variant: ButtonVariant.tonal,
              onPressed: () => _syncStatus(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
