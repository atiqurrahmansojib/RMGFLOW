import 'package:flutter/material.dart';

/// Visual weight of a [PrimaryButton].
enum ButtonVariant { filled, tonal, outlined, danger }

/// Pill action button with a built-in loading state: while [loading] it
/// shows a spinner, keeps its width and ignores taps (prevents double submit).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.variant = ButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  /// Full width (default) — set false for inline buttons.
  final bool expand;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final onTap = loading ? null : onPressed;
    final spinnerColor = switch (variant) {
      ButtonVariant.filled => s.onPrimary,
      ButtonVariant.danger => s.onError,
      ButtonVariant.tonal => s.onSecondaryContainer,
      ButtonVariant.outlined => s.primary,
    };

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    // Keep the spinner legible when the button is disabled for loading.
    ButtonStyle? loadingStyle(Color bg) => loading ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(bg)) : null;

    final Widget button = switch (variant) {
      ButtonVariant.filled => FilledButton(onPressed: onTap, style: loadingStyle(s.primary), child: child),
      ButtonVariant.tonal =>
        FilledButton.tonal(onPressed: onTap, style: loadingStyle(s.secondaryContainer), child: child),
      ButtonVariant.outlined => OutlinedButton(onPressed: onTap, child: child),
      ButtonVariant.danger => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
              backgroundColor: s.error, foregroundColor: s.onError, disabledBackgroundColor: loading ? s.error : null),
          child: child,
        ),
    };

    return Semantics(
      button: true,
      label: loading ? '$label, in progress' : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
