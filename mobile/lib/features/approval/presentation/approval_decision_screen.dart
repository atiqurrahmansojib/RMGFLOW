import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/approval_decision_controller.dart';
import '../domain/approval.dart';

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

  void _decide(ApprovalStatus decision) {
    if (decision == ApprovalStatus.rejected && _rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejection reason is required')));
      return;
    }
    ref.read(approvalDecisionControllerProvider.notifier).decide(
          widget.approval.id,
          ApprovalDecision(
            decision: decision,
            comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
            rejectionReason:
                _rejectionReasonController.text.trim().isEmpty ? null : _rejectionReasonController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(approvalDecisionControllerProvider, (previous, next) {
      if (next is ApprovalDecisionSuccess) {
        Navigator.of(context).pop();
      } else if (next is ApprovalDecisionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(approvalDecisionControllerProvider);
    final isSubmitting = state is ApprovalDecisionSubmitting;
    final approval = widget.approval;

    return Scaffold(
      appBar: AppBar(title: Text('${approval.targetType.label} Approval')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${approval.targetType.label} #${approval.targetId}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Round ${approval.roundNo} · ${approval.status.label}'),
                  if (approval.submittedAt != null) Text('Submitted: ${approval.submittedAt}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentsController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(labelText: 'Comments (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rejectionReasonController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(labelText: 'Rejection reason (required to reject)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : () => _decide(ApprovalStatus.returned),
                  child: const Text('Return'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: isSubmitting ? null : () => _decide(ApprovalStatus.rejected),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isSubmitting ? null : () => _decide(ApprovalStatus.approved),
                  child: isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
