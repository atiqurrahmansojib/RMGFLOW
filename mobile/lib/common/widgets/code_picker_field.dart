import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dropdown for reference codes the API keys by string (currency "USD",
/// incoterm "FOB"), fed by a `common/lookups` provider. Writes the picked
/// code into [controller] so existing form code keeps reading `.text`.
///
/// While the list loads, or if it fails, it degrades to a plain 3-letter
/// text field so the form is never blocked by reference data.
class CodePickerField extends ConsumerWidget {
  const CodePickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.codes,
    this.required = true,
    this.enabled = true,
    this.onChanged,
    this.codeLength = 3,
    this.names,
  });

  final TextEditingController controller;
  final String label;
  final ProviderBase<AsyncValue<List<String>>> codes;
  final bool required;
  final bool enabled;
  final ValueChanged<String?>? onChanged;

  /// Expected code length for the text fallback (3 for currency/incoterm, 2 for ISO country).
  final int codeLength;

  /// Optional code → name map shown next to the code, e.g. "BD · Bangladesh".
  final ProviderBase<AsyncValue<Map<String, String>>>? names;

  String? _validate(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return required ? 'Select a ${label.toLowerCase()}' : null;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(codes).valueOrNull;
    if (list == null || list.isEmpty) {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        maxLength: codeLength,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: required ? label : '$label (optional)', counterText: ''),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return required ? '$label is required' : null;
          return t.length != codeLength ? 'Use the $codeLength-letter code' : null;
        },
        onChanged: onChanged,
      );
    }
    final nameOf = names == null ? const <String, String>{} : (ref.watch(names!).valueOrNull ?? const {});
    final current = controller.text.trim().toUpperCase();
    // Keep a legacy/unknown saved value selectable rather than silently dropping it.
    final options = [...list, if (current.isNotEmpty && !list.contains(current)) current];
    return DropdownButtonFormField<String>(
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      decoration: InputDecoration(labelText: required ? label : '$label (optional)'),
      items: [
        if (!required) const DropdownMenuItem<String>(value: null, child: Text('—')),
        for (final c in options)
          DropdownMenuItem(
            value: c,
            child: Text(nameOf[c] == null ? c : '$c · ${nameOf[c]}', overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: _validate,
      onChanged: enabled
          ? (v) {
              controller.text = v ?? '';
              onChanged?.call(v);
            }
          : null,
    );
  }
}
