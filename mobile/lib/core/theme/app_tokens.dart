import 'package:flutter/material.dart';

/// Spacing scale (4pt grid). Use these instead of magic numbers.
class AppSpacing {
  AppSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard page padding for list/detail screens.
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 12, 16, 24);

  /// Padding at the bottom of a list so the FAB never covers the last item.
  static const EdgeInsets listWithFab = EdgeInsets.fromLTRB(16, 12, 16, 96);
}

/// Corner radii — hierarchy matters: bigger surfaces get bigger radii.
class AppRadius {
  AppRadius._();
  static const double sm = 8; // chips inside cards, small badges
  static const double md = 12; // inputs, tiles
  static const double lg = 16; // cards
  static const double xl = 24; // sheets, dialogs, hero headers
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Durations for the few motions we use.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration shimmer = Duration(milliseconds: 1300);
}
