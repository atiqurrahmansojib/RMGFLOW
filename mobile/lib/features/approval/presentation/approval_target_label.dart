import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../domain/approval.dart';

/// Human name for an approval's target — "QT-2026-014" instead of
/// "Quotation #14" — where a lookup exists; otherwise "Type #id".
String approvalTargetLabel(WidgetRef ref, ApprovalTargetType type, int id) {
  final fallback = '${type.label} #$id';
  return switch (type) {
    ApprovalTargetType.costing => lookupLabel(ref, costingLookupProvider(false), id, fallback: fallback),
    ApprovalTargetType.quotation =>
      '${type.label} ${lookupLabel(ref, quotationLookupProvider(null), id, fallback: '#$id')}',
    _ => fallback,
  };
}
