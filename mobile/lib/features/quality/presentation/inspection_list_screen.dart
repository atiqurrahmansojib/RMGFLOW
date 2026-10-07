import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/inspection_controller.dart';
import '../domain/quality.dart';
import 'defect_list_screen.dart';
import 'inspection_form_screen.dart';

/// Document 7 (#59): one order's inspection history.
class InspectionListScreen extends ConsumerWidget {
  const InspectionListScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionListControllerProvider(orderId));
    void openDefects(Inspection inspection) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DefectListScreen(inspection: inspection)));
    Future<void> create() async {
      final created = await Navigator.of(context)
          .push<Inspection>(MaterialPageRoute(builder: (_) => InspectionFormScreen(orderId: orderId)));
      if (!context.mounted) return;
      ref.read(inspectionListControllerProvider(orderId).notifier).refresh();
      // Straight into the new inspection's defects — the next thing to log.
      if (created != null) openDefects(created);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inspections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create,
        icon: const Icon(Icons.add),
        label: const Text('Record inspection'),
      ),
      body: switch (state) {
        InspectionListLoading() => const LoadingView(),
        InspectionListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(inspectionListControllerProvider(orderId).notifier).refresh(),
          ),
        InspectionListLoaded(:final inspections) when inspections.isEmpty => EmptyStateView(
            title: 'No inspections yet',
            message: 'Record inline, midline and final inspections. A passed final inspection unlocks shipment.',
            icon: Icons.fact_check_outlined,
            color: AppModules.quality.color,
            actionLabel: 'Record inspection',
            onAction: create,
          ),
        InspectionListLoaded(:final inspections) => RefreshIndicator(
            onRefresh: () => ref.read(inspectionListControllerProvider(orderId).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab.copyWith(left: 0, right: 0, top: 0),
              children: [
                GradientHeader.module(
                  AppModules.quality,
                  eyebrow: 'Quality',
                  title: '${inspections.length} inspection${inspections.length == 1 ? '' : 's'}',
                  subtitle: inspections
                          .any((i) => i.inspectionType == InspectionType.final_ && i.result == InspectionResult.pass)
                      ? 'Final inspection passed — shipment unlocked'
                      : 'A passed final inspection unlocks shipment',
                  bottom: Row(
                    children: [
                      HeaderStat(
                          value: '${inspections.where((i) => i.result == InspectionResult.pass).length}',
                          label: 'Passed'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(
                          value: '${inspections.where((i) => i.result == InspectionResult.fail).length}',
                          label: 'Failed'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(
                          value: fmtQty(inspections.fold<int>(0, (s, i) => s + i.inspectedQty)), label: 'Pcs checked'),
                    ],
                  ),
                ),
                for (final inspection in inspections)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      accentColor: inspection.result == InspectionResult.reinspect
                          ? AppColors.warning
                          : AppStatus.color(inspection.result.apiValue),
                      onTap: () => openDefects(inspection),
                      child: RecordRow(
                        leading: IconBadge(icon: AppModules.quality.icon, color: AppModules.quality.color),
                        title: '${inspection.inspectionType.label} inspection',
                        subtitle: formatApiDate(inspection.inspectionDate),
                        meta: '${fmtQty(inspection.inspectedQty)} pcs inspected'
                            '${inspection.aqlLevel != null ? ' · AQL ${inspection.aqlLevel}' : ''}',
                        trailing: StatusChip(
                          inspection.result.apiValue,
                          label: inspection.result.label,
                          tone: inspection.result == InspectionResult.reinspect ? StatusTone.warning : null,
                          dense: true,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      },
    );
  }
}
