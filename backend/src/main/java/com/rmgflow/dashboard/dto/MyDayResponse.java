package com.rmgflow.dashboard.dto;

import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.ta.dto.TaMilestoneResponse;
import com.rmgflow.task.dto.TaskResponse;

import java.util.List;

/** Document 14.9: the single cross-module "what needs attention today" view —
 * the recommended post-login landing endpoint, built from queries Phases 4/7/12
 * already expose rather than a new duplicated data path. */
public record MyDayResponse(
        List<TaMilestoneResponse> myOverdueMilestones,
        List<ApprovalResponse> organizationPendingApprovals,
        List<TaskResponse> myOverdueTasks
) {
}
