import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/empty_state_view.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/loading_view.dart';
import '../application/commercial_document_controller.dart';
import '../domain/commercial_document.dart';

/// Document 7 (#46-47)/8.9: generic versioned-document list, reused for every
/// `DocumentEntityType` (order/shipment/factory/style) rather than a
/// per-module documents screen.
class CommercialDocumentListScreen extends ConsumerWidget {
  const CommercialDocumentListScreen({super.key, required this.entityType, required this.entityId});

  final DocumentEntityType entityType;
  final int entityId;

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final documentTypeIdController = TextEditingController();
    final fileAttachmentIdController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: documentTypeIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Document Type ID'),
            ),
            TextField(
              controller: fileAttachmentIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Attachment ID (already uploaded)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Upload')),
        ],
      ),
    );
    if (confirmed != true) return;
    final documentTypeId = int.tryParse(documentTypeIdController.text.trim());
    final fileAttachmentId = int.tryParse(fileAttachmentIdController.text.trim());
    if (documentTypeId == null || fileAttachmentId == null) return;
    await ref.read(commercialDocumentActionControllerProvider.notifier).upload(
          CommercialDocumentDraft(
            entityType: entityType,
            entityId: entityId,
            documentTypeId: documentTypeId,
            fileAttachmentId: fileAttachmentId,
          ),
        );
    ref.read(commercialDocumentListControllerProvider((entityType: entityType, entityId: entityId)).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(commercialDocumentActionControllerProvider, (previous, next) {
      if (next is CommercialDocumentActionFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });
    final target = (entityType: entityType, entityId: entityId);
    final state = ref.watch(commercialDocumentListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _upload(context, ref),
        child: const Icon(Icons.upload_file_outlined),
      ),
      body: switch (state) {
        CommercialDocumentListLoading() => const LoadingView(),
        CommercialDocumentListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(commercialDocumentListControllerProvider(target).notifier).refresh(),
          ),
        CommercialDocumentListLoaded(:final documents) when documents.isEmpty =>
          const EmptyStateView(message: 'No documents uploaded yet.', icon: Icons.description_outlined),
        CommercialDocumentListLoaded(:final documents) => RefreshIndicator(
            onRefresh: () => ref.read(commercialDocumentListControllerProvider(target).notifier).refresh(),
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final document = documents[index];
                return ListTile(
                  title: Text('Type #${document.documentTypeId} · v${document.versionNo}'),
                  subtitle: Text(
                    'Uploaded ${document.uploadedAt}'
                    '${document.expiryDate != null ? ' · Expires ${document.expiryDate}' : ''}'
                    '${document.expired ? ' (EXPIRED)' : ''}',
                  ),
                  trailing: document.status == DocumentStatus.draft || document.status == DocumentStatus.submitted
                      ? TextButton(
                          onPressed: () async {
                            await ref.read(commercialDocumentActionControllerProvider.notifier).approve(document.id);
                            ref.read(commercialDocumentListControllerProvider(target).notifier).refresh();
                          },
                          child: const Text('Approve'),
                        )
                      : Chip(label: Text(document.status.label)),
                );
              },
            ),
          ),
      },
    );
  }
}
