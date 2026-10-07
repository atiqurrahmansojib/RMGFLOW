import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/lookups/module_access.dart';
import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../approval/domain/approval.dart' as approval;
import '../../approval/presentation/approval_history_screen.dart';
import '../../costing/presentation/costing_detail_screen.dart';
import '../application/quotation_form_controller.dart';
import '../domain/quotation.dart';
import 'quotation_form_screen.dart';

/// Statuses a quotation can be moved to by hand from [current], mirroring
/// QuotationService's Doc 10.2 status machine: DRAFT → SENT/NEGOTIATING;
/// SENT and NEGOTIATING → buyer's answer (NEGOTIATING/SENT, APPROVED,
/// REJECTED, EXPIRED); APPROVED/REJECTED/EXPIRED/SUPERSEDED are final.
/// APPROVED is offered only to roles holding QUOTATION_APPROVE (Doc 10.3).
List<QuotationStatus> nextQuotationStatuses(QuotationStatus current, {bool canApprove = true}) {
  final List<QuotationStatus> candidates = switch (current) {
    QuotationStatus.draft => const [QuotationStatus.sent, QuotationStatus.negotiating],
    QuotationStatus.sent || QuotationStatus.negotiating => const [
        QuotationStatus.sent,
        QuotationStatus.negotiating,
        QuotationStatus.approved,
        QuotationStatus.rejected,
        QuotationStatus.expired,
      ],
    _ => const [],
  };
  return candidates.where((s) => s != current && (canApprove || s != QuotationStatus.approved)).toList();
}

/// Document 7 (#40-42): Quotation detail — status-change actions and a link
/// into the generic Approval Engine's history for this target. A status
/// change updates the screen in place (no bounce back to the list).
class QuotationDetailScreen extends ConsumerStatefulWidget {
  const QuotationDetailScreen({super.key, required this.quotation});

  final Quotation quotation;

  @override
  ConsumerState<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends ConsumerState<QuotationDetailScreen> {
  late Quotation _quotation = widget.quotation;

  Future<void> _changeStatus(QuotationStatus s) async {
    final quotation = _quotation;
    final negative = s == QuotationStatus.rejected || s == QuotationStatus.expired;
    final ok = await confirmAction(
      context,
      title: 'Mark as ${s.label}?',
      message: '${quotation.quotationNo ?? 'This quotation'} will move from ${quotation.status.label} to ${s.label}.',
      confirmLabel: 'Mark ${s.label.toLowerCase()}',
      destructive: negative,
    );
    if (ok) ref.read(quotationStatusControllerProvider.notifier).updateStatus(quotation.id, s);
  }

  Future<void> _revise() async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => QuotationFormScreen(existingQuotation: _quotation, isRevise: true)),
    );
    if (!mounted || result is! Quotation) return;
    // Jump straight to the new version.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: result)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quotationStatusControllerProvider, (previous, next) {
      if (next is QuotationStatusFailed) {
        showErrorSnack(context, next.failure.message);
      } else if (next is QuotationStatusSuccess) {
        showSuccessSnack(context, 'Quotation marked ${next.quotation.status.label.toLowerCase()}');
        setState(() => _quotation = next.quotation);
      }
    });
    final updating = ref.watch(quotationStatusControllerProvider) is QuotationStatusUpdating;
    final quotation = _quotation;
    const module = AppModules.quotation;
    final total = quotation.unitPrice * quotation.quantity;
    final next = nextQuotationStatuses(quotation.status, canApprove: canApproveQuotations(ref.watch(currentUserProvider)));

    return Scaffold(
      appBar: AppBar(
        title: Text(quotation.quotationNo ?? 'Quotation #${quotation.id}'),
        actions: [
          IconButton(tooltip: 'Create new version', icon: const Icon(Icons.difference_outlined), onPressed: _revise),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          GradientHeader.module(
            module,
            margin: EdgeInsets.zero,
            eyebrow: 'Quotation · version ${quotation.versionNo}',
            title: lookupLabel(ref, buyerLookupProvider, quotation.buyerId),
            subtitle: lookupLabel(ref, styleLookupProvider(null), quotation.styleId),
            trailing: StatusChip(quotation.status.apiValue, label: quotation.status.label),
            bottom: Row(
              children: [
                Expanded(child: HeaderStat(value: formatMoney(quotation.currency, total), label: 'Total value')),
                Expanded(
                    child:
                        HeaderStat(value: formatMoney(quotation.currency, quotation.unitPrice), label: 'Unit price')),
                Expanded(child: HeaderStat(value: '${quotation.quantity}', label: 'Pieces')),
              ],
            ),
          ),
          SectionHeader(
            'Status',
            icon: Icons.sync_alt_rounded,
            accentColor: module.color,
            trailing: StatusMenuChip<QuotationStatus>(
              status: quotation.status.apiValue,
              label: quotation.status.label,
              dense: false,
              enabled: !updating,
              options: next,
              apiValueOf: (s) => s.apiValue,
              labelOf: (s) => s.label,
              onSelected: _changeStatus,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in next)
                ActionChip(
                  avatar: Icon(AppStatus.resolve(s.apiValue).icon, size: 18, color: AppStatus.color(s.apiValue)),
                  label: Text('Mark ${s.label.toLowerCase()}'),
                  onPressed: updating ? null : () => _changeStatus(s),
                ),
            ],
          ),
          if (updating) ...[const SizedBox(height: AppSpacing.sm), const LinearProgressIndicator()],
          SectionHeader('Offer', icon: Icons.request_quote_outlined, accentColor: module.color),
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quotation.quotationNo != null)
                  InfoRow(label: 'Quotation no.', value: quotation.quotationNo, copyable: true),
                InfoRow(label: 'Buyer', value: lookupLabel(ref, buyerLookupProvider, quotation.buyerId)),
                InfoRow(label: 'Style', value: lookupLabel(ref, styleLookupProvider(null), quotation.styleId)),
                InfoRow(
                  label: 'Costing',
                  value: lookupLabel(ref, costingLookupProvider(false), quotation.costingId,
                      fallback: 'Costing #${quotation.costingId}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CostingDetailScreen(costingId: quotation.costingId)),
                  ),
                ),
                InfoRow(label: 'Quantity', value: '${quotation.quantity} pcs'),
                InfoRow(label: 'Unit price', value: formatMoney(quotation.currency, quotation.unitPrice)),
                InfoRow(label: 'Total value', value: formatMoney(quotation.currency, total), emphasize: true),
              ],
            ),
          ),
          SectionHeader('Terms', icon: Icons.handshake_outlined, accentColor: module.color),
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(label: 'Incoterm', value: quotation.incoterm),
                InfoRow(
                    label: 'Lead time',
                    value: quotation.leadTimeDays == null ? null : '${quotation.leadTimeDays} days'),
                InfoRow(
                    label: 'Valid until',
                    value: quotation.validityDate == null ? null : formatApiDate(quotation.validityDate)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            icon: Icons.difference_outlined,
            label: 'Create new version',
            variant: ButtonVariant.tonal,
            onPressed: _revise,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            icon: Icons.history_rounded,
            label: 'Approval history',
            variant: ButtonVariant.outlined,
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
