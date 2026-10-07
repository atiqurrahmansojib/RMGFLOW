import 'package:flutter/material.dart';

/// Horizontal, scrollable row of single-select chips for list filters
/// (status, type…). The first chip is always "All" (value null).
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.allLabel = 'All',
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(allLabel), selected: selected == null, onSelected: (_) => onSelected(null)),
          ),
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(labelOf(v)), selected: selected == v, onSelected: (_) => onSelected(v)),
            ),
        ],
      ),
    );
  }
}

/// Scrollable wrapper so an empty/"no match" state still supports
/// pull-to-refresh inside a [RefreshIndicator].
class RefreshableEmpty extends StatelessWidget {
  const RefreshableEmpty({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }
}
