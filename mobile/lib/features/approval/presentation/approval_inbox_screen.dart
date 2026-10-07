import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../costing/presentation/costing_detail_screen.dart';
import '../application/approval_inbox_controller.dart';
import '../domain/approval.dart';
import 'approval_decision_screen.dart';
import 'approval_quick_decide.dart';
import 'approval_target_label.dart';

/// Document 7 (#67): Pending Approvals Inbox — one list across every target
/// type the shared Approval Engine covers (ADR-08), optionally filtered.
/// Swipe right to approve, left to reject (reason asked); long-press for
/// every action; tap for the full decision screen.
class ApprovalInboxScreen extends ConsumerStatefulWidget {
  const ApprovalInboxScreen({super.key});

  @override
  ConsumerState<ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends ConsumerState<ApprovalInboxScreen> {
  static const _module = AppModules.approvals;
  ApprovalTargetType? _type;

  void _refresh() => ref.read(approvalInboxControllerProvider.notifier).refresh();

  void _open(Approval approval) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ApprovalDecisionScreen(approval: approval)))
      .then((_) => mounted ? _refresh() : null);

  Future<void> _decide(Approval approval, ApprovalStatus decision) async {
    final label = approvalTargetLabel(ref, approval.targetType, approval.targetId);
    final ok = await quickDecide(context, ref, approval, decision, targetLabel: label);
    if (ok && mounted) _refresh();
  }

  IconData _iconFor(ApprovalTargetType t) => switch (t) {
        ApprovalTargetType.costing => AppModules.costing.icon,
        ApprovalTargetType.quotation => AppModules.quotation.icon,
        ApprovalTargetType.sampleRevision || ApprovalTargetType.ppSample => AppModules.sampling.icon,
        ApprovalTargetType.inspection => AppModules.quality.icon,
        ApprovalTargetType.shipment => AppModules.shipment.icon,
        ApprovalTargetType.document => AppModules.documents.icon,
        ApprovalTargetType.labDip => Icons.palette_outlined,
        ApprovalTargetType.trim => Icons.style_outlined,
      };

  Color _colorFor(ApprovalTargetType t) => switch (t) {
        ApprovalTargetType.costing => AppModules.costing.color,
        ApprovalTargetType.quotation => AppModules.quotation.color,
        ApprovalTargetType.sampleRevision || ApprovalTargetType.ppSample => AppModules.sampling.color,
        ApprovalTargetType.inspection => AppModules.quality.color,
        ApprovalTargetType.shipment => AppModules.shipment.color,
        ApprovalTargetType.document => AppModules.documents.color,
        _ => _module.color,
      };

  void _quickActions(Approval approval) {
    final label = approvalTargetLabel(ref, approval.targetType, approval.targetId);
    showQuickActions(
      context,
      title: label,
      subtitle: '${approval.targetType.label} · round ${approval.roundNo}',
      actions: [
        QuickAction(
          label: 'Approve',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          onSelected: () => _decide(approval, ApprovalStatus.approved),
        ),
        QuickAction(
          label: 'Return for changes',
          icon: Icons.keyboard_return_rounded,
          color: AppColors.warning,
          onSelected: () => _decide(approval, ApprovalStatus.returned),
        ),
        QuickAction(
          label: 'Reject',
          icon: Icons.cancel_rounded,
          destructive: true,
          onSelected: () => _decide(approval, ApprovalStatus.rejected),
        ),
        if (approval.targetType == ApprovalTargetType.costing)
          QuickAction(
            label: 'Review costing',
            icon: Icons.open_in_new_rounded,
            color: AppModules.costing.color,
            onSelected: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: approval.targetId))),
          ),
        QuickAction(
          label: 'Open decision screen',
          icon: Icons.approval_outlined,
          color: _module.color,
          onSelected: () => _open(approval),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalInboxControllerProvider);
    final count = state is ApprovalInboxLoaded ? state.approvals.length : null;

    return Scaffold(
      appBar: AppBar(title: Text(count == null ? 'Pending Approvals' : 'Pending Approvals ($count)')),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FilterChipBar<ApprovalTargetType>(
            values: ApprovalTargetType.values,
            selected: _type,
            labelOf: (t) => t.label,
            allLabel: 'All types',
            onSelected: (t) {
              setState(() => _type = t);
              ref.read(approvalInboxControllerProvider.notifier).load(targetType: t);
            },
          ),
          Expanded(
            child: switch (state) {
              ApprovalInboxLoading() => const LoadingView(),
              ApprovalInboxError(:final failure) => ErrorStateView(failure: failure, onRetry: _refresh),
              ApprovalInboxLoaded(:final approvals) when approvals.isEmpty => RefreshIndicator(
                  onRefresh: () => ref.read(approvalInboxControllerProvider.notifier).refresh(),
                  child: RefreshableEmpty(
                    child: EmptyStateView(
                      title: 'All caught up',
                      message: 'Nothing is waiting on your decision. Pull down to check again.',
                      icon: Icons.task_alt_outlined,
                      color: _module.color,
                    ),
                  ),
                ),
              ApprovalInboxLoaded(:final approvals) => RefreshIndicator(
                  onRefresh: () => ref.read(approvalInboxControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.page,
                    itemCount: approvals.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Icon(Icons.swipe_rounded,
                                  size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Swipe right to approve, left to reject. Long-press for more.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final approval = approvals[index - 1];
                      final color = _colorFor(approval.targetType);
                      return SwipeActions(
                        id: approval.id,
                        start: SwipeAction(
                          label: 'Approve',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          onTrigger: () => _decide(approval, ApprovalStatus.approved),
                        ),
                        end: SwipeAction(
                          label: 'Reject',
                          icon: Icons.cancel_rounded,
                          color: AppColors.danger,
                          onTrigger: () => _decide(approval, ApprovalStatus.rejected),
                        ),
                        child: RecordTile(
                          accentColor: color,
                          leading: RecordAvatar(color: color, icon: _iconFor(approval.targetType)),
                          title: approvalTargetLabel(ref, approval.targetType, approval.targetId),
                          subtitle: '${approval.targetType.label} · round ${approval.roundNo}',
                          meta: approval.submittedAt == null
                              ? null
                              : 'Submitted ${displayDateFormat.format(approval.submittedAt!.toLocal())}',
                          trailing: StatusChip(approval.status.apiValue, label: approval.status.label, dense: true),
                          onTap: () => _open(approval),
                          onLongPress: () => _quickActions(approval),
                        ),
                      );
                    },
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
