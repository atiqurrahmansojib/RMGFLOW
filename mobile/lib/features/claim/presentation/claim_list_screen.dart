import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/claim_controller.dart';
import '../domain/claim.dart';

/// Document 7 (#73-74)/6.3: claims raised against one order — buyer or
/// internal, tracked to resolution. ClaimService is isolated by construction
/// from Order/Shipment mutation, so this screen is purely tracking.
class ClaimListScreen extends ConsumerWidget {
  const ClaimListScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _createClaim(BuildContext context, WidgetRef ref) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final shipmentIdController = TextEditingController();
    ClaimRaisedBy raisedBy = ClaimRaisedBy.buyer;
    ClaimType claimType = ClaimType.quality;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('New Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ClaimRaisedBy>(
                value: raisedBy,
                decoration: const InputDecoration(labelText: 'Raised by'),
                items: ClaimRaisedBy.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                onChanged: (v) => setState(() => raisedBy = v!),
              ),
              DropdownButtonFormField<ClaimType>(
                value: claimType,
                decoration: const InputDecoration(labelText: 'Claim type'),
                items: ClaimType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                onChanged: (v) => setState(() => claimType = v!),
              ),
              TextField(controller: shipmentIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Shipment ID (optional)')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Claimed amount (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (confirmed != true || descriptionController.text.trim().isEmpty) return;
    await ref.read(claimActionControllerProvider.notifier).create(
          orderId,
          ClaimDraft(
            shipmentId: int.tryParse(shipmentIdController.text.trim()),
            raisedBy: raisedBy,
            claimType: claimType,
            description: descriptionController.text.trim(),
            claimedAmount: double.tryParse(amountController.text.trim()),
          ),
        );
    ref.read(claimListControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _resolveClaim(BuildContext context, WidgetRef ref, Claim claim) async {
    final resolutionController = TextEditingController();
    ClaimStatus status = ClaimStatus.resolved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Resolve Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ClaimStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [ClaimStatus.underReview, ClaimStatus.resolved, ClaimStatus.rejected]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) => setState(() => status = v!),
              ),
              TextField(controller: resolutionController, decoration: const InputDecoration(labelText: 'Resolution notes')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await ref.read(claimActionControllerProvider.notifier).resolve(
          claim.id,
          ClaimResolutionDraft(status: status, resolution: resolutionController.text.trim().isEmpty ? null : resolutionController.text.trim()),
        );
    ref.read(claimListControllerProvider(orderId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(claimActionControllerProvider, (previous, next) {
      if (next is ClaimActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(claimListControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Claims')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createClaim(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        ClaimListLoading() => const LoadingView(),
        ClaimListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(claimListControllerProvider(orderId).notifier).refresh(),
          ),
        ClaimListLoaded(:final claims) when claims.isEmpty =>
          const EmptyStateView(message: 'No claims raised for this order.', icon: Icons.gavel_outlined),
        ClaimListLoaded(:final claims) => RefreshIndicator(
            onRefresh: () => ref.read(claimListControllerProvider(orderId).notifier).refresh(),
            child: ListView.separated(
              itemCount: claims.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final claim = claims[index];
                return ListTile(
                  title: Text('${claim.claimType.label} · ${claim.raisedBy.label}'),
                  subtitle: Text(claim.description),
                  trailing: Chip(label: Text(claim.status.label)),
                  onTap: claim.status == ClaimStatus.resolved || claim.status == ClaimStatus.rejected
                      ? null
                      : () => _resolveClaim(context, ref, claim),
                );
              },
            ),
          ),
      },
    );
  }
}
