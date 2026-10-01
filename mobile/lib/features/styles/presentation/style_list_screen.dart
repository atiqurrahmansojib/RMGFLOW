import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/style_list_controller.dart';
import 'style_form_screen.dart';

/// Document 7 (#28): Style List — search by style no./description (Doc 31).
class StyleListScreen extends ConsumerStatefulWidget {
  const StyleListScreen({super.key});

  @override
  ConsumerState<StyleListScreen> createState() => _StyleListScreenState();
}

class _StyleListScreenState extends ConsumerState<StyleListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(styleListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Styles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StyleFormScreen()),
        ).then((_) => ref.read(styleListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search style number', prefixIcon: Icon(Icons.search), isDense: true),
              onSubmitted: (value) => ref.read(styleListControllerProvider.notifier).load(search: value),
            ),
          ),
          Expanded(
            child: switch (state) {
              StyleListLoading() => const LoadingView(),
              StyleListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(styleListControllerProvider.notifier).refresh(),
                ),
              StyleListLoaded(:final styles) when styles.isEmpty =>
                const EmptyStateView(message: 'No styles yet. Tap + to add one.', icon: Icons.checkroom_outlined),
              StyleListLoaded(:final styles) => RefreshIndicator(
                  onRefresh: () => ref.read(styleListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    itemCount: styles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final style = styles[index];
                      return ListTile(
                        title: Text(style.styleNo),
                        subtitle: Text([
                          if (style.buyerStyleNo != null) 'Buyer#: ${style.buyerStyleNo}',
                          if (style.productCategory != null) style.productCategory!,
                        ].join(' · ')),
                        trailing: style.currentRevisionId == null
                            ? const Chip(label: Text('No spec yet'))
                            : null,
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
