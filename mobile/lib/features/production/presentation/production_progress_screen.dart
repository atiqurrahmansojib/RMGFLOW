import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/production_controller.dart';
import 'production_update_form_screen.dart';

/// Document 7 (#52-53)/9.6/14.4: planned-vs-actual production progress —
/// every number shown is the server's cumulative rollup, never summed here.
class ProductionProgressScreen extends ConsumerWidget {
  const ProductionProgressScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productionProgressControllerProvider(orderId));
    void addUpdate() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProductionUpdateFormScreen(orderId: orderId)))
        .then((_) => ref.read(productionProgressControllerProvider(orderId).notifier).refresh());

    return Scaffold(
      appBar: AppBar(title: const Text('Production Progress')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addUpdate,
        icon: const Icon(Icons.add),
        label: const Text('Daily update'),
      ),
      body: switch (state) {
        ProductionProgressLoading() => const LoadingView(),
        ProductionProgressError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(productionProgressControllerProvider(orderId).notifier).refresh(),
          ),
        ProductionProgressLoaded(:final progress) => RefreshIndicator(
            onRefresh: () => ref.read(productionProgressControllerProvider(orderId).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab.copyWith(left: 0, right: 0, top: 0),
              children: [
                GradientHeader.module(
                  AppModules.production,
                  eyebrow: 'Packed',
                  title: '${progress.packingProgressPercent.toStringAsFixed(1)}%',
                  subtitle: '${fmtQty(progress.cumulativePacking)} of ${fmtQty(progress.orderQuantity)} pcs packed',
                  bottom: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: (progress.packingProgressPercent / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.xxl,
                        runSpacing: AppSpacing.md,
                        children: [
                          HeaderStat(value: fmtQty(progress.orderQuantity), label: 'Order qty'),
                          HeaderStat(value: fmtQty(progress.cumulativeRejection), label: 'Rejected'),
                          HeaderStat(value: '${progress.dailyUpdates.length}', label: 'Daily updates'),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader('Stages vs order quantity',
                          icon: Icons.stacked_bar_chart_rounded, accentColor: AppModules.production.color),
                      AppCard(
                        child: Column(
                          children: [
                            StageProgress(
                              label: 'Cutting',
                              icon: Icons.content_cut_rounded,
                              value: progress.cumulativeCutting,
                              target: progress.orderQuantity,
                              color: AppModules.sampling.color,
                            ),
                            StageProgress(
                              label: 'Sewing',
                              icon: Icons.dry_cleaning_outlined,
                              value: progress.cumulativeSewing,
                              target: progress.orderQuantity,
                              color: AppModules.production.color,
                            ),
                            StageProgress(
                              label: 'Finishing',
                              icon: Icons.iron_outlined,
                              value: progress.cumulativeFinishing,
                              target: progress.orderQuantity,
                              color: AppModules.costing.color,
                            ),
                            StageProgress(
                              label: 'Packing',
                              icon: Icons.inventory_2_outlined,
                              value: progress.cumulativePacking,
                              target: progress.orderQuantity,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                      const SectionHeader('Quality loss',
                          icon: Icons.report_gmailerrorred_rounded, accentColor: AppColors.danger),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: fmtQty(progress.cumulativeRejection),
                              label: 'Rejected pcs',
                              icon: Icons.block_rounded,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              value: fmtQty(progress.cumulativeAlteration),
                              label: 'Altered pcs',
                              icon: Icons.build_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      SectionHeader('Daily updates',
                          count: progress.dailyUpdates.length,
                          icon: Icons.event_repeat_rounded,
                          accentColor: AppModules.production.color),
                      if (progress.dailyUpdates.isEmpty)
                        EmptyStateView(
                          message: 'No daily updates yet. Record today\'s cutting, sewing and packing output.',
                          icon: Icons.trending_up_rounded,
                          color: AppModules.production.color,
                          actionLabel: 'Daily update',
                          onAction: addUpdate,
                        ),
                      ...progress.dailyUpdates.map((u) => AppCard(
                            accentColor: AppModules.production.color,
                            child: RecordRow(
                              leading: IconBadge(icon: Icons.event_note_rounded, color: AppModules.production.color),
                              title: formatApiDate(u.updateDate),
                              subtitle: 'Cut ${fmtQty(u.cuttingQty)} · Sew ${fmtQty(u.sewingQty)} · '
                                  'Finish ${fmtQty(u.finishingQty)} · Pack ${fmtQty(u.packingQty)}',
                              meta: u.rejectionQty + u.alterationQty == 0
                                  ? null
                                  : 'Reject ${fmtQty(u.rejectionQty)} · Alter ${fmtQty(u.alterationQty)}',
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }
}
