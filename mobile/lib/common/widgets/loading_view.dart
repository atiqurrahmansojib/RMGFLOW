import 'package:flutter/material.dart';

/// Document 7 (#97-99) / 12.7: one loading widget reused by every list/detail
/// screen — do not reimplement a spinner per feature.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
