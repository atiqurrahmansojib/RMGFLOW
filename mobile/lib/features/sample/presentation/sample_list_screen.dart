import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/sample_list_controller.dart';
import 'sample_detail_screen.dart';
import 'sample_form_screen.dart';

/// Document 7 (#32): Sample list — status is a DERIVED rollup (Doc 8.4), shown
/// as-is from the server, never computed here.
class SampleListScreen extends ConsumerWidget {
  const SampleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sampleListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Samples')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SampleFormScreen()),
        ).then((_) => ref.read(sampleListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        SampleListLoading() => const LoadingView(),
        SampleListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(sampleListControllerProvider.notifier).refresh(),
          ),
        SampleListLoaded(:final samples) when samples.isEmpty =>
          const EmptyStateView(message: 'No samples yet. Tap + to request one.', icon: Icons.science_outlined),
        SampleListLoaded(:final samples) => RefreshIndicator(
            onRefresh: () => ref.read(sampleListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: samples.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sample = samples[index];
                return ListTile(
                  title: Text(sample.sampleNo),
                  subtitle: Text('Style #${sample.styleId} · Buyer #${sample.buyerId} · requested ${sample.requestDate}'),
                  trailing: Chip(label: Text(sample.currentStatus.label)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SampleDetailScreen(sample: sample)),
                  ).then((_) => ref.read(sampleListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
