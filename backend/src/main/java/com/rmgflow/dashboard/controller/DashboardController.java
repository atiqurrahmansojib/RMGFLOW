package com.rmgflow.dashboard.controller;

import com.rmgflow.approval.service.ApprovalService;
import com.rmgflow.dashboard.dto.MyDayResponse;
import com.rmgflow.ta.service.TaMilestoneService;
import com.rmgflow.task.service.TaskItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Document 14.9's own recommendation: one cross-module "what needs attention
 * today" endpoint, built from queries each owning module already exposes
 * (TaMilestoneService/ApprovalService/TaskItemService) rather than a new
 * duplicated data path. Intended as the post-login landing view for every
 * operational role (Doc 14.9).
 */
@RestController
@RequestMapping("/api/v1/dashboard/my-day")
@RequiredArgsConstructor
public class DashboardController {

    private final TaMilestoneService taMilestoneService;
    private final ApprovalService approvalService;
    private final TaskItemService taskItemService;

    @GetMapping
    public MyDayResponse myDay() {
        return new MyDayResponse(
                taMilestoneService.myOverdueMilestones(),
                approvalService.pendingInbox(null, PageRequest.of(0, 50)).getContent(),
                taskItemService.myOverdueTasks()
        );
    }
}
