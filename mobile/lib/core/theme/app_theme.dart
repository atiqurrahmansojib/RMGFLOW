import 'package:flutter/material.dart';

/// Document 35: one design-system entry point — colors/typography defined
/// once here, not per screen. Deliberately minimal for Phase 1 (app shell);
/// expand with buyer/style/status-badge-specific tokens as those modules land.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF0B5D8F); // deep blue — industrial/operational, not generic Material purple

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}
