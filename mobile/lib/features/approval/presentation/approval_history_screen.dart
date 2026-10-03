import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/approval_repository_impl.dart';
import '../domain/approval.dart';

final _approvalHistoryProvider =
    FutureProvider.autoDispose.family<List<Approval>, ({ApprovalTargetType targetType, int targetId})>((ref, args) {
  return ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(approvalRepositoryProvider).history(targetType: args.targetType, targetId: args.targetId),
      );
});

/// Document 8.4: append-only round history for one target — every submit/
/// decide is a new row, never an edit, so this is a straight chronological list.
class ApprovalHistoryScreen extends ConsumerWidget {
  const ApprovalHistoryScreen({super.key, required this.targetType, required this.targetId});

  final ApprovalTargetType targetType;
  final int targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (targetType: targetType, targetId: targetId);
    final async = ref.watch(_approvalHistoryProvider(args));

    return Scaffold(
      appBar: AppBar(title: Text('${targetType.label} #$targetId — Approval History')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_approvalHistoryProvider(args)),
        ),
        data: (rounds) => rounds.isEmpty
            ? const EmptyStateView(message: 'No approval rounds yet.', icon: Icons.history)
            : ListView.separated(
                itemCount: rounds.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final round = rounds[index];
                  return ListTile(
                    title: Text('Round ${round.roundNo} — ${round.status.label}'),
                    subtitle: Text([
                      if (round.submittedAt != null) 'Submitted: ${round.submittedAt}',
                      if (round.decidedAt != null) 'Decided: ${round.decidedAt}',
                      if (round.rejectionReason != null) 'Reason: ${round.rejectionReason}',
                      if (round.comments != null) 'Comments: ${round.comments}',
                    ].join('\n')),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    );
  }
}
