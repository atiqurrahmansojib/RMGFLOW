import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../application/activity_controller.dart';
import '../domain/activity.dart';

/// Document 7 (#89-91)/8.9: generic communication/activity log, reused for
/// any entity type by passing a different `entityType`/`entityId`.
class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key, required this.entityType, required this.entityId});

  final String entityType;
  final int entityId;

  static final _when = DateFormat('dd MMM yyyy, HH:mm');

  static IconData iconFor(ActivityType t) => switch (t) {
        ActivityType.call => Icons.call_outlined,
        ActivityType.email => Icons.email_outlined,
        ActivityType.meeting => Icons.groups_outlined,
        ActivityType.note => Icons.sticky_note_2_outlined,
      };

  static Color colorFor(ActivityType t) => switch (t) {
        ActivityType.call => AppModules.orders.color,
        ActivityType.email => AppModules.inquiries.color,
        ActivityType.meeting => AppModules.costing.color,
        ActivityType.note => AppModules.ta.color,
      };

  Future<void> _logActivity(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<ActivityDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ActivitySheet(entityType: entityType, entityId: entityId),
    );
    if (draft == null) return;
    await ref.read(activityFormControllerProvider.notifier).submit(draft);
    if (context.mounted && ref.read(activityFormControllerProvider) is ActivityFormSuccess) {
      showSuccessSnack(context, '${draft.activityType.label} logged');
    }
    ref.read(activityListControllerProvider((entityType: entityType, entityId: entityId)).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activityFormControllerProvider, (previous, next) {
      if (next is ActivityFormFailed) showErrorSnack(context, next.failure.message);
    });
    final target = (entityType: entityType, entityId: entityId);
    final state = ref.watch(activityListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logActivity(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log activity'),
      ),
      body: switch (state) {
        ActivityListLoading() => const LoadingView(),
        ActivityListError(:final failure) => ErrorStateView(
            failure: failure,
            onRetry: () => ref.read(activityListControllerProvider(target).notifier).refresh(),
          ),
        ActivityListLoaded(:final activities) when activities.isEmpty => EmptyStateView(
            title: 'No activity yet',
            message: 'Log calls, emails, meetings and notes so the whole team sees the history.',
            icon: Icons.history_edu_outlined,
            color: AppModules.inquiries.color,
            actionLabel: 'Log activity',
            onAction: () => _logActivity(context, ref),
          ),
        ActivityListLoaded(:final activities) => RefreshIndicator(
            onRefresh: () => ref.read(activityListControllerProvider(target).notifier).refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.listWithFab,
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final color = colorFor(activity.activityType);
                final day = DateUtils.dateOnly(activity.occurredAt.toLocal());
                final prevDay = index == 0 ? null : DateUtils.dateOnly(activities[index - 1].occurredAt.toLocal());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (prevDay == null || prevDay != day)
                      SectionHeader(
                        DateUtils.isSameDay(day, DateTime.now()) ? 'Today' : displayDateFormat.format(day),
                        icon: Icons.calendar_today_rounded,
                        accentColor: AppModules.inquiries.color,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
                      ),
                    AppCard(
                      accentColor: color,
                      child: RecordRow(
                        leading: IconBadge(icon: iconFor(activity.activityType), color: color, size: 40),
                        title: activity.content,
                        subtitle: '${activity.activityType.label} · ${_when.format(activity.occurredAt.toLocal())}',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      },
    );
  }
}

class _ActivitySheet extends StatefulWidget {
  const _ActivitySheet({required this.entityType, required this.entityId});
  final String entityType;
  final int entityId;

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _content = TextEditingController();
  ActivityType _type = ActivityType.call;
  DateTime _occurredAt = DateTime.now();

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
    setState(() => _occurredAt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0));
  }

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
              Text('Log activity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<ActivityType>(
                segments: ActivityType.values
                    .map(
                        (t) => ButtonSegment(value: t, label: Text(t.label), icon: Icon(ActivityListScreen.iconFor(t))))
                    .toList(),
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('When'),
                subtitle: Text(ActivityListScreen._when.format(_occurredAt)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickWhen,
              ),
              TextFormField(
                controller: _content,
                autofocus: true,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notes', hintText: 'What was discussed or agreed?'),
                validator: Validators.required('Notes'),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save',
                icon: Icons.check_rounded,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(ActivityDraft(
                    entityType: widget.entityType,
                    entityId: widget.entityId,
                    activityType: _type,
                    occurredAt: _occurredAt,
                    content: _content.text.trim(),
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
