import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/style_list_controller.dart';
import '../domain/style.dart';
import 'style_detail_screen.dart';
import 'style_form_screen.dart';

/// Document 7 (#28): Style List — search by style no./description (Doc 31).
class StyleListScreen extends ConsumerStatefulWidget {
  const StyleListScreen({super.key});

  @override
  ConsumerState<StyleListScreen> createState() => _StyleListScreenState();
}

class _StyleListScreenState extends ConsumerState<StyleListScreen> {
  static const _module = AppModules.styles;
  final _searchController = TextEditingController();
  int? _highlightId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => ref.read(styleListControllerProvider.notifier).refresh();

  /// Create → straight into the new style so the first spec can be added.
  Future<void> _openForm() async {
    final result =
        await Navigator.of(context).push<Object?>(MaterialPageRoute(builder: (_) => const StyleFormScreen()));
    if (!mounted) return;
    _refresh();
    if (result is Style) {
      setState(() => _highlightId = result.id);
      _openDetail(result);
    }
  }

  void _openDetail(Style style) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => StyleDetailScreen(style: style)))
      .then((_) => mounted ? _refresh() : null);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(styleListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Styles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add style'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search style number or description',
              debounce: const Duration(milliseconds: 400),
              onChanged: (value) => ref.read(styleListControllerProvider.notifier).load(search: value),
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
              StyleListLoaded(:final styles) when styles.isEmpty => _searchController.text.isNotEmpty
                  ? EmptyStateView(
                      message: 'No styles match your search.', icon: Icons.search_off_rounded, color: _module.color)
                  : EmptyStateView(
                      title: 'No styles yet',
                      message: 'A style is a garment design for a buyer. Add one to start costing it.',
                      icon: _module.icon,
                      color: _module.color,
                      actionLabel: 'Add style',
                      onAction: _openForm,
                    ),
              StyleListLoaded(:final styles) => RefreshIndicator(
                  onRefresh: () => ref.read(styleListControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.listWithFab,
                    itemCount: styles.length,
                    itemBuilder: (context, index) {
                      final style = styles[index];
                      final hasSpec = style.currentRevisionId != null;
                      return RecordTile(
                        accentColor: hasSpec ? _module.color : AppColors.warning,
                        leading: RecordAvatar(color: _module.color, icon: _module.icon),
                        title: style.styleNo,
                        subtitle: [
                          lookupLabel(ref, buyerLookupProvider, style.buyerId, fallback: ''),
                          if (style.buyerStyleNo != null) "Buyer's no. ${style.buyerStyleNo}",
                        ].where((p) => p.isNotEmpty).join(' · '),
                        meta: [
                          if (style.gender != null) style.gender!,
                          if (style.productCategory != null) style.productCategory!,
                        ].join(' · '),
                        trailing: hasSpec
                            ? StatusChip(style.active ? 'ACTIVE' : 'INACTIVE', dense: true)
                            : const StatusChip('PENDING', label: 'No spec yet', dense: true),
                        highlighted: style.id == _highlightId,
                        onTap: () => _openDetail(style),
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
