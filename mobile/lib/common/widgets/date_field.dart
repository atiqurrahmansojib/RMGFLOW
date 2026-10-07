import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';

/// API date format (Doc 12: ISO local date).
final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');

/// Display format, e.g. "07 Oct 2026".
final DateFormat displayDateFormat = DateFormat('dd MMM yyyy');

String? toApiDate(DateTime? d) => d == null ? null : apiDateFormat.format(d);

/// Parses an API `yyyy-MM-dd` (or full ISO) string; null-safe.
DateTime? parseApiDate(String? s) => (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

/// Formats an API date string for display, falling back to the raw value.
String formatApiDate(String? s) {
  final d = parseApiDate(s);
  if (d == null) return s ?? '—';
  return displayDateFormat.format(d);
}

/// Read-only form field that opens a Material date picker — no more typing
/// "yyyy-MM-dd". Participates in [Form] validation via [required] and
/// [validator]; shows a clear button for optional dates.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.helperText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Extra rule on top of [required], e.g. "must be after order date".
  final String? Function(DateTime?)? validator;
  final String? helperText;

  Future<void> _pick(BuildContext context, FormFieldState<DateTime> field) async {
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);
    var initial = value ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
    );
    if (picked == null) return;
    field.didChange(picked);
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      // Keyed on value so external changes (e.g. reset) re-seed the field.
      key: ValueKey('$label-${value?.toIso8601String()}'),
      initialValue: value,
      enabled: enabled,
      validator: (v) {
        if (required && v == null) return 'Please pick ${label.toLowerCase()}';
        return validator?.call(v);
      },
      builder: (field) {
        final current = field.value;
        return InkWell(
          borderRadius: AppRadius.input,
          onTap: enabled ? () => _pick(context, field) : null,
          child: InputDecorator(
            isEmpty: current == null,
            decoration: InputDecoration(
              labelText: required ? label : '$label (optional)',
              prefixIcon: const Icon(Icons.event_rounded),
              helperText: helperText,
              errorText: field.errorText,
              enabled: enabled,
              suffixIcon: (!required && current != null && enabled)
                  ? IconButton(
                      tooltip: 'Clear date',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        field.didChange(null);
                        onChanged(null);
                      },
                    )
                  : null,
            ),
            child: current == null ? null : Text(displayDateFormat.format(current)),
          ),
        );
      },
    );
  }
}
