import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
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
    final commentsController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Revision'),
        content: TextField(
          controller: commentsController,
          decoration: const InputDecoration(labelText: 'Comments (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;
    final draft = SampleRevisionDraft(
      submittedDate: DateTime.now().toIso8601String().split('T').first,
      comments: commentsController.text.trim().isEmpty ? null : commentsController.text.trim(),
    );
    await ref.read(sampleRevisionFormControllerProvider.notifier).submit(sample.id, draft);
    ref.invalidate(_sampleRevisionsProvider(sample.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sampleRevisionFormControllerProvider, (previous, next) {
      if (next is SampleRevisionFormFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final revisionsAsync = ref.watch(_sampleRevisionsProvider(sample.id));

    return Scaffold(
      appBar: AppBar(title: Text(sample.sampleNo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sample.sampleNo, style: Theme.of(context).textTheme.titleMedium),
                      Chip(label: Text(sample.currentStatus.label)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Style #${sample.styleId} · Buyer #${sample.buyerId}'),
                  if (sample.factoryId != null) Text('Factory #${sample.factoryId}'),
                  Text('Sample type #${sample.sampleTypeId}'),
                  Text('Requested: ${sample.requestDate}'),
                  if (sample.requiredDate != null) Text('Required by: ${sample.requiredDate}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revisions', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _addRevision(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New revision'),
              ),
            ],
          ),
          revisionsAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorStateView(
              failure: mapErrorToFailure(error),
              onRetry: () => ref.invalidate(_sampleRevisionsProvider(sample.id)),
            ),
            data: (revisions) => revisions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No revisions yet.'),
                  )
                : Column(
                    children: revisions
                        .map((r) => Card(
                              child: ListTile(
                                title: Text('Revision ${r.revisionNo}'),
                                subtitle: Text([
                                  if (r.submittedDate != null) 'Submitted: ${r.submittedDate}',
                                  if (r.comments != null) r.comments!,
                                ].join(' · ')),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Sync status from latest approval'),
            onPressed: () async {
              await ref.read(sampleRepositoryProvider).syncStatusFromLatestApproval(sample.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Latest revision approval history'),
            onPressed: revisionsAsync.valueOrNull == null || revisionsAsync.valueOrNull!.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApprovalHistoryScreen(
                          targetType: approval.ApprovalTargetType.sampleRevision,
                          targetId: revisionsAsync.valueOrNull!.last.id,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
