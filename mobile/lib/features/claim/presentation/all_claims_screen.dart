import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../../order/presentation/open_order.dart';
import '../data/claim_repository_impl.dart';
import '../domain/claim.dart';
import 'claim_list_screen.dart';

/// Document 7 (#81): every claim in the organization, across orders — filter
/// by status, search by order/description, and jump into an order's claims to
/// resolve one. Claims are raised from inside an order (they need its id).
final allClaimsProvider = FutureProvider.autoDispose<List<Claim>>((ref) {
  return ref.read(authControllerProvider.notifier).callAuthorized(() => ref.read(claimRepositoryProvider).listAll());
});

class AllClaimsScreen extends ConsumerStatefulWidget {
  const AllClaimsScreen({super.key});

  @override
  ConsumerState<AllClaimsScreen> createState() => _AllClaimsScreenState();
}

class _AllClaimsScreenState extends ConsumerState<AllClaimsScreen> {
  ClaimStatus? _status;
  String _query = '';

  Future<void> _refresh() async {
    ref.invalidate(allClaimsProvider);
    await ref.read(allClaimsProvider.future);
  }

  String _order(Claim c) => lookupLabel(ref, orderLookupProvider, c.orderId, fallback: 'Order #${c.orderId}');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allClaimsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Claims')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(failure: mapErrorToFailure(e), onRetry: _refresh),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final rows = all.where((c) {
            if (_status != null && c.status != _status) return false;
            if (q.isEmpty) return true;
            return _order(c).toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q) ||
                c.claimType.label.toLowerCase().contains(q);
          }).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final open = all.where((c) => c.status == ClaimStatus.open || c.status == ClaimStatus.underReview).toList();
          final claimedOpen = open.fold<double>(0, (sum, c) => sum + (c.claimedAmount ?? 0));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Open claims',
                          value: '${open.length}',
                          icon: Icons.gavel_rounded,
                          color: AppModules.claims.color,
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          label: 'Amount at stake',
                          value: fmtCompact(claimedOpen),
                          caption: 'Open claims, order currency',
                          icon: Icons.money_off_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: SearchField(
                    hintText: 'Search order, type or description',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FilterChipBar<ClaimStatus>(
                  values: ClaimStatus.values,
                  selected: _status,
                  labelOf: (s) => s.label,
                  onSelected: (s) => setState(() => _status = s),
                ),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyStateView(
                      color: AppModules.claims.color,
                      title: all.isEmpty ? 'No claims' : 'Nothing here',
                      message: all.isEmpty
                          ? 'No buyer or internal claims have been raised. Raise one from an order → Claims.'
                          : 'No claims match this filter.',
                      icon: Icons.gavel_outlined,
                    ),
                  )
                else
                  for (final c in rows)
                    Builder(builder: (context) {
                      final order = _order(c);
                      Future<void> openClaims() async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ClaimListScreen(orderId: c.orderId)));
                        if (mounted) _refresh();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: AppCard(
                          accentColor: AppStatus.color(c.status.apiValue),
                          onTap: openClaims,
                          onLongPress: () => showQuickActions(
                            context,
                            title: '$order · ${c.claimType.label}',
                            subtitle: c.description,
                            actions: [
                              QuickAction(
                                icon: AppModules.claims.icon,
                                label: "Open this order's claims",
                                color: AppModules.claims.color,
                                onTap: openClaims,
                              ),
                              QuickAction(
                                icon: AppModules.orders.icon,
                                label: 'Open order',
                                color: AppModules.orders.color,
                                onTap: () => openOrderById(context, ref, c.orderId),
                              ),
                            ],
                          ),
                          child: RecordRow(
                            leading: IconBadge(icon: AppModules.claims.icon, color: AppModules.claims.color),
                            title: '$order · ${c.claimType.label}',
                            subtitle: c.description,
                            meta:
                                'By ${c.raisedBy.label.toLowerCase()} · ${displayDateFormat.format(c.createdAt.toLocal())}'
                                '${c.claimedAmount != null ? ' · claimed ${fmtQty(c.claimedAmount!)}' : ''}',
                            trailing: StatusChip(c.status.apiValue, label: c.status.label, dense: true),
                          ),
                        ),
                      );
                    }),
              ],
            ),
          );
        },
      ),
    );
  }
}
