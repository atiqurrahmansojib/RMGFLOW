import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/approval_repository_impl.dart';
import '../domain/approval.dart';

/// One-gesture approval decisions from the inbox (swipe / long-press):
/// approve asks a single confirm tap (decisions are immutable, so an
/// accidental swipe must not record one), reject asks for the mandatory
/// reason and return asks for an optional note. Returns true when the decision was recorded.
Future<bool> quickDecide(
  BuildContext context,
  WidgetRef ref,
  Approval approval,
  ApprovalStatus decision, {
  required String targetLabel,
}) async {
  String? reason;
  String? comments;
  if (decision == ApprovalStatus.approved) {
    final ok = await confirmAction(
      context,
      title: 'Approve $targetLabel?',
      message: 'Approvals are final and cannot be changed afterwards.',
      confirmLabel: 'Approve',
    );
    if (!ok) return false;
  } else if (decision == ApprovalStatus.rejected) {
    reason = await promptForReason(
      context,
      title: 'Reject $targetLabel?',
      message: 'The submitter will need to start a new round.',
      label: 'Rejection reason',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null) return false;
  } else if (decision == ApprovalStatus.returned) {
    comments = await promptForReason(
      context,
      title: 'Return $targetLabel for changes?',
      message: 'The submitter can fix it and resubmit.',
      label: 'What needs changing (optional)',
      confirmLabel: 'Return',
      required: false,
    );
    if (comments == null) return false;
  }
  try {
    await ref.read(authControllerProvider.notifier).callAuthorized(
          () => ref.read(approvalRepositoryProvider).decide(
                approval.id,
                ApprovalDecision(decision: decision, comments: blankToNull(comments), rejectionReason: reason),
              ),
        );
    if (context.mounted) {
      final verb = switch (decision) {
        ApprovalStatus.approved => 'approved',
        ApprovalStatus.rejected => 'rejected',
        _ => 'returned for changes',
      };
      showSuccessSnack(context, '$targetLabel $verb');
    }
    return true;
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    return false;
  }
}
