import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/application/auth_controller.dart';

/// One selectable record for a [LookupField] — the id the API wants plus a
/// human label, so users pick "H&M (HM01)" instead of typing "3".
@immutable
class LookupOption {
  const LookupOption({required this.id, required this.label, this.subtitle, this.status, this.parentId});

  final int id;
  final String label;
  final String? subtitle;

  /// Owning record where useful for auto-fill, e.g. a style's buyer id.
  final int? parentId;

  /// Optional raw status, rendered as a chip in the picker (e.g. costing APPROVED).
  final String? status;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) || (subtitle?.toLowerCase().contains(q) ?? false) || id.toString() == q;
  }
}

/// Upper bound for picker lists. Lookups are org-scoped server-side and a
/// buying house rarely has more active buyers/factories/styles than this;
/// the picker's own search filters within the loaded set.
const _lookupPageSize = 200;

Future<List<Map<String, dynamic>>> _fetch(Ref ref, String path, {Map<String, dynamic>? query}) {
  return ref.read(authControllerProvider.notifier).callAuthorized(() async {
    final response = await ref.read(apiDioProvider).get(path, queryParameters: query);
    final data = response.data;
    // Paged endpoints wrap rows in `content`; reference-data endpoints return a bare list.
    final list = data is Map<String, dynamic> ? data['content'] as List : data as List;
    return list.cast<Map<String, dynamic>>();
  });
}

Future<List<Map<String, dynamic>>> _paged(Ref ref, String path, [Map<String, dynamic>? extra]) =>
    _fetch(ref, path, query: {'page': 0, 'size': _lookupPageSize, ...?extra});

String? _join(List<String?> parts) {
  final kept = parts.where((p) => p != null && p.trim().isNotEmpty).toList();
  return kept.isEmpty ? null : kept.join(' · ');
}

final buyerLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _paged(ref, '/buyers');
  return rows
      .where((b) => b['active'] != false)
      .map((b) => LookupOption(
            id: b['id'] as int,
            label: b['name'] as String,
            subtitle: _join([b['code'] as String?, b['country'] as String?]),
          ))
      .toList();
});

final factoryLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _paged(ref, '/factories');
  return rows
      .where((f) => f['active'] != false)
      .map((f) => LookupOption(
            id: f['id'] as int,
            label: f['name'] as String,
            subtitle: _join([f['code'] as String?, f['country'] as String?]),
          ))
      .toList();
});

/// Styles, optionally narrowed to one buyer (orders/samples pick the buyer first).
final styleLookupProvider = FutureProvider.autoDispose.family<List<LookupOption>, int?>((ref, buyerId) async {
  final rows = await _paged(ref, '/styles');
  return rows
      .where((s) => s['active'] != false && (buyerId == null || s['buyerId'] == buyerId))
      .map((s) => LookupOption(
            id: s['id'] as int,
            label: s['styleNo'] as String,
            parentId: s['buyerId'] as int?,
            subtitle:
                _join([s['buyerStyleNo'] as String?, s['productCategory'] as String?, s['description'] as String?]),
          ))
      .toList();
});

final inquiryLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _paged(ref, '/inquiries');
  return rows
      .map((i) => LookupOption(
            id: i['id'] as int,
            label: i['inquiryNo'] as String,
            subtitle: i['buyerName'] as String?,
            status: i['status'] as String?,
          ))
      .toList();
});

/// Costings; pass `approvedOnly: true` for quotation creation (Doc 9: a
/// quotation must be built on an approved costing).
final costingLookupProvider = FutureProvider.autoDispose.family<List<LookupOption>, bool>((ref, approvedOnly) async {
  final rows = await _paged(ref, '/costings');
  return rows
      .where((c) => !approvedOnly || c['status'] == 'APPROVED')
      .map((c) => LookupOption(
            id: c['id'] as int,
            label: 'Costing #${c['id']} · v${c['versionNo']}',
            subtitle: _join([
              'Style #${c['styleId']}',
              'Qty ${c['quantity']}',
              if (c['totalCost'] != null) '${c['currency']} ${(c['totalCost'] as num).toStringAsFixed(2)}',
            ]),
            status: c['status'] as String?,
          ))
      .toList();
});

/// Quotations, optionally narrowed to one buyer.
final quotationLookupProvider = FutureProvider.autoDispose.family<List<LookupOption>, int?>((ref, buyerId) async {
  final rows = await _paged(ref, '/quotations', {if (buyerId != null) 'buyerId': buyerId});
  return rows
      .map((q) => LookupOption(
            id: q['id'] as int,
            label: (q['quotationNo'] as String?) ?? 'Quotation #${q['id']}',
            subtitle: _join([
              'v${q['versionNo']}',
              '${q['currency']} ${(q['unitPrice'] as num).toStringAsFixed(2)} × ${q['quantity']}',
            ]),
            status: q['status'] as String?,
          ))
      .toList();
});

final orderLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _paged(ref, '/orders');
  return rows
      .map((o) => LookupOption(
            id: o['id'] as int,
            label: o['orderNo'] as String,
            subtitle: _join(['PO ${o['buyerPoNo']}', o['deliveryDate'] as String?]),
            status: o['status'] as String?,
          ))
      .toList();
});

/// Shipments of one order (claims are optionally linked to a shipment).
final shipmentLookupProvider = FutureProvider.autoDispose.family<List<LookupOption>, int>((ref, orderId) async {
  final rows = await _fetch(ref, '/orders/$orderId/shipments');
  return rows
      .map((s) => LookupOption(
            id: s['id'] as int,
            label: s['shipmentNo'] as String,
            subtitle: _join(['Qty ${s['quantityShipped']}', s['etd'] == null ? null : 'ETD ${s['etd']}']),
            status: s['status'] as String?,
          ))
      .toList();
});

final sampleTypeLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _fetch(ref, '/sample-types');
  return rows.map((t) => LookupOption(id: t['id'] as int, label: t['name'] as String)).toList();
});

final defectTypeLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _fetch(ref, '/defect-types');
  return rows
      .map((t) => LookupOption(
            id: t['id'] as int,
            label: t['name'] as String,
            subtitle: _join([t['category'] as String?, t['severity'] as String?]),
          ))
      .toList();
});

final documentTypeLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _fetch(ref, '/document-types');
  return rows
      .map((t) => LookupOption(
            id: t['id'] as int,
            label: t['name'] as String,
            subtitle: t['category'] as String?,
          ))
      .toList();
});

/// Simple string lookups for reference data that the API keys by code
/// (currency "USD", incoterm "FOB", country "BD").
final currencyCodesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final rows = await _fetch(ref, '/currencies');
  return rows.map((c) => (c['code'] ?? c['id']).toString()).toList();
});

final incotermCodesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final rows = await _fetch(ref, '/incoterms');
  return rows.map((c) => (c['code'] ?? c['id']).toString()).toList();
});

final countryCodesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final rows = await _fetch(ref, '/countries');
  return rows.map((c) => (c['code'] ?? c['id']).toString()).toList();
});

/// Code → display name for reference data keyed by code (`/countries`, `/currencies`, `/incoterms`).
final referenceNamesProvider = FutureProvider.autoDispose.family<Map<String, String>, String>((ref, path) async {
  final rows = await _fetch(ref, path);
  return {
    for (final r in rows)
      if (r['code'] != null) r['code'].toString(): (r['name'] ?? r['code']).toString(),
  };
});

/// Files already attached to a record (Doc 8.9 generic Attachment module), so a
/// commercial document can reference one by name instead of a raw id.
final attachmentLookupProvider =
    FutureProvider.autoDispose.family<List<LookupOption>, ({String entityType, int entityId})>((ref, target) async {
  final rows = await _fetch(ref, '/attachments', query: {'entityType': target.entityType, 'entityId': target.entityId});
  return rows.map((a) {
    final kb = ((a['sizeBytes'] as num?) ?? 0) / 1024;
    return LookupOption(
      id: a['id'] as int,
      label: (a['fileName'] as String?) ?? 'File #${a['id']}',
      subtitle: _join([a['contentType'] as String?, kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '${kb.toStringAsFixed(0)} KB']),
    );
  }).toList();
});

/// Org users for assignee pickers (GET /users — needs TASK_MANAGE server-side).
final userLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _fetch(ref, '/users');
  return rows
      .map((u) => LookupOption(
            id: u['id'] as int,
            label: u['fullName'] as String,
            subtitle: _join([
              u['email'] as String?,
              ((u['roles'] as List?) ?? const [])
                  .map((r) => _roleLabel(r as String))
                  .join(', '),
            ]),
          ))
      .toList();
});

String _roleLabel(String role) => role
    .split('_')
    .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
    .join(' ');

/// Seasons reference data (shared, Doc 8.3) for the style form.
final seasonLookupProvider = FutureProvider.autoDispose<List<LookupOption>>((ref) async {
  final rows = await _fetch(ref, '/seasons');
  return rows
      .map((s) => LookupOption(
            id: s['id'] as int,
            label: '${s['name']} ${s['year']}',
            subtitle: _join([s['startDate'] as String?, s['endDate'] as String?]),
          ))
      .toList();
});
