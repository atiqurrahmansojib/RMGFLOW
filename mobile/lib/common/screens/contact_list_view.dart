import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/failure_mapper.dart';
import '../widgets/widgets.dart';

/// Contacts sub-resource of a buyer or factory (Doc 7 #19/#23). Both APIs share
/// one shape — `{name, email, phone, primary}` plus `department` (buyer) or
/// `role` (factory) — so one view serves both.
final _contactsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, path) => getJsonList(ref, path),
);

class ContactListView extends ConsumerWidget {
  const ContactListView({super.key, required this.path, required this.roleKey, required this.roleLabel});

  /// e.g. `/buyers/3/contacts` or `/factories/5/contacts`.
  final String path;

  /// `department` (buyer) or `role` (factory).
  final String roleKey;
  final String roleLabel;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final body = await showFormSheet<Map<String, dynamic>>(context, _ContactSheet(roleLabel: roleLabel, roleKey: roleKey));
    if (body == null) return;
    try {
      await authorizedWidgetCall(ref, (dio) => dio.post(path, data: body));
      if (context.mounted) showSuccessSnack(context, 'Contact added');
      ref.invalidate(_contactsProvider(path));
    } on DioException catch (e) {
      if (context.mounted) showErrorSnack(context, mapDioErrorToFailure(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_contactsProvider(path));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-contact-$path',
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add contact'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(failure: mapErrorToFailure(e), onRetry: () => ref.invalidate(_contactsProvider(path))),
        data: (contacts) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_contactsProvider(path)),
          child: contacts.isEmpty
              ? RefreshableEmpty(
                  child: EmptyStateView(
                    title: 'No contacts yet',
                    message: 'Add the people you deal with — merchandisers, QA, accounts.',
                    icon: Icons.contacts_outlined,
                    actionLabel: 'Add contact',
                    onAction: () => _add(context, ref),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = contacts[i];
                    final name = c['name'] as String? ?? '—';
                    final email = c['email'] as String?;
                    final phone = c['phone'] as String?;
                    return ListTile(
                      leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name[0].toUpperCase())),
                      title: Row(
                        children: [
                          Flexible(child: Text(name)),
                          if (c['primary'] == true) ...[
                            const SizedBox(width: 8),
                            const StatusChip('ACTIVE', label: 'Primary', dense: true, showIcon: false),
                          ],
                        ],
                      ),
                      subtitle: Text([
                        if (c[roleKey] != null) c[roleKey] as String,
                        if (email != null) email,
                        if (phone != null) phone,
                      ].join(' · ')),
                      trailing: (email ?? phone) == null
                          ? null
                          : IconButton(
                              tooltip: 'Copy ${email != null ? 'email' : 'phone'}',
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: email ?? phone!));
                                showSuccessSnack(context, 'Copied ${email ?? phone}');
                              },
                            ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({required this.roleLabel, required this.roleKey});
  final String roleLabel;
  final String roleKey;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _primary = false;

  @override
  void dispose() {
    for (final c in [_name, _role, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
        formKey: _formKey,
        title: 'Add contact',
        actionLabel: 'Save contact',
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop({
            'name': _name.text.trim(),
            widget.roleKey: blankToNull(_role.text),
            'email': blankToNull(_email.text),
            'phone': blankToNull(_phone.text),
            'primary': _primary,
          });
        },
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: Validators.required('Name'),
          ),
          TextFormField(
            controller: _role,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: '${widget.roleLabel} (optional)'),
          ),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
            validator: (v) => (v != null && v.trim().isNotEmpty && !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)', hintText: '+880…'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Primary contact'),
            value: _primary,
            onChanged: (v) => setState(() => _primary = v),
          ),
        ],
      );
}
