import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/files/attachment_opener.dart';
import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/commercial_document_controller.dart';
import '../domain/commercial_document.dart';

/// Document 7 (#46-47)/8.9: generic versioned-document list, reused for every
/// `DocumentEntityType` (order/shipment/factory/style) rather than a
/// per-module documents screen.
class CommercialDocumentListScreen extends ConsumerWidget {
  const CommercialDocumentListScreen({super.key, required this.entityType, required this.entityId});

  final DocumentEntityType entityType;
  final int entityId;

  ({DocumentEntityType entityType, int entityId}) get _target => (entityType: entityType, entityId: entityId);

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<CommercialDocumentDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _DocumentSheet(entityType: entityType, entityId: entityId),
    );
    if (draft == null) return;
    await ref.read(commercialDocumentActionControllerProvider.notifier).upload(draft);
    if (context.mounted && ref.read(commercialDocumentActionControllerProvider) is CommercialDocumentActionSuccess) {
      showSuccessSnack(context, 'Document added');
    }
    ref.read(commercialDocumentListControllerProvider(_target).notifier).refresh();
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, CommercialDocument document, String typeName) async {
    final ok = await confirmAction(
      context,
      title: 'Approve $typeName v${document.versionNo}?',
      message: 'Approved documents are treated as final for this ${entityType.label.toLowerCase()}.',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    await ref.read(commercialDocumentActionControllerProvider.notifier).approve(document.id);
    if (context.mounted && ref.read(commercialDocumentActionControllerProvider) is CommercialDocumentActionSuccess) {
      showSuccessSnack(context, '$typeName approved');
    }
    ref.read(commercialDocumentListControllerProvider(_target).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(commercialDocumentActionControllerProvider, (previous, next) {
      if (next is CommercialDocumentActionFailed) showErrorSnack(context, next.failure.message);
    });
    final target = _target;
    final state = ref.watch(commercialDocumentListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: Text('${entityType.label} Documents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(context, ref),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Add document'),
      ),
      body: switch (state) {
        CommercialDocumentListLoading() => const LoadingView(),
        CommercialDocumentListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(commercialDocumentListControllerProvider(target).notifier).refresh(),
          ),
        CommercialDocumentListLoaded(:final documents) when documents.isEmpty => EmptyStateView(
            title: 'No documents yet',
            message: 'Add invoices, packing lists, B/L, certificates and other commercial documents here.',
            icon: Icons.description_outlined,
            color: AppModules.documents.color,
            actionLabel: 'Add document',
            actionIcon: Icons.upload_file_outlined,
            onAction: () => _upload(context, ref),
          ),
        CommercialDocumentListLoaded(:final documents) => RefreshIndicator(
            onRefresh: () => ref.read(commercialDocumentListControllerProvider(target).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab.copyWith(left: 0, right: 0, top: 0),
              children: [
                GradientHeader.module(
                  AppModules.documents,
                  eyebrow: '${entityType.label} documents',
                  title: '${documents.length} document${documents.length == 1 ? '' : 's'}',
                  subtitle: 'Swipe right on a pending document to approve it',
                  bottom: Row(
                    children: [
                      HeaderStat(
                          value: '${documents.where((d) => d.status == DocumentStatus.approved).length}',
                          label: 'Approved'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(
                          value:
                              '${documents.where((d) => d.status == DocumentStatus.draft || d.status == DocumentStatus.submitted).length}',
                          label: 'Pending'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(value: '${documents.where((d) => d.expired).length}', label: 'Expired'),
                    ],
                  ),
                ),
                for (final document in documents)
                  Builder(builder: (context) {
                    final typeName = lookupLabel(ref, documentTypeLookupProvider, document.documentTypeId,
                        fallback: 'Document type #${document.documentTypeId}');
                    final pending =
                        document.status == DocumentStatus.draft || document.status == DocumentStatus.submitted;
                    final status = document.expired ? 'EXPIRED' : document.status.apiValue;
                    void open() => openAttachment(context, ref, document.fileAttachmentId,
                        fallbackName: '$typeName v${document.versionNo}');
                    final expiresIn = daysFromToday(document.expiryDate);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SwipeAction(
                        key: ValueKey('doc-${document.id}'),
                        startLabel: 'Approve',
                        startIcon: Icons.check_circle_rounded,
                        startColor: AppColors.success,
                        onSwipeStart: pending ? () => _approve(context, ref, document, typeName) : null,
                        child: AppCard(
                          accentColor: AppStatus.color(status),
                          // Tap to download and open the file itself (Doc 7 #76 preview).
                          onTap: open,
                          onLongPress: () => showQuickActions(
                            context,
                            title: '$typeName · v${document.versionNo}',
                            actions: [
                              QuickAction(
                                  icon: Icons.open_in_new_rounded,
                                  label: 'Open file',
                                  color: AppModules.documents.color,
                                  onTap: open),
                              if (pending)
                                QuickAction(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Approve',
                                  color: AppColors.success,
                                  onTap: () => _approve(context, ref, document, typeName),
                                ),
                            ],
                          ),
                          child: RecordRow(
                            leading: IconBadge(icon: Icons.description_rounded, color: AppModules.documents.color),
                            title: '$typeName · v${document.versionNo}',
                            subtitle: 'Uploaded ${displayDateFormat.format(document.uploadedAt.toLocal())}',
                            meta: document.expiryDate == null ? null : 'Expires ${formatApiDate(document.expiryDate)}',
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusChip(status,
                                    label: document.expired ? 'Expired' : document.status.label, dense: true),
                                if (!document.expired && expiresIn != null && expiresIn <= 30) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  TonePill('expires ${relativeDays(expiresIn)}',
                                      color: AppColors.warning, icon: Icons.timer_outlined),
                                ],
                              ],
                            ),
                            footer: pending
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => _approve(context, ref, document, typeName),
                                      icon: const Icon(Icons.check_rounded, size: 18),
                                      label: const Text('Approve'),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
      },
    );
  }
}

class _DocumentSheet extends StatefulWidget {
  const _DocumentSheet({required this.entityType, required this.entityId});
  final DocumentEntityType entityType;
  final int entityId;

  @override
  State<_DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends State<_DocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _typeId;
  int? _attachmentId;
  DateTime? _expiry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add document', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              LookupField(
                label: 'Document type',
                icon: Icons.category_outlined,
                required: true,
                options: documentTypeLookupProvider,
                emptyMessage: 'No document types set up. Ask an admin to add them in master data.',
                onChanged: (v) => _typeId = v,
              ),
              const SizedBox(height: AppSpacing.md),
              LookupField(
                label: 'File',
                icon: Icons.attach_file_rounded,
                required: true,
                options: attachmentLookupProvider((entityType: widget.entityType.apiValue, entityId: widget.entityId)),
                helperText: 'Choose a file already attached to this ${widget.entityType.label.toLowerCase()}',
                emptyMessage: 'No files attached to this ${widget.entityType.label.toLowerCase()} yet. '
                    'Upload the file from the web app first, then link it here.',
                onChanged: (v) => _attachmentId = v,
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                label: 'Expiry date',
                value: _expiry,
                helperText: 'For certificates, LCs and other documents that expire',
                onChanged: (d) => setState(() => _expiry = d),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Add document',
                icon: Icons.check_rounded,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(CommercialDocumentDraft(
                    entityType: widget.entityType,
                    entityId: widget.entityId,
                    documentTypeId: _typeId!,
                    fileAttachmentId: _attachmentId!,
                    expiryDate: toApiDate(_expiry),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
