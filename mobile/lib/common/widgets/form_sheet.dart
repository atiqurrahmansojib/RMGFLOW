import 'package:flutter/material.dart';

import 'primary_button.dart';

/// Opens a modal bottom sheet sized for a short form (keyboard-aware, drag
/// handle, safe area). Returns whatever the sheet pops with.
Future<T?> showFormSheet<T>(BuildContext context, Widget sheet) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );

/// Standard body for a form bottom sheet: title, spaced fields and one
/// primary action. Wraps [children] in the given [formKey]'s Form.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.formKey,
    required this.title,
    required this.children,
    required this.actionLabel,
    required this.onSave,
    this.subtitle,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
              const SizedBox(height: 8),
              PrimaryButton(label: actionLabel, icon: Icons.check_rounded, onPressed: onSave),
            ],
          ),
        ),
      ),
    );
  }
}
