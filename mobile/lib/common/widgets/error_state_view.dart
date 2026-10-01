import 'package:flutter/material.dart';

import '../../core/network/failure.dart';

/// Document 7 (#99) / 12.7: shared error-state widget driven by the Failure
/// type (core/network/failure.dart) — never a raw exception message shown
/// to the user.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(failure.message, textAlign: TextAlign.center),
            if (failure is ValidationFailure)
              ...(failure as ValidationFailure).fieldErrors.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
