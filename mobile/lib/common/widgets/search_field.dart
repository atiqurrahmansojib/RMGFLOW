import 'dart:async';

import 'package:flutter/material.dart';

/// Pill search input with leading search icon, a clear button that appears
/// once there's text, and optional debounce for server-side search.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.debounce,
    this.autofocus = false,
    this.trailing,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// When set, [onChanged] fires only after typing pauses for this long.
  final Duration? debounce;
  final bool autofocus;

  /// Extra trailing widget, e.g. a filter IconButton.
  final Widget? trailing;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  void _changed(String v) {
    final cb = widget.onChanged;
    if (cb == null) return;
    if (widget.debounce == null) {
      cb(v);
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.debounce!, () => cb(v));
  }

  void _clear() {
    _controller.clear();
    _timer?.cancel();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isDark = s.brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(999));
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _changed,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        filled: true,
        fillColor: isDark ? s.surfaceContainerHigh : s.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(Icons.search_rounded, color: s.onSurfaceVariant),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controller.text.isNotEmpty)
              IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded, size: 20), onPressed: _clear),
            if (widget.trailing != null) widget.trailing!,
            const SizedBox(width: 4),
          ],
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.primary, width: 1.6)),
      ),
    );
  }
}
