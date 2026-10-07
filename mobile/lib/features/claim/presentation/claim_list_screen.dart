import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/claim_controller.dart';
import '../domain/claim.dart';

/// Document 7 (#73-74)/6.3: claims raised against one order — buyer or
/// internal, tracked to resolution. ClaimService is isolated by construction
/// from Order/Shipment mutation, so this screen is purely tracking.
class ClaimListScreen extends ConsumerWidget {
  const ClaimListScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _createClaim(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<ClaimDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ClaimSheet(orderId: orderId),
    );
    if (draft == null) return;
    await ref.read(claimActionControllerProvider.notifier).create(orderId, draft);
    if (context.mounted && ref.read(claimActionControllerProvider) is ClaimActionSuccess) {
      showSuccessSnack(context, 'Claim recorded');
    }
    ref.read(claimListControllerProvider(orderId).notifier).refresh();
  }

  Future<void> _resolveClaim(BuildContext context, WidgetRef ref, Claim claim, [ClaimStatus? status]) async {
    // "Under review" needs no notes — one tap from the status menu.
    final draft = status == ClaimStatus.underReview
        ? const ClaimResolutionDraft(status: ClaimStatus.underReview)
        : await showModalBottomSheet<ClaimResolutionDraft>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => _ResolveSheet(claim: claim, initialStatus: status ?? ClaimStatus.resolved),
          );
    if (draft == null) return;
    await ref.read(claimActionControllerProvider.notifier).resolve(claim.id, draft);
    if (context.mounted && ref.read(claimActionControllerProvider) is ClaimActionSuccess) {
      showSuccessSnack(context, 'Claim marked ${draft.status.label.toLowerCase()}');
    }
    ref.read(claimListControllerProvider(orderId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(claimActionControllerProvider, (previous, next) {
      if (next is ClaimActionFailed) showErrorSnack(context, next.failure.message);
    });
    final state = ref.watch(claimListControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Claims')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createClaim(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New claim'),
      ),
      body: switch (state) {
        ClaimListLoading() => const LoadingView(),
        ClaimListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(claimListControllerProvider(orderId).notifier).refresh(),
          ),
        ClaimListLoaded(:final claims) when claims.isEmpty => EmptyStateView(
            title: 'No claims',
            message: 'Record buyer claims (short shipment, quality, delay) here and track them to resolution.',
            icon: Icons.gavel_outlined,
            color: AppModules.claims.color,
            actionLabel: 'New claim',
            onAction: () => _createClaim(context, ref),
          ),
        ClaimListLoaded(:final claims) => RefreshIndicator(
            onRefresh: () => ref.read(claimListControllerProvider(orderId).notifier).refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab,
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];
                final closed = claim.status == ClaimStatus.resolved || claim.status == ClaimStatus.rejected;
                return AppCard(
                  accentColor: AppStatus.color(claim.status.apiValue),
                  onTap: closed ? null : () => _resolveClaim(context, ref, claim),
                  child: RecordRow(
                    leading: IconBadge(icon: AppModules.claims.icon, color: AppModules.claims.color),
                    title: '${claim.claimType.label} · by ${claim.raisedBy.label.toLowerCase()}',
                    subtitle: claim.description,
                    meta: [
                      displayDateFormat.format(claim.createdAt.toLocal()),
                      if (claim.claimedAmount != null) 'claimed ${fmtQty(claim.claimedAmount!)}',
                      if (claim.resolution != null) 'Resolution: ${claim.resolution}',
                    ].join(' · '),
                    trailing: StatusMenuChip<ClaimStatus>(
                      status: claim.status.apiValue,
                      label: claim.status.label,
                      enabled: !closed,
                      options: [ClaimStatus.underReview, ClaimStatus.resolved, ClaimStatus.rejected]
                          .where((x) => x != claim.status)
                          .toList(),
                      apiOf: (x) => x.apiValue,
                      labelOf: (x) => x.label,
                      onSelected: (x) => _resolveClaim(context, ref, claim, x),
                    ),
                  ),
                );
              },
            ),
          ),
      },
    );
  }
}

class _ClaimSheet extends StatefulWidget {
  const _ClaimSheet({required this.orderId});
  final int orderId;

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  ClaimRaisedBy _raisedBy = ClaimRaisedBy.buyer;
  ClaimType _type = ClaimType.quality;
  int? _shipmentId;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ClaimDraft(
      shipmentId: _shipmentId,
      raisedBy: _raisedBy,
      claimType: _type,
      description: _description.text.trim(),
      claimedAmount: double.tryParse(_amount.text.trim()),
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
              Text('New claim', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<ClaimRaisedBy>(
                segments: ClaimRaisedBy.values
                    .map((v) => ButtonSegment(value: v, label: Text('By ${v.label.toLowerCase()}')))
                    .toList(),
                selected: {_raisedBy},
                onSelectionChanged: (s) => setState(() => _raisedBy = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ClaimType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Claim type'),
                items: ClaimType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              LookupField(
                label: 'Shipment',
                icon: Icons.local_shipping_outlined,
                options: shipmentLookupProvider(widget.orderId),
                emptyMessage: 'This order has no shipments yet.',
                onChanged: (v) => _shipmentId = v,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', hintText: 'What happened? e.g. 120 pcs short in carton 14'),
                validator: Validators.required('Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amount,
                keyboardType: NumberInput.decimalKeyboard,
                inputFormatters: NumberInput.decimal,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Claimed amount (optional)'),
                validator: Validators.money(required: false, what: 'Claimed amount'),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Record claim', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({required this.claim, this.initialStatus = ClaimStatus.resolved});
  final Claim claim;
  final ClaimStatus initialStatus;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late ClaimStatus _status = widget.initialStatus;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_status != ClaimStatus.underReview) {
      final ok = await confirmAction(
        context,
        title: 'Close this claim as ${_status.label.toLowerCase()}?',
        message: 'A ${_status.label.toLowerCase()} claim can no longer be updated.',
        confirmLabel: 'Mark ${_status.label.toLowerCase()}',
        destructive: _status == ClaimStatus.rejected,
      );
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pop(ClaimResolutionDraft(status: _status, resolution: blankToNull(_notes.text)));
  }

  @override
  Widget build(BuildContext context) {
    final needsNotes = _status != ClaimStatus.underReview;
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
              Text('Update claim', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.claim.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<ClaimStatus>(
                segments: [ClaimStatus.underReview, ClaimStatus.resolved, ClaimStatus.rejected]
                    .map((v) => ButtonSegment(value: v, label: Text(v.label)))
                    .toList(),
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: needsNotes ? 'Resolution notes' : 'Notes (optional)',
                  hintText: 'e.g. Credit note of USD 450 agreed with buyer',
                ),
                validator: needsNotes ? Validators.required('Resolution notes') : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Save', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
