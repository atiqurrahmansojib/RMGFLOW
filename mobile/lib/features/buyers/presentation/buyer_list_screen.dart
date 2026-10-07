import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/buyer_list_controller.dart';
import '../domain/buyer.dart';
import 'buyer_contacts_screen.dart';
import 'buyer_form_screen.dart';

/// Document 7 (#16): Buyer List — search box + FAB to create, per Doc 35
/// ("minimal-click", "search-driven"). A just-created buyer is highlighted.
class BuyerListScreen extends ConsumerStatefulWidget {
  const BuyerListScreen({super.key});

  @override
  ConsumerState<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends ConsumerState<BuyerListScreen> {
  static const _module = AppModules.buyers;
  final _searchController = TextEditingController();
  int? _highlightId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([Buyer? existing]) async {
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => BuyerFormScreen(existingBuyer: existing)));
    if (!mounted) return;
    if (result is Buyer && existing == null) setState(() => _highlightId = result.id);
    ref.read(buyerListControllerProvider.notifier).refresh();
  }

  void _openContacts(Buyer buyer) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BuyerContactsScreen(buyer: buyer)));

  void _quickActions(Buyer buyer) => showQuickActions(
        context,
        title: buyer.name,
        subtitle: buyer.code,
        actions: [
          QuickAction(
              label: 'Edit buyer', icon: Icons.edit_outlined, color: _module.color, onSelected: () => _openForm(buyer)),
          QuickAction(
              label: 'Contacts',
              icon: Icons.contacts_outlined,
              color: AppColors.teal,
              onSelected: () => _openContacts(buyer)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buyers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add buyer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search buyers by name or code',
              debounce: const Duration(milliseconds: 400),
              onChanged: (value) => ref.read(buyerListControllerProvider.notifier).load(search: value),
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
              BuyerListLoaded(:final buyers) when buyers.isEmpty => _searchController.text.isNotEmpty
                  ? EmptyStateView(
                      message: 'No buyers match your search.', icon: Icons.search_off_rounded, color: _module.color)
                  : EmptyStateView(
                      title: 'No buyers yet',
                      message: 'Buyers are the brands you source for. Add your first one to start taking inquiries.',
                      icon: _module.icon,
                      color: _module.color,
                      actionLabel: 'Add buyer',
                      onAction: _openForm,
                    ),
              BuyerListLoaded(:final buyers) => RefreshIndicator(
                  onRefresh: () => ref.read(buyerListControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.listWithFab,
                    itemCount: buyers.length,
                    itemBuilder: (context, index) {
                      final buyer = buyers[index];
                      return RecordTile(
                        accentColor: buyer.active ? _module.color : AppColors.neutral,
                        leading: RecordAvatar(color: _module.color, text: recordInitials(buyer.name)),
                        title: buyer.name,
                        subtitle: [
                          buyer.code,
                          if (buyer.country != null) buyer.country!,
                          if (buyer.defaultCurrency != null) buyer.defaultCurrency!,
                        ].join(' · '),
                        trailing: buyer.active
                            ? const StatusChip('ACTIVE', dense: true)
                            : const StatusChip('INACTIVE', dense: true),
                        highlighted: buyer.id == _highlightId,
                        onTap: () => _openForm(buyer),
                        onLongPress: () => _quickActions(buyer),
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
