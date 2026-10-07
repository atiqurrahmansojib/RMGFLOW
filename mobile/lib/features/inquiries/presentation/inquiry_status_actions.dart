import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inquiry_repository_impl.dart';
import '../domain/inquiry.dart';

/// Shared status-change flow for an inquiry (Doc 10.1 state machine — the
/// backend decides which transitions are legal).

String inquiryStatusHint(InquiryStatus s) => switch (s) {
      InquiryStatus.open => 'Still being worked on',
      InquiryStatus.quoted => 'A quotation has been sent to the buyer',
      InquiryStatus.won => 'Buyer confirmed — ready for an order',
      InquiryStatus.lost => 'Buyer went elsewhere (reason required)',
      InquiryStatus.hold => 'Paused by the buyer',
    };

/// Every status the inquiry can move to from where it is now.
List<InquiryStatus> nextInquiryStatuses(Inquiry inquiry) =>
    InquiryStatus.values.where((s) => s != inquiry.status).toList();

/// Asks for the target status (unless [target] is given) and — for Lost —
/// the mandatory reason. Returns null if the user backed out.
Future<({InquiryStatus status, String? lostReason})?> pickInquiryStatus(
  BuildContext context,
  Inquiry inquiry, {
  InquiryStatus? target,
  bool confirm = true,
}) async {
  final status = target ??
      await showModalBottomSheet<InquiryStatus>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Text('Move ${inquiry.inquiryNo} to…', style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final s in nextInquiryStatuses(inquiry))
                ListTile(
                  leading: Icon(AppStatus.resolve(s.apiValue).icon, color: AppStatus.color(s.apiValue)),
                  title: Text(s.label),
                  subtitle: Text(inquiryStatusHint(s)),
                  onTap: () => Navigator.of(context).pop(s),
                ),
            ],
          ),
        ),
      );
  if (status == null || !context.mounted) return null;

  if (status == InquiryStatus.lost) {
    final reason = await promptForReason(
      context,
      title: 'Mark inquiry as lost',
      message: 'Recording why helps the win/loss analysis in reports.',
      label: 'Reason for loss',
      confirmLabel: 'Mark lost',
      destructive: true,
    );
    if (reason == null) return null;
    return (status: status, lostReason: reason);
  }
  if (confirm) {
    final ok = await confirmAction(
      context,
      title: 'Change status to ${status.label}?',
      message: 'Inquiry ${inquiry.inquiryNo} will move from ${inquiry.status.label} to ${status.label}.',
      confirmLabel: 'Change status',
    );
    if (!ok) return null;
  }
  return (status: status, lostReason: null);
}

/// Inline status change from a list row: no confirmation (the menu pick is
/// the confirmation) except the Lost reason. Returns true on success.
Future<bool> changeInquiryStatusInline(
  BuildContext context,
  WidgetRef ref,
  Inquiry inquiry,
  InquiryStatus target,
) async {
  final pick = await pickInquiryStatus(context, inquiry, target: target, confirm: false);
  if (pick == null) return false;
  try {
    await ref.read(authControllerProvider.notifier).callAuthorized(
          () => ref.read(inquiryRepositoryProvider).changeStatus(inquiry.id, pick.status, lostReason: pick.lostReason),
        );
    if (context.mounted) showSuccessSnack(context, '${inquiry.inquiryNo} moved to ${pick.status.label}');
    return true;
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    return false;
  }
}
