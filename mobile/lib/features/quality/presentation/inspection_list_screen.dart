import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Inspections')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InspectionFormScreen(orderId: orderId)),
        ).then((_) => ref.read(inspectionListControllerProvider(orderId).notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        InspectionListLoading() => const LoadingView(),
        InspectionListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(inspectionListControllerProvider(orderId).notifier).refresh(),
          ),
        InspectionListLoaded(:final inspections) when inspections.isEmpty =>
          const EmptyStateView(message: 'No inspections recorded yet.', icon: Icons.fact_check_outlined),
        InspectionListLoaded(:final inspections) => RefreshIndicator(
            onRefresh: () => ref.read(inspectionListControllerProvider(orderId).notifier).refresh(),
            child: ListView.separated(
              itemCount: inspections.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return ListTile(
                  title: Text('${inspection.inspectionType.label} — ${inspection.inspectionDate}'),
                  subtitle: Text('Inspected qty: ${inspection.inspectedQty}${inspection.aqlLevel != null ? ' · AQL ${inspection.aqlLevel}' : ''}'),
                  trailing: Chip(
                    label: Text(inspection.result.label),
                    backgroundColor: inspection.result == InspectionResult.pass
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DefectListScreen(inspection: inspection)),
                  ),
                );
              },
            ),
          ),
      },
    );
  }
}
