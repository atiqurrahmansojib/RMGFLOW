import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../approval/domain/approval.dart' as approval;
import '../../approval/presentation/approval_history_screen.dart';
import '../application/quotation_form_controller.dart';
import '../domain/quotation.dart';
import 'quotation_form_screen.dart';

/// Document 7 (#40-42): Quotation detail — status-change actions and a link
/// into the generic Approval Engine's history for this target.
class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(quotationStatusControllerProvider, (previous, next) {
      if (next is QuotationStatusFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      } else if (next is QuotationStatusSuccess) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(quotation.quotationNo ?? 'Quotation #${quotation.id}')),
      body: ListView(
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
                      Text('Version ${quotation.versionNo}', style: Theme.of(context).textTheme.titleMedium),
                      Chip(label: Text(quotation.status.label)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Buyer #${quotation.buyerId} · Style #${quotation.styleId}'),
                  Text('Costing #${quotation.costingId}'),
                  Text('${quotation.currency} ${quotation.unitPrice} × ${quotation.quantity}'),
                  if (quotation.incoterm != null) Text('Incoterm: ${quotation.incoterm}'),
                  if (quotation.leadTimeDays != null) Text('Lead time: ${quotation.leadTimeDays} days'),
                  if (quotation.validityDate != null) Text('Valid until: ${quotation.validityDate}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Change status', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: QuotationStatus.values
                .where((s) => s != quotation.status)
                .map((s) => ActionChip(
                      label: Text(s.label),
                      onPressed: () =>
                          ref.read(quotationStatusControllerProvider.notifier).updateStatus(quotation.id, s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.difference_outlined),
            label: const Text('Create new version'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuotationFormScreen(existingQuotation: quotation, isRevise: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Approval history'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ApprovalHistoryScreen(
                  targetType: approval.ApprovalTargetType.quotation,
                  targetId: quotation.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
