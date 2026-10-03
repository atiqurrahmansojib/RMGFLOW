import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/quotation_list_controller.dart';
import 'quotation_detail_screen.dart';
import 'quotation_form_screen.dart';

/// Document 7 (#40): Quotation list.
class QuotationListScreen extends ConsumerWidget {
  const QuotationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quotationListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
        ).then((_) => ref.read(quotationListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        QuotationListLoading() => const LoadingView(),
        QuotationListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(quotationListControllerProvider.notifier).refresh(),
          ),
        QuotationListLoaded(:final quotations) when quotations.isEmpty =>
          const EmptyStateView(message: 'No quotations yet. Tap + to add one.', icon: Icons.request_quote_outlined),
        QuotationListLoaded(:final quotations) => RefreshIndicator(
            onRefresh: () => ref.read(quotationListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: quotations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final quotation = quotations[index];
                return ListTile(
                  title: Text(quotation.quotationNo ?? 'Quotation #${quotation.id}'),
                  subtitle: Text(
                    'Buyer #${quotation.buyerId} · Style #${quotation.styleId} · '
                    '${quotation.currency} ${quotation.unitPrice} × ${quotation.quantity}',
                  ),
                  trailing: Chip(label: Text(quotation.status.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: quotation)),
                  ).then((_) => ref.read(quotationListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
