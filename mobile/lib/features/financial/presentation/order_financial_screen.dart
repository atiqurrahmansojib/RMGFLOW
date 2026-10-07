import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/order_financial_controller.dart';
import '../domain/financial.dart';

/// Document 7 (#70-72)/9.10/9.12: one order's margin (estimate vs realized),
/// receivables, and payables — every number shown is exactly what the server
/// derived, never recomputed here.
class OrderFinancialScreen extends ConsumerWidget {
  const OrderFinancialScreen({super.key, required this.orderId});

  final int orderId;

  Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => child,
      );

  /// Runs a financial action, then acknowledges success and refreshes.
  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, String success) async {
    await action();
    if (context.mounted && ref.read(financialActionControllerProvider) is FinancialActionSuccess) {
      showSuccessSnack(context, success);
    }
    ref.read(orderFinancialControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _editFinancials(BuildContext context, WidgetRef ref, OrderFinancials current) async {
    final draft = await _sheet<OrderFinancialsDraft>(context, _FinancialsSheet(current: current));
    if (draft == null || !context.mounted) return;
    await _run(
        context,
        ref,
        () => ref.read(financialActionControllerProvider.notifier).upsertFinancials(orderId, draft),
        'Financials saved');
  }

  Future<void> _addReceivable(BuildContext context, WidgetRef ref) async {
    final entry = await _sheet<_PartyEntry>(context, const _PartyAmountSheet(isReceivable: true));
    if (entry == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(financialActionControllerProvider.notifier).createReceivable(
            orderId,
            ReceivableDraft(
                buyerId: entry.partyId, amount: entry.amount, currency: entry.currency, dueDate: entry.dueDate),
          ),
      'Receivable added',
    );
  }

  Future<void> _addPayable(BuildContext context, WidgetRef ref) async {
    final entry = await _sheet<_PartyEntry>(context, const _PartyAmountSheet(isReceivable: false));
    if (entry == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(financialActionControllerProvider.notifier).createPayable(
            orderId,
            PayableDraft(
                factoryId: entry.partyId, amount: entry.amount, currency: entry.currency, dueDate: entry.dueDate),
          ),
      'Payable added',
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref, {
    int? receivableId,
    int? payableId,
    required String currency,
    required double outstanding,
  }) async {
    final draft = await _sheet<PaymentRecordDraft>(
      context,
      PaymentSheet(receivableId: receivableId, payableId: payableId, currency: currency, outstanding: outstanding),
    );
    if (draft == null || !context.mounted) return;
    await _run(context, ref, () => ref.read(financialActionControllerProvider.notifier).recordPayment(draft),
        receivableId != null ? 'Payment received recorded' : 'Payment made recorded');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(financialActionControllerProvider, (previous, next) {
      if (next is FinancialActionFailed) showErrorSnack(context, next.failure.message);
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
            child: Builder(builder: (context) {
              final f = snapshot.financials;
              final margin = f.operationalMarginPercent;
              final openAr = snapshot.receivables.where((r) => r.amount - r.receivedAmount > 0.0001).length;
              final openAp = snapshot.payables.where((p) => p.amount - p.paidAmount > 0.0001).length;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  GradientHeader.module(
                    AppModules.financial,
                    eyebrow: margin == null ? 'Margin' : (f.isEstimate ? 'Margin · estimate' : 'Margin · realized'),
                    title: margin == null ? 'Not set' : '${margin.toStringAsFixed(2)}%',
                    subtitle: margin == null ? 'Enter quoted price and actual cost to see the margin' : null,
                    trailing: IconButton.filledTonal(
                      tooltip: 'Edit financials',
                      onPressed: () => _editFinancials(context, ref, f),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    bottom: Row(
                      children: [
                        HeaderStat(value: '$openAr', label: 'Open receivables'),
                        const SizedBox(width: AppSpacing.xxl),
                        HeaderStat(value: '$openAp', label: 'Open payables'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader('Unit economics',
                            icon: Icons.calculate_rounded, accentColor: AppModules.financial.color),
                        AppCard(
                          onTap: () => _editFinancials(context, ref, f),
                          child: Column(
                            children: [
                              InfoRow(label: 'Quoted unit price', value: f.quotedUnitPrice?.toStringAsFixed(2)),
                              InfoRow(label: 'Actual cost per unit', value: f.actualCostUnit?.toStringAsFixed(2)),
                              InfoRow(label: 'Realized unit price', value: f.realizedUnitPrice?.toStringAsFixed(2)),
                              if (margin != null)
                                InfoRow(
                                  label: f.isEstimate ? 'Margin (estimate)' : 'Margin (realized)',
                                  value: '${margin.toStringAsFixed(2)}%',
                                  emphasize: true,
                                  valueColor: margin < 0 ? AppColors.danger : AppColors.success,
                                ),
                            ],
                          ),
                        ),
                        SectionHeader(
                          'Receivables',
                          subtitle: 'Money the buyer owes us · swipe to record a payment',
                          icon: Icons.call_received_rounded,
                          accentColor: AppColors.success,
                          count: snapshot.receivables.length,
                          actionLabel: 'Add',
                          onAction: () => _addReceivable(context, ref),
                        ),
                        if (snapshot.receivables.isEmpty)
                          const _EmptyLine('No receivables yet — add the invoice amount due from the buyer.'),
                        ...snapshot.receivables.map((r) {
                          final outstanding = r.amount - r.receivedAmount;
                          final settled = outstanding <= 0.0001;
                          Future<void> pay() => _recordPayment(context, ref,
                              receivableId: r.id, currency: r.currency, outstanding: outstanding);
                          return _MoneyRow(
                            key: ValueKey('ar-${r.id}'),
                            party: lookupLabel(ref, buyerLookupProvider, r.buyerId, fallback: 'Buyer #${r.buyerId}'),
                            currency: r.currency,
                            amount: r.amount,
                            settledAmount: r.receivedAmount,
                            settledLabel: 'received',
                            dueDate: r.dueDate,
                            status: r.status,
                            color: AppColors.success,
                            actionLabel: 'Receive',
                            onPay: settled ? null : pay,
                          );
                        }),
                        SectionHeader(
                          'Payables',
                          subtitle: 'Money we owe the factory · swipe to record a payment',
                          icon: Icons.call_made_rounded,
                          accentColor: AppModules.production.color,
                          count: snapshot.payables.length,
                          actionLabel: 'Add',
                          onAction: () => _addPayable(context, ref),
                        ),
                        if (snapshot.payables.isEmpty)
                          const _EmptyLine('No payables yet — add the amount due to the factory.'),
                        ...snapshot.payables.map((p) {
                          final outstanding = p.amount - p.paidAmount;
                          final settled = outstanding <= 0.0001;
                          Future<void> pay() => _recordPayment(context, ref,
                              payableId: p.id, currency: p.currency, outstanding: outstanding);
                          return _MoneyRow(
                            key: ValueKey('ap-${p.id}'),
                            party: lookupLabel(ref, factoryLookupProvider, p.factoryId,
                                fallback: 'Factory #${p.factoryId}'),
                            currency: p.currency,
                            amount: p.amount,
                            settledAmount: p.paidAmount,
                            settledLabel: 'paid',
                            dueDate: p.dueDate,
                            status: p.status,
                            color: AppModules.production.color,
                            actionLabel: 'Pay',
                            onPay: settled ? null : pay,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
      },
    );
  }
}

/// Receivable / payable row: amount, settled-so-far bar, due badge and a
/// swipe (or button) to record a payment against the outstanding balance.
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    super.key,
    required this.party,
    required this.currency,
    required this.amount,
    required this.settledAmount,
    required this.settledLabel,
    required this.dueDate,
    required this.status,
    required this.color,
    required this.actionLabel,
    this.onPay,
  });

  final String party;
  final String currency;
  final double amount;
  final double settledAmount;
  final String settledLabel;
  final String dueDate;
  final String status;
  final Color color;
  final String actionLabel;
  final Future<void> Function()? onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = daysFromToday(dueDate);
    final ratio = amount <= 0 ? 0.0 : (settledAmount / amount).clamp(0.0, 1.0);
    final overdue = onPay != null && days != null && days < 0;
    return SwipeAction(
      key: key,
      startLabel: actionLabel,
      startIcon: Icons.payments_rounded,
      startColor: color,
      onSwipeStart: onPay,
      child: AppCard(
        accentColor: overdue ? AppColors.danger : AppStatus.color(status),
        onTap: onPay,
        child: RecordRow(
          title: party,
          subtitle: '${fmtMoney(currency, settledAmount)} $settledLabel · due ${formatApiDate(dueDate)}',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtMoney(currency, amount),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),
              overdue
                  ? TonePill(relativeDays(days), color: AppColors.danger, icon: Icons.alarm_rounded)
                  : StatusChip(status, dense: true),
            ],
          ),
          footer: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

/// Shared bottom-sheet chrome: title, scrollable form body, primary action.
class _SheetForm extends StatelessWidget {
  const _SheetForm(
      {required this.formKey,
      required this.title,
      required this.children,
      required this.actionLabel,
      required this.onSave});

  final GlobalKey<FormState> formKey;
  final String title;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              for (final c in children) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: c),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(label: actionLabel, icon: Icons.check_rounded, onPressed: onSave),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _moneyField(TextEditingController c, String label, {bool required = true, String? helper}) => TextFormField(
      controller: c,
      keyboardType: NumberInput.decimalKeyboard,
      inputFormatters: NumberInput.decimal,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: required ? label : '$label (optional)', helperText: helper),
      validator: Validators.money(required: required, what: label),
    );

class _FinancialsSheet extends StatefulWidget {
  const _FinancialsSheet({required this.current});
  final OrderFinancials current;

  @override
  State<_FinancialsSheet> createState() => _FinancialsSheetState();
}

class _FinancialsSheetState extends State<_FinancialsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _quoted = TextEditingController(text: widget.current.quotedUnitPrice?.toString());
  late final _actual = TextEditingController(text: widget.current.actualCostUnit?.toString());
  late final _realized = TextEditingController(text: widget.current.realizedUnitPrice?.toString());

  @override
  void dispose() {
    _quoted.dispose();
    _actual.dispose();
    _realized.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
        formKey: _formKey,
        title: 'Edit financials',
        actionLabel: 'Save',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop(OrderFinancialsDraft(
            quotedUnitPrice: double.tryParse(_quoted.text.trim()),
            actualCostUnit: double.tryParse(_actual.text.trim()),
            realizedUnitPrice: double.tryParse(_realized.text.trim()),
          ));
        },
        children: [
          _moneyField(_quoted, 'Quoted unit price', required: false),
          _moneyField(_actual, 'Actual cost per unit', required: false),
          _moneyField(_realized, 'Realized unit price', required: false, helper: 'Fill in once the order has shipped'),
        ],
      );
}

class _PartyEntry {
  const _PartyEntry(this.partyId, this.amount, this.currency, this.dueDate);
  final int partyId;
  final double amount;
  final String currency;
  final String dueDate;
}

class _PartyAmountSheet extends StatefulWidget {
  const _PartyAmountSheet({required this.isReceivable});
  final bool isReceivable;

  @override
  State<_PartyAmountSheet> createState() => _PartyAmountSheetState();
}

class _PartyAmountSheetState extends State<_PartyAmountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'USD');
  int? _partyId;
  DateTime? _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
        formKey: _formKey,
        title: widget.isReceivable ? 'New receivable' : 'New payable',
        actionLabel: widget.isReceivable ? 'Add receivable' : 'Add payable',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop(_PartyEntry(
            _partyId!,
            double.parse(_amount.text.trim()),
            _currency.text.trim().toUpperCase(),
            toApiDate(_dueDate)!,
          ));
        },
        children: [
          LookupField(
            label: widget.isReceivable ? 'Buyer' : 'Factory',
            icon: widget.isReceivable ? Icons.storefront_rounded : Icons.factory_outlined,
            required: true,
            options: widget.isReceivable ? buyerLookupProvider : factoryLookupProvider,
            onChanged: (v) => _partyId = v,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _moneyField(_amount, 'Amount')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CodePickerField(
                  controller: _currency,
                  label: 'Currency',
                  codes: currencyCodesProvider,
                ),
              ),
            ],
          ),
          DateField(label: 'Due date', required: true, value: _dueDate, onChanged: (d) => setState(() => _dueDate = d)),
        ],
      );
}

/// Records money received against a receivable or paid against a payable.
/// Shared with the organization-wide receivables/payables screen.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key, this.receivableId, this.payableId, required this.currency, required this.outstanding});
  final int? receivableId;
  final int? payableId;
  final String currency;
  final double outstanding;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  static const _methods = ['Bank transfer (TT)', 'LC', 'Cheque', 'Cash', 'Other'];
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.outstanding.toStringAsFixed(2));
  final _reference = TextEditingController();
  DateTime? _paidDate = DateTime.now();
  String? _method;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim());
    final ok = await confirmAction(
      context,
      title: 'Record ${widget.currency} ${amount.toStringAsFixed(2)}?',
      message: '${amount > widget.outstanding + 0.0001 ? 'This is MORE than the outstanding '
              '${widget.currency} ${widget.outstanding.toStringAsFixed(2)}. ' : ''}'
          'Payments are part of the financial audit trail and cannot be edited afterwards.',
      confirmLabel: 'Record payment',
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(PaymentRecordDraft(
      receivableId: widget.receivableId,
      payableId: widget.payableId,
      amount: amount,
      paidDate: toApiDate(_paidDate)!,
      method: _method,
      referenceNo: blankToNull(_reference.text),
    ));
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
        formKey: _formKey,
        title: widget.receivableId != null ? 'Record payment received' : 'Record payment made',
        actionLabel: 'Record payment',
        onSave: _save,
        children: [
          TextFormField(
            controller: _amount,
            keyboardType: NumberInput.decimalKeyboard,
            inputFormatters: NumberInput.decimal,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${widget.currency} ',
              helperText: 'Outstanding: ${widget.currency} ${widget.outstanding.toStringAsFixed(2)}',
            ),
            validator: Validators.money(what: 'Amount'),
          ),
          DateField(
            label: 'Payment date',
            required: true,
            value: _paidDate,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _paidDate = d),
          ),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Method (optional)'),
            items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v),
          ),
          TextFormField(
            controller: _reference,
            decoration:
                const InputDecoration(labelText: 'Reference no. (optional)', hintText: 'Bank ref, LC no., cheque no.'),
          ),
        ],
      );
}
