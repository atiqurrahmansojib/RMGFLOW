import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/inquiry_list_controller.dart';
import '../domain/inquiry.dart';
import 'inquiry_form_screen.dart';

/// Document 7 (#24)/14.2: Inquiry List — the BD pipeline view, filterable by status.
class InquiryListScreen extends ConsumerWidget {
  const InquiryListScreen({super.key});

  Color _statusColor(BuildContext context, InquiryStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      InquiryStatus.open => scheme.primary,
      InquiryStatus.quoted => scheme.tertiary,
      InquiryStatus.won => Colors.green,
      InquiryStatus.lost => scheme.error,
      InquiryStatus.hold => scheme.outline,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inquiryListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiries'),
        actions: [
          PopupMenuButton<InquiryStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) => ref.read(inquiryListControllerProvider.notifier).load(status: status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All statuses')),
              ...InquiryStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.label))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InquiryFormScreen()),
        ).then((_) => ref.read(inquiryListControllerProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        InquiryListLoading() => const LoadingView(),
        InquiryListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(inquiryListControllerProvider.notifier).refresh(),
          ),
        InquiryListLoaded(:final inquiries) when inquiries.isEmpty =>
          const EmptyStateView(message: 'No inquiries yet. Tap + to log one.', icon: Icons.mail_outline),
        InquiryListLoaded(:final inquiries) => RefreshIndicator(
            onRefresh: () => ref.read(inquiryListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: inquiries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                return ListTile(
                  title: Text(inquiry.buyerName),
                  subtitle: Text(inquiry.inquiryNo),
                  trailing: Chip(
                    label: Text(inquiry.status.label),
                    backgroundColor: _statusColor(context, inquiry.status).withOpacity(0.15),
                    labelStyle: TextStyle(color: _statusColor(context, inquiry.status)),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InquiryFormScreen(existingInquiry: inquiry)),
                  ).then((_) => ref.read(inquiryListControllerProvider.notifier).refresh()),
                );
              },
            ),
          ),
      },
    );
  }
}
