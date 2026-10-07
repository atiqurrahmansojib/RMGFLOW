import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../costing/presentation/costing_detail_screen.dart';
import '../application/approval_decision_controller.dart';
import '../domain/approval.dart';
import 'approval_target_label.dart';

/// Document 7 (#68): Approval Detail/Action — generic across every target
/// type (ADR-08). This screen only knows the approval round itself; the
/// caller is responsible for linking to the actual target's detail screen
/// first if the decider needs to review it before deciding.
class ApprovalDecisionScreen extends ConsumerStatefulWidget {
  const ApprovalDecisionScreen({super.key, required this.approval});

  final Approval approval;

  @override
  ConsumerState<ApprovalDecisionScreen> createState() => _ApprovalDecisionScreenState();
}

class _ApprovalDecisionScreenState extends ConsumerState<ApprovalDecisionScreen> {
  final _commentsController = TextEditingController();
  final _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  /// Resolved in build (it watches lookups) and reused by the confirm dialog.
  String _targetLabel = '';

  Future<void> _decide(ApprovalStatus decision) async {
    if (decision == ApprovalStatus.rejected && _rejectionReasonController.text.trim().isEmpty) {
      // Ask for the reason right here instead of bouncing the user to the field.
      final reason = await promptForReason(
        context,
        title: 'Reject $_targetLabel?',
        message: 'The submitter will need to start a new round.',
        label: 'Rejection reason',
        confirmLabel: 'Reject',
        destructive: true,
      );
      if (reason == null || !mounted) return;
      _rejectionReasonController.text = reason;
      ref.read(approvalDecisionControllerProvider.notifier).decide(
            widget.approval.id,
            ApprovalDecision(
              decision: decision,
              comments: blankToNull(_commentsController.text),
              rejectionReason: reason,
            ),
          );
      return;
    }
    final target = _targetLabel;
    final (title, message, label) = switch (decision) {
      ApprovalStatus.approved => (
          'Approve $target?',
          'This decision is recorded permanently in the approval history.',
          'Approve'
        ),
      ApprovalStatus.rejected => (
          'Reject $target?',
          'Reason: "${_rejectionReasonController.text.trim()}". The submitter will need to start a new round.',
          'Reject'
        ),
      _ => ('Return $target for changes?', 'The submitter can fix it and resubmit.', 'Return'),
    };
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      confirmLabel: label,
      destructive: decision == ApprovalStatus.rejected,
    );
    if (!ok) return;
    ref.read(approvalDecisionControllerProvider.notifier).decide(
          widget.approval.id,
          ApprovalDecision(
            decision: decision,
            comments: blankToNull(_commentsController.text),
            rejectionReason: blankToNull(_rejectionReasonController.text),
          ),
        );
  }

  /// Opens the record being approved, where the app has a screen for it.
  Widget? _targetScreen(Approval approval) => switch (approval.targetType) {
        ApprovalTargetType.costing => CostingDetailScreen(costingId: approval.targetId),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    _targetLabel = approvalTargetLabel(ref, widget.approval.targetType, widget.approval.targetId);
    ref.listen(approvalDecisionControllerProvider, (previous, next) {
      if (next is ApprovalDecisionSuccess) {
        showSuccessSnack(context, 'Decision recorded');
        Navigator.of(context).pop(true);
      } else if (next is ApprovalDecisionFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final state = ref.watch(approvalDecisionControllerProvider);
    final isSubmitting = state is ApprovalDecisionSubmitting;
    final approval = widget.approval;
    final targetScreen = _targetScreen(approval);

    const module = AppModules.approvals;

    return Scaffold(
      appBar: AppBar(title: Text('${approval.targetType.label} Approval')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          GradientHeader.module(
            module,
            margin: EdgeInsets.zero,
            eyebrow: '${approval.targetType.label} approval',
            title: _targetLabel,
            subtitle: approval.submittedAt == null
                ? null
                : 'Submitted ${displayDateFormat.format(approval.submittedAt!.toLocal())}',
            trailing: StatusChip(approval.status.apiValue, label: approval.status.label),
            bottom: Row(
              children: [
                Expanded(child: HeaderStat(value: '${approval.roundNo}', label: 'Round')),
                Expanded(child: HeaderStat(value: approval.targetType.label, label: 'Type')),
              ],
            ),
          ),
          if (approval.comments != null) ...[
            SectionHeader('Submitter comments', icon: Icons.chat_bubble_outline_rounded, accentColor: module.color),
            AppCard(
              margin: EdgeInsets.zero,
              child: InfoRow(label: 'Comments', value: approval.comments, vertical: true),
            ),
          ],
          if (targetScreen != null) ...[
            const SizedBox(height: AppSpacing.md),
            LinkCard(
              icon: Icons.open_in_new_rounded,
              color: AppModules.costing.color,
              title: 'Review ${approval.targetType.label.toLowerCase()} details',
              subtitle: 'Open the record before deciding',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => targetScreen)),
            ),
          ],
          FormSection(
            title: 'Your decision',
            icon: Icons.gavel_rounded,
            color: module.color,
            children: [
              TextField(
                controller: _commentsController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Comments (optional)'),
                maxLines: 2,
              ),
              TextField(
                controller: _rejectionReasonController,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  helperText: 'Only needed if you reject — you will be asked if blank',
                ),
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Approve',
            icon: Icons.check_circle_rounded,
            loading: isSubmitting,
            onPressed: () => _decide(ApprovalStatus.approved),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Return',
                  icon: Icons.keyboard_return_rounded,
                  variant: ButtonVariant.outlined,
                  onPressed: isSubmitting ? null : () => _decide(ApprovalStatus.returned),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Reject',
                  icon: Icons.cancel_rounded,
                  variant: ButtonVariant.danger,
                  onPressed: isSubmitting ? null : () => _decide(ApprovalStatus.rejected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
