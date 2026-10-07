import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/screens/contact_list_view.dart';
import '../../../common/widgets/a_record_widgets.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../domain/factory.dart';

/// Document 7 (#21/#23): the factory detail tabs that live on sub-resources —
/// Contacts, Capabilities (product categories), Certifications (with expiry)
/// and per-buyer compliance approvals (Doc 9.4: an order can only be placed
/// with a factory the buyer has approved).
class FactoryProfileScreen extends StatelessWidget {
  const FactoryProfileScreen({super.key, required this.factory, this.initialTab = 0});

  final Factory factory;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final base = '/factories/${factory.id}';
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(factory.name),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Contacts'),
              Tab(text: 'Capabilities'),
              Tab(text: 'Certifications'),
              Tab(text: 'Buyer approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContactListView(path: '$base/contacts', roleKey: 'role', roleLabel: 'Role'),
            _CapabilitiesTab(path: '$base/capabilities'),
            _CertificationsTab(path: '$base/certifications'),
            _BuyerApprovalsTab(path: '$base/buyer-approvals'),
          ],
        ),
      ),
    );
  }
}

final _rowsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, path) => getJsonList(ref, path),
);

/// POST/PUT [body] to [path]; on success acknowledge and reload the tab.
Future<void> _write(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required Map<String, dynamic> body,
  required String success,
  bool put = false,
}) async {
  try {
    await authorizedWidgetCall(ref, (dio) => put ? dio.put(path, data: body) : dio.post(path, data: body));
    if (context.mounted) showSuccessSnack(context, success);
    ref.invalidate(_rowsProvider(path));
  } on DioException catch (e) {
    if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
  }
}

/// Shared list scaffolding for the three sub-resource tabs: loading/error,
/// pull-to-refresh, an empty state with a call-to-action and an add FAB.
class _SubResourceList extends ConsumerWidget {
  const _SubResourceList({
    required this.path,
    required this.addLabel,
    required this.onAdd,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.itemBuilder,
  });

  final String path;
  final String addLabel;
  final VoidCallback onAdd;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(BuildContext context, Map<String, dynamic> row) itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_rowsProvider(path));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-$path',
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(addLabel),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorStateView(failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_rowsProvider(path))),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_rowsProvider(path)),
          child: rows.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: emptyTitle,
                    message: emptyMessage,
                    icon: emptyIcon,
                    color: AppModules.factories.color,
                    actionLabel: addLabel,
                    onAction: onAdd,
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.listWithFab,
                  itemCount: rows.length,
                  itemBuilder: (context, i) => itemBuilder(context, rows[i]),
                ),
        ),
      ),
    );
  }
}

class _CapabilitiesTab extends ConsumerWidget {
  const _CapabilitiesTab({required this.path});
  final String path;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final category = await promptForReason(
      context,
      title: 'Add capability',
      label: 'Product category',
      message: 'What can this factory make? e.g. Knit tops, Denim bottoms, Outerwear.',
      confirmLabel: 'Add',
    );
    if (category == null || !context.mounted) return;
    await _write(context, ref, path: path, body: {'productCategory': category}, success: 'Capability added');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SubResourceList(
        path: path,
        addLabel: 'Add capability',
        onAdd: () => _add(context, ref),
        emptyTitle: 'No capabilities yet',
        emptyMessage: 'List the product categories this factory can produce so merchandisers can shortlist it.',
        emptyIcon: Icons.precision_manufacturing_outlined,
        itemBuilder: (context, row) => RecordTile(
          accentColor: AppColors.info,
          leading: const RecordAvatar(color: AppColors.info, icon: Icons.checkroom_rounded, size: 40),
          title: row['productCategory'] as String? ?? '—',
        ),
      );
}

class _CertificationsTab extends ConsumerWidget {
  const _CertificationsTab({required this.path});
  final String path;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, const _CertificationSheet());
    if (body == null || !context.mounted) return;
    await _write(context, ref, path: path, body: body, success: 'Certification added');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SubResourceList(
        path: path,
        addLabel: 'Add certification',
        onAdd: () => _add(context, ref),
        emptyTitle: 'No certifications yet',
        emptyMessage: 'Record compliance certificates (BSCI, WRAP, OEKO-TEX, GOTS…) and their expiry dates.',
        emptyIcon: Icons.verified_outlined,
        itemBuilder: (context, row) {
          final expired = row['expired'] == true;
          final issued = row['issuedDate'] as String?;
          final expiry = row['expiryDate'] as String?;
          final status = expired ? 'EXPIRED' : 'VALID';
          return RecordTile(
            accentColor: expired ? AppColors.danger : AppStatus.color(status),
            leading: RecordAvatar(
                color: expired ? AppColors.danger : AppColors.success,
                icon: Icons.workspace_premium_outlined,
                size: 40),
            title: row['certName'] as String? ?? '—',
            subtitle: [
              if (issued != null) 'Issued ${formatApiDate(issued)}',
              expiry != null ? 'Expires ${formatApiDate(expiry)}' : 'No expiry date',
            ].join(' · '),
            trailing: StatusChip(status, dense: true),
          );
        },
      );
}

class _CertificationSheet extends StatefulWidget {
  const _CertificationSheet();

  @override
  State<_CertificationSheet> createState() => _CertificationSheetState();
}

class _CertificationSheetState extends State<_CertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DateTime? _issued;
  DateTime? _expiry;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: 'Add certification',
        actionLabel: 'Save certification',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop({
            'certName': _name.text.trim(),
            'issuedDate': toApiDate(_issued),
            'expiryDate': toApiDate(_expiry),
          });
        },
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Certificate name', hintText: 'e.g. BSCI, WRAP, OEKO-TEX'),
            validator: Validators.required('Certificate name'),
          ),
          DateField(
            label: 'Issued date (optional)',
            value: _issued,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _issued = d),
          ),
          DateField(
            label: 'Expiry date (optional)',
            value: _expiry,
            onChanged: (d) => setState(() => _expiry = d),
            validator: (d) =>
                d != null && _issued != null && d.isBefore(_issued!) ? 'Expiry must be after the issued date' : null,
          ),
        ],
      );
}

class _BuyerApprovalsTab extends ConsumerWidget {
  const _BuyerApprovalsTab({required this.path});
  final String path;

  Future<void> _upsert(BuildContext context, WidgetRef ref, [Map<String, dynamic>? existing]) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, _BuyerApprovalSheet(existing: existing));
    if (body == null || !context.mounted) return;
    await _write(context, ref, path: path, body: body, success: 'Buyer approval saved', put: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SubResourceList(
        path: path,
        addLabel: 'Set approval',
        onAdd: () => _upsert(context, ref),
        emptyTitle: 'No buyer approvals yet',
        emptyMessage:
            'Orders can only be placed with a factory the buyer has approved. Record each buyer\'s decision here.',
        emptyIcon: Icons.handshake_outlined,
        itemBuilder: (context, row) {
          final buyerId = row['buyerId'] as int?;
          final approved = row['approvedDate'] as String?;
          final expiry = row['expiryDate'] as String?;
          final status = row['status'] as String? ?? 'PENDING';
          final name = lookupLabel(ref, buyerLookupProvider, buyerId, fallback: 'Buyer #$buyerId');
          return RecordTile(
            accentColor: AppStatus.color(status),
            leading: RecordAvatar(color: AppModules.buyers.color, text: recordInitials(name), size: 40),
            title: name,
            subtitle: [
              if (approved != null) 'Approved ${formatApiDate(approved)}',
              if (expiry != null) 'Valid until ${formatApiDate(expiry)}',
              'Tap to update',
            ].join(' · '),
            trailing: StatusChip(status, dense: true),
            onTap: () => _upsert(context, ref, row),
          );
        },
      );
}

class _BuyerApprovalSheet extends StatefulWidget {
  const _BuyerApprovalSheet({this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<_BuyerApprovalSheet> createState() => _BuyerApprovalSheetState();
}

class _BuyerApprovalSheetState extends State<_BuyerApprovalSheet> {
  static const _statuses = ['PENDING', 'APPROVED', 'REJECTED', 'EXPIRED'];
  final _formKey = GlobalKey<FormState>();
  late int? _buyerId = widget.existing?['buyerId'] as int?;
  late String _status = widget.existing?['status'] as String? ?? 'APPROVED';
  late DateTime? _approved = parseApiDate(widget.existing?['approvedDate'] as String?) ?? DateTime.now();
  late DateTime? _expiry = parseApiDate(widget.existing?['expiryDate'] as String?);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_status == 'REJECTED') {
      final ok = await confirmAction(
        context,
        title: 'Mark as rejected?',
        message: 'New orders for this buyer will be blocked from using this factory.',
        confirmLabel: 'Mark rejected',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pop({
      'buyerId': _buyerId,
      'status': _status,
      'approvedDate': toApiDate(_approved),
      'expiryDate': toApiDate(_expiry),
    });
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: widget.existing == null ? 'Set buyer approval' : 'Update buyer approval',
        actionLabel: 'Save',
        onSave: _save,
        children: [
          LookupField(
            label: 'Buyer',
            icon: Icons.storefront_outlined,
            options: buyerLookupProvider,
            initialValue: _buyerId,
            required: true,
            enabled: widget.existing == null,
            onChanged: (v) => _buyerId = v,
          ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(AppStatus.humanize(s)))).toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          DateField(
            label: 'Approved date (optional)',
            value: _approved,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _approved = d),
          ),
          DateField(
            label: 'Valid until (optional)',
            value: _expiry,
            onChanged: (d) => setState(() => _expiry = d),
          ),
        ],
      );
}
