import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
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
      appBar: AppBar(title: const Text('Approval History')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_approvalHistoryProvider(args)),
        ),
        data: (rounds) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_approvalHistoryProvider(args)),
          child: rounds.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No approval rounds yet',
                    message: 'This ${targetType.label.toLowerCase()} has not been submitted for approval.',
                    icon: Icons.history,
                    color: AppModules.approvals.color,
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.page,
                  itemCount: rounds.length,
                  itemBuilder: (context, index) {
                    final round = rounds[index];
                    final color = AppStatus.color(round.status.apiValue);
                    return RecordTile(
                      accentColor: color,
                      leading: RecordAvatar(color: color, text: 'R${round.roundNo}', size: 40),
                      title: '${targetType.label} #$targetId · round ${round.roundNo}',
                      subtitle: [
                        if (round.rejectionReason != null) 'Reason: ${round.rejectionReason}',
                        if (round.comments != null) 'Comments: ${round.comments}',
                      ].join('\n'),
                      meta: [
                        if (round.submittedAt != null)
                          'Submitted ${displayDateFormat.format(round.submittedAt!.toLocal())}',
                        if (round.decidedAt != null) 'Decided ${displayDateFormat.format(round.decidedAt!.toLocal())}',
                      ].join(' · '),
                      trailing: StatusChip(round.status.apiValue, label: round.status.label, dense: true),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
