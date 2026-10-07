import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/b_kit.dart';
import '../../../common/widgets/widgets.dart';
import '../../../core/network/failure_mapper.dart';
import '../../auth/application/auth_controller.dart';
import '../application/pending_commit_queue.dart';
import '../application/ta_milestone_controller.dart';
import '../data/ta_milestone_repository_impl.dart';
import '../domain/ta_milestone.dart';
import 'ta_template_list_screen.dart';

/// Document 7 (#54-58): one order's T&A calendar as a visual timeline.
/// Status colours reflect the server-derived status (Doc 9.5) — DONE/BLOCKED/
/// CRITICAL_DELAY/OVERDUE/DUE_TODAY/UPCOMING/PENDING — never recomputed here.
///
/// "Done today" is one tap: the row turns done immediately and the actual
/// date is sent once the Undo window ends (the server never lets an actual
/// date change afterwards, so Undo must happen before the call). The write
/// sits in [PendingCommitQueue], so it is still committed if the user leaves
/// the screen or backgrounds the app before the snackbar closes.
class TaMilestoneListScreen extends ConsumerStatefulWidget {
  const TaMilestoneListScreen({super.key, required this.orderId, required this.styleId});

  final int orderId;
  final int styleId;

  @override
  ConsumerState<TaMilestoneListScreen> createState() => _TaMilestoneListScreenState();
}

class _TaMilestoneListScreenState extends ConsumerState<TaMilestoneListScreen> {
  /// Milestones marked done locally, waiting for the Undo window to close.
  final Map<int, String> _pending = {};
  List<TaMilestone>? _last;
  late final PendingCommitQueue _queue;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(pendingCommitQueueProvider);
  }

  @override
  void dispose() {
    // Leaving the screen ends the Undo window: commit now rather than lose it.
    final orderId = widget.orderId;
    _queue.flush(where: (k) => k is (String, int, int) && k.$1 == 'ta-done' && k.$2 == orderId);
    super.dispose();
  }

  TaMilestoneListController get _list => ref.read(taMilestoneListControllerProvider(widget.orderId).notifier);

  Future<void> _complete(TaMilestone milestone, DateTime date) async {
    final day = DateUtils.dateOnly(date);
    String? delayReason;
    if (day.isAfter(DateTime.parse(milestone.effectiveDate))) {
      delayReason = await promptForReason(
        context,
        title: 'Delay reason required',
        message: 'This milestone was due ${formatApiDate(milestone.effectiveDate)} and is being completed late.',
        label: 'Reason for delay',
        confirmLabel: 'Save',
      );
      if (delayReason == null || !mounted) return;
    }
    final draft = RecordActualDateDraft(actualDate: toApiDate(day)!, delayReason: delayReason);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final key = ('ta-done', widget.orderId, milestone.id);
    final list = _list;
    setState(() => _pending[milestone.id] = draft.actualDate);
    _queue.schedule(key, () async {
      try {
        await container.read(authControllerProvider.notifier).callAuthorized(
              () => container.read(taMilestoneRepositoryProvider).recordActualDate(widget.orderId, milestone.id, draft),
            );
      } on DioException catch (e) {
        try {
          messenger.showSnackBar(SnackBar(
            content: Text(mapDioErrorToFailure(e).message),
            backgroundColor: AppColors.danger,
          ));
        } catch (_) {
          // Messenger already gone (app closing) — nothing left to show it on.
        }
      }
      if (!mounted) return;
      await list.refresh();
      if (mounted) setState(() => _pending.remove(milestone.id));
    });
    showUndoSnack(
      context,
      '${milestone.milestoneTypeName} done ${displayDateFormat.format(day)}',
      onUndo: () {
        if (_queue.cancel(key) && mounted) setState(() => _pending.remove(milestone.id));
      },
      onCommit: () => _queue.commit(key),
    );
  }

  Future<void> _pickDate(TaMilestone milestone) async {
    final date = await showDatePicker(
      context: context,
      helpText: 'When was "${milestone.milestoneTypeName}" done?',
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    await _complete(milestone, date);
  }

  void _actions(TaMilestone m) => showQuickActions(
        context,
        title: m.milestoneTypeName,
        subtitle: 'Due ${formatApiDate(m.effectiveDate)}',
        actions: [
          QuickAction(
            icon: Icons.today_rounded,
            label: 'Done today',
            color: AppColors.success,
            onTap: () => _complete(m, DateTime.now()),
          ),
          QuickAction(
            icon: Icons.edit_calendar_rounded,
            label: 'Done on another date…',
            color: AppModules.ta.color,
            onTap: () => _pickDate(m),
          ),
        ],
      );

  Future<void> _generate({required bool hasExisting}) async {
    final ok = await confirmAction(
      context,
      title: hasExisting ? 'Regenerate T&A calendar?' : 'Generate T&A calendar?',
      message: hasExisting
          ? 'Milestones will be generated again from the T&A template for this order\'s style.'
          : 'Milestones and planned dates will be created from the T&A template, counting back from the ex-factory date.',
      confirmLabel: 'Generate',
    );
    if (ok) _list.generate(widget.styleId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taMilestoneListControllerProvider(widget.orderId));
    if (state is TaMilestoneListLoaded) _last = state.milestones;
    final hasExisting = (_last ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('T&A Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Generate from template',
            onPressed: () => _generate(hasExisting: hasExisting),
          ),
          IconButton(
            icon: const Icon(Icons.view_timeline_outlined),
            tooltip: 'T&A templates',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaTemplateListScreen())),
          ),
        ],
      ),
      body: switch (state) {
        // Keep showing the last timeline during a background refresh.
        TaMilestoneListLoading() when _last != null && _last!.isNotEmpty => _timeline(_last!),
        TaMilestoneListLoading() => const LoadingView(),
        TaMilestoneListError(:final failure) => ErrorStateView(failure: failure, onRetry: _list.refresh),
        TaMilestoneListLoaded(:final milestones) when milestones.isEmpty => EmptyStateView(
            title: 'No T&A milestones yet',
            message: "Generate the Time & Action calendar from the style's template to track every critical date.",
            icon: Icons.event_note_outlined,
            color: AppModules.ta.color,
            actionLabel: 'Generate calendar',
            actionIcon: Icons.auto_awesome_outlined,
            onAction: () => _generate(hasExisting: false),
          ),
        TaMilestoneListLoaded(:final milestones) => _timeline(milestones),
      },
    );
  }

  bool _isDone(TaMilestone m) => m.status == TaMilestoneStatus.done || _pending.containsKey(m.id);

  String _statusOf(TaMilestone m) => _isDone(m) ? TaMilestoneStatus.done.apiValue : m.status.apiValue;

  Widget _timeline(List<TaMilestone> milestones) {
    final done = milestones.where(_isDone).length;
    final late = milestones
        .where((m) =>
            !_isDone(m) && (m.status == TaMilestoneStatus.overdue || m.status == TaMilestoneStatus.criticalDelay))
        .length;
    final dueSoon = milestones.where((m) {
      if (_isDone(m)) return false;
      final d = daysFromToday(m.effectiveDate);
      return d != null && d >= 0 && d <= 7;
    }).length;

    return RefreshIndicator(
      onRefresh: _list.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: milestones.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GradientHeader.module(
              AppModules.ta,
              eyebrow: 'Time & Action',
              title: '$done of ${milestones.length} done',
              subtitle: late > 0 ? '$late milestone${late == 1 ? '' : 's'} running late' : 'Everything on track',
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: milestones.isEmpty ? 0 : done / milestones.length,
                      minHeight: 8,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      HeaderStat(value: '$done', label: 'Done'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(value: '$late', label: 'Late'),
                      const SizedBox(width: AppSpacing.xxl),
                      HeaderStat(value: '$dueSoon', label: 'Due in 7 days'),
                    ],
                  ),
                ],
              ),
            );
          }
          final i = index - 1;
          final m = milestones[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _TimelineItem(
              milestone: m,
              status: _statusOf(m),
              pendingActualDate: _pending[m.id],
              previousColor: i == 0 ? null : AppStatus.color(_statusOf(milestones[i - 1])),
              isLast: i == milestones.length - 1,
              onDoneToday: _isDone(m) ? null : () => _complete(m, DateTime.now()),
              onMore: _isDone(m) ? null : () => _actions(m),
              onOtherDate: _isDone(m) ? null : () => _pickDate(m),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.milestone,
    required this.status,
    required this.previousColor,
    required this.isLast,
    this.pendingActualDate,
    this.onDoneToday,
    this.onMore,
    this.onOtherDate,
  });

  final TaMilestone milestone;
  final String status;
  final String? pendingActualDate;
  final Color? previousColor;
  final bool isLast;
  final VoidCallback? onDoneToday;
  final VoidCallback? onMore;
  final VoidCallback? onOtherDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final m = milestone;
    final color = AppStatus.color(status);
    final done = onDoneToday == null;
    final actual = pendingActualDate ?? m.actualDate;
    final daysToGo = daysFromToday(m.effectiveDate);

    Widget? badge;
    if (m.delayDays > 0) {
      badge = TonePill('${m.delayDays} d late', color: AppColors.danger, icon: Icons.schedule_rounded);
    } else if (!done && daysToGo != null && daysToGo >= 0 && daysToGo <= 14) {
      badge = TonePill(relativeDays(daysToGo), color: daysToGo <= 2 ? AppColors.warning : AppColors.info);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(width: 3, color: previousColor?.withValues(alpha: 0.5) ?? Colors.transparent),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient(color),
                    boxShadow: AppColors.softShadow(color),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Text('${m.sequence}',
                          style:
                              theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: Container(width: 3, color: isLast ? Colors.transparent : color.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              accentColor: color,
              onTap: onMore,
              onLongPress: onMore,
              child: RecordRow(
                title: m.milestoneTypeName,
                subtitle: [
                  'Due ${formatApiDate(m.effectiveDate)}',
                  if (m.revisedDate != null) 'planned ${formatApiDate(m.plannedDate)}',
                ].join(' · '),
                meta: [
                  if (actual != null) 'Done ${formatApiDate(actual)}',
                  if (m.delayReason != null) 'Delay: ${m.delayReason}',
                ].join(' · '),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status, dense: true),
                    if (badge != null) ...[const SizedBox(height: AppSpacing.xs), badge],
                  ],
                ),
                footer: done
                    ? null
                    : Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: onDoneToday,
                            icon: const Icon(Icons.task_alt_rounded, size: 18),
                            label: const Text('Done today'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton(
                            onPressed: onOtherDate,
                            style: TextButton.styleFrom(foregroundColor: s.onSurfaceVariant),
                            child: const Text('Other date'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
