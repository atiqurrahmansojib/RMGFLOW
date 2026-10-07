import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../order/presentation/open_order.dart';
import '../application/task_controller.dart';
import '../domain/task_item.dart';

/// Document 7 (#92-93)/21: `target == null` shows "My Open Tasks" (reached
/// from HomeScreen); a non-null target shows tasks attached to that entity
/// (reached from a module's detail screen) — same screen, same repository.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key, this.target});

  final ({String entityType, int entityId})? target;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _hideClosed = true;

  /// The task just created — tinted so it is easy to spot in the list.
  int? _highlightId;
  String _query = '';

  ({String entityType, int entityId})? get target => widget.target;

  Future<void> _createTask() async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _TaskSheet(entityType: target?.entityType, entityId: target?.entityId),
    );
    if (draft == null) return;
    await ref.read(taskActionControllerProvider.notifier).create(draft);
    final result = ref.read(taskActionControllerProvider);
    if (mounted && result is TaskActionSuccess) {
      showSuccessSnack(context, 'Task created');
      setState(() => _highlightId = result.task.id);
    }
    ref.read(taskListControllerProvider(target).notifier).refresh();
  }

  Future<void> _setStatus(TaskItem task, TaskStatus status) async {
    if (status == TaskStatus.cancelled) {
      final ok = await confirmAction(
        context,
        title: 'Cancel this task?',
        message: '"${task.title}" will be closed without being done.',
        confirmLabel: 'Cancel task',
        destructive: true,
      );
      if (!ok) return;
    }
    await ref.read(taskActionControllerProvider.notifier).updateStatus(task.id, status);
    if (mounted && ref.read(taskActionControllerProvider) is TaskActionSuccess) {
      showSuccessSnack(
          context, status == TaskStatus.done ? 'Nice — task done' : 'Task marked ${status.label.toLowerCase()}');
    }
    ref.read(taskListControllerProvider(target).notifier).refresh();
  }

  Future<void> _reassign(TaskItem task) async {
    final picked = await showLookupPicker(
      context,
      title: 'Assignee',
      options: userLookupProvider,
      selectedId: task.assignedToId,
      allowClear: task.assignedToId != null,
      emptyMessage: 'No users found in your organization.',
    );
    if (picked == null || picked.id == task.assignedToId || !mounted) return;
    await ref.read(taskActionControllerProvider.notifier).reassign(task.id, picked.id);
    if (mounted && ref.read(taskActionControllerProvider) is TaskActionSuccess) {
      showSuccessSnack(context, picked.id == null ? 'Task unassigned' : 'Task reassigned');
    }
    ref.read(taskListControllerProvider(target).notifier).refresh();
  }

  void _actions(TaskItem task) {
    final closed = task.status == TaskStatus.done || task.status == TaskStatus.cancelled;
    showQuickActions(
      context,
      title: task.title,
      subtitle: entityRefLabel(ref, task.entityType, task.entityId),
      actions: [
        if (!closed) ...[
          QuickAction(
            icon: Icons.task_alt_rounded,
            label: 'Mark done',
            color: AppColors.success,
            onTap: () => _setStatus(task, TaskStatus.done),
          ),
          if (task.status != TaskStatus.inProgress)
            QuickAction(
              icon: Icons.autorenew_rounded,
              label: 'Start (in progress)',
              color: AppColors.indigo,
              onTap: () => _setStatus(task, TaskStatus.inProgress),
            ),
        ],
        if (!closed)
          QuickAction(
            icon: Icons.person_search_rounded,
            label: task.assignedToName != null ? 'Reassign (now ${task.assignedToName})' : 'Assign to…',
            color: AppColors.indigo,
            onTap: () => _reassign(task),
          ),
        if (task.entityType == 'Order')
          QuickAction(
            icon: AppModules.orders.icon,
            label: 'Open order',
            color: AppModules.orders.color,
            onTap: () => openOrderById(context, ref, task.entityId),
          ),
        if (!closed)
          QuickAction(
            icon: Icons.block_rounded,
            label: 'Cancel task',
            color: AppColors.neutral,
            onTap: () => _setStatus(task, TaskStatus.cancelled),
          ),
      ],
    );
  }

  StatusTone _priorityTone(TaskPriority priority) => switch (priority) {
        TaskPriority.urgent => StatusTone.danger,
        TaskPriority.high => StatusTone.warning,
        TaskPriority.medium => StatusTone.info,
        TaskPriority.low => StatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(taskActionControllerProvider, (previous, next) {
      if (next is TaskActionFailed) showErrorSnack(context, next.failure.message);
    });
    final state = ref.watch(taskListControllerProvider(target));

    return Scaffold(
      appBar: AppBar(title: Text(target == null ? 'My Tasks' : 'Tasks')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _createTask, icon: const Icon(Icons.add), label: const Text('New task')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: SearchField(hintText: 'Search tasks', onChanged: (v) => setState(() => _query = v)),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Hide done and cancelled'),
            value: _hideClosed,
            onChanged: (v) => setState(() => _hideClosed = v),
          ),
          Expanded(
            child: switch (state) {
              TaskListLoading() => const LoadingView(),
              TaskListError(:final failure) => ErrorStateView(
                  failure: failure,
                  onRetry: () => ref.read(taskListControllerProvider(target).notifier).refresh(),
                ),
              TaskListLoaded(:final tasks) => Builder(builder: (context) {
                  final q = _query.trim().toLowerCase();
                  final visible = tasks.where((t) {
                    if (_hideClosed && (t.status == TaskStatus.done || t.status == TaskStatus.cancelled)) return false;
                    return q.isEmpty ||
                        t.title.toLowerCase().contains(q) ||
                        (t.description?.toLowerCase().contains(q) ?? false);
                  }).toList()
                    // Overdue first, then by due date.
                    ..sort((a, b) {
                      if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
                      return (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999');
                    });
                  return RefreshIndicator(
                    onRefresh: () => ref.read(taskListControllerProvider(target).notifier).refresh(),
                    child: visible.isEmpty
                        ? RefreshableEmpty(
                            child: EmptyStateView(
                              title: tasks.isEmpty ? 'No tasks' : 'All clear',
                              message: tasks.isEmpty
                                  ? (target == null
                                      ? 'Tasks assigned to you will show up here. Create one and link it to an order, buyer or style.'
                                      : 'Add a to-do for this record so nothing slips.')
                                  : 'Nothing open matches. Turn off "Hide done" to see finished tasks.',
                              icon: Icons.task_alt_rounded,
                              color: AppModules.tasks.color,
                              actionLabel: 'New task',
                              onAction: _createTask,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.listWithFab,
                            itemCount: visible.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final open = tasks
                                    .where((t) => t.status != TaskStatus.done && t.status != TaskStatus.cancelled)
                                    .toList();
                                final today = open.where((t) => daysFromToday(t.dueDate) == 0).length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                  child: Row(
                                    children: [
                                      TonePill('${open.length} open',
                                          color: AppModules.tasks.color, icon: Icons.checklist_rounded),
                                      const SizedBox(width: AppSpacing.sm),
                                      if (open.any((t) => t.overdue))
                                        TonePill('${open.where((t) => t.overdue).length} overdue',
                                            color: AppColors.danger, icon: Icons.alarm_rounded),
                                      const SizedBox(width: AppSpacing.sm),
                                      if (today > 0)
                                        TonePill('$today due today',
                                            color: AppColors.warning, icon: Icons.today_rounded),
                                      const Spacer(),
                                      Text('Swipe → done',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                );
                              }
                              final task = visible[index - 1];
                              final closed = task.status == TaskStatus.done || task.status == TaskStatus.cancelled;
                              final tone = task.overdue ? StatusTone.danger : _priorityTone(task.priority);
                              return SwipeAction(
                                key: ValueKey('task-${task.id}'),
                                startLabel: 'Done',
                                startIcon: Icons.task_alt_rounded,
                                startColor: AppColors.success,
                                onSwipeStart: closed ? null : () => _setStatus(task, TaskStatus.done),
                                child: AppCard(
                                  accentColor: closed ? AppColors.neutral : tone.color,
                                  color: task.id == _highlightId
                                      ? Color.alphaBlend(AppModules.tasks.color.withValues(alpha: 0.10),
                                          Theme.of(context).colorScheme.surface)
                                      : null,
                                  // From My Tasks, a tap goes straight to the linked order.
                                  onTap: target == null && task.entityType == 'Order'
                                      ? () => openOrderById(context, ref, task.entityId)
                                      : () => _actions(task),
                                  onLongPress: () => _actions(task),
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.xs, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        tooltip: closed ? task.status.label : 'Mark done',
                                        onPressed: closed ? null : () => _setStatus(task, TaskStatus.done),
                                        icon: Icon(
                                          closed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                          color: closed ? AppColors.success : tone.color,
                                        ),
                                      ),
                                      Expanded(
                                        child: RecordRow(
                                          title: task.title,
                                          subtitle: [
                                            entityRefLabel(ref, task.entityType, task.entityId),
                                            if (task.dueDate != null) 'Due ${formatApiDate(task.dueDate)}',
                                            task.assignedToName != null ? '→ ${task.assignedToName}' : 'Unassigned',
                                          ].join(' · '),
                                          meta: task.description,
                                          trailing: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              StatusMenuChip<TaskStatus>(
                                                status: task.status.apiValue,
                                                label: task.status.label,
                                                enabled: !closed,
                                                options: [TaskStatus.inProgress, TaskStatus.done, TaskStatus.cancelled]
                                                    .where((s) => s != task.status)
                                                    .toList(),
                                                apiOf: (s) => s.apiValue,
                                                labelOf: (s) => s.label,
                                                onSelected: (s) => _setStatus(task, s),
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              task.overdue && !closed
                                                  ? const StatusChip('OVERDUE', dense: true)
                                                  : StatusChip(task.priority.apiValue,
                                                      label: task.priority.label,
                                                      tone: _priorityTone(task.priority),
                                                      dense: true,
                                                      showIcon: false),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
            },
          ),
        ],
      ),
    );
  }
}

class _TaskSheet extends ConsumerStatefulWidget {
  const _TaskSheet({this.entityType, this.entityId});

  /// Null when opened from My Tasks — the sheet then asks what the task is about.
  final String? entityType;
  final int? entityId;

  @override
  ConsumerState<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends ConsumerState<_TaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate = DateUtils.dateOnly(DateTime.now());
  int? _assigneeId;
  bool _assigneeTouched = false;
  late String _linkType = widget.entityType ?? 'Order';
  int? _linkId;

  bool get _pickLink => widget.entityType == null;

  /// Same entityType spelling the detail screens use ('Order'), so a task
  /// created here also shows on that record's own task list.
  static const _linkTypes = {
    'Order': 'Order',
    'Buyer': 'Buyer',
    'Factory': 'Factory',
    'Style': 'Style',
    'Inquiry': 'Inquiry'
  };

  ProviderBase<AsyncValue<List<LookupOption>>> get _linkOptions => switch (_linkType) {
        'Buyer' => buyerLookupProvider,
        'Factory' => factoryLookupProvider,
        'Style' => styleLookupProvider(null),
        'Inquiry' => inquiryLookupProvider,
        _ => orderLookupProvider,
      };

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final me = ref.read(currentUserProvider);
    Navigator.of(context).pop(TaskDraft(
      entityType: _pickLink ? _linkType : widget.entityType!,
      entityId: _pickLink ? _linkId! : widget.entityId!,
      title: _title.text.trim(),
      description: blankToNull(_description.text),
      assignedToId: _assigneeTouched ? _assigneeId : (_assigneeId ?? me?.id),
      priority: _priority,
      dueDate: toApiDate(_dueDate),
    ));
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
              Text('New task', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              if (_pickLink) ...[
                DropdownButtonFormField<String>(
                  initialValue: _linkType,
                  decoration: const InputDecoration(labelText: 'Task is about'),
                  items: _linkTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() {
                    _linkType = v!;
                    _linkId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                LookupField(
                  key: ValueKey(_linkType),
                  label: _linkTypes[_linkType]!,
                  options: _linkOptions,
                  required: true,
                  onChanged: (v) => _linkId = v,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _title,
                autofocus: !_pickLink,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Chase lab-dip approval'),
                validator: Validators.required('Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values.map((p) => ButtonSegment(value: p, label: Text(p.label))).toList(),
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                label: 'Due date',
                value: _dueDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                onChanged: (d) => setState(() => _dueDate = d),
              ),
              const SizedBox(height: AppSpacing.md),
              LookupField(
                label: 'Assignee (optional)',
                icon: Icons.person_outline_rounded,
                initialValue: _assigneeId ?? ref.read(currentUserProvider)?.id,
                options: userLookupProvider,
                helperText: 'Defaults to you — clear it to leave the task unassigned',
                emptyMessage: 'No users found in your organization.',
                onChanged: (v) {
                  _assigneeTouched = true;
                  _assigneeId = v;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(label: 'Create task', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
