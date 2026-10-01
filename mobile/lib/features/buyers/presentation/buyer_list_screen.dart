import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/buyer_list_controller.dart';
import 'buyer_form_screen.dart';

/// Document 7 (#16): Buyer List — search box + FAB to create, per Doc 35
/// ("minimal-click", "search-driven").
class BuyerListScreen extends ConsumerStatefulWidget {
  const BuyerListScreen({super.key});

  @override
  ConsumerState<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends ConsumerState<BuyerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buyers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BuyerFormScreen()),
        ).then((_) => ref.read(buyerListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search buyers',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (value) => ref.read(buyerListControllerProvider.notifier).load(search: value),
            ),
          ),
          Expanded(
            child: switch (state) {
              BuyerListLoading() => const LoadingView(),
              BuyerListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(buyerListControllerProvider.notifier).refresh(),
                ),
              BuyerListLoaded(:final buyers) when buyers.isEmpty =>
                const EmptyStateView(message: 'No buyers yet. Tap + to add one.', icon: Icons.business_outlined),
              BuyerListLoaded(:final buyers) => RefreshIndicator(
                  onRefresh: () => ref.read(buyerListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    itemCount: buyers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final buyer = buyers[index];
                      return ListTile(
                        title: Text(buyer.name),
                        subtitle: Text('${buyer.code}${buyer.country != null ? ' · ${buyer.country}' : ''}'),
                        trailing: buyer.active ? null : const Chip(label: Text('Inactive')),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BuyerFormScreen(existingBuyer: buyer)),
                        ).then((_) => ref.read(buyerListControllerProvider.notifier).refresh()),
                      );
                    },
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
