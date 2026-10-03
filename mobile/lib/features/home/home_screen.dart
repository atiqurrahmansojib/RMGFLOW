import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../approval/presentation/approval_inbox_screen.dart';
import '../auth/application/auth_controller.dart';
import '../buyers/presentation/buyer_list_screen.dart';
import '../costing/presentation/costing_list_screen.dart';
import '../dashboard/presentation/my_day_screen.dart';
import '../factories/presentation/factory_list_screen.dart';
import '../inquiries/presentation/inquiry_list_screen.dart';
import '../notification/presentation/notification_list_screen.dart';
import '../order/presentation/order_list_screen.dart';
import '../quotation/presentation/quotation_list_screen.dart';
import '../sample/presentation/sample_list_screen.dart';
import '../styles/presentation/style_list_screen.dart';
import '../task/presentation/task_list_screen.dart';

/// Document 7's module launcher. Doc 14.9's "My Day" dashboard (reached via
/// the app-bar icon here) is the recommended post-login landing view, but
/// this module grid stays as the way to reach every feature directly.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RMGFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'My Day',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyDayScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Buyers'),
              subtitle: const Text('Buyer master, contacts, requirements'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.factory_outlined),
              title: const Text('Factories & Vendors'),
              subtitle: const Text('Factory master, capabilities, certifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FactoryListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Inquiries'),
              subtitle: const Text('BD pipeline, factory sourcing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InquiryListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.checkroom_outlined),
              title: const Text('Styles'),
              subtitle: const Text('Style master and specs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StyleListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Costing'),
              subtitle: const Text('Itemized cost sheets, margin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CostingListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: const Text('Quotations'),
              subtitle: const Text('Buyer quotations from approved costings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuotationListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Samples'),
              subtitle: const Text('Sample requests, revisions, approval sync'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SampleListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              subtitle: const Text('Confirmed orders, amendments, T&A calendar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: const Text('Pending Approvals'),
              subtitle: const Text('Costing, quotation, sample revision approval inbox'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApprovalInboxScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_outlined),
              title: const Text('My Tasks'),
              subtitle: const Text('Open tasks assigned to you'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaskListScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
