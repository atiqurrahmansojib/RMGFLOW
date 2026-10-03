import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/order_financial_controller.dart';
import '../domain/financial.dart';

/// Document 7 (#70-72)/9.10/9.12: one order's margin (estimate vs realized),
/// receivables, and payables — every number shown is exactly what the server
/// derived, never recomputed here.
class OrderFinancialScreen extends ConsumerWidget {
  const OrderFinancialScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _editFinancials(BuildContext context, WidgetRef ref, OrderFinancials current) async {
    final quotedController = TextEditingController(text: current.quotedUnitPrice?.toString());
    final actualController = TextEditingController(text: current.actualCostUnit?.toString());
    final realizedController = TextEditingController(text: current.realizedUnitPrice?.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Financials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quotedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quoted unit price'),
            ),
            TextField(
              controller: actualController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Actual cost per unit'),
            ),
            TextField(
              controller: realizedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Realized unit price (optional, once shipped)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(financialActionControllerProvider.notifier).upsertFinancials(
          orderId,
          OrderFinancialsDraft(
            quotedUnitPrice: double.tryParse(quotedController.text.trim()),
            actualCostUnit: double.tryParse(actualController.text.trim()),
            realizedUnitPrice: double.tryParse(realizedController.text.trim()),
          ),
        );
    ref.read(orderFinancialControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _addReceivable(BuildContext context, WidgetRef ref) async {
    final buyerIdController = TextEditingController();
    final amountController = TextEditingController();
    final currencyController = TextEditingController();
    DateTime dueDate = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Receivable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: buyerIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buyer ID')),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
            TextField(controller: currencyController, decoration: const InputDecoration(labelText: 'Currency')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed != true) return;
    final buyerId = int.tryParse(buyerIdController.text.trim());
    final amount = double.tryParse(amountController.text.trim());
    if (buyerId == null || amount == null || currencyController.text.trim().isEmpty) return;
    await ref.read(financialActionControllerProvider.notifier).createReceivable(
          orderId,
          ReceivableDraft(
            buyerId: buyerId,
            amount: amount,
            currency: currencyController.text.trim().toUpperCase(),
            dueDate: dueDate.toIso8601String().split('T').first,
          ),
        );
    ref.read(orderFinancialControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _addPayable(BuildContext context, WidgetRef ref) async {
    final factoryIdController = TextEditingController();
    final amountController = TextEditingController();
    final currencyController = TextEditingController();
    DateTime dueDate = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Payable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: factoryIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Factory ID')),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
            TextField(controller: currencyController, decoration: const InputDecoration(labelText: 'Currency')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed != true) return;
    final factoryId = int.tryParse(factoryIdController.text.trim());
    final amount = double.tryParse(amountController.text.trim());
    if (factoryId == null || amount == null || currencyController.text.trim().isEmpty) return;
    await ref.read(financialActionControllerProvider.notifier).createPayable(
          orderId,
          PayableDraft(
            factoryId: factoryId,
            amount: amount,
            currency: currencyController.text.trim().toUpperCase(),
            dueDate: dueDate.toIso8601String().split('T').first,
          ),
        );
    ref.read(orderFinancialControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref, {int? receivableId, int? payableId}) async {
    final amountController = TextEditingController();
    final methodController = TextEditingController();
    final referenceController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
            TextField(controller: methodController, decoration: const InputDecoration(labelText: 'Method (optional)')),
            TextField(controller: referenceController, decoration: const InputDecoration(labelText: 'Reference No (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Record')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;
    await ref.read(financialActionControllerProvider.notifier).recordPayment(
          PaymentRecordDraft(
            receivableId: receivableId,
            payableId: payableId,
            amount: amount,
            paidDate: DateTime.now().toIso8601String().split('T').first,
            method: methodController.text.trim().isEmpty ? null : methodController.text.trim(),
            referenceNo: referenceController.text.trim().isEmpty ? null : referenceController.text.trim(),
          ),
        );
    ref.read(orderFinancialControllerProvider(orderId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(financialActionControllerProvider, (previous, next) {
      if (next is FinancialActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final state = ref.watch(orderFinancialControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Financials')),
      body: switch (state) {
        OrderFinancialLoading() => const LoadingView(),
        OrderFinancialError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(orderFinancialControllerProvider(orderId).notifier).refresh(),
          ),
        OrderFinancialLoaded(:final snapshot) => RefreshIndicator(
            onRefresh: () => ref.read(orderFinancialControllerProvider(orderId).notifier).refresh(),
            child: ListView(
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
                            Text('Margin', style: Theme.of(context).textTheme.titleMedium),
                            TextButton(
                              onPressed: () => _editFinancials(context, ref, snapshot.financials),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                        if (snapshot.financials.quotedUnitPrice != null) Text('Quoted: ${snapshot.financials.quotedUnitPrice}'),
                        if (snapshot.financials.actualCostUnit != null) Text('Actual cost: ${snapshot.financials.actualCostUnit}'),
                        if (snapshot.financials.realizedUnitPrice != null) Text('Realized: ${snapshot.financials.realizedUnitPrice}'),
                        if (snapshot.financials.operationalMarginPercent != null)
                          Text(
                            'Margin: ${snapshot.financials.operationalMarginPercent!.toStringAsFixed(2)}% '
                            '(${snapshot.financials.isEstimate ? "estimate" : "realized"})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Receivables', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(onPressed: () => _addReceivable(context, ref), icon: const Icon(Icons.add), label: const Text('Add')),
                  ],
                ),
                ...snapshot.receivables.map((r) => Card(
                      child: ListTile(
                        title: Text('Buyer #${r.buyerId} · ${r.currency} ${r.amount.toStringAsFixed(2)}'),
                        subtitle: Text('Received ${r.receivedAmount.toStringAsFixed(2)} · Due ${r.dueDate}'),
                        trailing: Chip(label: Text(r.status)),
                        onTap: () => _recordPayment(context, ref, receivableId: r.id),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payables', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(onPressed: () => _addPayable(context, ref), icon: const Icon(Icons.add), label: const Text('Add')),
                  ],
                ),
                ...snapshot.payables.map((p) => Card(
                      child: ListTile(
                        title: Text('Factory #${p.factoryId} · ${p.currency} ${p.amount.toStringAsFixed(2)}'),
                        subtitle: Text('Paid ${p.paidAmount.toStringAsFixed(2)} · Due ${p.dueDate}'),
                        trailing: Chip(label: Text(p.status)),
                        onTap: () => _recordPayment(context, ref, payableId: p.id),
                      ),
                    )),
              ],
            ),
          ),
      },
    );
  }
}
