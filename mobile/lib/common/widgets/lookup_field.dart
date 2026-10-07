import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../lookups/lookup_providers.dart';
import 'search_field.dart';
import 'status_chip.dart';

/// Searchable picker that replaces "type the numeric id" inputs. Looks like a
/// normal form field; tapping it opens a bottom sheet listing [options]
/// (a lookup FutureProvider from `common/lookups`) with a search box.
///
/// Integrates with [Form] validation: set [required] to get a
/// "Please select …" error when nothing is picked.
class LookupField extends ConsumerStatefulWidget {
  const LookupField({
    super.key,
    required this.label,
    required this.options,
    this.initialValue,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.icon,
    this.helperText,
    this.emptyMessage = 'Nothing to choose from yet.',
  });

  final String label;
  final ProviderBase<AsyncValue<List<LookupOption>>> options;
  final int? initialValue;
  final ValueChanged<int?>? onChanged;
  final bool required;
  final bool enabled;
  final IconData? icon;
  final String? helperText;
  final String emptyMessage;

  @override
  ConsumerState<LookupField> createState() => _LookupFieldState();
}

class _LookupFieldState extends ConsumerState<LookupField> {
  final _fieldKey = GlobalKey<FormFieldState<int>>();

  /// Lets a parent drive the value (auto-fill) by passing a new [initialValue].
  @override
  void didUpdateWidget(covariant LookupField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _fieldKey.currentState?.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fieldKey.currentState?.didChange(widget.initialValue));
    }
  }

  Future<void> _open(FormFieldState<int> field) async {
    final picked = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _LookupSheet(
        title: widget.label,
        options: widget.options,
        selectedId: field.value,
        allowClear: !widget.required && field.value != null,
        emptyMessage: widget.emptyMessage,
      ),
    );
    if (picked == null) return;
    field.didChange(picked.id);
    widget.onChanged?.call(picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.options);
    return FormField<int>(
      key: _fieldKey,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      validator: (v) => widget.required && v == null ? 'Please select ${widget.label.toLowerCase()}' : null,
      builder: (field) {
        final options = async.valueOrNull ?? const <LookupOption>[];
        LookupOption? selected;
        for (final o in options) {
          if (o.id == field.value) selected = o;
        }
        final theme = Theme.of(context);
        final text = field.value == null ? null : selected?.label ?? (async.isLoading ? 'Loading…' : '#${field.value}');
        return InkWell(
          borderRadius: AppRadius.input,
          onTap: widget.enabled ? () => _open(field) : null,
          child: InputDecorator(
            isEmpty: text == null,
            isFocused: false,
            decoration: InputDecoration(
              labelText: widget.required ? widget.label : '${widget.label} (optional)',
              prefixIcon: widget.icon == null ? null : Icon(widget.icon),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              helperText: selected?.subtitle ?? widget.helperText,
              helperMaxLines: 2,
              errorText: field.errorText,
              enabled: widget.enabled,
            ),
            child: text == null
                ? null
                : Text(text, style: theme.textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }
}

/// Opens the same searchable picker [LookupField] uses, without a form field
/// (e.g. "Reassign" from a quick-action menu). Returns null when dismissed;
/// otherwise a record whose `id` is the chosen id, or null when cleared.
Future<({int? id})?> showLookupPicker(
  BuildContext context, {
  required String title,
  required ProviderBase<AsyncValue<List<LookupOption>>> options,
  int? selectedId,
  bool allowClear = false,
  String emptyMessage = 'Nothing to choose from yet.',
}) async {
  final picked = await showModalBottomSheet<_Pick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LookupSheet(
      title: title,
      options: options,
      selectedId: selectedId,
      allowClear: allowClear,
      emptyMessage: emptyMessage,
    ),
  );
  return picked == null ? null : (id: picked.id);
}

class _Pick {
  const _Pick(this.id);
  final int? id;
}

class _LookupSheet extends ConsumerStatefulWidget {
  const _LookupSheet({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.allowClear,
    required this.emptyMessage,
  });

  final String title;
  final ProviderBase<AsyncValue<List<LookupOption>>> options;
  final int? selectedId;
  final bool allowClear;
  final String emptyMessage;

  @override
  ConsumerState<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends ConsumerState<_LookupSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.options);
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text('Select ${widget.title.toLowerCase()}', style: theme.textTheme.titleMedium)),
                  if (widget.allowClear)
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(const _Pick(null)), child: const Text('Clear')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SearchField(hintText: 'Search', onChanged: (v) => setState(() => _query = v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load the list.'),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(onPressed: () => ref.invalidate(widget.options), child: const Text('Retry')),
                    ],
                  ),
                ),
                data: (options) {
                  final filtered = options.where((o) => o.matches(_query)).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          options.isEmpty ? widget.emptyMessage : 'No match for "$_query".',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final o = filtered[index];
                      final isSelected = o.id == widget.selectedId;
                      return ListTile(
                        selected: isSelected,
                        title: Text(o.label),
                        subtitle:
                            o.subtitle == null ? null : Text(o.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded)
                            : (o.status == null ? null : StatusChip(o.status!, dense: true)),
                        onTap: () => Navigator.of(context).pop(_Pick(o.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves an id to its human label via a lookup provider, for detail and
/// list screens that only have the foreign key ("Style #12" → "ST-2026-001").
/// Falls back to [fallback] (default `#id`) while loading or if not found.
String lookupLabel(
  WidgetRef ref,
  ProviderBase<AsyncValue<List<LookupOption>>> provider,
  int? id, {
  String? fallback,
}) {
  if (id == null) return fallback ?? '—';
  final options = ref.watch(provider).valueOrNull;
  if (options != null) {
    for (final o in options) {
      if (o.id == id) return o.label;
    }
  }
  return fallback ?? '#$id';
}

/// "Order ORD-2026-001" instead of "Order #12" for generic entity links
/// (tasks, notifications, activities) — resolved through the matching lookup
/// when one exists, otherwise "Type #id".
String entityRefLabel(WidgetRef ref, String entityType, int id) {
  final type = entityType.toUpperCase();
  final ProviderBase<AsyncValue<List<LookupOption>>>? provider = switch (type) {
    'ORDER' => orderLookupProvider,
    'BUYER' => buyerLookupProvider,
    'FACTORY' => factoryLookupProvider,
    'STYLE' => styleLookupProvider(null),
    'INQUIRY' => inquiryLookupProvider,
    'COSTING' => costingLookupProvider(false),
    'QUOTATION' => quotationLookupProvider(null),
    _ => null,
  };
  final kind = type == 'TAMILESTONE' ? 'T&A milestone' : AppStatus.humanize(entityType);
  if (provider == null) return '$kind #$id';
  final label = lookupLabel(ref, provider, id, fallback: '#$id');
  // Costing labels already start with "Costing".
  return label.startsWith(kind) ? label : '$kind $label';
}
