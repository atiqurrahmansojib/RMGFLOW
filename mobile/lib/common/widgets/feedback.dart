import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Shared confirmation / snackbar / validation helpers so every screen asks
/// and answers the same way (Doc 7 UX rules: confirm irreversible actions,
/// acknowledge every save).

/// Asks before an irreversible or high-impact action. Returns true only if
/// the user explicitly confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final s = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: s.error, foregroundColor: s.onError) : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a mandatory reason (reject, cancel, lost…). Returns the trimmed
/// text, or null if the user backed out.
Future<String?> promptForReason(
  BuildContext context, {
  required String title,
  String label = 'Reason',
  String confirmLabel = 'Submit',
  String? message,
  bool destructive = false,
  bool required = true,
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final s = Theme.of(context).colorScheme;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[Text(message), const SizedBox(height: 12)],
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(labelText: label),
              validator: (v) =>
                  required && (v == null || v.trim().isEmpty) ? 'Please enter a ${label.toLowerCase()}' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: s.error, foregroundColor: s.onError) : null,
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.of(ctx).pop(controller.text.trim());
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Input formatters for numeric fields — block letters at the keyboard so
/// validation errors are the exception, not the norm.
class NumberInput {
  NumberInput._();
  static final List<TextInputFormatter> integer = [FilteringTextInputFormatter.digitsOnly];
  static final List<TextInputFormatter> decimal = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
  ];
  static const TextInputType decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
}

/// Reusable validators with clear, human messages.
class Validators {
  Validators._();

  static String? Function(String?) required([String what = 'This field']) =>
      (v) => (v == null || v.trim().isEmpty) ? '$what is required' : null;

  /// Whole number > 0 (or ≥ 0 when [allowZero]). Empty passes if not [required].
  static String? Function(String?) positiveInt(
          {bool required = true, bool allowZero = false, String what = 'Quantity'}) =>
      (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return required ? '$what is required' : null;
        final n = int.tryParse(t);
        if (n == null) return 'Enter a whole number';
        if (allowZero ? n < 0 : n <= 0) return '$what must be ${allowZero ? '0 or more' : 'greater than 0'}';
        return null;
      };

  /// Decimal amount > 0 (or ≥ 0 when [allowZero]).
  static String? Function(String?) money({bool required = true, bool allowZero = false, String what = 'Amount'}) =>
      (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return required ? '$what is required' : null;
        final n = double.tryParse(t);
        if (n == null) return 'Enter a valid number, e.g. 12.50';
        if (allowZero ? n < 0 : n <= 0) return '$what must be ${allowZero ? '0 or more' : 'greater than 0'}';
        return null;
      };

  /// 0–100 percentage.
  static String? Function(String?) percent({bool required = true, String what = 'Percentage'}) => (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return required ? '$what is required' : null;
        final n = double.tryParse(t);
        if (n == null) return 'Enter a number between 0 and 100';
        if (n < 0 || n > 100) return '$what must be between 0 and 100';
        return null;
      };
}

/// Trimmed text or null when blank — keeps optional fields out of payloads.
String? blankToNull(String? v) {
  final t = v?.trim();
  return (t == null || t.isEmpty) ? null : t;
}
