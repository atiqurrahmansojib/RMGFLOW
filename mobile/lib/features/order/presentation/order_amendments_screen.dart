import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
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

  /// Common amendable fields (Doc 9.6) — "Other" lets the user type any field.
  static const _fields = [
    'Ex-factory date',
    'Delivery date',
    'Quantity',
    'Unit price',
    'Color / size breakdown',
    'Incoterm',
    'Destination',
    'Factory',
    'Other',
  ];

  Future<void> _requestAmendment(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<OrderAmendmentDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _AmendmentSheet(fields: _fields),
    );
    if (draft == null) return;
    await ref.read(orderActionControllerProvider.notifier).requestAmendment(orderId, draft);
    if (context.mounted && ref.read(orderActionControllerProvider) is OrderActionSuccess) {
      showSuccessSnack(context, 'Amendment requested — waiting for approval');
    }
    ref.invalidate(_orderAmendmentsProvider(orderId));
  }

  Future<void> _decide(BuildContext context, WidgetRef ref, OrderAmendment amendment, bool approve) async {
    final ok = await confirmAction(
      context,
      title: approve ? 'Approve amendment #${amendment.amendmentNo}?' : 'Reject amendment #${amendment.amendmentNo}?',
      message: approve
          ? '${amendment.fieldChanged} will change from "${amendment.oldValue ?? '—'}" to "${amendment.newValue ?? '—'}".'
          : 'The order keeps its current ${amendment.fieldChanged.toLowerCase()}.',
      confirmLabel: approve ? 'Approve' : 'Reject',
      destructive: !approve,
    );
    if (!ok) return;
    final notifier = ref.read(orderActionControllerProvider.notifier);
    if (approve) {
      await notifier.approveAmendment(orderId, amendment.id);
    } else {
      await notifier.rejectAmendment(orderId, amendment.id);
    }
    if (context.mounted && ref.read(orderActionControllerProvider) is OrderActionSuccess) {
      showSuccessSnack(context, approve ? 'Amendment approved' : 'Amendment rejected');
    }
    ref.invalidate(_orderAmendmentsProvider(orderId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(orderActionControllerProvider, (previous, next) {
      if (next is OrderActionFailed) showErrorSnack(context, next.failure.message);
    });
    final async = ref.watch(_orderAmendmentsProvider(orderId));
    final busy = ref.watch(orderActionControllerProvider) is OrderActionInProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Amendments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => _requestAmendment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Request change'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_orderAmendmentsProvider(orderId)),
        ),
        data: (amendments) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_orderAmendmentsProvider(orderId)),
          child: amendments.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No amendments',
                    message: 'Confirmed orders are changed only through an approved amendment.',
                    icon: Icons.edit_note_outlined,
                    color: AppModules.quotation.color,
                    actionLabel: 'Request change',
                    onAction: () => _requestAmendment(context, ref),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.listWithFab,
                  itemCount: amendments.length,
                  itemBuilder: (context, index) {
                    final amendment = amendments[index];
                    final pending = amendment.status == OrderAmendmentStatus.requested;
                    final s = Theme.of(context).colorScheme;
                    return AppCard(
                      accentColor: AppStatus.color(amendment.status.apiValue),
                      onLongPress: pending
                          ? () => showQuickActions(
                                context,
                                title: 'Amendment #${amendment.amendmentNo}',
                                subtitle: amendment.fieldChanged,
                                actions: [
                                  QuickAction(
                                    icon: Icons.check_rounded,
                                    label: 'Approve',
                                    color: AppColors.success,
                                    onTap: () => _decide(context, ref, amendment, true),
                                  ),
                                  QuickAction(
                                    icon: Icons.close_rounded,
                                    label: 'Reject',
                                    color: AppColors.danger,
                                    onTap: () => _decide(context, ref, amendment, false),
                                  ),
                                ],
                              )
                          : null,
                      child: RecordRow(
                        leading: IconBadge(icon: Icons.edit_note_rounded, color: AppModules.quotation.color),
                        title: '#${amendment.amendmentNo} · ${amendment.fieldChanged}',
                        subtitle: '${amendment.oldValue ?? '—'}  →  ${amendment.newValue ?? '—'}',
                        meta: amendment.reason,
                        trailing: StatusChip(amendment.status.apiValue, label: amendment.status.label, dense: true),
                        footer: pending
                            ? Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      label: 'Approve',
                                      icon: Icons.check_rounded,
                                      variant: ButtonVariant.tonal,
                                      onPressed: busy ? null : () => _decide(context, ref, amendment, true),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: s.error),
                                      onPressed: busy ? null : () => _decide(context, ref, amendment, false),
                                      icon: const Icon(Icons.close_rounded),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AmendmentSheet extends StatefulWidget {
  const _AmendmentSheet({required this.fields});
  final List<String> fields;

  @override
  State<_AmendmentSheet> createState() => _AmendmentSheetState();
}

class _AmendmentSheetState extends State<_AmendmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _otherField = TextEditingController();
  final _value = TextEditingController();
  final _reason = TextEditingController();
  String? _field = 'Ex-factory date';

  @override
  void dispose() {
    _otherField.dispose();
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(OrderAmendmentDraft(
      fieldChanged: _field == 'Other' ? _otherField.text.trim() : _field!,
      newValue: blankToNull(_value.text),
      reason: _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Request amendment', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _field,
                decoration: const InputDecoration(labelText: 'What needs to change?'),
                items: widget.fields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                validator: (v) => v == null ? 'Please choose a field' : null,
                onChanged: (v) => setState(() => _field = v),
              ),
              if (_field == 'Other') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _otherField,
                  decoration: const InputDecoration(labelText: 'Field name'),
                  validator: Validators.required('Field name'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _value,
                decoration: const InputDecoration(labelText: 'New value', hintText: 'e.g. 2026-11-30 or 12,000 pcs'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Reason', hintText: 'Why is the buyer/factory asking for this?'),
                validator: Validators.required('Reason'),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Submit request', icon: Icons.send_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
