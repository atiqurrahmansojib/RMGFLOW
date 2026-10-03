import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../../../core/network/failure_mapper.dart';
import '../../approval/domain/approval.dart' as approval;
import '../../approval/presentation/approval_history_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../application/costing_form_controller.dart';
import '../data/costing_repository_impl.dart';
import '../domain/costing.dart';
import 'costing_form_screen.dart';

final _costingDetailProvider = FutureProvider.autoDispose.family<Costing, int>((ref, id) {
  return ref.read(authControllerProvider.notifier).callAuthorized(
        () => ref.read(costingRepositoryProvider).get(id),
      );
});

/// Document 7 (#37-39): costing detail — items breakdown, server-computed
/// margin, and the actions legal from its current status (edit/revise/submit).
class CostingDetailScreen extends ConsumerWidget {
  const CostingDetailScreen({super.key, required this.costingId});

  final int costingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_costingDetailProvider(costingId));

    return Scaffold(
      appBar: AppBar(title: Text('Costing #$costingId')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_costingDetailProvider(costingId)),
        ),
        data: (costing) => ListView(
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
                        Text('Version ${costing.versionNo}', style: Theme.of(context).textTheme.titleMedium),
                        Chip(label: Text(costing.status.label)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Style #${costing.styleId}${costing.inquiryId != null ? ' · Inquiry #${costing.inquiryId}' : ''}'),
                    Text('Quantity: ${costing.quantity}'),
                    Text('Exchange rate: ${costing.exchangeRate} ${costing.currency}'),
                    if (costing.targetPrice != null) Text('Target price: ${costing.targetPrice}'),
                    const Divider(height: 24),
                    Text(
                      'Total cost: ${costing.currency} ${costing.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (costing.marginPercent != null)
                      Text('Margin: ${costing.marginPercent!.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Cost Items', style: Theme.of(context).textTheme.titleMedium),
            ...costing.items.map((item) => Card(
                  child: ListTile(
                    title: Text(item.componentType.label + (item.description != null ? ' — ${item.description}' : '')),
                    subtitle: Text(
                      'unit ${item.unitCost} × qty ${item.consumption} × (1 + ${item.wastagePercent}% wastage)',
                    ),
                    trailing: Text(item.totalCost.toStringAsFixed(2)),
                  ),
                )),
            const SizedBox(height: 16),
            if (costing.status == CostingStatus.draft) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit draft'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CostingFormScreen(existingCosting: costing, mode: CostingFormMode.editDraft),
                  ),
                ).then((_) => ref.invalidate(_costingDetailProvider(costingId))),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit for approval'),
                onPressed: () async {
                  await ref.read(costingSubmitControllerProvider.notifier).submitForApproval(costing.id);
                  ref.invalidate(_costingDetailProvider(costingId));
                },
              ),
            ] else
              OutlinedButton.icon(
                icon: const Icon(Icons.difference_outlined),
                label: const Text('Create new version'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CostingFormScreen(existingCosting: costing, mode: CostingFormMode.revise),
                  ),
                ).then((_) => ref.invalidate(_costingDetailProvider(costingId))),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Approval history'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApprovalHistoryScreen(
                    targetType: approval.ApprovalTargetType.costing,
                    targetId: costing.id,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
