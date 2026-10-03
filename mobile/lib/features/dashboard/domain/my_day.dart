import '../../approval/domain/approval.dart';
import '../../ta/domain/ta_milestone.dart';
import '../../task/domain/task_item.dart';

/// Mirrors backend MyDayResponse (Doc 14.9) — the single cross-module "what
/// needs attention today" view, assembled server-side from queries the
/// owning modules already expose (TaMilestoneService/ApprovalService/
/// TaskItemService), never a duplicated data path.
class MyDay {
  const MyDay({
    required this.myOverdueMilestones,
    required this.organizationPendingApprovals,
    required this.myOverdueTasks,
  });

  factory MyDay.fromJson(Map<String, dynamic> json) => MyDay(
        myOverdueMilestones: (json['myOverdueMilestones'] as List? ?? [])
            .map((e) => TaMilestone.fromJson(e as Map<String, dynamic>))
            .toList(),
        organizationPendingApprovals: (json['organizationPendingApprovals'] as List? ?? [])
            .map((e) => Approval.fromJson(e as Map<String, dynamic>))
            .toList(),
        myOverdueTasks: (json['myOverdueTasks'] as List? ?? [])
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<TaMilestone> myOverdueMilestones;
  final List<Approval> organizationPendingApprovals;
  final List<TaskItem> myOverdueTasks;
}
