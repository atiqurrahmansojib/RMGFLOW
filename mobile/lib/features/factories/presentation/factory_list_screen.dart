import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../application/factory_list_controller.dart';
import '../domain/factory.dart';
import 'factory_form_screen.dart';
import 'factory_profile_screen.dart';

/// Document 7 (#20): Factory/Vendor List — filterable by partner type (Doc 6:
/// factory types "do not behave identically", so filtering by type matters).
/// Name/code search is client-side: the API has no search param for factories.
class FactoryListScreen extends ConsumerStatefulWidget {
  const FactoryListScreen({super.key});

  @override
  ConsumerState<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends ConsumerState<FactoryListScreen> {
  static const _module = AppModules.factories;
  PartnerType? _type;
  String _query = '';
  int? _highlightId;

  /// Create → the new factory's profile opens straight away so contacts,
  /// capabilities and buyer approvals can be added without hunting for it.
  Future<void> _openForm([Factory? existing]) async {
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute(builder: (_) => FactoryFormScreen(existingFactory: existing)));
    if (!mounted) return;
    ref.read(factoryListControllerProvider.notifier).refresh();
    if (result is Factory && existing == null) {
      setState(() => _highlightId = result.id);
      _openProfile(result);
    }
  }

  void _openProfile(Factory f, [int tab = 0]) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FactoryProfileScreen(factory: f, initialTab: tab)));

  void _quickActions(Factory f) => showQuickActions(
        context,
        title: f.name,
        subtitle: '${f.code} · ${f.partnerType.label}',
        actions: [
          QuickAction(
              label: 'Edit factory', icon: Icons.edit_outlined, color: _module.color, onSelected: () => _openForm(f)),
          QuickAction(
              label: 'Contacts',
              icon: Icons.contacts_outlined,
              color: AppColors.teal,
              onSelected: () => _openProfile(f)),
          QuickAction(
              label: 'Capabilities',
              icon: Icons.precision_manufacturing_outlined,
              color: AppColors.info,
              onSelected: () => _openProfile(f, 1)),
          QuickAction(
              label: 'Certifications',
              icon: Icons.workspace_premium_outlined,
              color: AppColors.success,
              onSelected: () => _openProfile(f, 2)),
          QuickAction(
              label: 'Buyer approvals',
              icon: Icons.handshake_outlined,
              color: AppColors.marigold,
              onSelected: () => _openProfile(f, 3)),
        ],
      );

  void _setType(PartnerType? type) {
    setState(() => _type = type);
    ref.read(factoryListControllerProvider.notifier).load(partnerType: type);
  }

  bool _matches(Factory f) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return f.name.toLowerCase().contains(q) ||
        f.code.toLowerCase().contains(q) ||
        (f.country?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(factoryListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Factories & Vendors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add factory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SearchField(hintText: 'Search name, code or country', onChanged: (v) => setState(() => _query = v)),
          ),
          FilterChipBar<PartnerType>(
            values: PartnerType.values,
            selected: _type,
            labelOf: (t) => t.label,
            allLabel: 'All types',
            onSelected: _setType,
          ),
          Expanded(
            child: switch (state) {
              FactoryListLoading() => const LoadingView(),
              FactoryListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(factoryListControllerProvider.notifier).refresh(),
                ),
              FactoryListLoaded(:final factories) when factories.isEmpty && _type == null => EmptyStateView(
                  title: 'No factories yet',
                  message: 'Add the factories, subcontractors and vendors you place orders with.',
                  icon: _module.icon,
                  color: _module.color,
                  actionLabel: 'Add factory',
                  onAction: _openForm,
                ),
              FactoryListLoaded(:final factories) => Builder(builder: (context) {
                  final visible = factories.where(_matches).toList();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(factoryListControllerProvider.notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              message: 'No factories match this search or filter.',
                              icon: Icons.search_off_rounded,
                              color: _module.color,
                              actionLabel: 'Add factory',
                              onAction: _openForm,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final factory = visible[index];
                              return RecordTile(
                                accentColor: factory.active ? _module.color : AppColors.neutral,
                                leading: RecordAvatar(color: _module.color, icon: _module.icon),
                                title: factory.name,
                                subtitle: [
                                  factory.code,
                                  factory.partnerType.label,
                                  if (factory.country != null) factory.country!,
                                ].join(' · '),
                                meta: factory.capacityPerMonth == null
                                    ? null
                                    : 'Capacity ${factory.capacityPerMonth} pcs/month',
                                trailing: StatusChip(factory.active ? 'ACTIVE' : 'INACTIVE', dense: true),
                                highlighted: factory.id == _highlightId,
                                onTap: () => _openForm(factory),
                                onLongPress: () => _quickActions(factory),
                              );
                            },
                          ),
                  );
                }),
            },
          ),
        ],
      ),
    );
  }
}
