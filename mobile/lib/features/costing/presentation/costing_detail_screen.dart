import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
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

  Future<void> _submitForApproval(BuildContext context, WidgetRef ref, Costing costing) async {
    final ok = await confirmAction(
      context,
      title: 'Submit for approval?',
      message: 'Version ${costing.versionNo} will be sent to an approver. '
          'You will not be able to edit it while it is under review.',
      confirmLabel: 'Submit',
    );
    if (!ok) return;
    await ref.read(costingSubmitControllerProvider.notifier).submitForApproval(costing.id);
    ref.invalidate(_costingDetailProvider(costingId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_costingDetailProvider(costingId));
    ref.listen(costingSubmitControllerProvider, (_, next) {
      if (next is CostingSubmitSuccess) {
        showSuccessSnack(context, 'Submitted for approval');
      } else if (next is CostingSubmitFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final submitting = ref.watch(costingSubmitControllerProvider) is CostingSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text('Costing #$costingId')),
      body: async.when(
        loading: () => const LoadingView(layout: LoadingLayout.detail),
        error: (error, _) => ErrorStateView(
          failure: mapErrorToFailure(error),
          onRetry: () => ref.invalidate(_costingDetailProvider(costingId)),
        ),
        data: (costing) {
          const module = AppModules.costing;
          final margin = costing.marginPercent;
          final style = lookupLabel(ref, styleLookupProvider(null), costing.styleId);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_costingDetailProvider(costingId)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.page,
              children: [
                GradientHeader.module(
                  module,
                  margin: EdgeInsets.zero,
                  eyebrow: 'Costing · version ${costing.versionNo}',
                  title: style,
                  subtitle:
                      costing.inquiryId == null ? null : lookupLabel(ref, inquiryLookupProvider, costing.inquiryId),
                  trailing: StatusChip(costing.status.apiValue, label: costing.status.label),
                  bottom: Row(
                    children: [
                      Expanded(
                          child:
                              HeaderStat(value: formatMoney(costing.currency, costing.totalCost), label: 'Total cost')),
                      Expanded(
                        child:
                            HeaderStat(value: margin == null ? '—' : '${margin.toStringAsFixed(1)}%', label: 'Margin'),
                      ),
                      Expanded(child: HeaderStat(value: '${costing.quantity}', label: 'Pieces')),
                    ],
                  ),
                ),
                SectionHeader('Summary', icon: Icons.summarize_outlined, accentColor: module.color),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(label: 'Style', value: style),
                      if (costing.inquiryId != null)
                        InfoRow(label: 'Inquiry', value: lookupLabel(ref, inquiryLookupProvider, costing.inquiryId)),
                      InfoRow(label: 'Quantity', value: '${costing.quantity} pcs'),
                      InfoRow(label: 'Exchange rate', value: '${costing.exchangeRate} ${costing.currency}'),
                      if (costing.targetPrice != null)
                        InfoRow(label: 'Target price', value: formatMoney(costing.currency, costing.targetPrice)),
                      const Divider(height: AppSpacing.xl),
                      InfoRow(
                        label: 'Total cost',
                        value: formatMoney(costing.currency, costing.totalCost),
                        emphasize: true,
                      ),
                      if (costing.totalCost == null)
                        Text(
                          'Cost and margin figures are hidden for your role.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (margin != null)
                        InfoRow(
                          label: 'Margin',
                          value: '${margin.toStringAsFixed(2)}%',
                          emphasize: true,
                          valueColor: margin < 0 ? AppColors.danger : AppColors.success,
                        ),
                    ],
                  ),
                ),
                SectionHeader(
                  'Cost items',
                  count: costing.items.length,
                  icon: Icons.list_alt_rounded,
                  accentColor: module.color,
                ),
                for (final item in costing.items)
                  RecordTile(
                    accentColor: module.color,
                    title: item.componentType.label + (item.description != null ? ' — ${item.description}' : ''),
                    subtitle:
                        'Unit ${item.unitCost ?? 'hidden'} × consumption ${item.consumption} + ${item.wastagePercent}% wastage',
                    trailing: Text(
                      formatMoney(null, item.totalCost),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (costing.status == CostingStatus.draft) ...[
                  PrimaryButton(
                    icon: Icons.send_outlined,
                    label: 'Submit for approval',
                    loading: submitting,
                    onPressed: () => _submitForApproval(context, ref, costing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit draft',
                    variant: ButtonVariant.tonal,
                    onPressed: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CostingFormScreen(existingCosting: costing, mode: CostingFormMode.editDraft),
                          ),
                        )
                        .then((_) => ref.invalidate(_costingDetailProvider(costingId))),
                  ),
                ] else
                  PrimaryButton(
                    icon: Icons.difference_outlined,
                    label: 'Create new version',
                    variant: ButtonVariant.tonal,
                    onPressed: () async {
                      final result = await Navigator.of(context).push<Object?>(
                        MaterialPageRoute(
                          builder: (_) => CostingFormScreen(existingCosting: costing, mode: CostingFormMode.revise),
                        ),
                      );
                      if (!context.mounted) return;
                      if (result is Costing && result.id != costingId) {
                        // Jump straight to the new version.
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: result.id)),
                        );
                      } else {
                        ref.invalidate(_costingDetailProvider(costingId));
                      }
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  icon: Icons.history_rounded,
                  label: 'Approval history',
                  variant: ButtonVariant.outlined,
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
          );
        },
      ),
    );
  }
}
