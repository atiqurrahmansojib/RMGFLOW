import 'package:flutter/material.dart';

import '../../../common/screens/contact_list_view.dart';
import '../domain/buyer.dart';

/// Document 7 (#17 Contacts tab / #19): a buyer's contact people.
class BuyerContactsScreen extends StatelessWidget {
  const BuyerContactsScreen({super.key, required this.buyer});

  final Buyer buyer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${buyer.name} · Contacts')),
      body: ContactListView(path: '/buyers/${buyer.id}/contacts', roleKey: 'department', roleLabel: 'Department'),
    );
  }
}
