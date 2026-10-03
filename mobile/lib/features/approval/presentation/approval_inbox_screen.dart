import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/approval_inbox_controller.dart';
import 'approval_decision_screen.dart';

/// Document 7 (#67): Pending Approvals Inbox — one list across every target
/// type the shared Approval Engine covers (ADR-08), optionally filtered.
class ApprovalInboxScreen extends ConsumerWidget {
  const ApprovalInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalInboxControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: switch (state) {
        ApprovalInboxLoading() => const LoadingView(),
        ApprovalInboxError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(approvalInboxControllerProvider.notifier).refresh(),
          ),
        ApprovalInboxLoaded(:final approvals) when approvals.isEmpty =>
          const EmptyStateView(message: 'Nothing waiting on your decision.', icon: Icons.task_alt_outlined),
        ApprovalInboxLoaded(:final approvals) => RefreshIndicator(
            onRefresh: () => ref.read(approvalInboxControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: approvals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final approval = approvals[index];
                return ListTile(
                  title: Text('${approval.targetType.label} #${approval.targetId}'),
                  subtitle: Text('Round ${approval.roundNo}'),
                  trailing: Chip(label: Text(approval.status.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ApprovalDecisionScreen(approval: approval)),
                  ).then((_) => ref.read(approvalInboxControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
