import 'package:flutter/material.dart';

import '../../../../common/widgets/widgets.dart';

/// Maps a free-text report category from the server ("Orders", "T&A Delay",
/// "Quality") to the matching module's icon and accent colour, falling back
/// to the Reports module.
AppModule reportCategoryModule(String category) {
  final c = category.toLowerCase();
  if (c.contains('buyer')) return AppModules.buyers;
  if (c.contains('factor') || c.contains('vendor')) return AppModules.factories;
  if (c.contains('inquir') || c.contains('sales')) return AppModules.inquiries;
  if (c.contains('style')) return AppModules.styles;
  if (c.contains('quot')) return AppModules.quotation;
  if (c.contains('cost') || c.contains('margin')) return AppModules.costing;
  if (c.contains('approv')) return AppModules.approvals;
  if (c.contains('t&a') || c.contains('delay') || c.contains('milestone')) return AppModules.ta;
  if (c.contains('production')) return AppModules.production;
  if (c.contains('quality') || c.contains('inspection')) return AppModules.quality;
  if (c.contains('sample')) return AppModules.sampling;
  if (c.contains('ship') || c.contains('logistic')) return AppModules.shipment;
  if (c.contains('document') || c.contains('commercial')) return AppModules.documents;
  if (c.contains('financ') || c.contains('account')) return AppModules.financial;
  if (c.contains('claim')) return AppModules.claims;
  if (c.contains('order')) return AppModules.orders;
  if (c.contains('task')) return AppModules.tasks;
  return AppModules.reports;
}

/// Rotating accent palette for report summary cards.
const List<Color> reportSummaryPalette = [
  AppColors.indigo,
  AppColors.teal,
  AppColors.marigold,
  AppColors.coral,
  AppColors.info,
  AppColors.success,
];

/// Icons for summary cards, picked from the label wording.
IconData reportSummaryIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('value') || l.contains('amount') || l.contains('revenue') || l.contains('cost')) {
    return Icons.payments_rounded;
  }
  if (l.contains('margin') || l.contains('%') || l.contains('rate') || l.contains('percent')) {
    return Icons.percent_rounded;
  }
  if (l.contains('qty') || l.contains('quantity') || l.contains('pcs') || l.contains('pieces')) {
    return Icons.inventory_2_rounded;
  }
  if (l.contains('delay') || l.contains('overdue') || l.contains('late')) return Icons.schedule_rounded;
  if (l.contains('order')) return Icons.receipt_long_rounded;
  return Icons.insights_rounded;
}

/// Whether a column holds workflow statuses (rendered as [StatusChip]).
bool isStatusColumn(String key, String label) =>
    key.toLowerCase().contains('status') || label.toLowerCase().contains('status');
