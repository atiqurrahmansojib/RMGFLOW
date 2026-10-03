import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../application/order_action_controller.dart';
import '../data/order_repository_impl.dart';
import '../domain/order.dart';

final _orderAmendmentsProvider = FutureProvider.autoDispose.family<List<OrderAmendment>, int>((ref, orderId) {
  return ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(orderRepositoryProvider).listAmendments(orderId),
      );
});

/// Document 7 (#51)/9.6: every confirmed-order field change is a recorded,
/// decided amendment — never a silent edit.
class OrderAmendmentsScreen extends ConsumerWidget {
  const OrderAmendmentsScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _requestAmendment(BuildContext context, WidgetRef ref) async {
    final fieldController = TextEditingController();
    final valueController = TextEditingController();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Amendment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: fieldController, decoration: const InputDecoration(labelText: 'Field changed')),
            TextField(controller: valueController, decoration: const InputDecoration(labelText: 'New value')),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (fieldController.text.trim().isEmpty || reasonController.text.trim().isEmpty) return;
    await ref.read(orderActionControllerProvider.notifier).requestAmendment(
          orderId,
          OrderAmendmentDraft(
            fieldChanged: fieldController.text.trim(),
            newValue: valueController.text.trim().isEmpty ? null : valueController.text.trim(),
            reason: reasonController.text.trim(),
          ),
        );
    ref.invalidate(_orderAmendmentsProvider(orderId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(orderActionControllerProvider, (previous, next) {
      if (next is OrderActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final async = ref.watch(_orderAmendmentsProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amendments'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _requestAmendment(context, ref)),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_orderAmendmentsProvider(orderId)),
        ),
        data: (amendments) => amendments.isEmpty
            ? const EmptyStateView(message: 'No amendments requested.', icon: Icons.edit_note_outlined)
            : ListView.separated(
                itemCount: amendments.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final amendment = amendments[index];
                  return ListTile(
                    title: Text('#${amendment.amendmentNo} — ${amendment.fieldChanged}'),
                    subtitle: Text('${amendment.oldValue ?? '—'} → ${amendment.newValue ?? '—'}\n${amendment.reason}'),
                    isThreeLine: true,
                    trailing: amendment.status == OrderAmendmentStatus.requested
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  await ref.read(orderActionControllerProvider.notifier).approveAmendment(orderId, amendment.id);
                                  ref.invalidate(_orderAmendmentsProvider(orderId));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () async {
                                  await ref.read(orderActionControllerProvider.notifier).rejectAmendment(orderId, amendment.id);
                                  ref.invalidate(_orderAmendmentsProvider(orderId));
                                },
                              ),
                            ],
                          )
                        : Chip(label: Text(amendment.status.label)),
                  );
                },
              ),
      ),
    );
  }
}
